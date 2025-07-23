module udp_rx (
    (* KEEP = "TRUE" *) input   wire            gmii_rxc        ,   //时钟
    (* KEEP = "TRUE" *) input   wire            rst_n           ,   //复位
    (* KEEP = "TRUE" *) input   wire            gmii_rx_en      ,   //接收数据有效
    (* KEEP = "TRUE" *) input   wire    [7:0]   gmii_rxd        ,   //接收数据
    (* KEEP = "TRUE" *) input   wire    [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
    (* KEEP = "TRUE" *) input   wire    [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址
    (* KEEP = "TRUE" *) output  reg     [7:0]   udp_rx_data     ,   //解析后的数据
    (* KEEP = "TRUE" *) output  reg             udp_rx_data_en  ,   //数据有效
    (* KEEP = "TRUE" *) output  reg             udp_rx_done         //接收完成信号
);
    
parameter BOARD_MAC = 48'h00_11_22_33_44_55     ;   //FPGA的MAC地址
parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd5} ;   //FPGA的IP地址

//-----状态编码------//
localparam IDLE         = 7'b000_0001;  //空闲
localparam PRE_DATA     = 7'b000_0010;  //前导码
localparam ETH_HEAD     = 7'b000_0100;  //以太网帧头
localparam IP_HEAD      = 7'b000_1000;  //ip首部
localparam UDP_HEAD     = 7'b001_0000;  //udp首部
localparam UDP_DATA     = 7'b010_0000;  //udp数据
localparam UDP_END      = 7'b100_0000;  //结束

reg [6:0] c_state,n_state;


//------中间寄存器-------//
reg         error                   ;
reg [10:0]  cnt_byte                ;    //字节计数器寄存器
reg [15:0]  eth_type                ;    //长度/类型  IP协议：0800
reg [15:0]  ip_data_len             ;    //ip数据包总长度
reg [47:0]  des_mac                 ;    //arp_rx解析后的目的mac地址
reg [31:0]  des_ip                  ;    //arp_rx解析后的目的ip地址
reg [47:0]  src_mac                 ;    //arp_rx解析后的源mac地址
reg [31:0]  src_ip                  ;    //arp_rx解析后的源ip地址
reg [7:0 ]  ip_type                 ;    //协议（8bit）：TCP 协议：8’d6；UDP 协议：8’d17;ICMP 协议：8’d2; 

//------三段式状态机 一   将次态赋值给现态--------//
always @(posedge gmii_rxc ) begin
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
                    if(gmii_rx_en && gmii_rxd == 8'h55)
                        n_state = PRE_DATA;
                    else
                        n_state = IDLE;
                end
                PRE_DATA  : begin
                    if(error)
                        n_state = UDP_END;
                    else if(cnt_byte == 6 && gmii_rxd == 8'hd5)
                        n_state = ETH_HEAD;
                    else
                        n_state = PRE_DATA;
                end
                ETH_HEAD  : begin
                    if(error)
                        n_state = UDP_END;
                    else if(cnt_byte == 13)begin
                        if(gmii_rxd == 8'h00 && eth_type[7:0] == 8'h08)
                            n_state = IP_HEAD;
                        else
                            n_state = UDP_END;
                    end
                    else
                        n_state = ETH_HEAD;
                end
                IP_HEAD   : begin
                    if(error)
                        n_state = UDP_END;
                    else if(cnt_byte == 19)begin
                        if(des_ip[23:0] == BOARD_IP[31:8] && gmii_rxd == BOARD_IP[7:0])
                            n_state = UDP_HEAD;
                        else
                            n_state = UDP_END;
                    end
                    else
                        n_state = IP_HEAD;
                end
                UDP_HEAD  : begin
                    if(cnt_byte == 7)
                        n_state = UDP_DATA;
                    else
                        n_state = UDP_HEAD;
                end
                UDP_DATA  : begin
                    if(cnt_byte == ip_data_len - 29)
                        n_state = UDP_END;
                    else
                        n_state = UDP_DATA;
                end
                UDP_END   : begin
                    if(gmii_rx_en == 0)
                        n_state = IDLE;
                    else
                        n_state = UDP_END;
                end
            default: n_state = IDLE;
        endcase
    end
end

//------三段式状态机 三   对中间变量及输出结果赋值--------//
//字节计数器寄存器赋值
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        cnt_byte <= 0;
    else begin
        case (c_state)
                PRE_DATA : begin
                    if(cnt_byte == 6)
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
                IP_HEAD  : begin
                    if(cnt_byte == 19)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                UDP_HEAD : begin
                    if(cnt_byte == 7)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
                UDP_DATA : begin
                    if(cnt_byte == ip_data_len - 29)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
            default: cnt_byte <= 0;
        endcase
    end
end

//对错误信号赋值
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        error <= 0;
    else begin
        case (c_state)
                PRE_DATA : begin
                    if(cnt_byte < 6 && gmii_rxd != 8'h55)
                        error <= 1;
                    else
                        error <= 0;
                end
                ETH_HEAD : begin
                    if(cnt_byte == 6 && des_mac != BOARD_MAC)
                        error <= 1;
                    else if(cnt_byte == 12 && src_mac != pc_mac)
                        error <= 1;
                    else
                        error <= 0;
                end
                IP_HEAD  : begin
                    if(cnt_byte == 10 && ip_type != 8'h11)
                        error <= 1;
                    else if(cnt_byte == 16 && src_ip != pc_ip)
                        error <= 1;
                    else
                        error <= 0;
                end
            default: error <= 0;
        endcase
    end
end

//解析接收类型
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        eth_type <= 0;
    else if(c_state == ETH_HEAD && cnt_byte > 11)
        eth_type <= {eth_type[7:0],gmii_rxd};
    else
        eth_type <= eth_type;
end

//解析ip数据包总长度
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        ip_data_len <= 0;
    else if(c_state == IP_HEAD && cnt_byte > 1 && cnt_byte < 4)
        ip_data_len <= {ip_data_len[7:0],gmii_rxd};
    else
        ip_data_len <= ip_data_len;
end

//解析目的mac地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        des_mac <= 0;
    else if(c_state == ETH_HEAD && cnt_byte < 6)
        des_mac <= {des_mac[39:0],gmii_rxd};
    else
        des_mac <= des_mac;
end

//解析目的ip地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        des_ip <= 0;
    else if(c_state == IP_HEAD && cnt_byte > 15 && cnt_byte < 20)
        des_ip <= {des_ip[23:0],gmii_rxd};
    else
        des_ip <= des_ip;
end

//解析原mac地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        src_mac <= 0;
    else if(c_state == ETH_HEAD && cnt_byte > 5 && cnt_byte < 12)
        src_mac <= {src_mac[39:0],gmii_rxd};
    else
        src_mac <= src_mac;
end

//解析原ip地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        src_ip <= 0;
    else if(c_state == IP_HEAD && cnt_byte > 11 && cnt_byte < 16)
        src_ip <= {src_ip[23:0],gmii_rxd};
    else
        src_ip <= src_ip;
end

//解析udp协议
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        ip_type <= 0;
    else if(c_state == IP_HEAD && cnt_byte > 8 && cnt_byte < 10)
        ip_type <= gmii_rxd;
    else
        ip_type <= ip_type;
end

//解析udp数据 + 数据使能
always @(posedge gmii_rxc ) begin
    if(!rst_n)begin
        udp_rx_data    <= 0; 
        udp_rx_data_en <= 0;
    end
    else if(c_state == UDP_DATA)begin
        udp_rx_data    <= gmii_rxd; 
        udp_rx_data_en <= 1;
    end
    else begin
        udp_rx_data    <= udp_rx_data; 
        udp_rx_data_en <= 0;
    end
end

//解析数据接收完成信号
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        udp_rx_done <= 0;
    else if(c_state == UDP_DATA && cnt_byte == ip_data_len - 29)
        udp_rx_done <= 1;
    else
        udp_rx_done <= 0;
end

ila_udp_rx u_ila_udp_rx (
	.clk(gmii_rxc), // input wire clk

	.probe0(gmii_rxd), // input wire [7:0]  probe0  
	.probe1(udp_rx_data), // input wire [7:0]  probe1 
	.probe2(gmii_rx_en ), // input wire [0:0]  probe2 
	.probe3(udp_rx_data_en), // input wire [0:0]  probe3 
	.probe4(udp_rx_done   ) // input wire [0:0]  probe4
);
endmodule