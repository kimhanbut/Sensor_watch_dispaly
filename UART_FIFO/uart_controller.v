// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 2025/05/22 11:24:16
// // Design Name: 
// // Module Name: uart_controller
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////


// module uart_controller (
//     input  wire       clk,
//     input  wire       reset,
//     input  wire       btn_start,
//     input  wire [7:0] tx_din,
//     input  wire       rx,
//     output wire       rx_done,
//     output wire       tx_busy,
//     output wire [7:0] rx_data,
//     output wire       tx
// );


//     wire w_bd_tick, w_start_db, w_rx_done;
//     wire [7:0] w_dout;
//     assign rx_done = w_rx_done;
//     assign rx_data = w_dout;
    

//     baud_rate U_BR (
//         .clk(clk),
//         .reset(reset),
//         .baud_tick(w_bd_tick)
//     );


//     uart_tx U_TX (
//         .clk(clk),
//         .reset(reset),
//         .baud_tick(w_bd_tick),
//         .start(w_start_db | w_rx_done),
//         .din(w_dout),
//         .o_tx_done(),
//         .o_tx_busy(tx_busy),
//         .o_tx(tx)
//     );



//     uart_rx U_RX (
//         .clk(clk),
//         .reset(reset),
//         .rx(rx),
//         .b_tick(w_bd_tick),
//         .o_rx_done(w_rx_done),
//         .o_dout(w_dout)
//     );




//     btn_debounce U_BTN_DB_START (
//         .clk  (clk),
//         .reset(reset),
//         .i_btn(btn_start),
//         .o_btn(w_start_db)
//     );


// endmodule




`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/22 11:24:16
// Design Name: 
// Module Name: uart_controller
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


module uart_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] tx_push_data,
    input  wire       rx,
    input  wire       tx_push,

    output wire       rx_done,
    output wire       tx_done,
    output wire       tx_full,
    output wire [7:0] rx_data,
    output wire       tx,
    output wire       tx_busy

);


    wire w_bd_tick, w_tx_busy, w_tx_start;
    wire [7:0] w_rx_pop_data, w_tx_pop_data;
    assign tx_busy = w_tx_busy;

    baud_rate U_BR (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_bd_tick)
    );


    uart_tx U_TX (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_bd_tick),
        .start(~w_tx_start),
        .din(w_tx_pop_data),
        .o_tx_done(tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );


    uart_rx U_RX (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .b_tick(w_bd_tick),
        .o_rx_done(rx_done),
        .o_dout(rx_data)
    );




    //===============================FIFO==================================




    fifo U_TX_FIFO (
        .clk(clk),
        .reset(reset),
        .push(tx_push),
        .pop(~w_tx_busy),
        .push_data(tx_push_data),
        .full(tx_full),
        .empty(w_tx_start),  //empty가 아니면 계속 보내겠다.
        .pop_data(w_tx_pop_data)

    );



endmodule
