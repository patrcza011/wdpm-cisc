`timescale 1ns / 1ps

module top_tb;

    // Parameters
    parameter DATA_WIDTH  = 8;
    parameter ROM_ADDR_WIDTH  = 8;
    parameter RAM_ADDR_WIDTH  = 8;
    parameter REG_ADDR_WIDTH  = 4;
    parameter OP_WIDTH = 4;
    parameter OPERAND_WIDTH = 8;
    parameter MODE_WIDTH = 4;
    parameter ADDR_MODE_WIDTH = 2;
    parameter ROM_WIDTH = 16;
    parameter ROM_SIZE = 256;
    parameter RAM_SIZE = 256;

    // Testbench signals
    logic clk;
    logic rst;

    // Outputs from DUT
    logic fetch_ena_out;
    logic jump_ena_out;
    logic execute_ena_out;
    logic write_ram_ena_out;
    logic write_reg_ena_out;
    logic zero_flag_out;
    logic sign_flag_out;
    logic carry_flag_out;
    logic [OPERAND_WIDTH-1:0] operand_out;
    logic [ADDR_MODE_WIDTH-1:0] addr_mode_out;
    logic [OP_WIDTH-1:0] opcode_out;
    logic [DATA_WIDTH:0] temp_data_out;
    logic [DATA_WIDTH-1:0] in_data_out;
    logic [DATA_WIDTH-1:0] out_data_out;
    logic [DATA_WIDTH-1:0] ram_data_out;
    logic [DATA_WIDTH-1:0] reg_data_out;
    logic [ROM_WIDTH-1:0] rom_data_temp_out;
    logic [ROM_WIDTH-1:0] rom_data_out;
    logic [ROM_ADDR_WIDTH-1:0] rom_addr_out;
    logic [RAM_ADDR_WIDTH-1:0] ram_addr_out;
    logic [REG_ADDR_WIDTH-1:0] reg_addr_out;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .rst(rst),
        .fetch_ena_out(fetch_ena_out),
        .jump_ena_out(jump_ena_out),
        .execute_ena_out(execute_ena_out),
        .write_ram_ena_out(write_ram_ena_out),
        .write_reg_ena_out(write_reg_ena_out),
        .zero_flag_out(zero_flag_out),
        .sign_flag_out(sign_flag_out),
        .carry_flag_out(carry_flag_out),
        .operand_out(operand_out),
        .addr_mode_out(addr_mode_out),
        .opcode_out(opcode_out),
        .temp_data_out(temp_data_out),
        .in_data_out(in_data_out),
        .out_data_out(out_data_out),
        .ram_data_out(ram_data_out),
        .reg_data_out(reg_data_out),
        .rom_data_temp_out(rom_data_temp_out),
        .rom_data_out(rom_data_out),
        .rom_addr_out(rom_addr_out),
        .ram_addr_out(ram_addr_out),
        .reg_addr_out(reg_addr_out)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Testbench process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;

        // Apply reset
        #20;
        rst = 0;

        // Stimulate signals (if necessary, depending on module functionality)
        // Add custom logic to drive inputs to the DUT here if needed

        // Wait for a few clock cycles to observe the behavior
        #200;

        // Finish simulation
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor($time, 
                 " fetch_ena=%b jump_ena=%b execute_ena=%b write_ram_ena=%b write_reg_ena=%b zero_flag=%b sign_flag=%b carry_flag=%b",
                 fetch_ena_out, jump_ena_out, execute_ena_out, write_ram_ena_out, write_reg_ena_out, 
                 zero_flag_out, sign_flag_out, carry_flag_out);
    end

endmodule
