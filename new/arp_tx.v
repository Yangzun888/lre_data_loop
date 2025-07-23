module arp_tx (
     (* KEEP = "TRUE" *)input   wire            gmii_txc        ,   //时钟125Mhz
     (* KEEP = "TRUE" *)input   wire            rst_n           ,   //复位 低电平有效
     (* KEEP = "TRUE" *)input   wire            arp_tx_start    ,   //开始发送信号 
     (* KEEP = "TRUE" *)input   wire            arp_tx_type     ,   //0 发送请求包   1发送应答包
     (* KEEP = "TRUE" *)input   wire    [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
     (* KEEP = "TRUE" *)input   wire    [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址
     (* KEEP = "TRUE" *)output  reg             arp_gmii_tx_en  ,   //单沿转双沿的发送使能
     (* KEEP = "TRUE" *)output  reg     [7:0]   arp_gmii_txd    ,   //单沿转双沿的发送数据
     (* KEEP = "TRUE" *)output  reg             arp_tx_done     ,   //发生完成信号
     (* KEEP = "TRUE" *)//crc_32校验端口
     (* KEEP = "TRUE" *)output  reg             crc_en          ,  //crc使能，开始校验标志
     (* KEEP = "TRUE" *)output  reg             crc_clr         ,  //crc数据复位信号            
     (* KEEP = "TRUE" *)input   wire  [31:0]    crc_data        ,  //CRC校验数据
     (* KEEP = "TRUE" *)input   wire  [7 :0]    crc_next           //CRC下次校验完成数据
);

parameter BOARD_MAC = 48'h00_11_22_33_44_55     ;   //FPGA的MAC地址
parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd5} ;   //FPGA的IP地址
parameter DES_IP    = {8'd192,8'd168,8'd0,8'd5} ;   //目的的IP地址


localparam IDLE     = 5'b0_0001;    //空闲
localparam PRE_DATA = 5'b0_0010;    //前导码(7byte的8'h55)+帧起始界定符(1byte的8'hd5)
localparam ETH_HEAD = 5'b0_0100;    //以太网帧头(14byte)
localparam ARP_DATA = 5'b0_1000;    //arp数据(28byte有效+18byte填充)
localparam CRC      = 5'b1_0000;    //crc校验(4byte)

reg [4:0] c_state,n_state;


//---中间寄存器定义---
reg [5:0] cnt_byte; //字节计数器寄存器

reg [7:0] head_data [13:0] ;    //以太网帧头
reg [7:0] arp_data_reg [27:0] ;    //arp数据包

//------三段式状态机 一   将次态赋值给现态--------//
always @(posedge gmii_txc ) begin
    if(!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

//------三段式状态机 二   状态跳转描述--------//
always @(*) begin
    if(!rst_n)
        n_state = IDLE;
    else begin
        case (c_state)
                IDLE     : begin
                    if(arp_tx_start)            
                        n_state = PRE_DATA;
                    else
                        n_state = IDLE;
                end
                PRE_DATA : begin
                    if(cnt_byte == 7)
                        n_state = ETH_HEAD;
                    else
                        n_state = PRE_DATA;
                end
                ETH_HEAD : begin
                    if(cnt_byte == 13)
                        n_state = ARP_DATA;
                    else
                        n_state = ETH_HEAD;
                end
                ARP_DATA : begin
                    if(cnt_byte == 45)
                        n_state = CRC;
                    else
                        n_state = ARP_DATA;
                end
                CRC      : begin
                    if(cnt_byte == 3)
                        n_state = IDLE;
                    else
                        n_state = CRC;
                end
            default: n_state = IDLE;
        endcase
    end
end

//------三段式状态机 三   对中间变量及输出结果赋值--------//
//---对字节计数器寄存器赋值
always @(posedge gmii_txc ) begin
    if(!rst_n)
        cnt_byte <= 0;
    else begin
        case (c_state)
                PRE_DATA : begin
                    if(cnt_byte == 7)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                ETH_HEAD : begin
                    if(cnt_byte == 13)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                ARP_DATA : begin
                    if(cnt_byte == 45)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                CRC      : begin
                    if(cnt_byte == 3)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
            default: cnt_byte <= 0;
        endcase
    end
end


always @(posedge gmii_txc ) begin
    if(!rst_n)begin
        arp_gmii_txd <= 0;

        //-----以太网帧头---//
        //目的mac 广播
        head_data[0]  <= 8'hff;
        head_data[1]  <= 8'hff;
        head_data[2]  <= 8'hff;
        head_data[3]  <= 8'hff;
        head_data[4]  <= 8'hff;
        head_data[5]  <= 8'hff;
        //源mac 板子
        head_data[6]  <= BOARD_MAC[47:40];
        head_data[7]  <= BOARD_MAC[39:32];
        head_data[8]  <= BOARD_MAC[31:24];
        head_data[9]  <= BOARD_MAC[23:16];
        head_data[10] <= BOARD_MAC[15:8];
        head_data[11] <= BOARD_MAC[7:0];
        //长度 / 类型
        head_data[12] <= 8'h08;
        head_data[13] <= 8'h06;

        //-----arp数据包---//
        //硬件类型：硬件地址的类型，以太网固定为 0x0001。
        arp_data_reg[0] <= 8'h00;
        arp_data_reg[1] <= 8'h01;
        //协议类型：ARP 协议的上层协议是 IP 协议，该值为 0x0800。
        arp_data_reg[2] <= 8'h08;
        arp_data_reg[3] <= 8'h00;
        //硬件地址长度：MAC 地址长度，以字节为单位，该值为 6。
        arp_data_reg[4] <= 8'h06;
        //协议地址长度：IP 地址长度，以字节为单位，该值为 4。
        arp_data_reg[5] <= 8'h04;
        //OP：操作码，表示该数据包是 ARP 请求包，还是 ARP 应答包，1 表示请求包，2 表示应答包。
        arp_data_reg[6] <= 8'h00;    //开始复位时发送请求包(下面把自己所有的mac 和 ip地址发送)，用于与主机建立联系
        arp_data_reg[7] <= 8'h01;
        //源 MAC 地址：发送端的硬件地址
        arp_data_reg[8 ] <= BOARD_MAC[47:40];
        arp_data_reg[9 ] <= BOARD_MAC[39:32];
        arp_data_reg[10] <= BOARD_MAC[31:24];
        arp_data_reg[11] <= BOARD_MAC[23:16];
        arp_data_reg[12] <= BOARD_MAC[15:8];
        arp_data_reg[13] <= BOARD_MAC[7:0];
        //源 IP 地址：发送端的 IP 地址
        arp_data_reg[14] <= BOARD_IP[31:24];
        arp_data_reg[15] <= BOARD_IP[23:16];
        arp_data_reg[16] <= BOARD_IP[15:8];
        arp_data_reg[17] <= BOARD_IP[7:0];
        //目的 MAC 地址：接收端的 MAC 地址，广播
        arp_data_reg[18] <= 8'hff;
        arp_data_reg[19] <= 8'hff;
        arp_data_reg[20] <= 8'hff;
        arp_data_reg[21] <= 8'hff;
        arp_data_reg[22] <= 8'hff;
        arp_data_reg[23] <= 8'hff;
        //目的 IP 地址：接收端的 IP 地址。
        arp_data_reg[24] <= DES_IP[31:24];
        arp_data_reg[25] <= DES_IP[23:16];
        arp_data_reg[26] <= DES_IP[15:8];
        arp_data_reg[27] <= DES_IP[7:0];
    end
    else begin
        case (c_state)
                IDLE     : begin
                    arp_gmii_txd <= 0;
                    if(arp_tx_type)begin //发送应答包
                        //-----以太网帧头---//
                        //目的mac pc的
                        head_data[0]  <= pc_mac[47:40];
                        head_data[1]  <= pc_mac[39:32];
                        head_data[2]  <= pc_mac[31:24];
                        head_data[3]  <= pc_mac[23:16];
                        head_data[4]  <= pc_mac[15:8];
                        head_data[5]  <= pc_mac[7:0];

                        //目的 MAC 地址：接收端的 MAC 地址，pc的
                        arp_data_reg[18] <= pc_mac[47:40];
                        arp_data_reg[19] <= pc_mac[39:32];
                        arp_data_reg[20] <= pc_mac[31:24];
                        arp_data_reg[21] <= pc_mac[23:16];
                        arp_data_reg[22] <= pc_mac[15:8];
                        arp_data_reg[23] <= pc_mac[7:0];

                         //OP：操作码，
                        arp_data_reg[7] <= 8'h02;
                    end
                    else
                        arp_data_reg[7] <= 8'h01;
                end
                PRE_DATA : begin
                    if(cnt_byte < 7)
                        arp_gmii_txd <= 8'h55;
                    else
                        arp_gmii_txd <= 8'hd5;
                end
                ETH_HEAD : begin
                    arp_gmii_txd <= head_data[cnt_byte];
                end
                ARP_DATA : begin
                    if(cnt_byte < 28)
                        arp_gmii_txd <= arp_data_reg[cnt_byte];
                    else
                        arp_gmii_txd <= 8'd0;   //填充数据
                end
                CRC      : begin
                    if(cnt_byte == 0)
                        arp_gmii_txd <= {~crc_next[0],~crc_next[1],~crc_next[2],~crc_next[3],
                                         ~crc_next[4],~crc_next[5],~crc_next[6],~crc_next[7]};
                    else if(cnt_byte == 1)
                        arp_gmii_txd <= {~crc_data[16],~crc_data[17],~crc_data[18],~crc_data[19],
                                         ~crc_data[20],~crc_data[21],~crc_data[22],~crc_data[23]};
                    else if(cnt_byte == 2)
                        arp_gmii_txd <= {~crc_data[8],~crc_data[9],~crc_data[10],~crc_data[11],
                                         ~crc_data[12],~crc_data[13],~crc_data[14],~crc_data[15]};
                    else if(cnt_byte == 3)
                        arp_gmii_txd <= {~crc_data[0],~crc_data[1],~crc_data[2],~crc_data[3],
                                         ~crc_data[4],~crc_data[5],~crc_data[6],~crc_data[7]};
                end
            default: arp_gmii_txd <= 8'd0;
        endcase
    end
end

always @(posedge gmii_txc ) begin
    if(!rst_n)
        arp_gmii_tx_en <= 0;
    else if(c_state == IDLE)
        arp_gmii_tx_en <= 0;
    else
        arp_gmii_tx_en <= 1;
end

always @(posedge gmii_txc ) begin
    if(!rst_n)begin
        arp_tx_done <= 0;
        crc_clr     <= 0;
    end
    else if(c_state == CRC && cnt_byte == 3)begin
        arp_tx_done <= 1;
        crc_clr     <= 1;
    end
    else begin
        arp_tx_done <= 0;
        crc_clr     <= 0;
    end
end

always @(posedge gmii_txc ) begin
    if(!rst_n)
        crc_en <= 0;
    else if(c_state == ETH_HEAD || c_state == ARP_DATA)
        crc_en <= 1;
    else
        crc_en <= 0;
end

 ila_arp_tx u_ila_arp_tx (
	.clk(gmii_txc), // input wire clk
	.probe0(arp_gmii_txd), // input wire [7:0]  probe0  
	.probe1(arp_gmii_tx_en), // input wire [0:0]  probe1 
	.probe2(arp_tx_done), // input wire [0:0]  probe2 
	.probe3(arp_tx_type), // input wire [0:0]  probe3 
	.probe4(arp_tx_start), // input wire [0:0]  probe4
    .probe5(arp_done), // input wire [0:0]  probe5
    .probe6(c_state), // input wire [4:0]  probe6
    .probe7(cnt_byte)// input wire [5:0]  probe7
);
endmodule