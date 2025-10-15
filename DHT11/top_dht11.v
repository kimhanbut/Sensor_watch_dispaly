`timescale 1ns / 1ps


module top_dht11 (
    input wire clk,
    input wire reset,
    input wire btn_start,
    input wire btnL_temp,
    input wire btnR_humi,
    inout wire dht11_io,
    input wire rx,


    output wire       dht11_valid,
    output wire       tx,
    output wire       rx_done,
    output wire [7:0] rh_data,
    output wire [7:0] temp_data,
    output wire [7:0] rx_data
    
);


    wire [7:0] w_rh_data, w_temp_data, w_rx_data;
    wire [7:0] w_max_temp, w_max_humi, w_min_temp, w_min_humi;

    wire w_update, w_dht11_valid;
    assign dht11_valid = w_dht11_valid;

    assign rh_data = w_rh_data;
    assign temp_data = w_temp_data;

    //===================================auto update====================================
    tick_gen_1hz U_1HZ (
        .clk(clk),
        .reset(reset),
        .o_tick(w_sec_tick)
    );


    auto_update U_AUTO_UD (
        .clk(clk),
        .reset(reset),
        .sec_tick(w_sec_tick),
        .update_tick(w_update)
    );



    //==============================DHT11 data===============================
    dht11_controller U_DHT_CTRL (
        .clk(clk),
        .reset(reset),
        .start(btn_start | w_update),
        .rh_data(w_rh_data),
        .temp_data(w_temp_data),
        .dht11_done(),
        .dht11_valid(w_dht11_valid),  //checksum 때문에 존재
        .dht11_io(dht11_io)
    );

    max_min_decision U_MAX_MIN (
        .clk(clk),
        .reset(reset),
        .dht11_valid(w_dht11_valid),
        .rh_data(w_rh_data),
        .temp_data(w_temp_data),
        .max_humi(w_max_humi),
        .max_temp(w_max_temp),
        .min_humi(w_min_humi),
        .min_temp(w_min_temp)
    );



    sender_uart U_ART_SEND (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .temp_start(btnL_temp),
        .humi_start(btnR_humi),
        .i_max_temp(w_max_temp),
        .i_min_temp(w_min_temp),
        .i_max_humi(w_max_humi),
        .i_min_humi(w_min_humi),
        .tx(tx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );




endmodule






module max_min_decision (
    input  wire       clk,
    input  wire       reset,
    input  wire       dht11_valid,
    input  wire [7:0] rh_data,
    input  wire [7:0] temp_data,
    output wire [7:0] max_humi,
    output wire [7:0] max_temp,
    output wire [7:0] min_humi,
    output wire [7:0] min_temp
);
    reg [7:0]
        temp_max_reg,
        temp_min_reg,
        humi_max_reg,
        humi_min_reg,
        temp_max_next,
        temp_min_next,
        humi_max_next,
        humi_min_next;

    assign max_humi = humi_max_reg;
    assign max_temp = temp_max_reg;
    assign min_humi = humi_min_reg;
    assign min_temp = temp_min_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            temp_max_reg <= 0;
            temp_min_reg <= 8'hff;
            humi_max_reg <= 0;
            humi_min_reg <= 8'hff;
        end else begin
            temp_max_reg <= temp_max_next;
            temp_min_reg <= temp_min_next;
            humi_max_reg <= humi_max_next;
            humi_min_reg <= humi_min_next;
        end
    end


    always @(*) begin
        temp_max_next = temp_max_reg;
        temp_min_next = temp_min_reg;
        humi_max_next = humi_max_reg;
        humi_min_next = humi_min_reg;

        if (dht11_valid) begin
            if (temp_data > temp_max_reg) temp_max_next = temp_data;
            if (temp_data < temp_min_reg) temp_min_next = temp_data;
            if (rh_data > humi_max_reg && rh_data < 100)
                humi_max_next = rh_data;
            if (rh_data < humi_min_reg) humi_min_next = rh_data;
        end
    end


endmodule












module auto_update (
    input  wire clk,
    input  wire reset,
    input  wire sec_tick,
    output wire update_tick
);

    reg u_tick_reg, u_tick_next;
    reg [4:0] sec_cnt_reg, sec_cnt_next;


    assign update_tick = u_tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sec_cnt_reg <= 0;
            u_tick_reg  <= 0;
        end else begin
            sec_cnt_reg <= sec_cnt_next;
            u_tick_reg  <= u_tick_next;
        end
    end




    always @(*) begin
        sec_cnt_next = sec_cnt_reg;
        u_tick_next  = u_tick_reg;
        if (sec_tick) begin
            if (sec_cnt_reg == 4) begin
                u_tick_next  = 1;
                sec_cnt_next = 0;
            end else begin
                sec_cnt_next = sec_cnt_reg + 1;
            end
        end else u_tick_next = 0;
    end



endmodule












module tick_gen_1hz (
    input  wire clk,
    input  wire reset,
    output wire o_tick
);

    parameter F_COUNT = 100_000_000;  //100khz
    reg [$clog2(F_COUNT)-1 : 0] cnt_reg;
    reg tick_reg;

    assign o_tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cnt_reg  <= 0;
            tick_reg <= 0;
        end else begin
            if (cnt_reg == F_COUNT - 1) begin
                cnt_reg  <= 0;
                tick_reg <= 1'b1;
            end else begin
                cnt_reg  <= cnt_reg + 1;
                tick_reg <= 1'b0;
            end
        end
    end



endmodule
