// Program Memory Module

/*   
		 
		  Instruction format in immediate/direct mode: {4bit OPCODE, 4bit MODE, 8bit OPERAND}
		  Instruction format in direct/indirect mode: {4bit OPCODE, 4bit MODE, 4bit OPERAND1, 4bit OPERAND2}
		  
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
        OP_NOT  = 4'b1010,
        OP_JA   = 4'b1011,
        OP_JZ   = 4'b1100,
        OP_JS   = 4'b1101,
        OP_JNZ  = 4'b1110,
        OP_JNS  = 4'b1111;

  
        NOP = 4'b0000,
        IMM = 4'b0001, // Immediate
        LOAD = 4'b0010, // Load from memory to acc with direct addressing
        STORE = 4'b0011, // Store from memory to acc with direct addressing
        REG_TO_REG = 4'b0100, // From reg to reg
        REG_TO_MEM = 4'b0101, // From reg to mem (indirect addressing)
        MEM_TO_REG = 4'b0110, // From mem to reg (indirect addressing)
        MEM_TO_MEM = 4'b0111; // From mem to mem (indirect addressing)
		  
*/
module program_memory
#(
    parameter ADDR_WIDTH = 8,   // Address width
    parameter DATA_WIDTH = 16,  // Instruction width
    parameter MEM_SIZE   = 256  // Memory size (number of instructions)
)
(
    input  logic [ADDR_WIDTH-1:0] address,     
    output logic [DATA_WIDTH-1:0] instruction 
);

    // Declare memory array based on parameterized size and data width
    logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];

    // Initialize memory contents
    initial begin

        memory[0] = 16'b0000_0001_0000_1000; //MOVI 8, 8 -> ACC
		  memory[1] = 16'b0001_0001_0000_0010; //ADDI 2, ACC = ACC+2
        memory[2] = 16'b0000_0011_0000_0000; //STORE, ACC -> RAM[0]
		  memory[3] = 16'b0000_0110_0000_0001; //MOV R0* -> R1
		  memory[4] = 16'b0000_0110_0000_0000; //MOV R0* -> R0
		  memory[5] = 16'b0001_0100_0000_0001; //ADD R0, R1, R1 = R0+R2
		  memory[6] = 16'b1011_0100_0001_0001; //Unconditional jump to R1 ROM location, second operand unnecessary
    end

    // Output the instruction at the given address
    assign instruction = memory[address];

endmodule


// Data Memory Module
module data_memory
#(
    parameter ADDR_WIDTH = 8,   // Address width
    parameter DATA_WIDTH = 8,   // Data width for each memory entry
    parameter MEM_SIZE   = 256  // Memory size
)
(
    input  logic                  clk,           // Clock signal
    input  logic [ADDR_WIDTH-1:0] address,       // Address input
    input  logic [DATA_WIDTH-1:0] data_in,       // Data input
    input  logic                  write_enable,  // Write enable
    output logic [DATA_WIDTH-1:0] data_out       // Data output
);

    // Declare data memory array
    logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];

    // Synchronous write on the rising edge of the clock
    always_ff @(posedge clk) begin
        if (write_enable) begin
            memory[address] <= data_in;
        end
    end

    // Continuous read from memory
    assign data_out = memory[address];

endmodule

