`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2024 12:34:17 PM
// Design Name: 
// Module Name: tb_evict_cont
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


module tb_evict_cont();
    
    localparam ADDR_WIDTH = 12;
    localparam TAG_WIDTH = 5;
    localparam INDEX_BITS = 3;
    localparam OFFSET_BITS = 2;
    
    reg clk, nrst;
    reg [ADDR_WIDTH-1:0] addr;
    reg [TAG_WIDTH-1:0] r_tag_info_of_LRU;
    reg [INDEX_BITS-1:0] r_index;
    reg [OFFSET_BITS-1:0] r_offset;
    reg [128:0] r_data;
    reg evict_en;
    
    wire enaA;
    wire [ADDR_WIDTH-1:0] addr_to_BRAM;
    wire [31:0] dinA;
    wire [3:0] wea;
    
    
    eviction_controller # (
     .TAG_WIDTH(TAG_WIDTH), .INDEX_BITS(INDEX_BITS), .OFFSET_BITS(OFFSET_BITS), .ADDR_WIDTH(ADDR_WIDTH))
        UUT (
        .clk(clk),  .nrst(nrst),
        .i_tag_info_of_LRU(r_tag_info_of_LRU),
        .i_index(r_index), .i_offset(r_offset),
        .i_LRU_data_cache_line(r_data),
        .i_guard_evict(),
        .i_evict_en(evict_en),
        
        .o_addr_to_BRAM(addr_to_BRAM),
        .o_weB(wea),
        .o_data_to_BRAM(dinA),
        .o_enaB(enaA)
        );
        
    single_port_bram #(.ADDR_WIDTH(ADDR_WIDTH))
      bram (.clkA(clk), .addrA(addr_to_BRAM), .enaA(1'b1), .dinA(dinA), .weA(wea));

    
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        evict_en = 0;
        nrst = 0;
        addr = 12'h000;
        #12
        nrst = 1;
        #18
        r_tag_info_of_LRU = 5'b00000;
        r_index = 3'b010;
        r_offset = 2'b00;
        evict_en = 1;
        r_data = 128'hAAAAAAAABBBBBBBBCCCCCCCCDDDDDDDD;
        #200
        $finish;
    end
    
endmodule
