`timescale 1ns / 1ps

module tb_alu;

    // --------------------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------------------
    parameter DATA_WIDTH  = 8;
    parameter ALU_OP_BITS = 4;

    // --------------------------------------------------------------------------
    // ALU signals
    // --------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] acc;
    logic [DATA_WIDTH-1:0] src;
    logic [ALU_OP_BITS-1:0] alu_op;
    logic                   carry_in;   // carry_flag input to the ALU
    logic [DATA_WIDTH:0]    temp_result; 

    // --------------------------------------------------------------------------
    // Flags signals and clock/reset for the flag_register
    // --------------------------------------------------------------------------
    logic                   clk;
    logic                   reset;
    logic                   update_flags;
    logic                   zero_flag;
    logic                   sign_flag;
    logic                   carry_flag;

    // --------------------------------------------------------------------------
    // Instantiate ALU
    // --------------------------------------------------------------------------
    alu dut_alu (
        .acc        (acc),
        .src        (src),
        .alu_op     (alu_op),
        .carry_flag (carry_in),    // Our input carry
        .temp_result(temp_result)
    );

    // --------------------------------------------------------------------------
    // Instantiate Flag Register
    // --------------------------------------------------------------------------
    flag_register dut_flag_reg (
        .clk        (clk),
        .reset      (reset),
        .update_flags(update_flags),
        .temp_result(temp_result),
        .zero_flag  (zero_flag),
        .sign_flag  (sign_flag),
        .carry_flag (carry_flag)
    );

    // --------------------------------------------------------------------------
    // Localparams for ALU operations (matching the ALU)
    // --------------------------------------------------------------------------
    localparam [ALU_OP_BITS-1:0]
        OP_PASS = 4'b0000,
        OP_ADD  = 4'b0001,
        OP_SUB  = 4'b0010,
        OP_INC  = 4'b0011,
        OP_DEC  = 4'b0100,
        OP_RL   = 4'b0101,
        OP_RR   = 4'b0110,
        OP_AND  = 4'b0111,
        OP_OR   = 4'b1000,
        OP_XOR  = 4'b1001,
        OP_NOT  = 4'b1010;

    // --------------------------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns period => 100 MHz

    // --------------------------------------------------------------------------
    // Test Stimulus
    // --------------------------------------------------------------------------
    initial begin
        // Initialize signals
        reset         = 1'b0;
        update_flags  = 1'b0;
        carry_in      = 1'b0;
        acc           = {DATA_WIDTH{1'b0}};
        src           = {DATA_WIDTH{1'b0}};
        alu_op        = OP_PASS;

        // Apply reset
        reset = 1'b1;
        #20;
        reset = 1'b0;

        // Let’s enable updating flags for all operations in this TB
        update_flags = 1'b1;

        // ----------------------------------------------------------------------
        // Test 1: OP_PASS
        // ----------------------------------------------------------------------
        acc      = 8'hAA;
        src      = 8'h55;
        alu_op   = OP_PASS;
        carry_in = 1'b0;  // Not used for PASS
        #10;  // Wait for a few cycles
        $display("[OP_PASS] acc=%0h, src=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 2: OP_ADD without carry
        // ----------------------------------------------------------------------
        acc      = 8'h01;
        src      = 8'h02;
        alu_op   = OP_ADD;
        carry_in = 1'b0;
        #10;
        $display("[OP_ADD] acc=%0h, src=%0h, carry_in=%b => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, carry_in, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 3: OP_ADD with carry_in
        // ----------------------------------------------------------------------
        acc      = 8'hFF;
        src      = 8'h01;
        alu_op   = OP_ADD;
        carry_in = 1'b1;   // Adding 1 more
        #10;
        $display("[OP_ADD + carry_in] acc=%0h, src=%0h, carry_in=%b => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, carry_in, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 4: OP_SUB with carry_in
        // ----------------------------------------------------------------------
        acc      = 8'h05;
        src      = 8'h02;
        alu_op   = OP_SUB;
        carry_in = 1'b1;  // subtract an extra 1
        #10;
        $display("[OP_SUB - carry_in] acc=%0h, src=%0h, carry_in=%b => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, carry_in, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 5: OP_INC
        // ----------------------------------------------------------------------
        acc      = 8'h0F;
        src      = 8'h00; // not used for INC
        alu_op   = OP_INC;
        carry_in = 1'b0;  // not used for INC
        #10;
        $display("[OP_INC] acc=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 6: OP_DEC
        // ----------------------------------------------------------------------
        acc      = 8'h10;
        alu_op   = OP_DEC;
        #10;
        $display("[OP_DEC] acc=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 7: OP_RL (Rotate Left)
        // ----------------------------------------------------------------------
        acc      = 8'b1010_1010;
        alu_op   = OP_RL;
        #10;
        $display("[OP_RL ] acc=%0b => temp_result=%0b, Z=%b, S=%b, C=%b",
                 acc, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 8: OP_RR (Rotate Right)
        // ----------------------------------------------------------------------
        acc      = 8'b1010_1010;
        alu_op   = OP_RR;
        #10;
        $display("[OP_RR ] acc=%0b => temp_result=%0b, Z=%b, S=%b, C=%b",
                 acc, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 9: OP_AND
        // ----------------------------------------------------------------------
        acc    = 8'hF0;
        src    = 8'h0F;
        alu_op = OP_AND;
        #10;
        $display("[OP_AND] acc=%0h, src=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 10: OP_OR
        // ----------------------------------------------------------------------
        alu_op = OP_OR;
        #10;
        $display("[OP_OR ] acc=%0h, src=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 11: OP_XOR
        // ----------------------------------------------------------------------
        alu_op = OP_XOR;
        #10;
        $display("[OP_XOR] acc=%0h, src=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, src, temp_result, zero_flag, sign_flag, carry_flag);

        // ----------------------------------------------------------------------
        // Test 12: OP_NOT
        // ----------------------------------------------------------------------
        acc    = 8'h55;
        alu_op = OP_NOT;
        #10;
        $display("[OP_NOT] acc=%0h => temp_result=%0h, Z=%b, S=%b, C=%b",
                 acc, temp_result, zero_flag, sign_flag, carry_flag);

        // Finish simulation
        #20;
        $display("All tests complete.");
        $finish;
	
	
   	$dumpfile("testbench.vcd");
   	$dumpvars(0, tb_alu);

    end

endmodule
