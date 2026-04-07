`timescale 1ns/1ps
`include "mydefines.v"
module myopenmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  wire  gpio;

    

  initial begin
    CLOCK_50 = 1'b0;
    forever #5 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
    #1000000000 $stop;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, myopenmips_min_sopc_tb);
end


  mysoc myopenmips_min_sopc0(
		.clk(CLOCK_50),
		.GPIO01(gpio),
		.rst(rst)
	);

endmodule