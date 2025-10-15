`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/23 17:36:16
// Design Name: 
// Module Name: uart_stopwatch_top
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


module uart_stopwatch_top (
    input  wire       clk,
    input  wire       reset,
    input  wire       btnL_clear,
    input  wire       btnR_runstop,
    input  wire       btnU_up,
    input  wire       btnD_down,
    input  wire [1:0] sw,
    input  wire       sw_setting,
    input  wire       rx,
    output wire [3:0] led_for_mode,
    output wire [1:0] status_time,
    output wire       tx
);

    wire rx_done;
    wire [7:0] w_rx_push_data, w_rx_pop_data, w_tx_pop_data;
    wire w_tx_full, w_rx_empty, w_tx_empty, w_tx_busy;


    uart_controller U_UART_CTRL (
        .clk(clk),
        .reset(reset),
        .btn_start(~w_tx_empty),
        .tx_din(w_tx_pop_data),
        .rx(rx),
        .rx_done(w_rx_done),
        .tx_busy(w_tx_busy),
        .rx_data(w_rx_data),
        .tx(tx)
    );


    fifo U_TX_FIFO (
        .clk(clk),
        .reset(reset),
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .push_data(w_rx_pop_data),
        .full(w_tx_full),
        .empty(w_tx_empty),
        .pop_data(w_tx_pop_data)
    );





    stop_watch_normal_watch U_SW_TI (
        .clk(clk),
        .reset(reset),
        .btnL_clear(btnL_clear),
        .btnR_runstop(btnR_runstop),
        .btnU_up(btnU_up),
        .btnD_down(btnD_down),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .sw(sw),
        .sw_setting(sw_setting),
        .led_for_mode(led_for_mode),
        .status_time(status_time)
    );





endmodule
