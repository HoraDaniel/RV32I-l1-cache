`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 05:49:55 PM
// Design Name: 
// Module Name: way_decoder
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


module way_decoder 
    # (parameter CACHE_WAY = 4)
    (
    input [CACHE_WAY-1:0] way_hit,
    output reg [$clog2(CACHE_WAY)-1:0] way_number
    );
    
    integer i;
    reg found;
    
    always @(*) begin
        way_number = 0;  // Default value if no way is hit
        found = 0;       // Reset found flag

        // Loop through each bit in way_hit
        for (i = 0; i < CACHE_WAY; i = i + 1) begin
            if (way_hit[i] && !found) begin
                way_number = i[$clog2(CACHE_WAY)-1:0];
                found = 1;  // Set found to break the loop
            end
        end
    end
endmodule
