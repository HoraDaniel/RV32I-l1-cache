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


module cache_controller
    #(  parameter CACHE_WAY = 8, //
        parameter CACHE_SIZE = 32,  // in blocks Choices: 32, 64, 128
        parameter ADDR_WIDTH = 12, // since 4kB we should limit this
        parameter TAG_BITS = 25,
        parameter INDEX_BITS = 3,
        parameter OFFSET_BITS = 2
    )
    (
    input clk,
    input nrst,
    
    input [ADDR_WIDTH-1:0]          i_addr,
    input                           i_rd,
    input                           i_wr,
    input                           i_hit,              // From the Tag Array, asserts when there's a tag hit
    input                           i_done_burst_cont,  // From the Burst Controller
    input [31:0]                    i_data,
    input [CACHE_WAY-1:0]           i_way_accessed,
    
    // output: control signals
    output                          o_rdwr,             // WRITE = 1; READ = 0;
    output                          o_wr_tag,
    output                          o_burst_en,
    
    output [$clog2(CACHE_WAY)-1:0]  o_LRU_set,
    
    output [ADDR_WIDTH-1:0]         o_addr_to_BRAM,
    
    
    output [TAG_BITS-1:0]           o_tag,
    output [INDEX_BITS-1:0]         o_index,
    output [OFFSET_BITS-1:0]        o_offset
    
    );
    
    //================ Derived parameters ========================//
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    
    
    //================ States declaration ======================//
    reg [3:0] state;
    localparam S_IDLE = 4'b0000;
    localparam S_READ = 4'b0001;
    localparam S_WRITE = 4'b0010;
    localparam S_WAITFORMM = 4'b0011;
    localparam S_UPDATING = 4'b00100;
    localparam S_READMM = 4'b00101; 
    
    //================ Assigning Wires =========================//
    // Parse the address
    assign o_offset = i_addr[3:2];                                // offset is fixed since there will always be 4 words per block // TODO: fix this
    assign o_index = i_addr[ADDR_WIDTH - TAG_BITS - 1:4];
    assign o_tag = i_addr[ADDR_WIDTH-1: ADDR_WIDTH - TAG_BITS];
   
    
    // Internal wires
    wire [CACHE_WAY-1:0] LRU_set_wire;           // One hot encoding result of the PLRU module
    wire [$clog2(CACHE_WAY)-1:0] LRU_way;        // Decoded decimal from LRU_set_wire
    
    
    //Outputs
    assign o_rdwr = (state[1]) ? 1'b1 : 1'b0;
    assign o_burst_en = (state[2]) ? 1'b1 : 1'b0;
    assign o_wr_tag = (state[2] | state[1]) ? 1'b1 : 1'b0;
    assign o_LRU_set = LRU_way;
     
    // ============ Module instantiation ========//
    eightway_PLRU LRU_cont(  
        .i_way_accessed(i_way_accessed),
        .i_hit(i_hit),
        .o_LRU_set(LRU_set_wire)
        );
    
    way_decoder #(.CACHE_WAY(CACHE_WAY)) //Thank you ChatGPT
        way_decode(
            .way_hit(LRU_set_wire),
            .way_number(LRU_way)
        );
    
    
    // ============= FSM ==================//
    always@(posedge clk or negedge nrst) begin
        if (!nrst) begin
            // Reset signals go here
            state <= S_IDLE;
        end
        else begin
            case (state) 
                S_IDLE: begin
                    //wait for read/write signals
                    if (i_rd) state <= S_READ;
                    if (i_wr) state <= S_WRITE;
                end
                
                S_WRITE: begin
                    if (i_hit) state <= S_IDLE;
                    else state <= S_UPDATING;
                end
                
                S_READ: begin
                    if (i_hit) state <= S_IDLE;
                end
                
                S_UPDATING: begin
                    if (i_done_burst_cont) begin
                        if (i_rd) state <= S_READ;
                        else if (i_wr) state <= S_WRITE;
                    end
                end
            endcase
        end
    end
    
    
endmodule
