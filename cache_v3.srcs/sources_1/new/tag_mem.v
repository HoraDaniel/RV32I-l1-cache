`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 01:30:07 PM
// Design Name: 
// Module Name: tag_mem
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


module tag_mem 
    #(  parameter TAG_BITS = 25, //DEFAULT IS 8 WAY
        parameter INDEX_BITS = 3,
        parameter CACHE_WAY = 8,
        parameter CACHE_SIZE = 32
    )
    
    (
    input clk,
    input nrst,
    
    input                               i_wr_en,            // Enable tag writes
    
    input [TAG_BITS-1:0]                i_tag,
    input [INDEX_BITS-1:0]              i_index,
    
    input [$clog2(CACHE_WAY)-1:0]       i_LRU_set,          // LRU set in decimal so we can already input it sa tag_data[i_LRU_set]
    
    output wire                         o_hit,
    output wire [$clog2(CACHE_WAY)-1:0] o_curr_way,         // current way accessed in decimal for input in data array
    output wire [CACHE_WAY-1:0]         o_way_accessed,     // one hot encoding of the way accessed for input in Cache Controller
    output wire                         o_LRU_set_tag_info
    );
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam TAG_BITS_LRU = TAG_BITS + 3;             // [Valid, Data, LRU] + TAG_BIT lengths
    
    
    
    reg [CACHE_WAY-1:0]     r_way_hit;
    reg                     r_hit;
    reg [TAG_BITS_LRU-1:0]  tag_data[CACHE_WAY-1:0][NUM_SETS-1:0];
    reg [TAG_BITS_LRU-1:0]  r_tag_info;
    
    wire valid_bit = r_tag_info[TAG_BITS_LRU-1];
    wire [$clog2(CACHE_WAY)-1:0] curr_way;
    wire hit = (valid_bit & r_hit);
    
    // ============== Assigning outputs ========================//
    
    assign o_hit = hit;
    assign o_way_accessed = r_way_hit;
    assign o_curr_way = curr_way;
    
    // HARDCODED VALUES FOR TB
    initial begin
        tag_data[0][5] = {3'b100, 24'h0000ABC};
        tag_data[1][2] = {3'b100, 24'h0000123};
    end
    
   //================= Module instantiation ====================//
   
   way_decoder #(.CACHE_WAY(CACHE_WAY)) //Thank you ChatGPT
        way_decode_to_data_array(
            .way_hit(r_way_hit),
            .way_number(curr_way)
        );
        
    
    // ============== TAG  READS ============================//
    // loop through all possible ways to check if its a hit
    integer i;
    always@(*) begin
        r_way_hit <= 0;
        r_tag_info <= 0;
        r_hit <= 0;
        for (i = 0; i < CACHE_WAY; i = i+1) begin
            if ( (i_tag == tag_data[i][i_index][TAG_BITS_LRU-4:0])) begin
                r_tag_info <= tag_data[i][i_index];
                r_way_hit[i] <= 1;
                r_hit <= 1;
            end
        end
    end
    
    //================= TAG WRITES ==================//
    always@(posedge clk) begin
        if (!nrst) begin
            
        end
        else begin
            if (i_wr_en) begin
                // write tag
                if (hit) begin
                    // Cache read hit, update the dirty bit
                    tag_data[curr_way][i_index][TAG_BITS_LRU-2] <= 1'b1;
                end else begin
                    tag_data[i_LRU_set][i_index] <= {3'b100, i_tag};
                end
            end
        end
    end
    
    
endmodule
