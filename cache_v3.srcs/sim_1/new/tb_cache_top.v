`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2024 12:49:40 PM
// Design Name: 
// Module Name: tb_cache_top
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


module tb_cache_top();

    reg clk, nrst;
    reg [31:0] addr;
    reg [31:0] data_i;
    reg rd, wr;
    
    wire [31:0] data_o;
        
    cache_top #(.CACHE_SIZE(64), .CACHE_WAY(8), .ADDR_WIDTH(12)) 
        TOP(
            .clk(clk),  .nrst(nrst),
            .addr(addr),
            .rd(rd),    .wr(wr),
            .data_i(data_i),    .data_o(data_o)
        );
        
    always #10 clk = ~clk;
    initial begin
        clk = 0;
        nrst = 0;
        #10
        nrst = 1;
        #20
        //data_i = 32'hC0E197AB;
        addr = 12'h00055e50;
        data_i = 32'hBADC0DE;
        wr=1;
        #10
        #10
        #10
        addr = 12'h00000000;
        data_i = 32'hABABABAB;
        #150
        wr=0;
        addr = 12'h004;
        rd = 1;
        $finish;
    end

endmodule
