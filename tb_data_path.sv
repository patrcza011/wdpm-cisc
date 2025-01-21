`timescale 1ns / 1ps

module tb_data_path();

    // Parameters
    parameter MODE_WIDTH = 2;
    parameter RAM_DATA_WIDTH = 8;
    parameter RAM_ADDR_WIDTH = 8;
    parameter REG_DATA_WIDTH = 8;
    parameter REG_ADDR_WIDTH = 4;
    parameter OPERAND_WIDTH = 8;
    parameter DATA_WIDTH = 8;

    // Testbench signals
    reg [MODE_WIDTH-1:0] mode;
    reg [OPERAND_WIDTH-1:0] operand_in;
    reg [RAM_DATA_WIDTH-1:0] ram_data;
    reg [REG_DATA_WIDTH-1:0] reg_data;

    wire [DATA_WIDTH-1:0] data_out;
    wire [RAM_ADDR_WIDTH-1:0] ram_addr;
    wire [REG_ADDR_WIDTH-1:0] reg_addr;

    // Instantiate the DUT (Device Under Test)
    data_path dut (
        .mode(mode),
        .operand_in(operand_in),
        .ram_data(ram_data),
        .reg_data(reg_data),
        .data_out(data_out),
        .ram_addr(ram_addr),
        .reg_addr(reg_addr)
    );

    // Testbench procedure
    initial begin
        $display("Starting testbench");

        // Test case 1: Immediate Mode
        mode = 2'b00; // IMM
        operand_in = 8'hAA;
        ram_data = 8'h00;
        reg_data = 8'h00;
        #10;
        $display("Test 1: mode=IMM, data_out=%h (expected 0xAA)", data_out);
        
        // Test case 2: Direct Mode
        mode = 2'b01; // DIR
        operand_in = 8'h10;
        ram_data = 8'hBB;
        reg_data = 8'h00;
        #10;
        $display("Test 2: mode=DIR, ram_addr=%h, data_out=%h (expected ram_addr=0x10, data_out=0xBB)", ram_addr, data_out);

        // Test case 3: Indirect Mode
        mode = 2'b10; // INDIR
        operand_in = 8'h05;
        reg_data = 8'h20;
        ram_data = 8'hCC;
        #10;
        $display("Test 3: mode=INDIR, reg_addr=%h, ram_addr=%h, data_out=%h (expected reg_addr=0x05, ram_addr=0x20, data_out=0xCC)", reg_addr, ram_addr, data_out);

        // Test case 4: Register Mode
        mode = 2'b11; // REG
        operand_in = 8'h07;
        reg_data = 8'hDD;
        ram_data = 8'h00;
        #10;
        $display("Test 4: mode=REG, reg_addr=%h, data_out=%h (expected reg_addr=0x07, data_out=0xDD)", reg_addr, data_out);

        $display("Testbench completed");
        $stop;
    end

endmodule