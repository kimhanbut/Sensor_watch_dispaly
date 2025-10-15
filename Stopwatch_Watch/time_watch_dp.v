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


module time_watch_dp (
    input wire clk,
    input wire reset,
    input wire sw_setting,
    input wire sec_up,
    input wire min_up,
    input wire hour_up,
    input wire sec_down,
    input wire min_down,
    input wire hour_down,

    output wire [6:0] m_sec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [5:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    wire [1:0] w_ctrl_sec, w_ctrl_min, w_ctrl_hour;





    time_counter_ti #(
        .BIT_WIDTH (7),
        .TICK_COUNT(100),
        .INIT_VAL  (0)
    ) U_MSEC (
        .clk(clk),
        .reset(reset),
        .sw_setting(sw_setting),
        .i_tick(w_tick_100hz),
        .i_up(),
        .i_down(),
        .o_time(m_sec),
        .o_tick(w_sec_tick)
    );




    time_counter_ti #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .INIT_VAL  (0)
    ) U_SEC (
        .clk(clk),
        .reset(reset),
        .sw_setting(sw_setting),
        .i_tick(w_sec_tick),
        .i_up(sec_up),
        .i_down(sec_down),
        .o_time(sec),
        .o_tick(w_min_tick)
    );





    time_counter_ti #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .INIT_VAL  (0)
    ) U_MIN (
        .clk(clk),
        .reset(reset),
        .sw_setting(sw_setting),
        .i_tick(w_min_tick),
        .i_up(min_up),
        .i_down(min_down),
        .o_time(min),
        .o_tick(w_hour_tick)
    );





    time_counter_ti #(
        .BIT_WIDTH (6),
        .TICK_COUNT(24),
        .INIT_VAL  (12)
    ) U_HOUR (
        .clk(clk),
        .reset(reset),
        .sw_setting(sw_setting),
        .i_tick(w_hour_tick),
        .i_up(hour_up),
        .i_down(hour_down),
        .o_time(hour),
        .o_tick()
    );



    tick_gen_100hz U_TICK_100HZ (
        .clk(clk),
        .reset(reset),
        .o_tick_100(w_tick_100hz)
    );


endmodule



module time_counter_ti #(
    parameter BIT_WIDTH  = 7,
    parameter TICK_COUNT = 100,
    parameter INIT_VAL   = 0
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   sw_setting,
    input  wire                   i_tick,
    input  wire                   i_up,
    input  wire                   i_down,
    
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

        if ((i_tick == 1'b1) && (!sw_setting)) begin
            if (count_reg == (TICK_COUNT - 1)) begin
                count_next  = 0;
                o_tick_next = 1'b1;
            end else begin
                count_next = count_reg + 1;
            end
        end 
        
        else if ((i_up == 1'b1) && sw_setting) begin
        if (count_reg == (TICK_COUNT - 1)) begin
            count_next  = 0;
            o_tick_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
        end
        end

        else if (i_down == 1'b1) begin
            if (count_reg == 0) begin
                count_next  = TICK_COUNT - 1;
                o_tick_next = 1'b0;
            end else begin
                count_next = count_reg - 1;
            end
        end else o_tick_next = 1'b0;
    end




    //combinational logic for 

endmodule