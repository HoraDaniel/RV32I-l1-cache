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
        
        output [31:0] data_o
    );
    
    
    //================ Derived parameters ========================//
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam INDEX_BITS = $clog2(NUM_SETS); //index 
    localparam OFFSET_BITS = 2;
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS - 2; // why -2? Since I assume accesses to the memory are word aligned, last 2 bits are always 00.
    
    
    wire tag_hit;
    wire data_hit = tag_hit;
    wire wr_en;
    
    wire [TAG_BITS-1:0] tag;
    wire [OFFSET_BITS-1:0] offset;
    wire [INDEX_BITS-1:0] index;
    
    wire [$clog2(CACHE_WAY)-1:0] curr_way;
    wire [CACHE_WAY-1:0] way_accessed_to_controller;
    
    wire [CACHE_WAY-1:0]LRU_set_wire;
    wire burst_en;
    wire [31:0] doutA_from_BRAM;
    wire enaA;
    wire wr_tag_en;
    
    wire [ADDR_WIDTH-1:0] addr_wire_to_BRAM;
    wire [127:0] data_wire_fromBram_toCache;
    wire burst_done;
    
    //================ Module Instantiations =========================//
    cache_controller #(.CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE), .ADDR_WIDTH(ADDR_WIDTH), 
        .TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS))
        cache_controller(
            .clk(clk),
            .nrst(nrst),
            .addr(addr),
            .tag(tag), .index(index), .offset(offset),
            .rd(rd),
            .wr(wr),
            .hit(tag_hit),
            .data_in(data_i),
            .rdwr(wr_en),
            .way_accessed(way_accessed_to_controller),
            .LRU_set(LRU_set_wire),
            .burst_en(burst_en),
            .done_burst_cont(burst_done),
            .wr_tag(wr_tag_en)

        );
    
    
    tag_mem #(.TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE))
        tag_array(
            .clk(clk),
            .nrst(nrst),
            
            .wr_en(wr_tag_en),
            
            .tag(tag),
            .index(index),
            
            .hit(tag_hit),
            .curr_way(curr_way),
            .way_accessed(way_accessed_to_controller),
            .valid_bit(valid_bit),
            .dirty_bit(dirty_bit),
            .lru_bit(lru_bit),
            
            .LRU_set(LRU_set_wire)
            
        );
    
    cache_data #(.OFFSET_BITS(OFFSET_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE))
        data_array(
            .clk(clk),  .nrst(nrst), 
            .wr(wr_en), .rd(rd),
            .hit(tag_hit), 
            .way(curr_way), .index(index), .offset(offset),
            .data_i(data_i), .data_o(data_o),
            .LRU_set(LRU_set_wire), .din_from_BRAM(data_wire_fromBram_toCache),
            .data_BRAM_valid(burst_done)
        );
        
    single_port_bram #(.ADDR_WIDTH(ADDR_WIDTH))
        bram (.clkA(clk), .addrA(addr_wire_to_BRAM), .enaA(enaA), .doutA(doutA_from_BRAM));
        
        
    burst_cont #(.ADDR_WIDTH(ADDR_WIDTH))
        burst_cont(.burst_en(burst_en), .enaA(enaA), .clk(clk), .nrst(nrst), .addr(addr), 
            .data_from_BRAM(doutA_from_BRAM), .data_to_cache(data_wire_fromBram_toCache), .addr_to_BRAM(addr_wire_to_BRAM),
            .burst_done(burst_done));
    
endmodule
