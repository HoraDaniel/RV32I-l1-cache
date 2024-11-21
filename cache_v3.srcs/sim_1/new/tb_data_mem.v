`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 05:58:16 PM
// Design Name: 
// Module Name: tb_data_mem
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


module tb_data_mem(

    );
    
    localparam INDEX_BITS = 3;
    localparam OFFSET_BITS = 3;
    localparam CACHE_WAY = 4;
    
    reg clk;
    reg nrst;
    reg [INDEX_BITS-1:0] index;
    reg [OFFSET_BITS-1:0] offset;
    reg [CACHE_WAY-1:0] way_hit;
    
    wire [31:0] data_o;
    
    
    cache_data #() 
        data_array(
            .clk(clk),
            .nrst(nrst),
            .index(index),
            .offset(offset),
            .way(way_hit),
            .data_o(data_o)
        );
    
    
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        nrst = 0;
        
        # 10
        nrst = 1;
        
        # 10
        index = 2;
        offset = 0;
        way_hit = 4'b1000;
        
        #10
        index = 1;
        offset = 1;
        way_hit = 4'b0100;
    end

        
endmodule
