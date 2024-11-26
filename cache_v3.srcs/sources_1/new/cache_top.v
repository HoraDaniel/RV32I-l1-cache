`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 08:04:18 AM
// Design Name: 
// Module Name: cache_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_top 
    #(  parameter CACHE_WAY = 8, //
        parameter CACHE_SIZE = 64,  // in blocks Choices: 32, 64, 128
        parameter ADDR_WIDTH = 12 // since 4kB we should limit this
    )
    (
        input clk,
        input nrst,
        input [ADDR_WIDTH-1:0] addr,
        input rd,
        input wr,
        input [31:0] data_i,
        
        output [31:0] data_o,
        output all_done
        
    );
    
    
    //================ Derived parameters ========================//
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam INDEX_BITS = $clog2(NUM_SETS); //index 
    localparam OFFSET_BITS = 2;
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS - 2; // why -2? Since I assume accesses to the memory are word aligned, last 2 bits are always 00.
    
    
    wire                            tag_hit;
    wire data_hit = tag_hit;
    wire wr_en;
    
    wire [TAG_BITS-1:0]             tag;
    wire [OFFSET_BITS-1:0]          offset;
    wire [INDEX_BITS-1:0]           index;
    
    wire [$clog2(CACHE_WAY)-1:0]    curr_way;
    wire [CACHE_WAY-1:0]            way_accessed_to_controller;
    
    wire [31:0]                     data_bus;
    
    wire [$clog2(CACHE_WAY)-1:0]    LRU_set_wire;
    wire [TAG_BITS+2:0]             tag_bits_of_LRU_way;
    wire                            burst_en;
    wire [31:0]                     doutA_from_BRAM;
    wire                            enaA;
    wire                            wr_tag_en;
    
    wire [ADDR_WIDTH-1:0]           addr_wire_to_BRAM;
    wire [127:0]                    data_wire_fromBram_toCache;
    wire                            burst_done;
    
    wire                            evict_en;
    wire                            guard_evict;
    wire [ADDR_WIDTH-1:0]           addr_wire_to_BRAM_B; // port B are for Evictions
    wire [127:0]                    data_wire_Cache_to_BRAM_B;
    wire [31:0]                     data_wire_to_BRAM_B;
    wire [3:0]                      weB;
    
    
    //================ Module Instantiations =========================//
    cache_controller #(.CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE), .ADDR_WIDTH(ADDR_WIDTH), 
        .TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS))
        cache_controller(
            .clk(clk),            .nrst(nrst),
            .i_addr(addr),
            
            .i_rd(rd),
            .i_wr(wr),
            .i_hit(tag_hit),
            .i_data(data_i),
            .i_way_accessed(way_accessed_to_controller),
            .i_done_burst_cont(burst_done),
            .i_tag_info_of_LRU(tag_bits_of_LRU_way),
            
            .o_rdwr(wr_en),
            .o_tag(tag), .o_index(index), .o_offset(offset),
            .o_LRU_set(LRU_set_wire),
            .o_burst_en(burst_en),
            .o_wr_tag(wr_tag_en),
            .o_data(data_bus),
            .o_evict_en(evict_en),
            .o_guard_evict(guard_evict),
            
            .o_all_done(all_done)

        );
    
    
    tag_mem #(.TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE))
        tag_array(
            .clk(clk),
            .nrst(nrst),
            
            .i_wr_en(wr_tag_en),
            .i_tag(tag),            .i_index(index),
            .i_LRU_set(LRU_set_wire),
            
            .o_hit(tag_hit),
            .o_curr_way(curr_way),
            .o_way_accessed(way_accessed_to_controller),
            .o_LRU_set_tag_info(tag_bits_of_LRU_way)
        );
    
    cache_data #(.OFFSET_BITS(OFFSET_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE))
        data_array(
            .clk(clk),  .nrst(nrst), 
            .i_wr(wr_en),       .i_rd(rd),
            .i_hit(tag_hit), 
            .i_way(curr_way),   .i_index(index), .i_offset(offset),
            .i_data(data_bus),    .i_data_from_BRAM(data_wire_fromBram_toCache),
            .i_LRU_set(LRU_set_wire), 
            .i_data_BRAM_isValid(burst_done),
            .i_evict_en(evict_en),
            .i_guard_evict(guard_evict),
            
            .o_data(data_o),
            .o_data_to_evict(data_wire_Cache_to_BRAM_B)
        );
        
    dual_port_bram #(.ADDR_WIDTH(ADDR_WIDTH))
        bram (
            .clkA(clk), .addrA(addr_wire_to_BRAM), .enaA(1'b1), .doutA(doutA_from_BRAM),
            .clkB(clk), .addrB(addr_wire_to_BRAM_B), .enaB(1'b1), .dinB(data_wire_to_BRAM_B), .weB(weB)
            
            );
        
        
    burst_cont #(.ADDR_WIDTH(ADDR_WIDTH))
        burst_cont(.burst_en(burst_en), .enaA(enaA), .clk(clk), .nrst(nrst), .addr(addr), 
            .data_from_BRAM(doutA_from_BRAM), .data_to_cache(data_wire_fromBram_toCache), .addr_to_BRAM(addr_wire_to_BRAM),
            .burst_done(burst_done));
    
    eviction_controller #(
        .TAG_WIDTH(TAG_BITS),
        .INDEX_BITS(INDEX_BITS),
        .OFFSET_BITS(OFFSET_BITS),
        .ADDR_WIDTH(ADDR_WIDTH)
        )
        evict_cont(
            .clk(clk),  .nrst(nrst),
            .i_tag_info_of_LRU(tag_bits_of_LRU_way),            .i_index(index),         .i_offset(offset),
            .i_LRU_data_cache_line(data_wire_Cache_to_BRAM_B),   .i_evict_en(evict_en),      .i_guard_evict(guard_evict),
            
            .o_addr_to_BRAM(addr_wire_to_BRAM_B),          .o_weB(weB),           .o_data_to_BRAM(data_wire_to_BRAM_B),
            .o_enaB()
        );
    
endmodule
