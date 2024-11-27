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
    input [TAG_BITS+2:0]            i_tag_info_of_LRU,
    
    // output: control signals
    output                          o_rd,
    output                          o_wr,
    output                          o_wr_tag,
    output                          o_burst_en,
    
    output [$clog2(CACHE_WAY)-1:0]  o_LRU_set,
    
    output [ADDR_WIDTH-1:0]         o_addr_to_BRAM,
    
    
    output [TAG_BITS-1:0]           o_tag,
    output [INDEX_BITS-1:0]         o_index,
    output [OFFSET_BITS-1:0]        o_offset,
    output [31:0]                   o_data,
    output                          o_evict_en,
    output                          o_guard_evict, // A control signal to allow the eviction controller to sample  only once 
    
    
    
    //output for testbench only
    output                          o_all_done,
    output                          o_am_idle
    );
    
    //================ Derived parameters ========================//
    localparam NUM_SETS = CACHE_SIZE / CACHE_WAY;
    
    
    
    reg[ADDR_WIDTH-1:0]                     r_addr; // address latch
    reg[31:0]                               r_data; // data latch
    reg                                     r_wr;
    reg                                     r_rd;
   
    //================ States declaration ======================//
    reg [3:0] state;
    localparam S_IDLE = 3'b000;
    localparam S_READ = 3'b001;
    localparam S_WRITE = 3'b010;
    localparam S_WAITFORMM = 3'b011;
    localparam S_UPDATING = 3'b100;
    localparam S_READMM = 3'b101; 
    localparam S_DONE = 3'b110;
    
    //================ Assigning Wires =========================//
    // Parse the address
    // try: remove addr and data latches
    assign o_offset = r_addr[3:2];                                // offset is fixed since there will always be 4 words per block // TODO: fix this
    assign o_index = r_addr[ADDR_WIDTH - TAG_BITS - 1:4];
    assign o_tag = r_addr[ADDR_WIDTH-1: ADDR_WIDTH - TAG_BITS];
   
    // Parse the LRU Tag and check if dirty or invalid
    // If dirty, then we need to evict
    // If diry but invalid, then no need to evict
    wire LRU_valid_bit = i_tag_info_of_LRU[TAG_BITS + 2]; // really need to set this parametrizable
    wire LRU_dirty_bit = i_tag_info_of_LRU[TAG_BITS + 1];
   
    
    // Internal wires
    wire [CACHE_WAY-1:0] LRU_set_wire;           // One hot encoding result of the PLRU module
    wire [$clog2(CACHE_WAY)-1:0] LRU_way;        // Decoded decimal from LRU_set_wire
    
    
    //Outputs
    assign o_rdwr = (state[1]) ? 1'b1 : 1'b0;
    assign o_wr = r_wr;
    assign o_rd = r_rd;
    assign o_burst_en = (state == S_UPDATING) ? 1'b1 : 1'b0;
    assign o_wr_tag = (state[2] | state[1]) ? 1'b1 : 1'b0;
    assign o_LRU_set = LRU_way;
    assign o_data = r_data; ////
    assign o_guard_evict = ( (state == S_READ | state == S_WRITE) && !i_hit && LRU_dirty_bit && LRU_valid_bit  ) ? 1'b1 : 1'b0; 
    assign o_evict_en = (state == S_UPDATING) ? 1'b1 : 0;
     
     
     assign o_am_idle = (state == S_IDLE) ? 1'b1 : 1'b0;
     assign o_all_done = (state == S_DONE) ? 1'b1 :1'b0;
     
    // ============ Module instantiation ========//
    eightway_PLRU LRU_cont(  
        .i_way_accessed(i_way_accessed),
        .i_hit(i_hit),
        .o_LRU(LRU_set_wire)
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
            r_addr <= 0;
            r_data <= 0;
        end
        else begin
            
            r_addr <= i_addr;
            r_data <= i_data;
            r_rd <= i_rd;
            r_wr <= i_wr;
            case (state) 
                S_IDLE: begin
                    //wait for read/write signals 
                    if (i_rd) state <= S_READ;
                    if (i_wr) state <= S_WRITE;
                end
                
                S_WRITE: begin
                // Did something here; In case of consecutive writes, do not go back to IDLE state?
                // changed the states such that it has a DONE state for the TB for now
                    if (i_hit) begin
                        /*
                        if (i_wr) state <= S_WRITE;
                        else state <= S_IDLE;
                        */
                        state <= S_DONE;
                    end 
                    else state <= S_UPDATING;
                end
                
                S_READ: begin
                    if (i_hit) begin
                    /*
                        if (i_rd) state <= S_READ;
                        else state <= S_IDLE;
                    */
                    state <= S_DONE;
                    end
                    else state <= S_UPDATING;
                    
                    
                end
                
                S_UPDATING: begin
                    if (i_done_burst_cont) begin
                        if (i_rd) state <= S_READ;
                        else if (i_wr) state <= S_WRITE;
                    end
                end
                
                S_DONE: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
    

    
endmodule
