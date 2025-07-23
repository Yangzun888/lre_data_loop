module rgmii_tx (
    input   wire            gmii_txc     ,   //12.5mhz
    input   wire            gmii_tx_en   ,
    input   wire    [7:0]   gmii_txd     ,
 
    output  wire            rgmii_txc    ,
    output  wire            rgmii_tx_ctrl,
    output  wire    [3:0]   rgmii_txd     
);


assign rgmii_txc = gmii_txc;

ODDR #(
   .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
   .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
) ODDR_inst_tx_ctrl (
   .Q(rgmii_tx_ctrl),   // 1-bit DDR output
   .C(gmii_txc),   // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D1(gmii_tx_en), // 1-bit data input (positive edge)
   .D2(gmii_tx_en), // 1-bit data input (negative edge)
   .R(1'b0),   // 1-bit reset
   .S(1'b0)    // 1-bit set
);

genvar i;
generate
    for ( i = 0; i < 4; i = i + 1) begin:oddr_tx
        ODDR #(
            .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
            .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
            .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
        ) ODDR_inst_txd (
            .Q(rgmii_txd[i]),   // 1-bit DDR output
            .C(gmii_txc),   // 1-bit clock input
            .CE(1'b1), // 1-bit clock enable input
            .D1(gmii_txd[i]), // 1-bit data input (positive edge)
            .D2(gmii_txd[i + 4]), // 1-bit data input (negative edge)
            .R(1'b0),   // 1-bit reset
            .S(1'b0)    // 1-bit set
        );
    end
endgenerate


    
endmodule