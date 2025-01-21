module register_file #(
    // Number of bits in each register
    parameter DATA_WIDTH = 8,
    // Number of address lines (2 bits => 4 registers, 3 bits => 8 registers, etc.)
    parameter ADDR_WIDTH = 4
) (
    input  logic                          clk,          // Clock
    input  logic                          reset,        // Reset
    input  logic [ADDR_WIDTH-1:0]         address,      // Address (for both read and write)
    input  logic                          write_enable, // Write enable
    input  logic [DATA_WIDTH-1:0]         write_data,   // Data to write
    output logic [DATA_WIDTH-1:0]         read_data     // Data read out
);

    // Number of registers is derived from the address width
    localparam NUM_REGS = 1 << ADDR_WIDTH;

    // Declare the register array
    logic [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];

    // Synchronous reset and write logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers to zero
            for (int i = 0; i < NUM_REGS; i++) begin
                registers[i] <= '0;
            end
        end
        else if (write_enable) begin
            // Write to the selected register
            registers[address] <= write_data;
        end
    end

    // Asynchronous read from the selected register
    assign read_data = registers[address];

endmodule
