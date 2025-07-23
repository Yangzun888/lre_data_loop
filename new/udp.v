module udp (
     (* KEEP = "TRUE" *)input   wire            rst_n           ,   //复位，低电平有效
     (* KEEP = "TRUE" *)input   wire            gmii_txc        ,   //时钟
     (* KEEP = "TRUE" *)input   wire            gmii_rxc        ,   //时钟

    (* KEEP = "TRUE" *)input   wire            gmii_rx_en      ,   //接收数据有效
    (* KEEP = "TRUE" *)input   wire    [7:0]   gmii_rxd        ,   //接收数据

    (* KEEP = "TRUE" *) input   wire    [15:0]  IP_DATA_LEN     ,
    (* KEEP = "TRUE" *) input   wire    [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
    (* KEEP = "TRUE" *) input   wire    [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址
   (* KEEP = "TRUE" *) input   wire            udp_tx_start    ,   //开始发送信号
   (* KEEP = "TRUE" *) input   wire    [7:0]   udp_tx_data     ,   //发送的数据 fifo读出来的数据
   (* KEEP = "TRUE" *) output  wire            udp_tx_done     ,
   (* KEEP = "TRUE" *) output  wire            udp_tx_data_en  ,   //udp数据的请求信号（读使能）
   (* KEEP = "TRUE" *) output  wire            udp_gmii_tx_en  ,   //单沿转双沿的发送使能
(* KEEP = "TRUE" *)output  wire    [7:0]   udp_gmii_txd    ,   //单沿转双沿的发送数据
   (* KEEP = "TRUE" *) output  wire    [7:0]   udp_rx_data     ,   //解析后的数据  写入fifo
   (* KEEP = "TRUE" *) output  wire            udp_rx_data_en      //数据有效      写使能
);

//wire            udp_tx_done     ;
(* KEEP = "TRUE" *)wire            udp_rx_done     ;
wire            crc_en          ;  //crc使能，开始校验标志
wire            crc_clr         ;  //crc数据复位信号            
wire  [31:0]    crc_data        ;  //CRC校验数据
wire  [31:0]    crc_next        ;  //CRC下次校验完成数据

udp_tx udp_tx_u(
    .gmii_txc        (gmii_txc        ),   //时钟
    .rst_n           (rst_n           ),   //复位，低电平有效
    .udp_tx_start    (udp_tx_start ||udp_rx_done   ),   //开始发送信号  发送完成或者接收完成信号
    .udp_tx_data     (udp_tx_data     ),   //发送的数据
    .pc_mac          (pc_mac          ),   //arp_rx解析后的pc的mac地址
    .pc_ip           (pc_ip           ),   //arp_rx解析后的pc的ip地址
    .udp_tx_data_en  (udp_tx_data_en  ),   //udp数据的请求信号（读使能）
    .udp_gmii_tx_en  (udp_gmii_tx_en  ),   //单沿转双沿的发送使能
    .udp_gmii_txd    (udp_gmii_txd    ),   //单沿转双沿的发送数据
    .udp_tx_done     (udp_tx_done     ),   //发生完成信号
    .IP_DATA_LEN     (IP_DATA_LEN     ),
    //crc_32校验端口
    .crc_en          (crc_en          ),  //crc使能，开始校验标志
    .crc_clr         (crc_clr         ),  //crc数据复位信号            
    .crc_data        (crc_data        ),  //CRC校验数据
    .crc_next        (crc_next        )   //CRC下次校验完成数据
);

udp_rx udp_rx_u(
    .gmii_rxc        (gmii_rxc        ),   //时钟
    .rst_n           (rst_n           ),   //复位
    .gmii_rx_en      (gmii_rx_en      ),   //接收数据有效
    .gmii_rxd        (gmii_rxd        ),   //接收数据
    .pc_mac          (pc_mac          ),   //arp_rx解析后的pc的mac地址
    .pc_ip           (pc_ip           ),   //arp_rx解析后的pc的ip地址
    .udp_rx_data     (udp_rx_data     ),   //解析后的数据
    .udp_rx_data_en  (udp_rx_data_en  ),   //数据有效
    .udp_rx_done     (udp_rx_done     )    //接收完成信号
);

crc32_data crc32_data_u(
    .clk     (gmii_txc     ),  //时钟信号
    .rst_n   (rst_n   ),  //复位信号，低电平有效
    .data    (udp_gmii_txd    ),  //输入待校验8位数据
    .crc_en  (crc_en  ),  //crc使能，开始校验标志
    .crc_clr (crc_clr ),  //crc数据复位信号            
    .crc_data(crc_data),  //CRC校验数据
    .crc_next(crc_next)   //CRC下次校验完成数据
    );





endmodule