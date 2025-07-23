module arp (
    input   wire            rst_n           ,   //复位，低电平有效
 (* KEEP = "TRUE" *)  input   wire            gmii_rxc        ,   //时钟125Mhz，由phy产生
 (* KEEP = "TRUE" *)   input   wire            gmii_rx_en      ,  //接收数据使能
 (* KEEP = "TRUE" *)   input   wire    [7:0]   gmii_rxd        ,   //接收数据
 (* KEEP = "TRUE" *)   input   wire            arp_key_flag    ,    //按键消抖有效信号
 (* KEEP = "TRUE" *)   input   wire            gmii_txc        ,   //时钟125Mhz
    
    output  wire    [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
    output  wire    [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址    
    
 (* KEEP = "TRUE" *)   output  wire            arp_done        ,
 (* KEEP = "TRUE" *)   output  wire            arp_gmii_tx_en  ,   //单沿转双沿的发送使能
 (* KEEP = "TRUE" *)   output  wire    [7:0]   arp_gmii_txd        //单沿转双沿的发送数据
    
);

// wire     [47:0]  pc_mac          ;   //arp_rx解析后的pc的mac地址
// wire     [31:0]  pc_ip           ;   //arp_rx解析后的pc的ip地址    
(* KEEP = "TRUE" *)wire             arp_rx_done     ;   //arp解析数据完成信号
(* KEEP = "TRUE" *)wire             arp_rx_type     ;   //0 接收到的是请求包   1接收到的应答包  

(* KEEP = "TRUE" *)wire             arp_tx_start    ;   //开始发送信号 
(* KEEP = "TRUE" *)wire             arp_tx_type     ;   //0 发送请求包   1发送应答包
(* KEEP = "TRUE" *)wire             arp_tx_done     ;   //发生完成信号

wire             crc_en          ;  //crc使能，开始校验标志
wire             crc_clr         ;  //crc数据复位信号            
wire   [31:0]    crc_data        ;  //CRC校验数据
wire   [31:0]    crc_next        ;   //CRC下次校验完成数据


arp_rx arp_rx_u(
    .gmii_rxc        (gmii_rxc        ),   //时钟125Mhz，由phy产生
    .rst_n           (rst_n           ),   //复位，低电平有效
    .gmii_rx_en      (gmii_rx_en      ),   //接收数据使能
    .gmii_rxd        (gmii_rxd        ),   //接收数据

    .pc_mac          (pc_mac          ),   //arp_rx解析后的pc的mac地址
    .pc_ip           (pc_ip           ),   //arp_rx解析后的pc的ip地址     
    .arp_rx_done     (arp_rx_done     ),   //arp解析数据完成信号
    .arp_rx_type     (arp_rx_type     )    //0 接收到的是请求包   1接收到的应答包   
);

arp_tx arp_tx_u(
    .gmii_txc        (gmii_txc        ),   //时钟125Mhz
    .rst_n           (rst_n           ),   //复位 低电平有效
    .arp_tx_start    (arp_tx_start    ),   //开始发送信号 
    .arp_tx_type     (arp_tx_type     ),   //0 发送请求包   1发送应答包
    .pc_mac          (pc_mac          ),   //arp_rx解析后的pc的mac地址
    .pc_ip           (pc_ip           ),   //arp_rx解析后的pc的ip地址
    .arp_gmii_tx_en  (arp_gmii_tx_en  ),   //单沿转双沿的发送使能
    .arp_gmii_txd    (arp_gmii_txd    ),   //单沿转双沿的发送数据
    .arp_tx_done     (arp_tx_done     ),   //发生完成信号
    //crc_32校验端口
    .crc_en          (crc_en          ),  //crc使能，开始校验标志
    .crc_clr         (crc_clr         ),  //crc数据复位信号            
    .crc_data        (crc_data        ),  //CRC校验数据
    .crc_next        (crc_next        )   //CRC下次校验完成数据
);

arp_ctrl arp_ctrl_u(
    .gmii_txc    (gmii_txc    ),   //时钟
    .rst_n       (rst_n       ),   //复位
    .arp_key_flag(arp_key_flag),   //按键消抖有效信号
    .arp_rx_done (arp_rx_done ),   //接收完成信号
    .arp_rx_type (arp_rx_type ),   //接收的帧类型
    .arp_tx_start(arp_tx_start),   //开始发送信号 
    .arp_done    (arp_done)    ,
    .arp_tx_type (arp_tx_type )    //0 发送请求包   1发送应答包
);

crc32_data crc32_data_u(
    .clk     (gmii_txc),  //时钟信号
    .rst_n   (rst_n),  //复位信号，低电平有效
    .data    (arp_gmii_txd),  //输入待校验8位数据
    
    .crc_en  (crc_en  ),  //crc使能，开始校验标志
    .crc_clr (crc_clr ),  //crc数据复位信号            
    .crc_data(crc_data),  //CRC校验数据
    .crc_next(crc_next)   //CRC下次校验完成数据
    );
    
  
   

endmodule