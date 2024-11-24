`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 04:43:34 PM
// Design Name: 
// Module Name: burst_cont
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


module burst_cont# (
    parameter ADDR_WIDTH = 12
    )(
    input clk,
    input nrst,
    input burst_en,
    input [ADDR_WIDTH-1:0] addr,
    input [31:0] data_from_BRAM,
    output [127:0] data_to_cache,
    output reg [ADDR_WIDTH-1:0] addr_to_BRAM,
    output reg enaA,
    output burst_done
    );
    
    
    // The buffer register
    reg [127:0] buffer;
    // the buffer is parsed into:
    //  [31:0] word 0
    //  [63:32] word 1
    //  [95:64] word 3
    //  [127:96] word 4
    
    
    // Generate burst address for the BRAM
    reg [ADDR_WIDTH-1:0] addrs [3:0];
    reg first_clock_cycle;
    reg [1:0] counter;    
    reg done;
    
    assign burst_done = done;
    assign data_to_cache = buffer;
    
    initial begin
        counter = 0;
        first_clock_cycle = 0;
        done = 0;
    end

    
    always@(*) begin
        if (nrst) begin
            addrs[0] <= {addr[ADDR_WIDTH-1:4],4'h00};
            addrs[1] <= {addr[ADDR_WIDTH-1:4],4'h04};
            addrs[2] <= {addr[ADDR_WIDTH-1:4],4'h08};
            addrs[3] <= {addr[ADDR_WIDTH-1:4],4'h0C};  
        end
        addr_to_BRAM <= addrs[counter] >> 2; // IMPORTANT: REMOVE THE BITSHIFT BEFORE CONNECTING TO THE CORE WE'LL LOSE THE OFFSET
    end 
    
    // sequentially fetch the data from the addrs
    // This is so weird honestly
    always @(negedge clk) begin
        if (nrst && burst_en) begin

           // begin on the next clock cycle
           // Dunno why, but the timing is wrong if not
           if (!first_clock_cycle) begin
                first_clock_cycle = 1;
           end
           else begin
                counter <= counter + 1;
           end
           
           
           if (counter == 3) begin
                counter <= 0;
                done <= 1;
                enaA <= 0;
                first_clock_cycle <= 0;
           end
            
        end
        if (counter == 0 && !burst_en) done <= 0;
        if (burst_en && !done) enaA <= 1;
        else enaA <= 0;
        
        if (first_clock_cycle && enaA && burst_en) begin
            buffer <= {buffer[95:0], data_from_BRAM};
        end
    end
    
    always@(posedge clk) begin
        if (!nrst) begin
            counter <= 0;
            addr_to_BRAM <= 0;
            enaA <= 0;
        end
        else begin

           
        end
    end
    
endmodule
