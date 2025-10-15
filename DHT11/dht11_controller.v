`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/29 12:29:49
// Design Name: 
// Module Name: dht11_controller
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


module dht11_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    output wire [7:0] rh_data,
    output wire [7:0] temp_data,
    output wire       dht11_done,
    output wire       dht11_valid,  //checksum 때문에 존재
    inout  wire       dht11_io
);


    wire w_tick, w_sec_tick;


    tick_gen_10us U_TICK (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick)
    );



    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, 
            SYNCH = 4, DATA_SYNC = 5, DATA_DETECT = 6, STOP = 7;


    reg [2:0] c_state, n_state;
    reg [$clog2(1900) - 1:0] tick_cnt_reg, tick_cnt_next;
    reg dht11_reg, dht11_next;
    reg io_en_reg, io_en_next;
    reg valid_reg, valid_next;
    reg dht11_done_reg, dht11_done_next;
    reg [39:0] data_reg, data_next;
    reg [5:0] dcnt_reg, dcnt_next;




    assign dht11_io = (io_en_reg) ? dht11_reg : 1'bZ;
    assign dht11_valid = valid_reg;
    assign rh_data = data_reg[39:32];
    assign temp_data = data_reg[23:16];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state        <= 0;
            tick_cnt_reg   <= 0;
            dht11_reg      <= 1;
            io_en_reg      <= 1;
            data_reg       <= 0;
            valid_reg      <= 0;
            dcnt_reg       <= 0;
            dht11_done_reg <= 0;

        end else begin
            c_state        <= n_state;
            tick_cnt_reg   <= tick_cnt_next;
            dht11_reg      <= dht11_next;
            io_en_reg      <= io_en_next;
            data_reg       <= data_next;
            valid_reg      <= valid_next;
            dcnt_reg       <= dcnt_next;
            dht11_done_reg <= dht11_done_next;
        end
    end






    always @(*) begin
        n_state         = c_state;
        tick_cnt_next   = tick_cnt_reg;
        dht11_next      = dht11_reg;
        io_en_next      = io_en_reg;
        valid_next      = valid_reg;
        data_next       = data_reg;
        dcnt_next       = dcnt_reg;
        dht11_done_next = dht11_done_reg;
        case (c_state)
            IDLE: begin
                dht11_next      = 1'b1;
                io_en_next      = 1'b1;
                dcnt_next       = 0;
                dht11_done_next = 1'b0;
                if (start) begin
                    n_state = START;
                end
            end

            START: begin
                if (w_tick) begin
                    dht11_next = 1'b0;
                    if (tick_cnt_reg == 1900) begin
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                dht11_next = 1'b1;
                if (w_tick) begin
                    if (tick_cnt_reg == 2) begin
                        n_state = SYNCL;
                        tick_cnt_next = 0;
                        //convert inout_port to input
                        io_en_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCL: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        n_state = SYNCH;
                    end
                end
            end


            SYNCH: begin
                if (w_tick) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (!dht11_io) begin
                        n_state = DATA_SYNC;
                        tick_cnt_next = 0;
                        valid_next = 0;
                    end 
                    else if (tick_cnt_reg > 1000) begin  // 타임아웃 10ms
                        n_state = IDLE;  // 또는 ERROR 상태로 전환 가능
                        tick_cnt_next = 0;
                    end
                end
            end

            DATA_SYNC: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        tick_cnt_next = 0;
                        n_state = DATA_DETECT;
                    end
                end
                if (dcnt_reg > 39) begin
                    n_state = STOP;
                end
            end

            DATA_DETECT: begin///data count = 40 될 때 까지 high 구간 tick 세서 1,0 판별 후 다시 sync로 보내는 방식.
                if (w_tick && dcnt_reg < 40) begin
                    if (dht11_io) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        if (tick_cnt_reg >= 5) begin
                            data_next[39-dcnt_reg] = 1'b1;
                        end else begin
                            data_next[39-dcnt_reg] = 1'b0;
                        end
                        n_state = DATA_SYNC;
                        dcnt_next = dcnt_reg + 1;
                        tick_cnt_next = 0;
                    end
                end
            end

            STOP: begin
                valid_next = ((data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8]) == data_reg[7:0])? 1 : 0;
                if (w_tick) begin
                    if (!dht11_io) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                    if (tick_cnt_reg > 3) begin
                        n_state = IDLE;
                        tick_cnt_next = 0;
                        dht11_done_next = 1'b1;
                    end
                end
            end


        endcase
    end





endmodule











module tick_gen_10us (
    input  wire clk,
    input  wire reset,
    output wire o_tick
);

    parameter F_COUNT = 1000;  //100khz
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



