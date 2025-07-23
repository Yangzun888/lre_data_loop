module rgmii_rx (
    input   wire            rgmii_rxc       ,
    input   wire            rgmii_rx_ctrl   ,
    input   wire    [3:0]   rgmii_rxd       ,

    output  wire            gmii_rxc        ,
    output  wire            gmii_rx_en      ,
    output  wire    [7:0]   gmii_rxd        
);

wire rgmii_rx_bufg ;    //经过全局时钟网络资源的输入时钟
wire rgmii_rx_bufio;    //

wire [1:0]  gmii_rx_ctrl;

assign gmii_rxc = rgmii_rx_bufg;
assign gmii_rx_en = gmii_rx_ctrl[0] & gmii_rx_ctrl[1];

BUFIO BUFIO_inst (
   .O(rgmii_rx_bufio), // 1-bit output: Clock output (connect to I/O clock loads).
   .I(rgmii_rxc)  // 1-bit input: Clock input (connect to an IBUF or BUFMR).
);

BUFG BUFG_inst (
   .O(rgmii_rx_bufg), // 1-bit output: Clock output
   .I(rgmii_rxc)  // 1-bit input: Clock input
);


IDDR #(
   .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                   //    or "SAME_EDGE_PIPELINED" 
   .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
   .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
) IDDR_inst_rx_ctrl (
   .Q1(gmii_rx_ctrl[0]), // 1-bit output for positive edge of clock
   .Q2(gmii_rx_ctrl[1]), // 1-bit output for negative edge of clock
   .C(rgmii_rx_bufio),   // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D(rgmii_rx_ctrl),   // 1-bit DDR data input
   .R(1'b0),   // 1-bit reset
   .S(1'b0)    // 1-bit set
);
    

genvar i;
generate
    for ( i= 0; i < 4; i = i + 1) begin:iddr_rx
    IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                        //    or "SAME_EDGE_PIPELINED" 
        .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
        .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
        .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
    ) IDDR_inst_rxd (
        .Q1(gmii_rxd[i]), // 1-bit output for positive edge of clock
        .Q2(gmii_rxd[i + 4]), // 1-bit output for negative edge of clock
        .C(rgmii_rx_bufio),   // 1-bit clock input
        .CE(1'b1), // 1-bit clock enable input
        .D(rgmii_rxd[i]),   // 1-bit DDR data input
        .R(1'b0),   // 1-bit reset
        .S(1'b0)    // 1-bit set
        );
    end
endgenerate

endmodule