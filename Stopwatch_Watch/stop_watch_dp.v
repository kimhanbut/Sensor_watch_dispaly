`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/15 14:22:15
// Design Name: 
// Module Name: stop_watch
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


module stop_watch_dp (
    input wire clk,
    input wire reset,
    input wire run_stop,
    input wire clear,

    output wire [6:0] m_sec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [5:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    time_counter #(
        .BIT_WIDTH (7),
        .TICK_COUNT(100),
        .INIT_VAL  (0)
    ) U_MSEC (
        .clk(clk),
        .reset(reset | clear),
        .i_tick(w_tick_100hz),
        .o_time(m_sec),
        .o_tick(w_sec_tick)
    );




    time_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .INIT_VAL  (0)
    ) U_SEC (
        .clk(clk),
        .reset(reset | clear),
        .i_tick(w_sec_tick),
        .o_time(sec),
        .o_tick(w_min_tick)
    );





    time_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .INIT_VAL  (0)
    ) U_MIN (
        .clk(clk),
        .reset(reset | clear),
        .i_tick(w_min_tick),
        .o_time(min),
        .o_tick(w_hour_tick)
    );





    time_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(24),
        .INIT_VAL  (0)
    ) U_HOUR (
        .clk(clk),
        .reset(reset | clear),
        .i_tick(w_hour_tick),
        .o_time(hour),
        .o_tick()
    );



    tick_gen_100hz U_TICK_100HZ (
        .clk(clk & run_stop),
        .reset(reset | clear),
        .o_tick_100(w_tick_100hz)
    );



endmodule






module tick_gen_100hz (
    input  wire clk,
    input  wire reset,
    output reg  o_tick_100
);
    parameter FCOUNT = 1_000_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;


    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            o_tick_100 <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                o_tick_100 <= 1'b1; //when count value coincidence, o_tick_vlaue rising
                r_counter <= 0;
            end else begin
                o_tick_100 <= 1'b0;
            end
            r_counter <= r_counter + 1;
        end
    end

endmodule







module time_counter #(
    parameter BIT_WIDTH  = 7,
    parameter TICK_COUNT = 100,
    parameter INIT_VAL   = 0
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   i_tick,
    output wire [BIT_WIDTH-1 : 0] o_time,
    output wire                   o_tick
);

    reg [$clog2(TICK_COUNT)-1 : 0] count_reg, count_next;
    reg o_tick_reg, o_tick_next;

    assign o_time = count_reg;
    assign o_tick = o_tick_reg;


    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg  <= INIT_VAL;
            o_tick_reg <= 0;
        end else begin
            count_reg  <= count_next;
            o_tick_reg <= o_tick_next;
        end
    end



    //conmbinational logic for next state
    always @(*) begin
        count_next  = count_reg;
        o_tick_next = o_tick_reg;

        if (i_tick == 1'b1)begin
            if (count_reg == (TICK_COUNT - 1)) begin
                count_next  = 0;
                o_tick_next = 1'b1;
            end else begin
                count_next = count_reg + 1;
            end
        end 
        else o_tick_next = 1'b0;
    end




    //combinational logic for 

endmodule

