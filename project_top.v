`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/31 17:43:11
// Design Name: 
// Module Name: project_top
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


module project_top (
    input wire       clk,
    input wire       reset,
    input wire       btnU,
    input wire       btnD,
    input wire       btnR,
    input wire       btnL,
    input wire [3:0] sw,
    input wire       sw15,
    inout wire       dht11_io,
    input wire       rx,
    input wire       echo,

    output wire       trig,
    output wire [3:0] fnd_com,
    output wire [7:0] fnd_data,
    output reg        tx
);




    wire w_btnu_db, w_btnr_db, w_btnd_db, w_btnl_db;
    wire w_dht11_tx, w_watch_tx;
    wire w_dht11_rx, w_watch_rx, w_rx_done_watch, w_rx_done_dht, w_final_switch15;

    wire uart_sw2, uart_sw3;

    wire [9:0] w_dist_data;
    wire [7:0] w_rh_data, w_temp_data, w_rx_data_watch, w_rx_data_dht;

    wire [2:0] w_dht_btn;
    wire [3:0] w_stopwatch_btn;

    wire [1:0] w_status_time, w_final_switch;

    wire [6:0] w_msec;
    wire [5:0] w_sec, w_min, w_hour;


    assign w_dht11_rx = (sw[2]) ? rx : 1;
    assign w_watch_rx = (~sw[2]) ? rx : 1;



    //=================================btn DeMUX====================================
    demux_top U_DEMUX (
        .sw2(sw[2]),
        .btnL(w_btnl_db),
        .btnR(w_btnr_db),
        .btnU(w_btnu_db),
        .btnD(w_btnd_db),
        .btn_dht(w_dht_btn),
        .btn_sw(w_stopwatch_btn)
    );




    //==============================button debounce==============================
    btn_debounce U_BTNR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnR),
        .o_btn(w_btnr_db)
    );

    btn_debounce U_BTNL (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnL),
        .o_btn(w_btnl_db)
    );
    btn_debounce U_BTNU (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnU),
        .o_btn(w_btnu_db)
    );
    btn_debounce U_BTND (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnD),
        .o_btn(w_btnd_db)
    );




    //===================================Ultra Sonic=======================
    sr04_controller U_sr04_controller (
        .clk(clk),
        .rst(rst),
        .start(w_btnu_db & sw[3]),
        .echo(echo),
        .trigger(trig),
        .dist(w_dist_data),
        .dist_done()
    );


    //==================================Watch==================================

    stop_watch_normal_watch U_WATCH (
        .clk(clk),
        .reset(reset),
        .btnL_clear(w_btnl_db),
        .btnR_runstop(w_btnr_db),
        .btnU_up(w_btnu_db),
        .btnD_down(w_btnd_db),
        .rx_done(w_rx_done_watch),
        .rx_data(w_rx_data_watch),
        .sw(sw[1:0]),
        .sw_setting(sw15),
        .led_for_mode(),
        .status_time(w_status_time),
        .msec_watch(w_msec),
        .sec_watch(w_sec),
        .min_watch(w_min),
        .hour_watch(w_hour),
        .final_switch(w_final_switch),
        .final_switch15(w_final_switch15)
        

    );


    sender_uart_for_watch U_SEND_WATCH (
        .clk(clk),
        .reset(reset),
        .rx(w_watch_rx),
        .start((~sw[2]) & w_btnu_db & (~sw[1])),
        .i_temp(w_temp_data),
        .i_humi(w_rh_data),
        .i_sec(w_sec),
        .i_min(w_min),
        .i_hour(w_hour),
        .tx(w_watch_tx),
        .rx_done(w_rx_done_watch),
        .rx_data(w_rx_data_watch)

    );


    //==============================DHT11====================================
    top_dht11 U_DHT11 (
        .clk(clk),
        .reset(reset),
        .btn_start(w_dht_btn[0]),
        .btnL_temp(w_dht_btn[2]),
        .btnR_humi(w_dht_btn[1]),
        .dht11_io(dht11_io),
        .rx(w_dht11_rx),

        .dht11_valid(),
        .rx_done(w_rx_done_dht),
        .rx_data(w_rx_data_dht),
        .tx(w_dht11_tx),
        .rh_data(w_rh_data),
        .temp_data(w_temp_data)
    );






    //============================FND controller========================

    FND_controller U_FND_CTRL (
        .clk(clk),
        .reset(reset),
        .switch_dht(sw[2]),
        .switch_sr04(sw[3]),
        .switch_min_hour(sw[0]),
        .sw_setting(w_final_switch15 && (~w_final_switch[1])),
        .uart_switch0(w_final_switch[0]),
        .status(w_status_time),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .rh_data(w_rh_data),
        .temp_data(w_temp_data),
        .dist_data(w_dist_data),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );







    always @(*) begin
        tx = 1;
        if (sw[2] == 0) tx = w_watch_tx;
        else tx = w_dht11_tx;
    end


endmodule







module demux_top (
    input  wire       sw2,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnU,
    input  wire       btnD,
    output reg  [2:0] btn_dht,
    output reg  [3:0] btn_sw
);


    always @(*) begin
        btn_dht = 0;
        btn_sw  = 0;
        if (sw2 == 0) btn_sw = {btnL, btnR, btnU, btnD};
        else btn_dht = {btnL, btnR, btnU};
    end


endmodule

