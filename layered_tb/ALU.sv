`timescale 1ns / 1ps
/**
    Arithmetical Logical Unit module
*/

module ALU #(
    parameter SIZE = 8
  ) (
    input CE,
    input [2:0] OP_CODE, // 3-bit code for operation
    input [SIZE-1:0] left_operand,
    input [SIZE-1:0] right_operand,
    input carry_in,
    output carry_out,
    output [SIZE-1:0] op_out
  );

      localparam [2:0] OP_ADD = 3'b000,
                     OP_SUB = 3'b001,
                     OP_AND = 3'b010,
                     OP_OR  = 3'b011,
                     OP_XOR = 3'b100,
                     OP_NOT = 3'b101,
                     OP_LD  = 3'b110,
                     OP_ST  = 3'b111;

  logic carry_out_w;
  logic [SIZE-1:0] op_out_w;

  always @(*)
  begin
    carry_out_w = 0;
    op_out_w = 1'b0;

    if (CE)
    begin
      case (OP_CODE)
        OP_ADD:
          {carry_out_w, op_out_w} = left_operand + right_operand + carry_in;
        OP_SUB:
          {carry_out_w, op_out_w} = left_operand - right_operand + carry_in;
        OP_AND:
          op_out_w = left_operand & right_operand;
        OP_OR:
          op_out_w = left_operand | right_operand;
        OP_XOR:
          op_out_w = left_operand ^ right_operand;
        OP_NOT:
          op_out_w = ~left_operand;
        OP_LD:
          op_out_w = right_operand;
        OP_ST:
          op_out_w = left_operand;
        default:
          op_out_w = 'z;
      endcase
    end
  end

  assign carry_out = carry_out_w;
  assign op_out = op_out_w;
`ifdef FORMAL

  //////////////////////////////////////////////////////////////////////////////////////////
  ///////////// Assertions
  //////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////
  // Asstertion 1: Alu output is stable when CE is low
  //////////////////////////////////////////////////////////////////////////////////////////
  property ALU_stable_when_CE_is_low;
    @($fell(CE))
     until ($rose(CE))
     ($stable(op_out)&& $stable(carry_out));
  endproperty

  assert ALU_stable_when_CE_is_low else
           $display("ALU is not stable when CE is low");

  //////////////////////////////////////////////////////////////////////////////////////////
  // Asstertion 2: Alu output changes when CE is high
  //////////////////////////////////////////////////////////////////////////////////////////
  property output_changes_when_CE_is_high;
    @($rose(CE))
     until ($fell(CE))
     ($changed(op_out));
  endproperty

  assert output_changes_when_CE_is_high else
           $display("ALU output does not change when CE is high");

  //////////////////////////////////////////////////////////////////////////////////////////
  // Asstertion 3: Result lower than MAX_VAL
  //////////////////////////////////////////////////////////////////////////////////////////
  localparam MAX_VAL = 8'b11111111;
  property result_lower_than_MAX_VAL;
    @($rose(CE))
     until ($fell(CE))
     (op_out < MAX_VAL);
  endproperty

  assert result_lower_than_MAX_VAL else
           $display("ALU result is greater than MAX_VAL");

`endif
endmodule
