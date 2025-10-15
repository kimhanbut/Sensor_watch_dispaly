`timescale 1ns / 1ps

module top_sr04 (
    input        clk,
    input        rst,
    input        start,
    input        echo,
    output       trigger,
    output [9:0] dist_data
);


    sr04_controller U_sr04_controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .echo(echo),
        .trigger(trigger),
        .dist(dist_data),
        .dist_done()
    );


endmodule


