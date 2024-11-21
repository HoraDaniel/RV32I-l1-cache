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
        parameter INDEX_BITS = 3,//DEFAULT FOR 4 WAY
        parameter CACHE_WAY = 8,
        parameter CACHE_SIZE = 32
    )
    
    (
    input clk,
    input nrst,
    
    input wr_en,
    
    input [TAG_BITS-1:0] tag,
    input [INDEX_BITS-1:0] index,
    
    input [CACHE_WAY-1:0] LRU_set,
    
    output wire hit,
    output wire [$clog2(CACHE_WAY)-1:0] curr_way,
    output wire [CACHE_WAY-1:0] way_accessed,
    output wire valid_bit,
    output wire dirty_bit,
    output wire lru_bit
    );
    
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    localparam TAG_BITS_LRU = TAG_BITS + 3; // [Valid, Data, LRU] + TAG_BIT lengths
    
    
    wire clk_inv = ~clk;
    wire [$clog2(CACHE_WAY)-1:0] lru;
    reg [CACHE_WAY-1:0] way_hit;
    reg hit_r;
    reg [TAG_BITS_LRU-1:0] tag_data[CACHE_WAY-1:0][NUM_SETS-1:0];
    reg [TAG_BITS_LRU-1:0] tag_info;
    
    assign valid_bit = tag_info[TAG_BITS_LRU-1];
    assign dirty_bit = tag_info[TAG_BITS_LRU-2];
    assign lru_bit = tag_info[TAG_BITS_LRU-3];
    assign hit = (valid_bit & hit_r);
    assign way_accessed = way_hit;
    
    // HARDCODED VALUES FOR TB
    initial begin
        tag_data[0][5] = {3'b100, 24'h0000ABC};
        tag_data[1][2] = {3'b100, 24'h0000123};
    end
    
   //================= Module instantiation ====================//
   way_decoder #(.CACHE_WAY(CACHE_WAY)) //Thank you ChatGPT
        way_decode_to_data_array(
            .way_hit(way_hit),
            .way_number(curr_way)
        );
        
    way_decoder #(.CACHE_WAY(CACHE_WAY)) //Thank you ChatGPT
        way_decode_LRU(
            .way_hit(LRU_set),
            .way_number(lru)
        );
    
    
    integer i;
    always@(*) begin
        way_hit <= 0;
        tag_info <= 0;
        hit_r <= 0;
        for (i = 0; i < CACHE_WAY; i = i+1) begin
            if ( (tag == tag_data[i][index][TAG_BITS_LRU-4:0])) begin
                tag_info <= tag_data[i][index];
                way_hit[i] <= 1;
                hit_r <= 1;
            end
        end
    end
    
    //================= TAG WRITES ==================//
    always@(posedge clk) begin
        if (!nrst) begin
            
        end
        else begin
            case (wr_en)
                1'd1: begin
                    // write tag
                    if (hit) begin
                        // Cache read hit, update the valid, dirty and LRU bit
                        tag_data[curr_way][index][TAG_BITS_LRU-2] <= 1'b1;
                    end else begin
                        tag_data[lru][index] <= {3'b100, tag};
                    end
                end
            endcase
        end
    end
    
    
endmodule
