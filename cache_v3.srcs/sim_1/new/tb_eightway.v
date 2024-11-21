`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2024 09:57:23 AM
// Design Name: 
// Module Name: tb_eightway
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


module tb_eightway();

    reg [7:0] way_accessed;
    reg hit;
    
    
    eightway_PLRU UUT(.way_accessed(way_accessed), .hit(hit));
    
    
    initial begin
        hit = 1;
        way_accessed = 8'b00000001;
        
        #10
        way_accessed = 8'b01000000;
        
        #10
        way_accessed = 8'b10000000;
        
        #10
        way_accessed = 8'b00100000;
        
        #10
        way_accessed = 8'b00000000;
        
        #10
        way_accessed = 8'b00011000;
    end

    
endmodule
