`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 02:58:48 PM
// Design Name: 
// Module Name: tb_tag_mem
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


module tb_tag_mem();


    localparam CACHE_WAY = 8;
    localparam CACHE_SIZE = 128;
    
    localparam ADDR_WIDTH = 32;
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam INDEX_BITS = $clog2(NUM_SETS); //index 
    localparam OFFSET_BITS = 2;
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS - 2; 

    reg clk;
    reg nrst;
    reg [TAG_BITS-1:0] tag;
    reg [INDEX_BITS-1:0] index;
    reg wr;
    
    wire hit;
    wire curr_way;

    
    tag_mem #(.TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY), .CACHE_SIZE(CACHE_SIZE)) 
        tag_array(
            .clk(clk),
            .nrst(nrst),
            .tag(tag),
            .hit(hit),
            .curr_way(curr_way),
            .index(index),
            .wr_en(wr)
        );
    
    
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        nrst = 0;
        wr = 0;
        # 10
        nrst = 1;
        
        
        # 10
        tag = 24'h000ABC;
        index = 5;
        
        
        #10
        tag = 24'h000123;
        index = 2;
        
        #10
        tag = 24'h000A12;
        index = 3;
        
        #10
        tag = 24'h000123;
        index = 2;
        wr = 1;
        #20
        wr = 0;
    end
    
    


endmodule
