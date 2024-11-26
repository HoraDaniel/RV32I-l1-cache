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
    //reg [11:0] addr;
    //reg [31:0] data_i;
    //reg rd, wr;
    
    reg[47:0] ram_block[8:0];   
    

    reg [4:0] index;
    
    wire [47:0] test;
    wire [31:0] data_o;
    wire all_done;
    
    
    wire [3:0] rdwr = ram_block[index][47:44];
    wire [11:0] addr = ram_block[index][43:32];
    wire [31:0] data_i = ram_block[index][31:0];
    
    wire rd = rdwr[0];
    wire wr = rdwr[1];
    
    
    
    cache_top #(.CACHE_SIZE(64), .CACHE_WAY(8), .ADDR_WIDTH(12)) 
        TOP(
            .clk(clk),  .nrst(nrst),
            .addr(addr),
            .rd(rd),    .wr(wr),
            .data_i(data_i),    .data_o(data_o), .all_done(all_done)
        );
        
    always #10 clk = ~clk;
    initial begin
        clk = 0;
        nrst = 0;
        index = 0;
        
        $readmemh("tb_mem.mem", ram_block);
        #10
        index <= index + 1; // skip the first two test
        #2
        nrst = 1;
        #18
        index <= index + 1;
    end
    
    always@(posedge clk) begin
        if (all_done) index <= index + 1;
    end

endmodule
