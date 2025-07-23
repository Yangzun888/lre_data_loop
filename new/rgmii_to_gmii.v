module rgmii_to_gmii (
    //rgmii锟接匡拷
    (* KEEP = "TRUE" *)input   wire            rgmii_rxc       ,
    (* KEEP = "TRUE" *) input   wire           rgmii_rx_ctrl   ,
    (* KEEP = "TRUE" *)input   wire    [3:0]   rgmii_rxd       ,

    (* KEEP = "TRUE" *)output  wire            rgmii_txc       ,
    (* KEEP = "TRUE" *)output  wire            rgmii_tx_ctrl   ,
    (* KEEP = "TRUE" *)output  wire    [3:0]   rgmii_txd       , 
    //gmii锟接匡拷
    (* KEEP = "TRUE" *)input   wire            gmii_tx_en      ,
    (* KEEP = "TRUE" *)input   wire    [7:0]   gmii_txd        ,
    (* KEEP = "TRUE" *)output  wire            gmii_txc        ,

    (* KEEP = "TRUE" *)output  wire            gmii_rxc        ,
    (* KEEP = "TRUE" *)output  wire            gmii_rx_en      ,
    (* KEEP = "TRUE" *)output  wire    [7:0]   gmii_rxd        
);

(* KEEP = "TRUE" *)assign gmii_txc = gmii_rxc;    // 实际上是从rgmii 通过全局时钟恢复而来


rgmii_tx rgmii_tx_u(
    .gmii_txc     (gmii_txc     ),
    .gmii_tx_en   (gmii_tx_en   ),
    .gmii_txd     (gmii_txd     ),
    
    .rgmii_txc    (rgmii_txc    ),
    .rgmii_tx_ctrl(rgmii_tx_ctrl),
    .rgmii_txd    (rgmii_txd    ) 
);

rgmii_rx rgmii_rx_u(
    .rgmii_rxc      (rgmii_rxc       ),
    .rgmii_rx_ctrl  (rgmii_rx_ctrl   ),
    .rgmii_rxd      (rgmii_rxd       ),

    .gmii_rxc       (gmii_rxc        ),
    .gmii_rx_en     (gmii_rx_en      ),
    .gmii_rxd       (gmii_rxd        )
);


  
endmodule