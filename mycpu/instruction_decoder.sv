module instruction_decoder #(
    parameter ROM_WIDTH = 16,
    parameter OP_BITS = 4,
    parameter MODE_WIDTH = 4,
	 parameter ADDR_MODE_WIDTH = 2,
    parameter OPERAND_WIDTH = 8,
	 parameter DATA_WIDTH = 8
) (
    input  logic [ROM_WIDTH-1:0] rom_in,
	 input  logic 						   clk,
	 input  logic                    rst,
	 input  logic                    zero_flag,     
    input  logic                    sign_flag, 
	 output logic [OPERAND_WIDTH-1:0] operand_out,
	 output logic [ADDR_MODE_WIDTH-1:0] addr_mode_out, //addressing mode
	 output logic [OP_BITS-1:0] alu_op_out,
	 output logic fetch_ena,
	 output logic execute_ena,
	 output logic write_ram_ena,
	 output logic write_reg_ena,
	 output logic jump_ena
);
	     // Define states
    typedef enum logic [1:0] {
        FETCH    = 2'b00,
        EXECUTE  = 2'b01,
        EXECUTE_2 = 2'b10, //for 2 operand math/logic operations
		  WRITE_BACK = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Define opcodes
    localparam [OP_BITS-1:0]
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

    // Define modes
    localparam [MODE_WIDTH-1:0]
        NOP = 4'b0000,
        IMM = 4'b0001, // Immediate
        LOAD = 4'b0010, // Load from memory to acc with direct addressing
        STORE = 4'b0011, // Store from memory to acc with direct addressing
        REG_TO_REG = 4'b0100, // From reg to reg
        REG_TO_MEM = 4'b0101, // From reg to mem (indirect addressing)
        MEM_TO_REG = 4'b0110, // From mem to reg (indirect addressing)
        MEM_TO_MEM = 4'b0111; // From mem to mem (indirect addressing)
		  
	 localparam [ADDR_MODE_WIDTH-1:0]
        IMME = 2'b00, // Immediate
        DIR = 2'b01, //direct addressing mode
        INDIR = 2'b10, // indirect addressing mode
        REG = 2'b11; // register mode

    // Declare local signals for opcode, mode, operand, and operand halves
    logic [OP_BITS-1:0] opcode;            // Opcode (4 bits)
    logic [MODE_WIDTH-1:0] mode;           // Mode (4 bits)
    logic [OPERAND_WIDTH-1:0] operand;     // Operand (8 bits)
    logic [OPERAND_WIDTH/2-1:0] src; // Upper half of operand (4 bits) source
    logic [OPERAND_WIDTH/2-1:0] dst;  // Lower half of operand (4 bits) destination
	 logic [ADDR_MODE_WIDTH-1:0] src_st; //source addressing mode
	 logic [ADDR_MODE_WIDTH-1:0] dst_st; //destination addressing mode
	 logic 							  jump; //signal detecting jump opcodes
	 logic two_operand; //signal detecting two-operand operations (containing source and destination)
	 logic two_operand_math;	 // Signal to indicate two-argument math/logic operations

    // Assign slices from rom_in to respective signals
    assign opcode = rom_in[ROM_WIDTH-1:OPERAND_WIDTH + MODE_WIDTH];       // Bits 15 to 12
    assign mode = rom_in[OPERAND_WIDTH + MODE_WIDTH - 1:OPERAND_WIDTH];  // Bits 11 to 8
    assign operand = rom_in[OPERAND_WIDTH-1:0];                          // Bits 7 to 0

    // signal detecting two argument math/logic operation
    assign two_operand_math = (opcode == OP_ADD) || 
										(opcode == OP_SUB) || 
										(opcode == OP_AND) || 
										(opcode == OP_OR)  || 
										(opcode == OP_XOR);
	 // signal detecting two operand command									
	 assign two_operand = 		(mode == REG_TO_REG) || 
										(mode == REG_TO_MEM) || 
										(mode == MEM_TO_REG) || 
										(mode == MEM_TO_MEM);


    // Split operand into two halves when `two_operand` is true
    assign src = operand[OPERAND_WIDTH-1:OPERAND_WIDTH/2]; // Upper 4 bits
    assign dst = operand[OPERAND_WIDTH/2-1:0];             // Lower 4 bits
	
	 //splitting mode to source and destination operand
	  always_comb begin
        case (mode)
            IMM: begin
                // Immediate mode: Source is the operand, no destination
                src_st = IMME;
                dst_st = 0;
            end
            LOAD: begin
                // Load: Source is direct addressing (RAM address), no destination
                src_st = DIR;
                dst_st = 0;
            end
            STORE: begin
                // Store: Source is direct addressing (RAM address), no destination
                src_st = DIR;
                dst_st = 0;
            end
            REG_TO_REG: begin
				    // register to register
                src_st = REG;
                dst_st = REG;
            end
            REG_TO_MEM: begin
                src_st = REG;
                dst_st = INDIR;
            end
            MEM_TO_REG: begin
					 src_st = INDIR;
                dst_st = REG;
            end
            MEM_TO_MEM: begin
					 src_st = INDIR;
                dst_st = INDIR;           
            end
            default: begin
                // Default case: No operation
                src_st = '0;
                dst_st = '0;
            end
        endcase
    end
	 
	 
	 //jump handling
	 always_comb begin
		 jump = 1'b0; 

		 case (opcode)
			  OP_JA:   jump = 1'b1;               // Always jump
			  OP_JZ:   jump = zero_flag;          // Jump if zero flag is set
			  OP_JS:   jump = sign_flag;          // Jump if sign flag is set
			  OP_JNZ:  jump = !zero_flag;         // Jump if zero flag is not set
			  OP_JNS:  jump = !sign_flag;         // Jump if sign flag is not set
			  default: jump = 1'b0;               // Default case for safety
		 endcase
	  end
	  
	  //FSM for CISC machine cycle
	  always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= FETCH; // Default state
        else
            current_state <= next_state;
     end
	  
	  // state transition logic
    always_comb begin
        case (current_state)
            FETCH: begin
					 next_state = EXECUTE;
            end
            EXECUTE: begin
                if (two_operand_math && !(mode == IMM)) //in immediate mode cpu make operation with single argument and acc content
                    next_state = EXECUTE_2;
                else if (two_operand && !jump)
                    next_state = WRITE_BACK;
					 else
						  next_state = FETCH;
            end
            EXECUTE_2: begin
                next_state = WRITE_BACK;
            end
				WRITE_BACK: begin
                next_state = FETCH;
            end
            default: next_state = FETCH; // Safe default
        endcase
    end
	 
	 //output logic
	 always_comb begin
		 // Default assignments to avoid latches
		 fetch_ena = 1'b0;
		 alu_op_out = 4'b0000;
		 operand_out = '0;
		 addr_mode_out = '0;
		 jump_ena = 1'b0;
		 write_ram_ena = 1'b0;
		 execute_ena = 1'b0;
		 write_reg_ena = 1'b0;

		 case (current_state)
			  FETCH: begin
					fetch_ena = 1'b1;
			  end
			  EXECUTE: begin
					alu_op_out = (two_operand_math && !(mode == IMM)) ? OP_PASS : opcode;
					operand_out = two_operand ? src : operand;
					addr_mode_out = src_st;
					jump_ena = jump;
					write_ram_ena = (mode == STORE) ? 1'b1 : 1'b0;
					execute_ena = (mode == STORE || mode == NOP || jump) ? 1'b0 : 1'b1; //enabling jump 
			  end
			  EXECUTE_2: begin
					alu_op_out = opcode;
					addr_mode_out = dst_st;
					operand_out = dst;
					execute_ena = 1'b1;
			  end
			  WRITE_BACK: begin
					addr_mode_out = dst_st;
					operand_out = dst;
					write_ram_ena = (dst_st == INDIR) ? 1'b1 : 1'b0;
					write_reg_ena = (dst_st == REG) ? 1'b1 : 1'b0;
			  end
			  default: begin
					// Redundant here, as default assignments already avoid latches
			  end
		 endcase
	end

	 
        
endmodule
