`timescale 1ns / 1ps

module sr04_controller (
    input        clk,
    input        rst,
    input        start,
    input        echo,
    output       trigger,
    output [9:0] dist,
    output       dist_done
);

    wire w_tick;

    distance U_distance (
        .clk(clk),
        .rst(rst),
        .echo(echo),
        .i_tick(w_tick),
        .distance(dist),
        .dist_done(dist_done)
    );
    
    start_trigger U_start_trigger (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick),
        .start(start),
        .o_sr04_trigger(trigger)
    );
    
    tick_gen U_tick_gen (
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(w_tick)
    );

endmodule

module distance (
    input        clk,
    input        rst,
    input        echo,
    input        i_tick,                //10us
    output [9:0] distance,
    output       dist_done
);
    parameter IDLE = 0;
    parameter ECHO = 1;

    reg c_state, n_state;
    reg [5:0] count_reg, count_next;    //58까지 세기 위한 reg
    reg [9:0] dist_reg, dist_next;
    reg dist_done_reg, dist_done_next;

    assign distance = dist_reg;
    assign dist_done = dist_done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state       <= 0;
            count_reg     <= 0;
            dist_reg      <= 0;
            dist_done_reg <= 0;
        end
        else begin
            c_state       <= n_state;
            count_reg     <= count_next;
            dist_reg      <= dist_next;
            dist_done_reg <= dist_done_next;
        end
    end

    always @(*) begin
        n_state        = c_state;
        count_next     = count_reg;
        dist_next      = dist_reg;
        dist_done_next = dist_done_reg;
        case (c_state)
            IDLE : begin
                dist_done_next = 0;
                if (i_tick) begin
                    if (echo) begin
                        n_state = ECHO;
                        dist_next = 0;
                    end
                end
            end
            ECHO : begin
                if (i_tick) begin
                    count_next = count_reg + 1;
                    if (count_reg == 58) begin
                        count_next = 0;
                        dist_next = dist_reg + 1;
                    end
                    else if (!echo) begin
                        n_state = IDLE;
                        count_next = 0;
                        dist_done_next = 1;
                    end
                end
            end 
        endcase
    end
endmodule


module start_trigger (
    input  clk,
    input  rst,
    input  i_tick,
    input  start,
    output o_sr04_trigger
);
    reg state_reg, state_next;
    reg [3:0] count_reg, count_next;        //10까지 세기 위한 reg
    reg sr04_trigg_reg, sr04_tirgg_next;

    assign o_sr04_trigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg      <= 0;
            sr04_trigg_reg <= 0;
            count_reg      <= 0;
        end else begin
            state_reg      <= state_next;
            sr04_trigg_reg <= sr04_tirgg_next;
            count_reg      <= count_next;
        end
    end

    always @(*) begin
        state_next      = state_reg;
        sr04_tirgg_next = sr04_trigg_reg;
        count_next      = count_reg;
        case (state_reg)
            0: begin
                count_next      = 0;
                sr04_tirgg_next = 1'b0;
                if (start) begin
                    state_next = 1;
                end
            end
            1: begin
                if (i_tick) begin
                    sr04_tirgg_next = 1'b1;
                    count_next = count_reg + 1;
                    if (count_reg == 10) begin
                        state_next = 0;
                    end
                end
            end
        endcase
    end
endmodule


module tick_gen (
    input  clk,
    input  rst,
    output o_tick_1mhz
);

    parameter F_COUNT = 100;  //(system clk = 100_000_000 / 1_000_000(1Mhz, 1us))

    reg [$clog2(F_COUNT-1):0] count;
    reg tick;

    assign o_tick_1mhz = tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            tick  <= 0;
        end else begin
            if (count == (F_COUNT-1)) begin
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
        end
    end
endmodule