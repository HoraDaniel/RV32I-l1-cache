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
//////////////////////////////////////  tik////////////////////////////////////////////


module tag_mem 
    #(  parameter TAG_BITS = 5, //DEFAULT IS 8 WAY
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
    output wire [TAG_BITS + 2:0]        o_LRU_set_tag_info  // to Cache controller in case of eviction
    );
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam TAG_BITS_LRU = TAG_BITS + 3;             // [Valid, Data, LRU] + TAG_BIT lengths
    
    
    
    reg [CACHE_WAY-1:0]     r_way_hit;
    reg                     r_hit;
    reg [TAG_BITS_LRU-1:0]  tag_data[CACHE_WAY-1:0][NUM_SETS-1:0];
    reg [TAG_BITS_LRU-1:0]  r_tag_info;
    reg [TAG_BITS_LRU-1:0]  r_LRU_set_tag_evicted;
    reg                     r_found_flag;               // for eviction
    
    wire valid_bit = r_tag_info[TAG_BITS_LRU-1];
    wire [$clog2(CACHE_WAY)-1:0] curr_way;
    wire hit = (valid_bit & r_hit);
    
    // ============== Assigning outputs ========================//
    
    assign o_hit = hit;
    assign o_way_accessed = r_way_hit;
    assign o_curr_way = curr_way;
    assign o_LRU_set_tag_info = r_LRU_set_tag_evicted;
    
    // HARDCODED VALUES FOR TB (addr width = 12; way = 8)
    integer x;
    integer y;
    initial begin
        for (x = 0; x < CACHE_WAY; x = x + 1) begin
            for (y = 0; y < NUM_SETS; y = y + 1) begin
                tag_data[x][y] = {3'b000, 5'h00}; // 0xFF is invalid data
            end
        end
        tag_data[0][5] = {3'b100, 5'h0000ABC};
        tag_data[1][2] = {3'b100, 5'h0000123};
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
                if (tag_data[i][i_index][TAG_BITS_LRU-1]) begin
                    r_tag_info <= tag_data[i][i_index];
                    r_way_hit[i] <= 1;
                    r_hit <= 1;
                end   
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
    
    //================= LRU WAY TAG WRITES =================//
    // at negedge of clock
    integer j;
    always@(negedge clk) begin
        // This won't work
        // We can't evict an invalid line, when the LRU pointer points another cache line on another Way
        // We'll be evicting an entirely different line, and write at an entirely different Way
        // That would be very bad
        r_found_flag <= 0;
        for (j=0; j < CACHE_WAY; j = j + 1) begin
            // check if there are invalid cache line we can evict
            // only once, so we have found flag
            if (!tag_data[j][i_index][TAG_BITS_LRU-1] && !r_found_flag) begin
                r_found_flag <= 1;
                r_LRU_set_tag_evicted <= tag_data[j][i_index][TAG_BITS_LRU-4:0];
            end
        end
        // All valids, so store the LRU
        if (!r_found_flag) begin
            r_LRU_set_tag_evicted <= tag_data[i_LRU_set][i_index][TAG_BITS_LRU-4:0];
        end
    end
    
    
endmodule
