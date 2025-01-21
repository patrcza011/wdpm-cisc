`timescale 1ns/1ps

module tb_register_file;

    // --------------------------------------------------------------------------
    // PARAMETERS
    // --------------------------------------------------------------------------
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 2;
    localparam NUM_REGS   = 1 << ADDR_WIDTH;

    // --------------------------------------------------------------------------
    // DUT INTERFACE SIGNALS
    // --------------------------------------------------------------------------
    logic                     clk;
    logic                     reset;
    logic                     write_enable;
    logic [ADDR_WIDTH-1 : 0] address;
    logic [DATA_WIDTH-1 : 0] write_data;
    logic [DATA_WIDTH-1 : 0] read_data;

    // --------------------------------------------------------------------------
    // INSTANTIATE THE DUT
    // --------------------------------------------------------------------------
    register_file dut (
        .clk          (clk),
        .reset        (reset),
        .write_enable (write_enable),
        .address      (address),
        .write_data   (write_data),
        .read_data    (read_data)
    );

    // --------------------------------------------------------------------------
    // CLOCK GENERATION
    // --------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk; 
    // Clock period = 10ns

    // --------------------------------------------------------------------------
    // TESTBENCH SEQUENCES
    // --------------------------------------------------------------------------
    initial begin
        // Initialize signals
        reset        = 1;
        write_enable = 0;
        address      = '0;
        write_data   = '0;

        // Wait a couple of clock cycles in reset
        repeat (2) @(posedge clk);
        reset = 0;
        $display("Time=%0t: De-asserting reset.", $time);

        // Wait 1 cycle after reset
        @(posedge clk);

        // Example writes and reads
        write_to_address(2'b00, 8'hA5);
        write_to_address(2'b01, 8'h5A);
        write_to_address(2'b10, 8'hFF);
        write_to_address(2'b11, 8'h0F);

        // Read each address
        read_from_address(2'b00);
        read_from_address(2'b01);
        read_from_address(2'b10);
        read_from_address(2'b11);

        // Finish simulation
        #10;
        $display("All tests complete.");
        $finish;
    end

    // --------------------------------------------------------------------------
    // TASKS
    // --------------------------------------------------------------------------
    // Task to write data to a specified address
    task write_to_address(
        input [ADDR_WIDTH-1:0] wr_addr,
        input [DATA_WIDTH-1:0] wr_data
    );
        begin
            @(posedge clk);
            address      = wr_addr;
            write_data   = wr_data;
            write_enable = 1;
            @(posedge clk);  // Wait one clock edge
            write_enable = 0;
            $display("Time=%0t: Wrote 0x%0h to address %0d", $time, wr_data, wr_addr);
        end
    endtask

    // Task to read data from a specified address
    task read_from_address(
        input [ADDR_WIDTH-1:0] rd_addr
    );
        begin
            @(posedge clk);
            address = rd_addr;
            @(posedge clk); // Wait for read data to stabilize
            $display("Time=%0t: Read 0x%0h from address %0d", $time, read_data, rd_addr);
        end
    endtask

endmodule
