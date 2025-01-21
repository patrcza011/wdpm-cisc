`timescale 1ns/1ps

module tb_program_counter;
    // -------------------------------------------------
    // Parameter
    // -------------------------------------------------
    parameter WIDTH = 8;

    // -------------------------------------------------
    // Signals
    // -------------------------------------------------
    logic                  clk;
    logic                  reset;
    logic [WIDTH-1:0]      next_pc;
    logic                  clk_enable;
    logic                  mode;        // 0=increment, 1=write
    logic [WIDTH-1:0]      pc;

    // -------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------
    program_counter dut (
        .clk        (clk),
        .reset      (reset),
        .next_pc    (next_pc),
        .clk_enable (clk_enable),
        .mode       (mode),
        .pc         (pc)
    );

    // -------------------------------------------------
    // Clock Generation
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns period
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        // Initial conditions
        reset      = 1;
        next_pc    = '0;
        clk_enable = 0;
        mode       = 0; // default to increment mode

        // Release reset after some time
        #15;
        reset = 0;

        // Wait a couple cycles after reset
        repeat(2) @(posedge clk);

        // 1) Enable clock, increment mode
        clk_enable = 1;
        mode       = 0;  // 0=increment
        @(posedge clk);  // first increment
        @(posedge clk);  // second increment
        clk_enable = 0;  // disable updates for a moment

        // 2) Load next_pc = 0xA5
        next_pc    = 8'hA5;
        mode       = 1;  // 1=write
        clk_enable = 1;
        @(posedge clk);  // capture next_pc
        clk_enable = 0;

        // 3) Increment the new value twice more
        mode       = 0;  // back to increment
        clk_enable = 1;
        @(posedge clk);
        @(posedge clk);
        clk_enable = 0;

        // End simulation
        #10;
        $finish;
    end

    // -------------------------------------------------
    // Monitoring
    // -------------------------------------------------
    always @(posedge clk) begin
        $display("Time=%0t ns | reset=%b clk_enable=%b mode=%b next_pc=0x%0h pc=0x%0h",
            $time, reset, clk_enable, mode, next_pc, pc);
    end

endmodule
