module GPIO_AXI_TOP (
    // AXI interface
    input           axi_aclk,
    input           axi_arstn,
    
    // AXI Write Address Channel
    input           M_AXI_AWVALID,
    output reg      M_AXI_AWREADY,
    input  [31:0]   M_AXI_AWADDR,
    input           M_AXI_AWPROT,

    // AXI Write Data Channel
    input           M_AXI_WVALID,
    output reg      M_AXI_WREADY,
    input  [31:0]   M_AXI_WDATA,
    input  [3:0]    M_AXI_WSTRB,

    // AXI Write Response Channel
    input           M_AXI_BREADY,
    output reg      M_AXI_BVALID,
    output [1:0]    M_AXI_BRESP,

    // AXI Read Address Channel
    input           M_AXI_ARVALID,
    output reg      M_AXI_ARREADY,
    input  [31:0]   M_AXI_ARADDR,
    input           M_AXI_ARPROT,

    // AXI Read Data Channel
    output reg      M_AXI_RVALID,
    input           M_AXI_RREADY,
    output reg [31:0] M_AXI_RDATA,
    output [1:0]    M_AXI_RRESP,

    // GPIO pins
    inout           GPIO01,
    inout           GPIO05,
    inout           GPIO13,
    inout           GPIO18,
    inout           GPIO19,
    inout           GPIO20,
    inout           GPIO34,
    inout           GPIO35,
    inout           GPIO36,
    inout           GPIO37,
    inout           GPIO38,
    inout           GPIO39,
    inout           GPIO40
);

    reg [31:0]       gpioa_oe_r;  // GPIOA enable register
    reg [31:0]       gpioa_o_r;   // GPIOA output register
    reg [31:0]       gpiob_oe_r;  // GPIOB enable register
    reg [31:0]       gpiob_o_r;   // GPIOB output register

    // AXI Write Enable (for writing data to registers)
    wire we = M_AXI_AWVALID & M_AXI_WVALID & M_AXI_AWREADY & M_AXI_WREADY;
    
    // AXI Read Enable (for reading data from registers)
    wire re = M_AXI_ARVALID & M_AXI_ARREADY;

    // AXI handshake logic
    always @(posedge axi_aclk or negedge axi_arstn) begin
        if (!axi_arstn) begin
            M_AXI_AWREADY <= 1'b0;
            M_AXI_WREADY  <= 1'b0;
            M_AXI_BVALID  <= 1'b0;
            M_AXI_ARREADY <= 1'b0;
            M_AXI_RVALID  <= 1'b0;
        end else begin
            // Write Address Channel
            if (M_AXI_AWVALID && !M_AXI_AWREADY) begin
                M_AXI_AWREADY <= 1'b1;
            end else begin
                M_AXI_AWREADY <= 1'b0;
            end

            // Write Data Channel
            if (M_AXI_WVALID && !M_AXI_WREADY) begin
                M_AXI_WREADY <= 1'b1;
            end else begin
                M_AXI_WREADY <= 1'b0;
            end

            // Write Response Channel
            if (M_AXI_BREADY && M_AXI_BVALID) begin
                M_AXI_BVALID <= 1'b0;
            end else if (we) begin
                M_AXI_BVALID <= 1'b1;
            end

            // Read Address Channel
            if (M_AXI_ARVALID && !M_AXI_ARREADY) begin
                M_AXI_ARREADY <= 1'b1;
            end else begin
                M_AXI_ARREADY <= 1'b0;
            end

            // Read Data Channel
            if (M_AXI_RREADY && M_AXI_RVALID) begin
                M_AXI_RVALID <= 1'b0;
            end else if (re) begin
                M_AXI_RVALID <= 1'b1;
            end
        end
    end

    // Implement register write logic (AXI interface)
    always @(posedge axi_aclk or negedge axi_arstn) begin
        if (!axi_arstn) begin
            gpioa_oe_r <= 32'b0;
            gpioa_o_r  <= 32'b0;
            gpiob_oe_r <= 32'b0;
            gpiob_o_r  <= 32'b0;
        end else if (we) begin
            case (M_AXI_AWADDR[7:0])
                8'h40: gpioa_oe_r <= M_AXI_WDATA;
                8'h44: gpioa_o_r  <= M_AXI_WDATA;
                8'h50: gpiob_oe_r <= M_AXI_WDATA;
                8'h54: gpiob_o_r  <= M_AXI_WDATA;
                default: ; // Do nothing
            endcase
        end
    end

    // Signals for GPIO readback
    wire [31:0] gpioa_oe;
    wire [31:0] gpioa_o;
    wire [31:0] gpioa_i;
    wire [31:0] gpiob_oe;
    wire [31:0] gpiob_o;
    wire [31:0] gpiob_i;

    assign gpioa_oe = gpioa_oe_r;
    assign gpioa_o  = gpioa_o_r;
    assign gpiob_oe = gpiob_oe_r;
    assign gpiob_o  = gpiob_o_r;

    // Readback logic for AXI interface
    always @(*) begin
        case (M_AXI_ARADDR[7:0])
            8'h40: M_AXI_RDATA = gpioa_oe;
            8'h44: M_AXI_RDATA = gpioa_o;
            8'h48: M_AXI_RDATA = gpioa_i;
            8'h50: M_AXI_RDATA = gpiob_oe;
            8'h54: M_AXI_RDATA = gpiob_o;
            8'h58: M_AXI_RDATA = gpiob_i;
            default: M_AXI_RDATA = 32'b0;
        endcase
    end

    assign M_AXI_BRESP = 2'b00;  // OKAY response
    assign M_AXI_RRESP = 2'b00;  // OKAY response

    // GPIO I/O Buffer for bidirectional communication
    IOBUF pad_GPIO01 (.IO(GPIO01), .O(gpioa_i[1]), .I(gpioa_o[1]), .T(~gpioa_oe[1]));
    //IOBUF pad_GPIO05 (.IO(GPIO05), .O(gpioa_i[5]), .I(gpioa_o[5]), .T(~gpioa_oe[5]));
    //IOBUF pad_GPIO13 (.IO(GPIO13), .O(gpioa_i[13]), .I(gpioa_o[13]), .T(~gpioa_oe[13]));
    //IOBUF pad_GPIO18 (.IO(GPIO18), .O(gpioa_i[18]), .I(gpioa_o[18]), .T(~gpioa_oe[18]));
    //IOBUF pad_GPIO19 (.IO(GPIO19), .O(gpioa_i[19]), .I(gpioa_o[19]), .T(~gpioa_oe[19]));
    //IOBUF pad_GPIO20 (.IO(GPIO20), .O(gpioa_i[20]), .I(gpioa_o[20]), .T(~gpioa_oe[20]));
//
    //IOBUF pad_GPIO34 (.IO(GPIO34), .O(gpiob_i[2]), .I(gpiob_o[2]), .T(~gpiob_oe[2]));
    //IOBUF pad_GPIO35 (.IO(GPIO35), .O(gpiob_i[3]), .I(gpiob_o[3]), .T(~gpiob_oe[3]));
    //IOBUF pad_GPIO36 (.IO(GPIO36), .O(gpiob_i[4]), .I(gpiob_o[4]), .T(~gpiob_oe[4]));
    //IOBUF pad_GPIO37 (.IO(GPIO37), .O(gpiob_i[5]), .I(gpiob_o[5]), .T(~gpiob_oe[5]));
    //IOBUF pad_GPIO38 (.IO(GPIO38), .O(gpiob_i[6]), .I(gpiob_o[6]), .T(~gpiob_oe[6]));
    //IOBUF pad_GPIO39 (.IO(GPIO39), .O(gpiob_i[7]), .I(gpiob_o[7]), .T(~gpiob_oe[7]));
    //IOBUF pad_GPIO40 (.IO(GPIO40), .O(gpiob_i[8]), .I(gpiob_o[8]), .T(~gpiob_oe[8]));

endmodule