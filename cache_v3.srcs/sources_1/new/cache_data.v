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
    input wr,
    input rd,
    input hit,
    input data_BRAM_valid,
    
    input [CACHE_WAY-1:0] LRU_set,
    
    // Address
    input [$clog2(CACHE_WAY)-1:0] way,
    input [INDEX_BITS-1:0] index,
    input [OFFSET_BITS-1:0] offset,
    
    // Data
    input [31:0] data_i,
    input [127:0] din_from_BRAM,
    
    // Outputs
    output [31:0] data_o // to load block?
    );
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    
    
    //================ Assigning internal wires =================// 
    wire [$clog2(CACHE_WAY)-1:0] lru_way;
    
    way_decoder #(.CACHE_WAY(CACHE_WAY)) 
        decode_LRU(.way_hit(LRU_set), .way_number(lru_way));
    
    
    //================ Assigning Registers =====================//
    reg [31:0] data[CACHE_WAY-1:0][NUM_SETS-1:0][3:0]; // data[way][index][offset]
    
   //================ Hardcoded values for tb ================//
    initial begin
        data[0][5][0] = 32'hB055ADE1;
        data[0][4][0] = 32'hDEADBEEF;
    
    end
    
    //================= Assigning outputs =======================//
    assign data_o = (hit) ? data[way][index][offset] : 32'h0; // read hit
    
    
    
    //================= SYCHRONOUS WRITES ===============================//
    always @(posedge clk) begin
        if (!nrst) begin
            
        end
        else begin
            case (wr) 
                1'd0: begin
                    //reads
                end
                
                1'd1: begin
                    // writes
                    if (hit) begin
                        data[way][index][offset] <= data_i;
                    end  
                end
            endcase
            if (data_BRAM_valid) begin
                            data[way][index][3] <= din_from_BRAM[31:0];
                            data[way][index][2] <= din_from_BRAM[63:32];
                            data[way][index][1] <= din_from_BRAM[95:64]; 
                            data[way][index][0] <= din_from_BRAM[127:96];
            end
        end
    end
    
    
    
    
    
endmodule
