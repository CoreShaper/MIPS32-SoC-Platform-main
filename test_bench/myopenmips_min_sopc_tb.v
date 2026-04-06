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


  mysoc myopenmips_min_sopc0(
		.clk(CLOCK_50),
		.GPIO01(gpio),
		.rst(rst)
	);

endmodule

/*001101 00000 00001 H1100 1100
001101 00001 00010 H1612  1712
001101 00010 00011 H18A3  1FB3
001101 00011 00100 HFF00  FFB3
001101 00100 00101 H00FF  FFFF

344318A3
3464FF00
348500FF*/