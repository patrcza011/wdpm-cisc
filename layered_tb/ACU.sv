`timescale 1ns / 1ps
/**
    Accumulator module 
*/

module ACU
  #(
     parameter SIZE = 8 // Parameter declaration
   )
   (
     input logic clk,
     input logic rstn,
     input logic CE, // Control Enable: writes to the accumulator when high
     input logic [SIZE-1:0] in_val,
     output logic [SIZE-1:0] out_val
   );

  // Internal value register
  logic [SIZE-1:0] int_val_r;

  always @(posedge clk or negedge rstn)
  begin
    if (!rstn)
    begin
      int_val_r <= {SIZE{1'bz}};
    end
    else
    begin
      if (CE)
      begin
        int_val_r <= in_val;
      end
    end
  end

  assign out_val = int_val_r;

`ifdef FORMAL
  property data_stable_during_ce_low;
    @(posedge clk)
    disable iff (!rstn)
    (!CE && $fell(CE)) |=> $stable(out_val);
  endproperty

  assert property (data_stable_during_ce_low) 
    else $error("Data changed while CE was low!");

`endif
endmodule
