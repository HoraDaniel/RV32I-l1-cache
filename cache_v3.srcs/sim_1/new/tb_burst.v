`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 04:58:01 PM
// Design Name: 
// Module Name: tb_burst
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


module tb_burst(

    );
    
    localparam ADDR_WIDTH = 12;
    
    reg clk, nrst;
    reg burst_en;
    reg [ADDR_WIDTH-1:0] addr;
    
    wire enaA;
    wire [ADDR_WIDTH-1:0] addr_to_BRAM;
    wire [31:0] doutA;
    
    burst_cont #(.ADDR_WIDTH(ADDR_WIDTH))
        UUT (.addr(addr), .clk(clk), .nrst(nrst), .enaA(enaA), .burst_en(burst_en), .addr_to_BRAM(addr_to_BRAM),
            .data_from_BRAM(doutA));
        
    single_port_bram #(.ADDR_WIDTH(ADDR_WIDTH))
      bram (.clkA(clk), .addrA(addr_to_BRAM), .enaA(enaA), .doutA(doutA));

    
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        burst_en = 0;
        nrst = 0;
        addr = 12'h00000000;
        #8
        nrst = 1;
        #2
        burst_en = 1;
        #200
        $finish;
    end
endmodule
