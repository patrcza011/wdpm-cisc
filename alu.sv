module alu #(
    parameter DATA_WIDTH  = 8,
    parameter ALU_OP_BITS = 4
)(
    input  logic [DATA_WIDTH-1:0] acc,
    input  logic [DATA_WIDTH-1:0] src,
    input  logic [ALU_OP_BITS-1:0] alu_op,
	 input  logic 						  carry_flag,	 
    output logic [DATA_WIDTH:0]    temp_result // result + carry
);

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

    // Default assignment 
    always_comb begin
        // By default, pass 'acc' with no carry
        temp_result = {1'b0, acc};

        case (alu_op)
            OP_PASS: temp_result = {1'b0, src};  // PASS
            OP_ADD : temp_result = acc + src + carry_flag;    // ADD
            OP_SUB : temp_result = acc - src - carry_flag;    // SUB
            OP_INC : temp_result = acc + 1'b1;   // INC
            OP_DEC : temp_result = acc - 1'b1;   // DEC
            OP_RL  : temp_result = {acc[DATA_WIDTH-2:0], acc[DATA_WIDTH-1]}; // RL
            OP_RR  : temp_result = {acc[0], acc[DATA_WIDTH-1:1]};            // RR
            OP_AND : temp_result = acc & src;    // AND
            OP_OR  : temp_result = acc | src;    // OR
            OP_XOR : temp_result = acc ^ src;    // XOR
            OP_NOT : temp_result = ~acc;         // NOT
            // No need for 'default' in the case statement since we set a default above.
        endcase
    end

endmodule


// Flag Register Module
module flag_register #(
    parameter DATA_WIDTH = 8
)(
    input  logic                     clk,           // Clock signal
    input  logic                     reset,         // Reset signal
    input  logic                     update_flags,  // Control signal for flag update
    input  logic [DATA_WIDTH:0]     temp_result,   // Temporary result (DATA_WIDTH+1 bits)
    output logic                     zero_flag,     // Zero flag
    output logic                     sign_flag,     // Sign flag (MSB in 2's complement)
    output logic                     carry_flag     // Carry bit from temp_result
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            zero_flag  <= 1'b0;
            sign_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end 
        else if (update_flags) begin
            zero_flag  <= (temp_result[DATA_WIDTH-1:0] == {DATA_WIDTH{1'b0}});
            sign_flag  <= temp_result[DATA_WIDTH-1];  // MSB of the main data field
            carry_flag <= temp_result[DATA_WIDTH];    // Carry-out bit
        end
    end

endmodule
