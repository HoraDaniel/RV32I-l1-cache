`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2024 09:09:15 AM
// Design Name: 
// Module Name: tb_bram
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


module tb_bram(

    );
    
    localparam ADDR_WIDTH = 12;
    
    reg clk;
    reg [11:0] addr;
    reg enaA;
    
    wire [31:0] doutA;
    
    single_port_bram #(.ADDR_WIDTH(ADDR_WIDTH))
        bram (.clkA(clk), .addrA(addr), .enaA(enaA), .doutA(doutA));
        
        
    always #10 clk = ~clk;
    initial begin
        clk = 0;
        enaA = 0;
        #10
        enaA = 1;
        addr = 12'h000;
        #20
        enaA=0;
        addr = 12'h001;
        #20
        enaA=1;
        #20
        $finish;
    end
endmodule
