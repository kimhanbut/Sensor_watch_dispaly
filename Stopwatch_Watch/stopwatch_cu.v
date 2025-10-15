`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/16 15:11:39
// Design Name: 
// Module Name: stopwatch_cu
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


module stopwatch_cu (
    input  wire clk,
    input  wire reset,
    input  wire i_runstop,
    input  wire i_clear,
    input  wire i_uart_start,
    input  wire i_uart_stop,
    input  wire i_uart_clear,
    output wire o_run_stop,
    output wire o_clear

);

    reg [1:0] c_state, n_state;


    parameter stop = 2'd0;
    parameter run = 2'd1;
    parameter clear = 2'd2;


    assign o_run_stop = (c_state == run) ? 1 : 0;
    assign o_clear = (c_state == clear) ? 1 : 0;




    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= stop;
        end else begin
            c_state <= n_state;
        end
    end




    always @(*) begin
        n_state = c_state;
        case (c_state)

            stop:
            if (i_clear | i_uart_clear) n_state = clear;
            else if (i_runstop | i_uart_start) n_state = run;

            run: if (i_runstop | i_uart_stop) n_state = stop;

            clear: if (i_clear | i_uart_stop) n_state = stop;

        endcase
    end



endmodule





module time_cu (
    input  wire       clk,
    input  wire       reset,
    input  wire       sw_setting,
    input  wire       left,
    input  wire       right,
    input  wire       up,
    input  wire       down,
    input  wire       i_uart_right,
    input  wire       i_uart_left,
    input  wire       i_uart_up,
    input  wire       i_uart_down,
    output wire       o_sec_up,
    output wire       o_sec_down,
    output wire       o_min_up,
    output wire       o_min_down,
    output wire       o_hour_up,
    output wire       o_hour_down,
    output reg  [1:0] status

);

    reg [1:0] c_state, n_state;


    parameter sec = 2'd0;
    parameter min = 2'd1;
    parameter hour = 2'd2;


    assign o_sec_up    = (sw_setting && (c_state == sec && (up | i_uart_up))) ? 1 : 0;
    assign o_min_up    = (sw_setting && (c_state == min && (up | i_uart_up))) ? 1 : 0;
    assign o_hour_up   = (sw_setting && (c_state == hour && (up | i_uart_up))) ? 1 : 0;
    assign o_sec_down  = (sw_setting && (c_state == sec && (down | i_uart_down))) ? 1 : 0;
    assign o_min_down  = (sw_setting && (c_state == min && (down | i_uart_down))) ? 1 : 0;
    assign o_hour_down = (sw_setting && (c_state == hour && (down | i_uart_down))) ? 1 : 0;





    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= sec;
        end else begin
            c_state <= n_state;
        end
    end




    always @(*) begin
        n_state = c_state;
        status = 2'd0;
        if (sw_setting) begin
            case (c_state)

                sec: begin
                    if (left | i_uart_left) n_state = min;
                    else if (right | i_uart_right) n_state = hour;
                    status = 2'd0;
                end

                min: begin
                    if (left | i_uart_left) n_state = hour;
                    else if (right | i_uart_right) n_state = sec;
                    status = 2'd1;
                end

                hour: begin
                    if (left | i_uart_left) n_state = sec;
                    else if (right | i_uart_right) n_state = min;
                    status = 2'd2;
                end

            endcase
        end
    end




endmodule
