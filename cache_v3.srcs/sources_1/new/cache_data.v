`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 08:04:18 AM
// Design Name: 
// Module Name: cache_controller
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


module cache_data 
    #(  parameter OFFSET_BITS = 2, //DEFAULT for 4 blocks
        parameter INDEX_BITS = 3,//DEFAULT FOR 4 WAY
        parameter CACHE_WAY = 4,
        parameter CACHE_SIZE = 32
    )
    (
    // Controller signals
    input clk,
    input nrst,
    input                           i_wr,
    input                           i_rd,
    input                           i_hit,
    input                           i_data_BRAM_isValid,
    
    input [CACHE_WAY-1:0]           i_LRU_set,
    
    // Address
    input [$clog2(CACHE_WAY)-1:0]   i_way,
    input [INDEX_BITS-1:0]          i_index,
    input [OFFSET_BITS-1:0]         i_offset,
    
    // Data
    input [31:0]                    i_data,
    input [127:0]                   i_data_from_BRAM,
    
    // Outputs
    output [31:0]                   o_data // to load block?
    );
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    
    
    //================ Assigning internal wires =================// 
    
    
    //================ Assigning Registers =====================//
    reg [31:0] data[CACHE_WAY-1:0][NUM_SETS-1:0][3:0]; // data[way][index][offset]
    
   //================ Hardcoded values for tb ================//
    initial begin
        data[0][5][0] = 32'hB055ADE1;
        data[0][4][0] = 32'hDEADBEEF;
    
    end
    
    //================= Assigning outputs =======================//
    assign o_data = (i_hit) ? data[i_way][i_index][i_offset] : 32'h0; // read hit
    
    
    
    //================= SYCHRONOUS WRITES ===============================//
    always @(posedge clk) begin
        if (!nrst) begin
            
        end
        else begin
            case (i_wr) 
                1'd0: begin
                    //reads
                end
                
                1'd1: begin
                    // writes
                    if (i_hit) begin
                        data[i_way][i_index][i_offset] <= i_data;
                    end  
                end
            endcase
            if (i_data_BRAM_isValid) begin
                // why use i_way if its for hits? because of the Tag Writes accessing first the LRU way, it automatically sets
                // the LRU way as the accessed way (i_way), so if we used the actual LRU sent by the Cache controller,
                // there will be discrepancies in the Tag Writes and Data Writes.
                data[i_way][i_index][3] <= i_data_from_BRAM[31:0];
                data[i_way][i_index][2] <= i_data_from_BRAM[63:32];
                data[i_way][i_index][1] <= i_data_from_BRAM[95:64]; 
                data[i_way][i_index][0] <= i_data_from_BRAM[127:96];
            end
        end
    end
    
    
    
    
    
endmodule
