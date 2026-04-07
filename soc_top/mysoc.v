`include "mydefines.v"

module mysoc(
	    input wire clk,
	    input wire rst,
	    output wire cpu_test,
	    inout wire GPIO01
	);
	  wire [5:0] int;
	  wire timer_int_o;
	


  assign int = {5'b00000, timer_int_o};

  // Instantiate openmips module
  openmips openmips0(
      .clk(clk),
      .rst(rst),
      .int_i(int),
      .timer_int_o(timer_int_o),
      .cpu_test(cpu_test),
             // 指令存储器接口
        .inst_ce_o(inst_ce),
        .inst_addr_o(inst_addr),
        .inst_data_i(inst_data),
        .inst_stallreq_i(inst_stallreq),

        // 数据存储器接口
        .data_ce_o(data_ce),
        .data_addr_o(data_addr),
        .data_we_o(data_we),
        .data_sel_o(data_sel),
        .data_data_o(data_data_o),
        .data_data_i(data_data_i),
        .data_stallreq_i(data_stallreq)


	  );
	
	    
    endmodule