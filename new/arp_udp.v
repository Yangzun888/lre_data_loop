module arp_udp (      //  用于控制发送数据和使能   
    input   wire            udp_gmii_tx_en  ,   //单沿转双沿的发送使能
    input   wire    [7:0]   udp_gmii_txd    ,   //单沿转双沿的发送数据
    input   wire            arp_gmii_tx_en  ,   //单沿转双沿的发送使能
    input   wire    [7:0]   arp_gmii_txd    ,   //单沿转双沿的发送数据

    output  wire            gmii_tx_en      ,   //单沿转双沿的发送使能
    output  wire    [7:0]   gmii_txd            //单沿转双沿的发送数据
);  

assign gmii_tx_en = (arp_gmii_tx_en) ? arp_gmii_tx_en : udp_gmii_tx_en ;
assign gmii_txd   = (arp_gmii_tx_en) ? arp_gmii_txd   : udp_gmii_txd   ;
    
endmodule