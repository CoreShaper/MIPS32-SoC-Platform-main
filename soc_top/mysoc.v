`include "mydefines.v"

module mysoc(
	    input wire clk,
	    input wire rst,
	    output wire cpu_test,
	    inout wire GPIO01
	);
	  wire [5:0] int;
	  wire timer_int_o;
	
  // AXI signals
  wire [`RegBus] i_axi_rdata;
  wire i_axi_rvalid;
  wire [`RegBus] i_axi_araddr;
  wire i_axi_arvalid;
  wire i_axi_arready;
  wire i_axi_rready;

  wire [31:0] M_AXI_AWADDR;
  wire M_AXI_AWVALID;
  wire M_AXI_AWREADY;

  wire [31:0] M_AXI_WDATA;
  wire [3:0] M_AXI_WSTRB;
  wire M_AXI_WVALID;
  wire M_AXI_WREADY;

  wire [31:0] M_AXI_ARADDR;
  wire M_AXI_ARVALID;
  wire M_AXI_ARREADY;

  wire [31:0] M_AXI_RDATA;
  wire M_AXI_RVALID;
  wire M_AXI_RREADY;

  wire M_AXI_BVALID;
  wire M_AXI_BREADY;

  wire [31:0] M_AXI_AWADDR_0;
  wire M_AXI_AWVALID_0;
  wire M_AXI_AWREADY_0;
  wire [2:0] M_AXI_AWPROT_0;

  wire [31:0] M_AXI_WDATA_0;
  wire [3:0] M_AXI_WSTRB_0;
  wire M_AXI_WVALID_0;
  wire M_AXI_WREADY_0;

  wire [31:0] M_AXI_ARADDR_0;
  wire M_AXI_ARVALID_0;
  wire M_AXI_ARREADY_0;
  wire [2:0] M_AXI_ARPROT_0;

  wire [31:0] M_AXI_RDATA_0;
  wire M_AXI_RVALID_0;
  wire M_AXI_RREADY_0;
  wire [1:0] M_AXI_RRESP_0;

  wire M_AXI_BVALID_0;
  wire M_AXI_BREADY_0;
  wire [1:0] M_AXI_BRESP_0;

  wire [31:0] M_AXI_AWADDR_1;
  wire M_AXI_AWVALID_1;
  wire M_AXI_AWREADY_1;
  wire [2:0] M_AXI_AWPROT_1;

  wire [31:0] M_AXI_WDATA_1;
  wire [3:0] M_AXI_WSTRB_1;
  wire M_AXI_WVALID_1;
  wire M_AXI_WREADY_1;

  wire [31:0] M_AXI_ARADDR_1;
  wire M_AXI_ARVALID_1;
  wire M_AXI_ARREADY_1;
  wire [2:0] M_AXI_ARPROT_1;

  wire [31:0] M_AXI_RDATA_1;
  wire M_AXI_RVALID_1;
  wire M_AXI_RREADY_1;
  wire [1:0] M_AXI_RRESP_1;

  wire M_AXI_BVALID_1;
  wire M_AXI_BREADY_1;
  wire [1:0] M_AXI_BRESP_1;

  assign int = {5'b00000, timer_int_o};

  // Instantiate openmips module
  openmips openmips0(
      .clk(clk),
      .rst(rst),
      .int_i(int),
      .timer_int_o(timer_int_o),
      .cpu_test(cpu_test),

      // Instruction AXI bus interface
      .i_axi_rdata(i_axi_rdata),
      .i_axi_rvalid(i_axi_rvalid),
      .i_axi_araddr(i_axi_araddr),
	      .i_axi_arvalid(i_axi_arvalid),
	      .i_axi_arready(i_axi_arready),
	      .i_axi_rready(i_axi_rready),
	
	      // AXI4 interface signals
	      .M_AXI_AWADDR(M_AXI_AWADDR),
	      .M_AXI_AWVALID(M_AXI_AWVALID),
	      .M_AXI_AWREADY(M_AXI_AWREADY),
	      .M_AXI_WDATA(M_AXI_WDATA),
	      .M_AXI_WSTRB(M_AXI_WSTRB),
	      .M_AXI_WVALID(M_AXI_WVALID),
	      .M_AXI_WREADY(M_AXI_WREADY),
	      .M_AXI_ARADDR(M_AXI_ARADDR),
	      .M_AXI_ARVALID(M_AXI_ARVALID),
	      .M_AXI_ARREADY(M_AXI_ARREADY),
	      .M_AXI_RDATA(M_AXI_RDATA),
	      .M_AXI_RVALID(M_AXI_RVALID),
	      .M_AXI_RREADY(M_AXI_RREADY),
	      .M_AXI_BVALID(M_AXI_BVALID),
	      .M_AXI_BREADY(M_AXI_BREADY)
	  );
	
	  // Instantiate ROM
	  myinst_rom rom0(
	      .clk(clk),
	      .rst(rst),
	      .araddr(i_axi_araddr),
	      .arvalid(i_axi_arvalid),
	      .arready(i_axi_arready),
	      .rdata(i_axi_rdata),
	      .rvalid(i_axi_rvalid),
	      .rready(i_axi_rready)
	  );
	
	  // Instantiate AXI interconnect
	  axi_interconnect interconnect0(
	      .clk(clk),
	      .rst(rst),
	      .M_AXI_AWADDR(M_AXI_AWADDR),
	      .M_AXI_AWVALID(M_AXI_AWVALID),
	      .M_AXI_AWREADY(M_AXI_AWREADY),
	      .M_AXI_WDATA(M_AXI_WDATA),
	      .M_AXI_WSTRB(M_AXI_WSTRB),
	      .M_AXI_WVALID(M_AXI_WVALID),
	      .M_AXI_WREADY(M_AXI_WREADY),
	      .M_AXI_ARADDR(M_AXI_ARADDR),
	      .M_AXI_ARVALID(M_AXI_ARVALID),
	      .M_AXI_ARREADY(M_AXI_ARREADY),
	      .M_AXI_RDATA(M_AXI_RDATA),
	      .M_AXI_RVALID(M_AXI_RVALID),
	      .M_AXI_RREADY(M_AXI_RREADY),
	      .M_AXI_BVALID(M_AXI_BVALID),
	      .M_AXI_BREADY(M_AXI_BREADY),
	      .M_AXI_AWADDR_0(M_AXI_AWADDR_0),
	      .M_AXI_AWVALID_0(M_AXI_AWVALID_0),
	      .M_AXI_AWREADY_0(M_AXI_AWREADY_0),
	      .M_AXI_AWPROT_0(M_AXI_AWPROT_0),
	      .M_AXI_WDATA_0(M_AXI_WDATA_0),
	      .M_AXI_WSTRB_0(M_AXI_WSTRB_0),
	      .M_AXI_WVALID_0(M_AXI_WVALID_0),
	      .M_AXI_WREADY_0(M_AXI_WREADY_0),
	      .M_AXI_ARADDR_0(M_AXI_ARADDR_0),
	      .M_AXI_ARVALID_0(M_AXI_ARVALID_0),
	      .M_AXI_ARREADY_0(M_AXI_ARREADY_0),
	      .M_AXI_ARPROT_0(M_AXI_ARPROT_0),
	      .M_AXI_RDATA_0(M_AXI_RDATA_0),
	      .M_AXI_RVALID_0(M_AXI_RVALID_0),
	      .M_AXI_RREADY_0(M_AXI_RREADY_0),
	      .M_AXI_RRESP_0(M_AXI_RRESP_0),
	      .M_AXI_BVALID_0(M_AXI_BVALID_0),
	      .M_AXI_BREADY_0(M_AXI_BREADY_0),
	      .M_AXI_BRESP_0(M_AXI_BRESP_0),
	      .M_AXI_AWADDR_1(M_AXI_AWADDR_1),
	      .M_AXI_AWVALID_1(M_AXI_AWVALID_1),
	      .M_AXI_AWREADY_1(M_AXI_AWREADY_1),
	      .M_AXI_AWPROT_1(M_AXI_AWPROT_1),
	      .M_AXI_WDATA_1(M_AXI_WDATA_1),
	      .M_AXI_WSTRB_1(M_AXI_WSTRB_1),
	      .M_AXI_WVALID_1(M_AXI_WVALID_1),
	      .M_AXI_WREADY_1(M_AXI_WREADY_1),
	      .M_AXI_ARADDR_1(M_AXI_ARADDR_1),
	      .M_AXI_ARVALID_1(M_AXI_ARVALID_1),
	      .M_AXI_ARREADY_1(M_AXI_ARREADY_1),
	      .M_AXI_ARPROT_1(M_AXI_ARPROT_1),
	      .M_AXI_RDATA_1(M_AXI_RDATA_1),
	      .M_AXI_RVALID_1(M_AXI_RVALID_1),
	      .M_AXI_RREADY_1(M_AXI_RREADY_1),
	      .M_AXI_RRESP_1(M_AXI_RRESP_1),
	      .M_AXI_BVALID_1(M_AXI_BVALID_1),
	      .M_AXI_BREADY_1(M_AXI_BREADY_1),
	      .M_AXI_BRESP_1(M_AXI_BRESP_1)
	  );
	

	
	
	
	axi_bram_ctrl_0 ram0 (
	 .s_axi_aclk   (clk   ),        // input wire s_axi_aclk
	 .s_axi_aresetn(~rst),  // input wire s_axi_aresetn
	 .s_axi_awaddr(M_AXI_AWADDR_0[14 : 0]),   
	 .s_axi_awprot(M_AXI_AWPROT_0),   
	 .s_axi_awvalid(M_AXI_AWVALID_0), 
	 .s_axi_awready(M_AXI_AWREADY_0), 
	
	 .s_axi_wdata(M_AXI_WDATA_0),     
	 .s_axi_wstrb(M_AXI_WSTRB_0),     
	 .s_axi_wvalid(M_AXI_WVALID_0),   
	 .s_axi_wready(M_AXI_WREADY_0),   
	
	 .s_axi_bresp(M_AXI_BRESP_0),     
	 .s_axi_bvalid(M_AXI_BVALID_0),   
	 .s_axi_bready(M_AXI_BREADY_0),   
	
	 .s_axi_araddr(M_AXI_ARADDR_0[14 : 0]),   
	 .s_axi_arprot(M_AXI_ARPROT_0),   
	 .s_axi_arvalid(M_AXI_ARVALID_0), 
	 .s_axi_arready(M_AXI_ARREADY_0), 
	
	 .s_axi_rdata(M_AXI_RDATA_0),     
	 .s_axi_rresp(M_AXI_RRESP_0),     
	 .s_axi_rvalid(M_AXI_RVALID_0),   
	 .s_axi_rready(M_AXI_RREADY_0)  
	);
	
	 GPIO_AXI_TOP gpio(
	    // AXI interface
	    .axi_aclk(clk),
	    .axi_arstn(~rst),
	    
	    // AXI Write Address Channel
	    .M_AXI_AWVALID(M_AXI_AWVALID_1),
	    .M_AXI_AWREADY(M_AXI_AWREADY_1),
	    .M_AXI_AWADDR(M_AXI_AWADDR_1),
	    .M_AXI_AWPROT(M_AXI_AWPROT_1),
	
	    // AXI Write Data Channel
	    .M_AXI_WVALID(M_AXI_WVALID_1),
	    .M_AXI_WREADY(M_AXI_WREADY_1),
	    .M_AXI_WDATA(M_AXI_WDATA_1),
	    .M_AXI_WSTRB(M_AXI_WSTRB_1),
	
	    // AXI Write Response Channel
	    .M_AXI_BREADY(M_AXI_BREADY_1),
	    .M_AXI_BVALID(M_AXI_BVALID_1),
	    .M_AXI_BRESP(M_AXI_BRESP_1),
	
	    // AXI Read Address Channel
	    .M_AXI_ARVALID(M_AXI_ARVALID_1),
	    .M_AXI_ARREADY(M_AXI_ARREADY_1),
	    .M_AXI_ARADDR(M_AXI_ARADDR_1),
	    .M_AXI_ARPROT(M_AXI_ARPROT_1),
	
	    // AXI Read Data Channel
	    .M_AXI_RVALID(M_AXI_RVALID_1),
	    .M_AXI_RREADY(M_AXI_RREADY_1),
	    .M_AXI_RDATA(M_AXI_RDATA_1),
	    .M_AXI_RRESP(M_AXI_RRESP_1),
	
	    // GPIO pins
	    .GPIO01(GPIO01)
	);
    endmodule