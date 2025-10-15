`timescale 1ns / 1ps



module sender_uart_for_watch (
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    input  wire       start,
    input  wire [7:0] i_temp,
    input  wire [7:0] i_humi,
    input  wire [5:0] i_sec,
    input  wire [5:0] i_min,
    input  wire [5:0] i_hour,
    
    output wire       tx,
    output wire       rx_done,
    output wire [7:0] rx_data

);


    reg [1:0] c_state, n_state;
    reg [7:0] send_data_reg, send_data_next;
    reg send_reg, send_next;
    reg mode_reg, mode_next;
    reg [5:0] send_cnt_reg, send_cnt_next;
    wire [15:0] w_temp;
    wire [15:0] w_humi;
    wire tx_done, w_tx_full;


    //===============================num to ascii=============================
    data_to_ascii U_TEMP (
        .i_data(i_temp),
        .o_data(w_temp)
    );

    data_to_ascii U_HUMI (
        .i_data(i_humi),
        .o_data(w_humi)
    );



    wire [7:0] ascii_hour_hi = (i_hour / 10) + 8'd48;
    wire [7:0] ascii_hour_lo = (i_hour % 10) + 8'd48;
    wire [7:0] ascii_min_hi  = (i_min / 10)  + 8'd48;
    wire [7:0] ascii_min_lo  = (i_min % 10)  + 8'd48;
    wire [7:0] ascii_sec_hi  = (i_sec / 10)  + 8'd48;
    wire [7:0] ascii_sec_lo  = (i_sec % 10)  + 8'd48;

    //=================================UART logic===================================
    uart_controller U_UART_CTRL (
        .clk(clk),
        .reset(reset),
        .tx_push_data(send_data_reg),
        .rx(rx),
        .tx_push(send_reg),

        .rx_done(rx_done),
        .tx_done(tx_done),
        .tx_full(w_tx_full),
        .rx_data(rx_data),
        .tx(tx),
        .tx_busy()
    );



    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state       <= 0;
            send_data_reg <= 0;
            send_reg      <= 0;
            send_cnt_reg  <= 0;
        end else begin
            c_state       <= n_state;
            send_data_reg <= send_data_next;
            send_reg      <= send_next;
            send_cnt_reg  <= send_cnt_next;
        end
    end




    always @(*) begin
        n_state        = c_state;
        send_data_next = send_data_reg;
        send_next      = send_reg;
        send_cnt_next  = send_cnt_reg;

        case (c_state)
            0: begin
                if (start) begin
                    n_state = 1;
                end 
            end
            1: begin
                    n_state = 2;
            end
            2: begin
                if (~w_tx_full) begin
                    send_next = 1'b1;
                    if (send_cnt_reg < 34) begin
                        case (send_cnt_reg)
                        0:  send_data_next = "t";
                        1:  send_data_next = "i";
                        2:  send_data_next = "m";
                        3:  send_data_next = "e";
                        4:  send_data_next = " ";
                        5:  send_data_next = ascii_hour_hi;
                        6:  send_data_next = ascii_hour_lo;
                        7:  send_data_next = ":";
                        8:  send_data_next = ascii_min_hi;
                        9:  send_data_next = ascii_min_lo;
                        10: send_data_next = ":";
                        11: send_data_next = ascii_sec_hi;
                        12: send_data_next = ascii_sec_lo;
                        13: send_data_next = ",";
                        14: send_data_next = " ";
                        15: send_data_next = "t";
                        16: send_data_next = "e";
                        17: send_data_next = "m";
                        18: send_data_next = "p";
                        19: send_data_next = " ";
                        20: send_data_next = ":";
                        21: send_data_next = " ";
                        22: send_data_next = w_temp[15:8];
                        23: send_data_next = w_temp[7:0];
                        24: send_data_next = ",";
                        25: send_data_next = " ";
                        26: send_data_next = "h";
                        27: send_data_next = "u";
                        28: send_data_next = "m";
                        29: send_data_next = "i";
                        30: send_data_next = " ";
                        31: send_data_next = w_humi[15:8];
                        32: send_data_next = w_humi[7:0];
                        33: send_data_next = "\n";
                        endcase
                        send_cnt_next = send_cnt_reg + 1;
                    end else begin
                        n_state   = 0;
                        send_next = 0;
                        send_cnt_next = 0;
                    end

                end else n_state = c_state;
            end


        endcase
    end


endmodule






