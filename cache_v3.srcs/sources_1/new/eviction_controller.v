`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2024 07:21:10 PM
// Design Name: 
// Module Name: eviction_controller
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


module eviction_controller #(
    parameter TAG_WIDTH = 5,
    parameter INDEX_BITS = 3,
    parameter OFFSET_BITS = 2,
    
    parameter ADDR_WIDTH = 12
    )
    (
    input clk,
    input nrst,
    
    input[TAG_WIDTH-1:0]        i_tag_info_of_LRU,      // just the TAG, without the valid, dirty and LRU bits
    input[INDEX_BITS-1:0]       i_index,
    input[OFFSET_BITS-1:0]      i_offset,
    input[127:0]                i_LRU_data_cache_line,
    
    input                       i_evict_en,
    input                       i_guard_evict,           // A guard signal of sorts such that it only samples the correct LRU data?
    
    output [ADDR_WIDTH-1:0]     o_addr_to_BRAM,
    output [3:0]                o_weB,                  // necessary for the bytewise RAM for some reason
    output [31:0]               o_data_to_BRAM,
    output                      o_enaB                  // enable output signal for the BRAM port B
    );
    
    
    
    
    reg [ADDR_WIDTH-1:0]        r_addr_complete;
    reg [ADDR_WIDTH-1:0]        r_addr_buffer [3:0];
    reg [31:0]                  r_data_buffer[0:3];
    reg [1:0]                   r_counter;
    reg                         r_first_clock_cycle;
    reg                         r_done;
    reg                         r_enaB;
    reg [31:0]                  r_data_to_BRAM;
    reg [3:0]                   r_weB;
    
    
    assign o_enaB = r_enaB;
    assign o_addr_to_BRAM = r_addr_complete;
    assign o_data_to_BRAM = r_data_to_BRAM;
    assign o_weB = r_weB;
    
    initial begin
        r_first_clock_cycle <= 0;
        r_counter <= 0;
        r_done <= 0;
        r_weB <= 4'b0000;
    end
    
    //============== Write to a register the completed address ===========//
    always@(negedge clk) begin
        if (!nrst) begin
            // reset
            r_addr_complete <= 0;
            r_done <= 0;
            r_counter <= 0;
        end else begin
            if (i_guard_evict) begin
                // assemble the address from the TAG + INDEX + OFFSET + BYTE OFFSET
                // store in the buffer
                r_addr_buffer[0] <= {i_tag_info_of_LRU,i_index, 2'b00, 2'b00};
                r_addr_buffer[1] <= {i_tag_info_of_LRU,i_index, 2'b01, 2'b00};
                r_addr_buffer[2] <= {i_tag_info_of_LRU,i_index, 2'b10, 2'b00};
                r_addr_buffer[3] <= {i_tag_info_of_LRU,i_index, 2'b11, 2'b00};
                
                // store in the data buffer
                r_data_buffer[0] <= i_LRU_data_cache_line[31:0];
                r_data_buffer[1] <= i_LRU_data_cache_line[63:32];
                r_data_buffer[2] <= i_LRU_data_cache_line[95:64];
                r_data_buffer[3] <= i_LRU_data_cache_line[127:96];
            end
        end
    end
    
    //============== Send addr and data at negedge clk ==================//
    //Let's pattern this with the burst controller
    always@(negedge clk) begin
        if (i_evict_en) begin
            // begin on the next clock cycle
            // Dunno why, but the timing is wrong if not
            if (!r_first_clock_cycle) begin
                r_first_clock_cycle = 1;
            end
            else begin
                r_counter <= r_counter + 1;
            end
           
           
            if (r_counter == 3) begin
                r_done <= 1;
                r_enaB <= 0;
                r_weB <= 4'b0000;
                r_first_clock_cycle <= 0;
            end
           
            if (r_counter == 0 && !i_evict_en) r_done <= 0; 
            if (i_evict_en && !r_done) r_enaB <= 1;
            else r_enaB <= 0;
            
            if (r_first_clock_cycle && r_enaB && i_evict_en) begin
                r_weB <= 4'b1111;
                r_addr_complete <= r_addr_buffer[r_counter] >> 2;
                r_data_to_BRAM <= r_data_buffer[r_counter];
            end
        end
        
    end
endmodule
