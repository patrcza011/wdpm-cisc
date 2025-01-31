module pipo #(
    parameter int WIDTH = 8
) (
    input  logic                 clk,    // clock
    input  logic                 ce,     // clock enable
    input  logic                 rst,    // asynchronous reset (active-high)
    input  logic [WIDTH-1:0]     d,      // data in
    output logic [WIDTH-1:0]     q       // data out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= '0;    // q is reset immediately when rst is high
        end
        else if (ce) begin
            q <= d;
        end
    end

endmodule
