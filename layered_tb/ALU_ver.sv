`timescale 1ns / 1ps

//----------------------------------------------------------
class transaction;

    // Define parameters for data width and ALU operation width
    parameter DATA_W = 8;  // Match the SIZE parameter in ACU and ALU
    parameter ALU_OP_W = 3; // OP_CODE is 3 bits in ALU

    // Random fields for ALU operation and inputs
    rand bit [ALU_OP_W-1:0] op;  // ALU operation code (OP_CODE)
    rand bit [DATA_W-1:0] right_operand; // Right operand for ALU
    rand bit carry_in;  // Carry input for ALU
    rand bit CE;  // Control Enable for both ACU and ALU

    // Output fields
    bit [DATA_W-1:0] op_out;  // Result from ALU (op_out in ALU)
    bit carry_out;  // Carry out from ALU (carry_out in ALU)

    // Constraints to ensure valid operation codes
    constraint valid_op { op <= 3'b111 && op >= 3'b000; }  // OP_CODE is 3 bits (0 to 7)

endclass
//----------------------------------------------------------


class generator;
  mailbox gen_mbx;
  event trans_rdy;

  rand transaction trans;
  int  repeat_tests;  
  //constructor
  function new(mailbox gen_mbx, event trans_rdy);
    this.gen_mbx = gen_mbx;
    this.trans_rdy = trans_rdy;
  endfunction
  
  //++
  task main();
    repeat(repeat_tests)
    begin
      trans = new();
      trans.randomize();    
      $display("[GEN] Generated new transaction: %p", trans);
      gen_mbx.put(trans);
    end
   -> trans_rdy; 
  endtask
endclass

//----------------------------------------------------------
interface ALU_intf(input logic clk, reset);

    // Define parameters for data width and ALU operation width
    parameter DATA_W = 8;  // Match the SIZE parameter in ACU and ALU
    parameter ALU_OP_W = 3; // OP_CODE is 3 bits in ALU

    // Signals for ALU and ACU
    logic CE;  // Control Enable for both ACU and ALU
    logic [ALU_OP_W-1:0] op;  // ALU operation code (OP_CODE)
    logic [DATA_W-1:0] right_operand; // Right operand for ALU
    logic carry_in;  // Carry input for ALU

    // Outputs from ALU
    logic [DATA_W-1:0] op_out;  // Result from ALU (op_out in ALU)
    logic carry_out;  // Carry out from ALU (carry_out in ALU)

    // Driver clocking block
    clocking CLK_D @(posedge clk);
        default input #1 output #1;
        output CE;
        output op;
        output right_operand;
        output carry_in;

    endclocking

    // Monitor clocking block
    clocking CLK_M @(posedge clk);
        default input #1 output #1;
        input CE;
        input op;
        input right_operand;
        input carry_in;

        input op_out;
        input carry_out;
    endclocking

    // Driver modport
    modport driver_mode  (clocking CLK_D, input clk, reset);

    // Monitor modport
    modport monitor_mode (clocking CLK_M, input clk, reset);

endinterface

//----------------------------------------------------------
class driver;
  int trans_cnt; // Number of transactions
  virtual ALU_intf.driver_mode ALU_virt_inif;
  mailbox drv_mbx;
    
  // Constructor
  function new(virtual ALU_intf.driver_mode ALU_virt_inif, mailbox drv_mbx);
    this.ALU_virt_inif = ALU_virt_inif;
    this.drv_mbx = drv_mbx;
  endfunction
  
  // Reset task
  task reset;
    wait(ALU_virt_inif.reset);
    $display("[DRIVER] Reset started");

    // Reset all signals
    ALU_virt_inif.CLK_D.CE <= 0;
    ALU_virt_inif.CLK_D.op <= 0;
    ALU_virt_inif.CLK_D.right_operand <= 0;
    ALU_virt_inif.CLK_D.carry_in <= 0;

    wait(!ALU_virt_inif.reset);
    $display("[DRIVER] Reset finished");
  endtask
  
  // Main task to drive transactions
  task main;
    forever begin
      transaction trans;
      drv_mbx.get(trans); // Get a transaction from the mailbox
      $display("[DRIVER] Driving transaction: %p", trans);

      // Drive signals based on the transaction
      ALU_virt_inif.CLK_D.CE <= trans.CE;
      ALU_virt_inif.CLK_D.op <= trans.op;
      ALU_virt_inif.CLK_D.right_operand <= trans.right_operand;
      ALU_virt_inif.CLK_D.carry_in <= trans.carry_in;

      // Wait for a clock cycle
      @(posedge ALU_virt_inif.clk);

      // Increment transaction count
      trans_cnt++;
    end
  endtask
endclass

//----------------------------------------------------------
class monitor;
  virtual ALU_intf.monitor_mode ALU_virt_inif;
  mailbox mon_mbx;
  
  // Constructor
  function new(virtual ALU_intf.monitor_mode ALU_virt_inif, mailbox mon_mbx);
    this.ALU_virt_inif = ALU_virt_inif;
    this.mon_mbx = mon_mbx;
  endfunction
  
  // Transaction object to store monitored data
  transaction last_trans = new();
  integer trans_cnt = 0;

  // Main task to monitor signals
  task main;
    forever begin
        transaction trans;
        trans = new(); // Create a new transaction object

        // Wait for a clock cycle and capture signals
        @(posedge ALU_virt_inif.clk);

        // Capture inputs
        trans.CE = ALU_virt_inif.CLK_M.CE;
        trans.op = ALU_virt_inif.CLK_M.op;
        trans.right_operand = ALU_virt_inif.CLK_M.right_operand;
        trans.carry_in = ALU_virt_inif.CLK_M.carry_in;

        // Capture outputs
        trans.op_out = ALU_virt_inif.CLK_M.op_out;
        trans.carry_out = ALU_virt_inif.CLK_M.carry_out;

        // Store the transaction in the mailbox after the first transaction
        if (trans_cnt > 0) begin
            mon_mbx.put(last_trans);
        end

        // Update the last_trans object and increment transaction count
        last_trans = trans;
        trans_cnt++;
    end
  endtask
endclass

//----------------------------------------------------------
class scoreboard;
  parameter DATA_W = 8;
  mailbox mon_mbx;
  int trans_cnt;

  // Internal state for the accumulator (ACU)
  logic [DATA_W-1:0] acu_value;

  // Constructor
  function new(mailbox mon_mbx);
    this.mon_mbx = mon_mbx;
    this.acu_value = 0; // Initialize ACU value to 0
  endfunction

  // Main task to verify ALU and ACU operations
  task main;
    transaction trans;
    logic [DATA_W-1:0] expected_op_out;
    logic expected_carry_out;

    forever begin
      // Wait for a transaction from the monitor
      #50;
      $display("[SCOREBOARD] Waiting for mon_mbx");
      mon_mbx.get(trans);
      $display("[SCOREBOARD] Transaction received: %p, a=%h", trans, acu_value);

      // Only perform calculations and updates if CE is high
      if (trans.CE) begin
        // Calculate expected results based on the ALU operation
        case (trans.op)
          3'b000: begin // OP_ADD
            {expected_carry_out, expected_op_out} = acu_value + trans.right_operand + trans.carry_in;
          end
          3'b001: begin // OP_SUB
            {expected_carry_out, expected_op_out} = acu_value - trans.right_operand + trans.carry_in;
          end
          3'b010: begin // OP_AND
            expected_op_out = acu_value & trans.right_operand;
            expected_carry_out = 0; // No carry for logical operations
          end
          3'b011: begin // OP_OR
            expected_op_out = acu_value | trans.right_operand;
            expected_carry_out = 0; // No carry for logical operations
          end
          3'b100: begin // OP_XOR
            expected_op_out = acu_value ^ trans.right_operand;
            expected_carry_out = 0; // No carry for logical operations
          end
          3'b101: begin // OP_NOT
            expected_op_out = ~acu_value;
            expected_carry_out = 0; // No carry for logical operations
          end
          3'b110: begin // OP_LD
            expected_op_out = trans.right_operand;
            expected_carry_out = 0; // No carry for load operation
          end
          3'b111: begin // OP_ST
            expected_op_out = acu_value;
            expected_carry_out = 0; // No carry for store operation
          end
          default: begin
            $error("[SCOREBOARD] Unknown OP_CODE: %h", trans.op);
          end
        endcase

        // Update the ACU value with the ALU output (op_out) for every operation when CE is high
        acu_value = trans.op_out;

        // Compare expected results with actual results
        if (expected_op_out !== trans.op_out) begin
          $error("[SCOREBOARD] INVALID OP_OUT!! EXPECTED: %h, GOT: %h", expected_op_out, trans.op_out);
        end

        if (expected_carry_out !== trans.carry_out) begin
          $error("[SCOREBOARD] INVALID CARRY_OUT!! EXPECTED: %b, GOT: %b", expected_carry_out, trans.carry_out);
        end

        $display("[SCOREBOARD] Transaction verified successfully: op_out=%h, carry_out=%b", trans.op_out, trans.carry_out);
      end else begin
        // When CE is low, ensure that the ALU outputs are stable
        if (trans.op_out !== acu_value || trans.carry_out !== 0) begin
          $error("[SCOREBOARD] INVALID OUTPUTS WHEN CE IS LOW!! op_out=%h, carry_out=%b", trans.op_out, trans.carry_out);
        end
      end

      trans_cnt++;
    end
  endtask
endclass

//----------------------------------------------------------
class environment;
  generator gen;
  driver    driv;
  monitor   mon;
  scoreboard scb;
  mailbox   env_mbx_drv;
  mailbox   env_mbx_mon;
  event gen_ended;
  virtual ALU_intf ALU_virt_inif;
  
  //constructor
  function new(virtual ALU_intf ALU_virt_inif);
    this.ALU_virt_inif = ALU_virt_inif;
    env_mbx_drv = new();
    env_mbx_mon = new();
    gen = new(env_mbx_drv,gen_ended);
    driv = new(ALU_virt_inif,env_mbx_drv);
    mon  = new(ALU_virt_inif,env_mbx_mon);
    scb  = new(env_mbx_mon);
  endfunction

  //
  task pre_test();
    driv.reset();
  endtask
  
  //
  task test();
    fork 
      gen.main();
      driv.main();
      mon.main();
      scb.main();
    join_any
  endtask
  
  task post_test();
    wait(gen_ended.triggered);
    wait(gen.repeat_tests == driv.trans_cnt);
    wait(gen.repeat_tests == scb.trans_cnt);
  endtask  
  
  //run task
  task run;
    $display("PRE_TEST");
    pre_test();
    $display("TEST");
    test();
    $display("POST_TEST");
    post_test();
    $display("FINISH");
    $stop;
  endtask
  
endclass

//----------------------------------------------------------
program test(ALU_intf intf);
  environment env;
  initial 
  begin
    env = new(intf);
    env.gen.repeat_tests = 200;
    env.run();
  end
endprogram

//----------------------------------------------------------
module ALU_verification_top;
  parameter DATA_W = 8;
  bit clk;
  bit reset;
   // DUT - ACU and ALU instantiation
  logic [DATA_W-1:0] acu_out; // Output of ACU (connected to ALU's left_operand)
  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    reset = 1;
    #5 reset = 0;
  end

  // Interface
  ALU_intf intf(clk, reset);

  // Testcase
  test test1(intf);


  // ACU instantiation
  ACU #(
    .SIZE(DATA_W)
  ) acu_dut (
    .clk    (clk),
    .rstn   (!reset), // ACU uses active-low reset
    .CE     (intf.CE),
    .in_val (intf.op_out), // ACU input is the right_operand
    .out_val(acu_out) // ACU output (connected to ALU's left_operand)
  );

  // ALU instantiation
  ALU #(
    .SIZE(DATA_W)
  ) alu_dut (
    .CE            (intf.CE),
    .OP_CODE       (intf.op),
    .left_operand  (acu_out), // ACU output is the left_operand
    .right_operand (intf.right_operand),
    .carry_in      (intf.carry_in),
    .carry_out     (intf.carry_out), // Directly connect to interface
    .op_out        (intf.op_out)     // Directly connect to interface
  );

  // Enabling the wave dump
  initial begin
    // $dumpfile("dump.vcd"); $dumpvars;
  end

endmodule


//----------------------------------------------------------

