`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/19 11:58:25
// Design Name: 
// Module Name: btn_debounce
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


module btn_debounce (
    input  wire clk,
    input  wire reset,
    input  wire i_btn,
    output wire o_btn
);

    parameter F_COUNT = 1000;
    reg [$clog2(F_COUNT)-1 : 0] r_counter;
    reg r_clk;
    reg [15:0] q_reg, q_next;
    reg  r_edge_q;
    wire w_debounce;



    //================clk_count for 100kHz clk====================
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 1'b0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == F_COUNT - 1) begin
                r_counter <= 1'b0;
                r_clk <= 1'b1;
            end 
            else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end




    //========================Shift register for Debounce============================
    always @(posedge r_clk, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end
    always @(i_btn, q_reg, r_clk) begin
        q_next = {i_btn, q_reg[15:1]};
    end
    assign w_debounce = &q_reg;





    //=========================Edge detection======================
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_edge_q <= 0;
        end else begin
            r_edge_q <= w_debounce;
        end
    end

    assign o_btn = (~r_edge_q) & w_debounce;






endmodule
