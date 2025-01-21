`timescale 1ns/1ps

module tb_memory;

    // ------------------------------
    // Clock and Reset
    // ------------------------------
    logic clk;
    logic reset;

    // ------------------------------
    // Signals for Program Memory
    // ------------------------------
    logic [7:0]  prog_addr;          // Program memory address
    logic [15:0] prog_instruction;   // Program memory instruction output

    // ------------------------------
    // Signals for Data Memory
    // ------------------------------
    logic [7:0]  data_addr;          // Data memory address
    logic [7:0]  data_in;            // Data memory data input
    logic        write_enable;       // Data memory write enable
    logic [7:0]  data_out;           // Data memory data output

    // ------------------------------
    // DUT Instantiations
    // ------------------------------
    // Program Memory
    program_memory #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(16),
        .MEM_SIZE(256)
    ) u_program_memory (
        .address(prog_addr),
        .instruction(prog_instruction)
    );

    // Data Memory
    data_memory #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(8),
        .MEM_SIZE(256)
    ) u_data_memory (
        .clk(clk),
        .address(data_addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .data_out(data_out)
    );

    // ------------------------------
    // Clock Generation
    // ------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period of 10 time units
    end

    // ------------------------------
    // Test Sequence
    // ------------------------------
    initial begin
        $display("=======================================");
        $display(" Testbench for Program and Data Memory ");
        $display("=======================================");

        // Program Memory Reads
        $display("\n--- Program Memory Read Tests ---");
        prog_addr = 8'd0; #1;
        $display("Address %0d => Instruction = 0x%h", prog_addr, prog_instruction);

        prog_addr = 8'd1; #1;
        $display("Address %0d => Instruction = 0x%h", prog_addr, prog_instruction);

        prog_addr = 8'd2; #1;
        $display("Address %0d => Instruction = 0x%h", prog_addr, prog_instruction);

        prog_addr = 8'd3; #1;
        $display("Address %0d => Instruction = 0x%h", prog_addr, prog_instruction);

        prog_addr = 8'd4; #1;
        $display("Address %0d => Instruction = 0x%h", prog_addr, prog_instruction);

        // Data Memory Writes/Reads
        $display("\n--- Data Memory Write/Read Tests ---");
        write_enable = 1'b0;
        data_addr    = 8'd0;
        data_in      = 8'd0;
        #1;

        // Write data 0xAB to address 10
        data_addr    = 8'd10;
        data_in      = 8'hAB;
        write_enable = 1'b1;  // Trigger the write
        @(posedge clk);       // Wait for a clock edge
        write_enable = 1'b0;  // Done writing

        // Read it back
        data_addr    = 8'd10;
        @(posedge clk);       // Wait for a clock edge
        $display("Data Memory Read at address %0d => data_out = 0x%0h", data_addr, data_out);

        // Write data 0x55 to address 200
        data_addr    = 8'd200;
        data_in      = 8'h55;
        write_enable = 1'b1;
        @(posedge clk);       // Wait for a clock edge
        write_enable = 1'b0;

        // Read it back
        data_addr    = 8'd200;
        @(posedge clk);       // Wait for a clock edge
        $display("Data Memory Read at address %0d => data_out = 0x%0h", data_addr, data_out);

        $display("\nAll tests complete.");
        $finish;
    end

endmodule
