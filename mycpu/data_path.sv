module data_path #(
    parameter MODE_WIDTH = 2,
	 parameter RAM_DATA_WIDTH = 8,
	 parameter RAM_ADDR_WIDTH = 8,
	 parameter REG_DATA_WIDTH = 8,
	 parameter REG_ADDR_WIDTH = 4,
    parameter OPERAND_WIDTH = 8,
	 parameter DATA_WIDTH = 8
) (
	 input  logic [MODE_WIDTH-1:0] mode,	
    input  logic [OPERAND_WIDTH-1:0] operand_in,
	 input  logic [RAM_DATA_WIDTH-1:0] ram_data,
	 input  logic [REG_DATA_WIDTH-1:0] reg_data, 	 
    output logic [DATA_WIDTH-1:0] data_out,
	 output logic [RAM_ADDR_WIDTH-1:0] ram_addr,
	 output logic [REG_ADDR_WIDTH-1:0] reg_addr
);

	 localparam [MODE_WIDTH-1:0]
        IMM = 2'b00, 
        DIR = 2'b01, 
        INDIR = 2'b10, 
        REG = 2'b11; 
    
    always_comb begin
        // Default assignments to prevent latches
        ram_addr = '0;
        reg_addr = '0;
        data_out = '0;

        case (mode)
            IMM: begin
                data_out = operand_in; // Immediate
            end
            DIR: begin
                ram_addr = operand_in; // Direct addressing
                data_out = ram_data;
            end
            INDIR: begin
                reg_addr = operand_in; // Indirect addressing
                ram_addr = reg_data;
                data_out = ram_data;
            end
            REG: begin
                reg_addr = operand_in; // register mode
                data_out = reg_data;
            end
            default: begin
                // Default case to handle unexpected mode values
                ram_addr = '0;
                reg_addr = '0;
                data_out = '0;
            end
        endcase
    end

        
endmodule