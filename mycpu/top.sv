module top #(
    parameter DATA_WIDTH  = 8,
    parameter ROM_ADDR_WIDTH  = 8,
    parameter RAM_ADDR_WIDTH  = 8,
    parameter REG_ADDR_WIDTH  = 4,
    parameter OP_WIDTH = 4,
    parameter OPERAND_WIDTH = 8,
    parameter MODE_WIDTH = 4,
    parameter ADDR_MODE_WIDTH = 2,
    parameter ROM_WIDTH = 16,
    parameter ROM_SIZE = 256,
    parameter RAM_SIZE = 256
)(
    input  logic clk,
    input  logic rst,
    // Outputs for observing internal logic
    output logic fetch_ena_out,
    output logic jump_ena_out,
    output logic execute_ena_out,
    output logic write_ram_ena_out,
    output logic write_reg_ena_out,
    output logic zero_flag_out,
    output logic sign_flag_out,
    output logic carry_flag_out,
    output logic [OPERAND_WIDTH-1:0] operand_out,
    output logic [ADDR_MODE_WIDTH-1:0] addr_mode_out,
    output logic [OP_WIDTH-1:0] opcode_out,
    output logic [DATA_WIDTH:0] temp_data_out,
    output logic [DATA_WIDTH-1:0] in_data_out,
    output logic [DATA_WIDTH-1:0] out_data_out,
    output logic [DATA_WIDTH-1:0] ram_data_out,
    output logic [DATA_WIDTH-1:0] reg_data_out,
    output logic [ROM_WIDTH-1:0] rom_data_temp_out,
    output logic [ROM_WIDTH-1:0] rom_data_out,
    output logic [ROM_ADDR_WIDTH-1:0] rom_addr_out,
    output logic [RAM_ADDR_WIDTH-1:0] ram_addr_out,
    output logic [REG_ADDR_WIDTH-1:0] reg_addr_out
);

// Internal logic signals
logic fetch_ena;
logic jump_ena;
logic execute_ena;
logic write_ram_ena;
logic write_reg_ena;
logic zero_flag;
logic sign_flag;
logic carry_flag;
logic [OPERAND_WIDTH-1:0] operand;
logic [ADDR_MODE_WIDTH-1:0] addr_mode;
logic [OP_WIDTH-1:0] opcode;
logic [DATA_WIDTH:0] temp_data;
logic [DATA_WIDTH-1:0] in_data;
logic [DATA_WIDTH-1:0] out_data;
logic [DATA_WIDTH-1:0] ram_data;
logic [DATA_WIDTH-1:0] reg_data;
logic [ROM_WIDTH-1:0] rom_data_temp;
logic [ROM_WIDTH-1:0] rom_data;
logic [ROM_ADDR_WIDTH-1:0] rom_addr;
logic [RAM_ADDR_WIDTH-1:0] ram_addr;
logic [REG_ADDR_WIDTH-1:0] reg_addr;

// Assign internal logic to outputs
assign fetch_ena_out = fetch_ena;
assign jump_ena_out = jump_ena;
assign execute_ena_out = execute_ena;
assign write_ram_ena_out = write_ram_ena;
assign write_reg_ena_out = write_reg_ena;
assign zero_flag_out = zero_flag;
assign sign_flag_out = sign_flag;
assign carry_flag_out = carry_flag;
assign operand_out = operand;
assign addr_mode_out = addr_mode;
assign opcode_out = opcode;
assign temp_data_out = temp_data;
assign in_data_out = in_data;
assign out_data_out = out_data;
assign ram_data_out = ram_data;
assign reg_data_out = reg_data;
assign rom_data_temp_out = rom_data_temp;
assign rom_data_out = rom_data;
assign rom_addr_out = rom_addr;
assign ram_addr_out = ram_addr;
assign reg_addr_out = reg_addr;

program_counter #(
  .WIDTH(ROM_ADDR_WIDTH)
) pc_inst (
  .clk(clk),
  .reset(rst),
  .next_pc(in_data),
  .clk_enable(fetch_ena || jump_ena),
  .mode(jump_ena),
  .pc(rom_addr)
);

program_memory #(
  .ADDR_WIDTH(ROM_ADDR_WIDTH),
  .DATA_WIDTH(ROM_WIDTH),
  .MEM_SIZE(ROM_SIZE)
) u_program_memory (
  .address(rom_addr),
  .instruction(rom_data_temp)
);

data_memory #(
  .ADDR_WIDTH(RAM_ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .MEM_SIZE(RAM_SIZE)
) u_data_memory (
  .clk(clk),
  .address(ram_addr),
  .data_in(out_data),
  .write_enable(write_ram_ena),
  .data_out(ram_data)
);

pipo #(
  .WIDTH(ROM_WIDTH)
) u_pipo (
  .clk(clk),
  .ce(fetch_ena),
  .rst(rst),
  .d(rom_data_temp),
  .q(rom_data)
);

instruction_decoder #(
  .ROM_WIDTH(ROM_WIDTH),
  .OP_BITS(OP_WIDTH),
  .MODE_WIDTH(MODE_WIDTH),
  .ADDR_MODE_WIDTH(ADDR_MODE_WIDTH),
  .OPERAND_WIDTH(OPERAND_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
) u_instruction_decoder (
  .rom_in(rom_data),
  .clk(clk),
  .rst(rst),
  .zero_flag(zero_flag),
  .sign_flag(sign_flag),
  .operand_out(operand),
  .addr_mode_out(addr_mode),
  .alu_op_out(opcode),
  .fetch_ena(fetch_ena),
  .execute_ena(execute_ena),
  .write_ram_ena(write_ram_ena),
  .write_reg_ena(write_reg_ena),
  .jump_ena(jump_ena)
);


data_path #(
  .MODE_WIDTH(ADDR_MODE_WIDTH),
  .RAM_DATA_WIDTH(DATA_WIDTH),
  .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
  .REG_DATA_WIDTH(DATA_WIDTH),
  .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
  .OPERAND_WIDTH(OPERAND_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
) u_data_path (
  .mode(addr_mode),
  .operand_in(operand),
  .ram_data(ram_data),
  .reg_data(reg_data),
  .data_out(in_data),
  .ram_addr(ram_addr),
  .reg_addr(reg_addr)
);

alu #(
  .DATA_WIDTH(DATA_WIDTH),
  .ALU_OP_BITS(OP_WIDTH)
) alu_inst (
  .acc(out_data),
  .src(in_data),
  .alu_op(opcode),
  .carry_flag(carry_flag),
  .temp_result(temp_data)
);

pipo #(
  .WIDTH(DATA_WIDTH)
) u_pipo2 (
  .clk(clk),
  .ce(execute_ena),
  .rst(rst),
  .d(temp_data),
  .q(out_data)
);

flag_register #(
  .DATA_WIDTH(DATA_WIDTH)
) flag_register_inst (
  .clk(clk),
  .reset(rst),
  .update_flags(execute_ena),
  .temp_result(temp_data),
  .zero_flag(zero_flag),
  .sign_flag(sign_flag),
  .carry_flag(carry_flag)
);

register_file #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(REG_ADDR_WIDTH)
) reg_file_inst (
  .clk(clk),
  .reset(rst),
  .address(reg_addr),
  .write_enable(write_reg_ena),
  .write_data(out_data),
  .read_data(reg_data)
);

endmodule
