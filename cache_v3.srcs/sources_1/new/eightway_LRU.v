`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2024 08:20:14 AM
// Design Name: 
// Module Name: eightway_LRU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module is the LRU controller to be instantiated if CACHE_WAY = 8;
//              This module's task is to take in the way accessed then update the LRU output on the tags
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module eightway_PLRU(
    input [7:0] i_way_accessed, // one hot encoding input from way_hit
    input i_hit,
    output reg [7:0] o_LRU_set
    );
    
    
    // ============= Assigning registers ======== //
    reg plru_bits[6:0]; // holds the MRU ( why the name tho? I dunno) 
    
    // ============= Assigning wires ============ //
    wire root = plru_bits[6];
    
    integer i; // Iterator for initialization
    
    initial begin
        for (i = 0; i < 7; i = i + 1) begin
            plru_bits[i] = 1'b1;
        end
    end
    
    
    
    
    // ============= Logic ======================= //
    always@(*) begin
        // Convert way_accessed to plru_bits
        // when in doubt, brute-force your way out!
        if (i_hit) begin
            case (i_way_accessed) 
                8'b00000001: begin
                    plru_bits[6] <= 0;
                    plru_bits[5] <= 0;
                    plru_bits[4] <= 0;
                end
                
                8'b00000010: begin
                    plru_bits[6] <= 1'b0;
                    plru_bits[5] <= 1'b0;
                    plru_bits[4] <= 1'b1;
                end
                
                8'b00000100: begin
                    plru_bits[6] <= 1'b0;
                    plru_bits[5] <= 1'b1;
                    plru_bits[3] <= 1'b0;
                end
                
                8'b00001000: begin
                    plru_bits[6] <= 1'b0;
                    plru_bits[5] <= 1'b1;
                    plru_bits[3] <= 1'b1;
                end
                
                8'b00010000: begin
                    plru_bits[6] <= 1'b1;
                    plru_bits[2] <= 1'b0;
                    plru_bits[1] <= 1'b0;
                end
                
                8'b00100000: begin
                    plru_bits[6] <= 1'b1;
                    plru_bits[2] <= 1'b0;
                    plru_bits[1] <= 1'b1;
                end
                
                8'b01000000: begin
                    plru_bits[6] <= 1'b1;
                    plru_bits[2] <= 1'b1;
                    plru_bits[0] <= 1'b0;
                end
                
                8'b10000000: begin
                    plru_bits[6] <= 1'b1;
                    plru_bits[2] <= 1'b1;
                    plru_bits[0] <= 1'b1;
                end    
            endcase
        end
       
    end
    
    always@(*) begin
        // Check for LRU set
        case (root)
            1'b0: begin
            // Go right subtree
                case (plru_bits[2])
                    1'b0: begin
                        //go right 
                        if (plru_bits[0]) o_LRU_set <= 8'b01000000;
                        else o_LRU_set <= 8'b10000000;
                    end
                    
                    1'b1: begin
                        //go left
                        if (plru_bits[1]) o_LRU_set <= 8'b00010000;
                        else o_LRU_set <= 8'b00100000;
                    end
                endcase
            end
            
            1'b1: begin
            // go left subtree
                case (plru_bits[5])
                    1'b0: begin
                        //go right
                        if (plru_bits[3]) o_LRU_set <= 8'b00000100;
                        else o_LRU_set <= 8'b00001000;
                    end
                    
                    1'b1: begin
                        //go left
                        if (plru_bits[4]) o_LRU_set <= 8'b00000001;
                        else o_LRU_set <= 8'b00000010;
                    end
                endcase
            end
        endcase
        
    end
endmodule
