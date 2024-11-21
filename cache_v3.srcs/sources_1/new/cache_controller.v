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
    
    input [ADDR_WIDTH-1:0] addr,
    input rd,
    input wr,
    input hit,
    input done_burst_cont,
    input [31:0] data_in,
    input [CACHE_WAY-1:0] way_accessed,
    
    // output: control signals
    output rdwr, // WRITE = 1; READ = 0;
    output wr_tag,
    output burst_en,
    
    output [CACHE_WAY-1:0] LRU_set,
    
    output [ADDR_WIDTH-1:0] addr_to_BRAM,
    
    
    output [TAG_BITS-1:0] tag,
    output [INDEX_BITS-1:0] index,
    output [OFFSET_BITS-1:0] offset
    
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
    assign offset = addr[3:2]; // offset is fixed since there will always be 4 words per block // TODO: fix this
    assign index = addr[ADDR_WIDTH - TAG_BITS - 1:4];
    assign tag = addr[ADDR_WIDTH-1: ADDR_WIDTH - TAG_BITS];
    
    // Control wires
    wire tag_hit;
    wire curr_way;
    //wire [CACHE_WAY-1:0] way_accessed;
    
    wire valid_bit;
    wire dirty_bit;
    wire lru_bit;
    
    wire data_from_BRAM_valid;
    
    //Outputs
    assign rdwr = (state[1]) ? 1'b1 : 1'b0;
    assign burst_en = (state[2]) ? 1'b1 : 1'b0;
    assign wr_tag = (state[2]) ? 1'b1 : 1'b0;
    
    // ============ Module instantiation ========//
    eightway_PLRU LRU_cont(  
        .way_accessed(way_accessed),
        .hit(hit),
        .LRU_set(LRU_set));
    
    
    
    
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
                    if (rd) state <= S_READ;
                    if (wr) state <= S_WRITE;
                end
                
                S_WRITE: begin
                    if (hit) state <= S_IDLE;
                    else state <= S_UPDATING;
                end
                
                S_READ: begin
                    if (hit) state <= S_IDLE;
                end
                
                S_UPDATING: begin
                    if (done_burst_cont) state <= S_IDLE;
                end
            endcase
        end
    end
    
    
endmodule
