module program_counter #(
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic             reset,
    input  logic [WIDTH-1:0] next_pc,
    input  logic             clk_enable,  // Clock Enable
    input  logic             mode,        // Mode signal (0=increment, 1=write)
    output logic [WIDTH-1:0] pc
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= '0;
        end else if (clk_enable) begin
            pc <= mode ? next_pc : (pc + 1'b1);
        end
        // If clk_enable=0, no change (pc holds its value)
    end

endmodule
