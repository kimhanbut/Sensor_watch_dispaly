`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/30 15:02:22
// Design Name: 
// Module Name: sender_uart
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


module sender_uart (
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    input  wire       temp_start,
    input  wire       humi_start,
    input  wire [7:0] i_max_temp,
    input  wire [7:0] i_min_temp,
    input  wire [7:0] i_max_humi,
    input  wire [7:0] i_min_humi,
    output wire       tx,
    output wire       rx_done,
    output wire [7:0] rx_data

);


    reg [1:0] c_state, n_state;
    reg [7:0] send_data_reg, send_data_next;
    reg send_reg, send_next;
    reg mode_reg, mode_next;
    reg [4:0] send_cnt_reg, send_cnt_next;
    wire [23:0] w_max_temp, w_min_temp;
    wire [23:0] w_max_humi, w_min_humi;


    //===============================num to ascii=============================
    data_to_ascii U_MAX_TEMP (
        .i_data(i_max_temp),
        .o_data(w_max_temp)
    );

    data_to_ascii U_MIN_TEMP (
        .i_data(i_min_temp),
        .o_data(w_min_temp)
    );

    data_to_ascii U_MAX_HUMI (
        .i_data(i_max_humi),
        .o_data(w_max_humi)
    );

    data_to_ascii U_MIN_HUMI (
        .i_data(i_min_humi),
        .o_data(w_min_humi)
    );



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
            mode_reg      <= 0;
        end else begin
            c_state       <= n_state;
            send_data_reg <= send_data_next;
            send_reg      <= send_next;
            send_cnt_reg  <= send_cnt_next;
            mode_reg      <= mode_next;
        end
    end




    always @(*) begin
        n_state        = c_state;
        send_data_next = send_data_reg;
        send_next      = send_reg;
        send_cnt_next  = send_cnt_reg;
        mode_next      = mode_reg;

        case (c_state)
            0: begin
                mode_next = 0;
                if (temp_start) begin
                    n_state = 1;
                    send_cnt_next = 0;
                    mode_next = 1;
                end else if (humi_start) begin
                    n_state = 1;
                    send_cnt_next = 0;
                end
            end
            1: begin
                if (~w_tx_full) begin
                    send_next = 1'b1;
                    if (send_cnt_reg < 26) begin
                        case (send_cnt_reg)
                            1: send_data_next = "m";
                            2: send_data_next = "a";
                            3: send_data_next = "x";
                            4: send_data_next = " ";
                            5: send_data_next = (mode_reg) ? "t" : "h";
                            6: send_data_next = (mode_reg) ? "e" : "u";
                            7: send_data_next = (mode_reg) ? "m" : "m";
                            8: send_data_next = (mode_reg) ? "p" : "i";
                            9: send_data_next = " ";  // Hundreds
                            10: send_data_next = (mode_reg) ? w_max_temp[15 :8] : w_max_humi[15 :8];  // Tens
                            11:send_data_next = (mode_reg) ? w_max_temp[7: 0] : w_max_humi[7: 0];  // Units
                            12: send_data_next = ",";
                            13: send_data_next = " ";
                            14: send_data_next = "m";
                            15: send_data_next = "i";
                            16: send_data_next = "n";
                            17: send_data_next = " ";
                            18: send_data_next = (mode_reg) ? "t" : "h";
                            19: send_data_next = (mode_reg) ? "e" : "u";
                            20: send_data_next = (mode_reg) ? "m" : "m";
                            21: send_data_next = (mode_reg) ? "p" : "i";
                            22: send_data_next = " ";
                            23: send_data_next = (mode_reg) ? w_min_temp[15 :8] : w_min_humi[15 :8];
                            24: send_data_next = (mode_reg) ? w_min_temp[7: 0] : w_min_humi[7: 0];  //
                            25: send_data_next = "\n";

                        
                        endcase
                        send_cnt_next = send_cnt_reg + 1;
                    end else begin
                        n_state   = 0;
                        send_next = 0;
                    end

                end else n_state = c_state;
            end


        endcase
    end


endmodule





module data_to_ascii (
    input  wire [ 7:0] i_data,
    output wire [15:0] o_data
);

    assign o_data[7:0]   = (i_data % 10) + 8'h30;
    assign o_data[15:8]  = ((i_data / 10) % 10) + 8'h30;



endmodule



