`timescale 1ns / 1ps



module stop_watch_normal_watch (
    input wire       clk,
    input wire       reset,
    input wire       btnL_clear,
    input wire       btnR_runstop,
    input wire       btnU_up,
    input wire       btnD_down,
    input wire       rx_done,
    input wire [7:0] rx_data,
    input wire [1:0] sw,
    input wire       sw_setting,

    output wire [3:0] led_for_mode,
    output wire [1:0] status_time,
    output wire [6:0] msec_watch,
    output wire [5:0] sec_watch,
    output wire [5:0] min_watch,
    output wire [5:0] hour_watch,
    output wire [1:0] final_switch,
    output wire  final_switch15

);

    wire [ 6:0] w_msec_sw;
    wire [ 5:0] w_sec_sw;
    wire [ 5:0] w_min_sw;
    wire [ 5:0] w_hour_sw;

    wire [ 6:0] w_msec_w;
    wire [ 5:0] w_sec_w;
    wire [ 5:0] w_min_w;
    wire [ 5:0] w_hour_w;

    wire [24:0] w_dp_out;

    wire [3:0] w_out_ctrl, w_btn_ti;
    wire w_runstop, w_clear;
    wire w_sec_up, w_min_up, w_hour_up, w_sec_down, w_min_down, w_hour_down;

    wire [1:0] w_btn_sw;


    wire w_uart_start, w_uart_stop, w_uart_clear, w_uart_right, w_uart_reset,
        w_uart_left, w_uart_up, w_uart_down, w_uart_sw0, w_uart_sw1, w_final_sw0, w_final_sw1, w_uart_sw15;


    assign msec_watch = w_dp_out[6:0];
    assign sec_watch  = w_dp_out[12:7];
    assign min_watch  = w_dp_out[18:13];
    assign hour_watch = w_dp_out[24:19];
    assign final_switch = {w_final_sw1, w_final_sw0};
    assign final_switch15 = w_final_sw15;
    




    ///=============================LED controller============================

    led_controller U_LED_CTRL (
        .switch(sw),
        .led_for_mode(led_for_mode)
    );







    //===============================Control Unit==============================

    demux U_DEMUX (
        .sel(w_final_sw1),
        .btnL(btnL_clear),
        .btnR(btnR_runstop),
        .btnU(btnU_up),
        .btnD(btnD_down),
        .btn_sw(w_btn_sw),
        .btn_ti(w_btn_ti)
    );


    stopwatch_cu U_WATCH_CU (
        .clk(clk),
        .reset(reset | w_uart_reset),
        .i_runstop(w_btn_sw[0]),
        .i_clear(w_btn_sw[1]),
        .i_uart_start(w_uart_start),
        .i_uart_stop(w_uart_stop),
        .i_uart_clear(w_uart_clear),
        .o_run_stop(w_runstop),
        .o_clear(w_clear)
    );



    time_cu U_TIME_CU (
        .clk(clk),
        .reset(reset | w_uart_reset),
        .sw_setting(sw_setting),
        .left(w_btn_ti[3]),
        .right(w_btn_ti[2]),
        .up(w_btn_ti[1]),
        .down(w_btn_ti[0]),
        .i_uart_right(w_uart_right),
        .i_uart_left(w_uart_left),
        .i_uart_up(w_uart_up),
        .i_uart_down(w_uart_down),
        .o_sec_up(w_sec_up),
        .o_sec_down(w_sec_down),
        .o_min_up(w_min_up),
        .o_min_down(w_min_down),
        .o_hour_up(w_hour_up),
        .o_hour_down(w_hour_down),
        .status(status_time)
    );




    //===============================UART==================================
    uart_convert U_CONVERT(  //출력은 딱 1 tick만 나가도록 설계해야 함.
        .clk(clk),
        .reset(reset),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .uart_start(w_uart_start),
        .uart_stop(w_uart_stop),
        .uart_clear(w_uart_clear),
        .uart_right(w_uart_right),
        .uart_left(w_uart_left),
        .uart_up(w_uart_up),
        .uart_down(w_uart_down),
        .uart_reset(w_uart_reset),
        .uart_sw0(w_uart_sw0),
        .uart_sw1(w_uart_sw1),
        .uart_sw15(w_uart_sw15)
        
    );






    switch_state_machine U_SWITCH_PRIORITY (
        .clk(clk),
        .reset(reset),
        .i_sw0(sw[0]),
        .i_sw1(sw[1]),
        .i_uart_sw0(w_uart_sw0),
        .i_uart_sw1(w_uart_sw1),
        .final_sw0(w_final_sw0),
        .final_sw1(w_final_sw1)
    );


switch15_state_machine U_SWITCH15_STATE (
    .clk(clk),
    .reset(reset),
    .i_sw15(sw_setting),
    .i_uart_sw15(w_uart_sw15),
    .final_sw15(w_final_sw15)
    
);




    //===================================Data Path==================================
    stop_watch_dp U_Stopwatch_DP (
        .clk(clk),
        .reset(reset | w_uart_reset),
        .run_stop(w_runstop),
        .clear(w_clear),
        .m_sec(w_msec_sw),
        .sec(w_sec_sw),
        .min(w_min_sw),
        .hour(w_hour_sw)

    );

    time_watch_dp U_TIME_DP (
        .clk(clk),
        .reset(reset | w_uart_reset),
        .sw_setting(sw_setting),
        .sec_up(w_sec_up),
        .min_up(w_min_up),
        .hour_up(w_hour_up),
        .sec_down(w_sec_down),
        .min_down(w_min_down),
        .hour_down(w_hour_down),


        .m_sec(w_msec_w),
        .sec  (w_sec_w),
        .min  (w_min_w),
        .hour (w_hour_w)
    );







    mux2x1 U_MUX2X1 (
        .watch_dp({w_hour_w, w_min_w, w_sec_w, w_msec_w}),
        .stop_watch_dp({w_hour_sw, w_min_sw, w_sec_sw, w_msec_sw}),
        .switch1(w_final_sw1),
        .out_data_path(w_dp_out)
    );





endmodule



module mux2x1 (
    input  wire [24:0] watch_dp,
    input  wire [24:0] stop_watch_dp,
    input  wire        switch1,
    output wire [24:0] out_data_path
);

    assign out_data_path = (~switch1) ? watch_dp : stop_watch_dp;

endmodule





module demux (
    input  wire       sel,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnU,
    input  wire       btnD,
    output reg  [1:0] btn_sw,
    output reg  [3:0] btn_ti
);


    always @(*) begin
        btn_sw = 0;
        btn_ti = 0;
        if (sel == 1) btn_sw = {btnL, btnR};
        else btn_ti = {btnL, btnR, btnU, btnD};
    end


endmodule






module led_controller (
    input  wire [1:0] switch,
    output reg  [3:0] led_for_mode
);


    always @(*) begin
        case (switch)
            0: led_for_mode = 4'b0001;
            1: led_for_mode = 4'b0010;
            2: led_for_mode = 4'b1001;
            3: led_for_mode = 4'b1111;
        endcase
    end



endmodule






module switch_state_machine (
    input  wire clk,
    input  wire reset,
    input  wire i_sw0,
    input  wire i_sw1,
    input  wire i_sw15,
    input  wire i_uart_sw0,
    input  wire i_uart_sw1,
    input  wire i_uart_sw15,
    output reg  final_sw0,
    output reg  final_sw1,
    output reg  final_sw15
    
);
    localparam SW_SEC = 0, SW_MIN = 1, TI_SEC = 2, TI_MIN = 3;

    reg sw0_pre, sw1_pre, uart_sw0_pre, uart_sw1_pre;
    reg edge_sw0, edge_sw1, u_edge_sw0, u_edge_sw1;

    reg [1:0] c_state, n_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sw0_pre      <= 1'b0;
            sw1_pre      <= 1'b0;
            uart_sw0_pre <= 1'b0;
            uart_sw1_pre <= 1'b0;
            c_state      <= 0;
        end else begin
            edge_sw0     <= i_sw0 ^ sw0_pre;
            edge_sw1     <= i_sw1 ^ sw1_pre;
            u_edge_sw0   <= i_uart_sw0 ^ uart_sw0_pre;
            u_edge_sw1   <= i_uart_sw1 ^ uart_sw1_pre;

            sw0_pre      <= i_sw0;
            sw1_pre      <= i_sw1;
            uart_sw0_pre <= i_uart_sw0;
            uart_sw1_pre <= i_uart_sw1;
            c_state      <= n_state;
        end
    end



    always @(*) begin
        n_state = c_state;
        case (c_state)
            SW_SEC: begin
                if (edge_sw0 && i_sw0 == 1) begin
                    n_state = SW_MIN;
                end else if (edge_sw1 && i_sw1 == 1) begin
                    n_state = TI_SEC;
                end else if (u_edge_sw0 && i_uart_sw0 == 1) begin
                    n_state = SW_MIN;
                end else if (u_edge_sw1 && i_uart_sw1 == 1) begin
                    n_state = TI_SEC;
                end
                final_sw0 = 0;
                final_sw1 = 0;
            end

            SW_MIN: begin
                if (edge_sw0 && i_sw0 == 0) begin
                    n_state = SW_SEC;
                end else if (edge_sw1 && i_sw1 == 1) begin
                    n_state = TI_MIN;
                end else if (u_edge_sw0 && i_uart_sw0 == 0) begin
                    n_state = SW_SEC;
                end else if (u_edge_sw1 && i_uart_sw1 == 1) begin
                    n_state = TI_MIN;
                end
                final_sw0 = 1;
                final_sw1 = 0;
            end

            TI_SEC: begin
                if (edge_sw0 && i_sw0 == 1) begin
                    n_state = TI_MIN;
                end else if (edge_sw1 && i_sw1 == 0) begin
                    n_state = SW_SEC;
                end else if (u_edge_sw0 && i_uart_sw0 == 1) begin
                    n_state = TI_MIN;
                end else if (u_edge_sw1 && i_uart_sw1 == 0) begin
                    n_state = SW_SEC;
                end
                final_sw0 = 0;
                final_sw1 = 1;
            end

            TI_MIN: begin
                if (edge_sw0 && i_sw0 == 0) begin
                    n_state = TI_SEC;
                end else if (edge_sw1 && i_sw1 == 0) begin
                    n_state = SW_MIN;
                end else if (u_edge_sw0 && i_uart_sw0 == 0) begin
                    n_state = TI_SEC;
                end else if (u_edge_sw1 && i_uart_sw1 == 0) begin
                    n_state = SW_MIN;
                end
                final_sw0 = 1;
                final_sw1 = 1;
            end

        endcase
    end

endmodule





module switch15_state_machine (
    input  wire clk,
    input  wire reset,
    input  wire i_sw15,
    input  wire i_uart_sw15,
    output reg  final_sw15
    
);
    reg sw15_pre;
    reg edge_sw15;

    reg [1:0] c_state, n_state;

//===================edge detect==================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sw15_pre      <= 1'b0;
            c_state      <= 0;
        end else begin
            edge_sw15     <= i_sw15 ^ sw15_pre;
            sw15_pre      <= i_sw15;
            c_state      <= n_state;
        end
    end


    always @(*) begin
        n_state = c_state;
        case (c_state)
            0: begin
                if (edge_sw15 && i_sw15 == 1) begin
                    n_state = 1;
                end else if (edge_sw15 && i_uart_sw15 == 1) begin
                    n_state = 1;
                end
                final_sw15 = 0;
            end

            1: begin
                if (edge_sw15 && i_sw15 == 0) begin
                    n_state = 0;
                end else if (edge_sw15 && i_uart_sw15 == 0) begin
                    n_state = 0;
                end 
                final_sw15 = 1;
            end

        endcase
    end

endmodule








module uart_convert (  //출력은 딱 1 tick만 나가도록 설계해야 함.
    input  wire       clk,
    input  wire       reset,
    input  wire       rx_done,
    input  wire [7:0] rx_data,
    output reg        uart_start,
    output reg        uart_stop,
    output reg        uart_clear,
    output reg        uart_right,
    output reg        uart_left,
    output reg        uart_up,
    output reg        uart_down,
    output reg        uart_reset,
    output wire       uart_sw0,
    output wire       uart_sw1,
    output wire       uart_sw15
    
);


    reg sw0_reg, sw0_next, sw1_reg, sw1_next, sw15_reg, sw15_next;

    assign uart_sw0 = sw0_reg;
    assign uart_sw1 = sw1_reg;
   assign uart_sw15 = sw15_reg;



    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sw0_reg <= 1'b0;
            sw1_reg <= 1'b0;
            sw15_reg <= 1'b0;
        end else begin
            sw0_reg <= sw0_next;
            sw1_reg <= sw1_next;
            sw15_reg <= sw15_next;
        end
    end



    always @(*) begin
        uart_start = 1'b0;
        uart_stop  = 1'b0;
        uart_clear = 1'b0;
        uart_right = 1'b0;
        uart_left  = 1'b0;
        uart_up    = 1'b0;
        uart_down  = 1'b0;
        uart_reset = 1'b0;
        sw0_next   = sw0_reg;
        sw1_next   = sw1_reg;
        sw15_next   = sw15_reg;
        if (rx_done)
            case (rx_data)
                8'h47: uart_start = 1'b1;

                8'h53: uart_stop = 1'b1;

                8'h43: uart_clear = 1'b1;

                8'h55: uart_up = 1'b1;

                8'h44: uart_down = 1'b1;

                8'h52: uart_right = 1'b1;

                8'h4c: uart_left = 1'b1;

                8'h1b: uart_reset = 1'b1;

                8'h4e: sw1_next = ~sw1_reg;

                8'h4d: sw0_next = ~sw0_reg;

                8'h4F: sw15_next = ~sw15_reg;
            endcase

    end
endmodule
