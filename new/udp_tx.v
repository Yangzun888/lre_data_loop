module udp_tx (
    (* KEEP = "TRUE" *) input   wire            gmii_txc        ,   //时钟
    (* KEEP = "TRUE" *) input   wire            rst_n           ,   //复位，低电平有效
    (* KEEP = "TRUE" *) input   wire            udp_tx_start    ,   //开始发送信号
    (* KEEP = "TRUE" *) input   wire    [7:0]   udp_tx_data     ,   //发送的数据
    (* KEEP = "TRUE" *) //与arp_rx模块的接口
    (* KEEP = "TRUE" *) input   wire    [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
    (* KEEP = "TRUE" *) input   wire    [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址
    (* KEEP = "TRUE" *) //与gmii_to_rgmii模块的接口
    (* KEEP = "TRUE" *) output  reg             udp_gmii_tx_en  ,   //单沿转双沿的发送使能
    (* KEEP = "TRUE" *) output  reg     [7:0]   udp_gmii_txd    ,   //单沿转双沿的发送数据
    (* KEEP = "TRUE" *) //与udp_ctrl模块的接口
    (* KEEP = "TRUE" *) input   wire    [15:0]  IP_DATA_LEN     ,   //有ctrl模块控制的传输数据的长度
    (* KEEP = "TRUE" *) output  wire            udp_tx_data_en  ,   //udp数据的请求信号（读使能）
    (* KEEP = "TRUE" *) output  reg             udp_tx_done     ,   //发生完成信号 
    (* KEEP = "TRUE" *) //crc_32校验端口
    (* KEEP = "TRUE" *) input   wire  [31:0]    crc_data        ,  //CRC校验数据
    (* KEEP = "TRUE" *) input   wire  [31:0]    crc_next        ,  //CRC下次校验完成数据
    (* KEEP = "TRUE" *) output  reg             crc_en          ,  //crc使能，开始校验标志
    (* KEEP = "TRUE" *) output  reg             crc_clr            //crc数据复位信号            

);

//parameter IP_DATA_LEN = 46 ;    //传输的数据个数
parameter BOARD_MAC = 48'h00_11_22_33_44_55     ;   //FPGA的MAC地址
parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd5} ;   //FPGA的IP地址

localparam IDLE         = 7'b000_0001;  //空闲
localparam CHECK_SUM    = 7'b000_0010;  //首部校验和
localparam PRE_DATA     = 7'b000_0100;  //前导码
localparam ETH_HEAD     = 7'b000_1000;  //以太网帧头
localparam IP_HEAD      = 7'b001_0000;  //ip首部和udp首部
localparam UDP_DATA     = 7'b010_0000;  //udp数据
localparam CRC          = 7'b100_0000;  //crc校验

reg [6:0] c_state,n_state;

//---中间寄存器定义---
reg [10:0]  cnt_byte                ;    //字节计数器寄存器
reg [15:0]  sign_num                ;    //标识号
reg [31:0]  check_sum_data          ;    //ip首部校验和
reg [7:0]   eth_head_data [13:0]    ;    //以太网帧头
reg [7:0]   ip_head_data [27:0]     ;    //ip首部 + udp首部

wire [15:0] num;
assign num = IP_DATA_LEN - 20;

assign udp_tx_data_en = (c_state == UDP_DATA) ? 1 : 0;

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
                IDLE      : begin
                    if(udp_tx_start)
                        n_state = CHECK_SUM;
                    else
                        n_state = IDLE;
                end
                CHECK_SUM : begin               //IP首部校验和
                    if(cnt_byte == 3)
                        n_state = PRE_DATA;
                    else
                        n_state = CHECK_SUM;
                end
                PRE_DATA  : begin
                    if(cnt_byte == 7)
                        n_state = ETH_HEAD;
                    else
                        n_state = PRE_DATA;
                end
                ETH_HEAD  : begin
                    if(cnt_byte == 13)
                        n_state = IP_HEAD;
                    else
                        n_state = ETH_HEAD;
                end
                IP_HEAD   : begin
                    if(cnt_byte == 27)
                        n_state = UDP_DATA;
                    else
                        n_state = IP_HEAD;
                end
                UDP_DATA  : begin
                    if(cnt_byte == IP_DATA_LEN - 29)
                        n_state = CRC;
                    else
                        n_state = UDP_DATA;
                end
                CRC       : begin
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
                CHECK_SUM : begin
                    if(cnt_byte == 3)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                PRE_DATA  : begin
                    if(cnt_byte == 7)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                ETH_HEAD  : begin
                    if(cnt_byte == 13)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                IP_HEAD   : begin
                    if(cnt_byte == 27)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                UDP_DATA  : begin
                    if(cnt_byte == IP_DATA_LEN - 29)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                CRC       : begin
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
        udp_gmii_txd <= 0;
    end
    else begin
        case (c_state)
                IDLE      : begin
                    udp_gmii_txd <= 0;

                    //----以太网帧头----//
                    //目的mac地址
                    eth_head_data[0 ] <= pc_mac[47:40];
                    eth_head_data[1 ] <= pc_mac[39:32];
                    eth_head_data[2 ] <= pc_mac[31:24];
                    eth_head_data[3 ] <= pc_mac[23:16];
                    eth_head_data[4 ] <= pc_mac[15:8];
                    eth_head_data[5 ] <= pc_mac[7:0];
                    //目的mac地址
                    eth_head_data[6 ] <= BOARD_MAC[47:40];
                    eth_head_data[7 ] <= BOARD_MAC[39:32];
                    eth_head_data[8 ] <= BOARD_MAC[31:24];
                    eth_head_data[9 ] <= BOARD_MAC[23:16];
                    eth_head_data[10] <= BOARD_MAC[15:8];
                    eth_head_data[11] <= BOARD_MAC[7:0];
                    //长度/类型 ip协议
                    eth_head_data[12] <= 8'h08;
                    eth_head_data[13] <= 8'h00;

                    //----ip首部 + udp首部----//
                    //版本（4bit）：IPV4，固定为 4。
                    //首部长度（4bit）：IPV4 首部长度为 20byte，但是这里是以 4byte 作为一个单位，该值为 5。
                    ip_head_data[0] <= 8'h45;
                    //区分服务（8bit）：提供更好的服务，一般不使用
                    ip_head_data[1] <= 8'h00;
                    //总长度（16bit）：IP 首部和数据之和的总长度。
                    ip_head_data[2] <= IP_DATA_LEN[15:8];
                    ip_head_data[3] <= IP_DATA_LEN[7:0];
                    //标识（16bit）：同一个网络段中的数据包计数器，初始值可为随机数。
                    ip_head_data[4] <= sign_num[15:8];
                    ip_head_data[5] <= sign_num[7:0];
                    /*
                    标志（3bit）：最高位无效为 0，只有低两位有效；第二位表示是否分片，1 表示不能分片，0 表示可以分片；最低位表示是否是最后一个分片数据。
                    片偏移（13bit）：分片的偏移量，初始值为 0，表示和第一片数据的偏移量，以 8 个字节为单位。
                    */
                    ip_head_data[6] <= 8'h00;
                    ip_head_data[7] <= 8'h00;
                    //生存时间（8bit）：记录该数据包中经过路由的次数，每经过一次路由，该值减一，当该值减为 0 时，则这一个数据包会被丢弃。
                    ip_head_data[8] <= 8'h80;
                    //协议（8bit）：TCP 协议：8'd6；UDP 协议：8'd17;ICMP 协议：8'd2;
                    ip_head_data[9] <= 8'h11;
                    //首部校验和（16bit）：发送端需要提供 IP 首部的校验。
                    ip_head_data[10] <= 8'h00;
                    ip_head_data[11] <= 8'h00;
                    //源 IP 地址：发送端的 IP 地址。
                    ip_head_data[12] <= BOARD_IP[31:24];
                    ip_head_data[13] <= BOARD_IP[23:16];
                    ip_head_data[14] <= BOARD_IP[15:8];
                    ip_head_data[15] <= BOARD_IP[7:0];
                    //目的 IP 地址：接收端的 IP 地址。
                    ip_head_data[16] <= pc_ip[31:24];
                    ip_head_data[17] <= pc_ip[23:16];
                    ip_head_data[18] <= pc_ip[15:8];
                    ip_head_data[19] <= pc_ip[7:0];

                    //---udp首部---//
                    //源端口号（16bit）
                    ip_head_data[20] <= 8'h80;
                    ip_head_data[21] <= 8'h00;
                    //目的端口号（16bit）
                    ip_head_data[22] <= 8'h80;
                    ip_head_data[23] <= 8'h00;
                    //udp长度（16bit）
                    ip_head_data[24] <= num[15:8];
                    ip_head_data[25] <= num[7:0];
                    //udp首部校验和（16bit）
                    ip_head_data[26] <= 8'h00;
                    ip_head_data[27] <= 8'h00;
                end
                CHECK_SUM : begin
                    udp_gmii_txd <= 0;
                    if(cnt_byte == 3)begin
                        ip_head_data[10] <= ~ check_sum_data[15:8];
                        ip_head_data[11] <= ~ check_sum_data[7:0];
                    end
                end
                PRE_DATA  : begin
                    if(cnt_byte < 7)
                        udp_gmii_txd <= 8'h55;
                    else
                        udp_gmii_txd <= 8'hd5;
                end
                ETH_HEAD  : begin
                    udp_gmii_txd <= eth_head_data[cnt_byte];
                end
                IP_HEAD   : begin
                    udp_gmii_txd <= ip_head_data[cnt_byte];
                end
                UDP_DATA  : begin
                    udp_gmii_txd <= udp_tx_data;
                end
                CRC       : begin
                    if(cnt_byte == 0)
                        udp_gmii_txd <= {~crc_next[0],~crc_next[1],~crc_next[2],~crc_next[3],
                                         ~crc_next[4],~crc_next[5],~crc_next[6],~crc_next[7]};
                    else if(cnt_byte == 1)
                        udp_gmii_txd <= {~crc_data[16],~crc_data[17],~crc_data[18],~crc_data[19],
                                         ~crc_data[20],~crc_data[21],~crc_data[22],~crc_data[23]};
                    else if(cnt_byte == 2)
                        udp_gmii_txd <= {~crc_data[8],~crc_data[9],~crc_data[10],~crc_data[11],
                                         ~crc_data[12],~crc_data[13],~crc_data[14],~crc_data[15]};
                    else if(cnt_byte == 3)
                        udp_gmii_txd <= {~crc_data[0],~crc_data[1],~crc_data[2],~crc_data[3],
                                         ~crc_data[4],~crc_data[5],~crc_data[6],~crc_data[7]};
                end
            default: udp_gmii_txd <= 0;
        endcase
    end
end

//赋值标识号
always @(posedge gmii_txc ) begin
    if(!rst_n)
        sign_num <= 0;
    else if(udp_tx_done)
        sign_num <= sign_num + 1;
    else
        sign_num <= sign_num;
end

//赋值ip首部校验和
always @(posedge gmii_txc ) begin
    if(!rst_n)
        check_sum_data <= 0;
    else if(c_state == CHECK_SUM)begin
        if(cnt_byte == 0)   //做加法 ， 以两个字节为单位
            check_sum_data <= {ip_head_data[0],ip_head_data[1]} + {ip_head_data[2],ip_head_data[3]} + {ip_head_data[4],ip_head_data[5]} 
                             + {ip_head_data[6],ip_head_data[7]} + {ip_head_data[8],ip_head_data[9]} + {ip_head_data[10],ip_head_data[11]} 
                             + {ip_head_data[12],ip_head_data[13]} + {ip_head_data[14],ip_head_data[15]} + {ip_head_data[16],ip_head_data[17]}
                             + {ip_head_data[18],ip_head_data[19]};
        else if(cnt_byte == 1) //做溢出操作1
            check_sum_data <= check_sum_data[31:16] + check_sum_data[15:0];
        else if(cnt_byte == 2) //做溢出操作2
            check_sum_data <= check_sum_data[31:16] + check_sum_data[15:0];
        else
            check_sum_data <= check_sum_data;
    end
end

always @(posedge gmii_txc ) begin
    if(!rst_n)
        udp_gmii_tx_en <= 0;
    else if(c_state == IDLE || c_state == CHECK_SUM)
        udp_gmii_tx_en <= 0;
    else
        udp_gmii_tx_en <= 1;
end

always @(posedge gmii_txc ) begin
    if(!rst_n)begin
        udp_tx_done <= 0;
        crc_clr     <= 0;
    end
    else if(c_state == CRC && cnt_byte == 3)begin
        udp_tx_done <= 1;
        crc_clr     <= 1;
    end
    else begin
        udp_tx_done <= 0;
        crc_clr     <= 0;
    end
end

always @(posedge gmii_txc ) begin
    if(!rst_n)
        crc_en <= 0;
    else if(c_state == ETH_HEAD || c_state == IP_HEAD || c_state == UDP_DATA)
        crc_en <= 1;
    else
        crc_en <= 0;
end
    ila_udp u_ila_udp_tx (
	.clk(gmii_txc), // input wire clk

	.probe0(udp_tx_data), // input wire [7:0]  probe0  
	.probe1(udp_gmii_txd), // input wire [7:0]  probe1 
	.probe2(udp_tx_start  ), // input wire [0:0]  probe2 
	.probe3(udp_gmii_tx_en   ), // input wire [0:0]  probe3 
	.probe4(udp_tx_done   ), // input wire [0:0]  probe4 
	.probe5(udp_tx_data_en) // input wire [0:0]  probe5
);
endmodule