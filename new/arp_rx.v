module arp_rx (
   (* KEEP = "TRUE" *)input   wire            gmii_rxc        ,   //时钟50Mhz，由phy产生
   (* KEEP = "TRUE" *)input   wire            rst_n           ,   //复位，低电平有效
   (* KEEP = "TRUE" *)input   wire            gmii_rx_en      ,   //接收数据使能
   (* KEEP = "TRUE" *)input   wire    [7:0]   gmii_rxd        ,   //接收数据
   (* KEEP = "TRUE" *)output  reg     [47:0]  pc_mac          ,   //arp_rx解析后的pc的mac地址
   (* KEEP = "TRUE" *)output  reg     [31:0]  pc_ip           ,   //arp_rx解析后的pc的ip地址     
   (* KEEP = "TRUE" *)output  reg             arp_rx_done     ,   //arp解析数据完成信号
   (* KEEP = "TRUE" *)output  reg             arp_rx_type         //0 接收到的是请求包   1接收到的应答包   
);

parameter BOARD_MAC = 48'h00_11_22_33_44_55     ;   //FPGA的MAC地址
parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd5} ;   //FPGA的IP地址

localparam IDLE     = 5'b0_0001;    //空闲
localparam PRE_DATA = 5'b0_0010;    //前导码(7byte的8'h55)+帧起始界定符(1byte的8'hd5)
localparam ETH_HEAD = 5'b0_0100;    //以太网帧头(14byte)
localparam ARP_DATA = 5'b0_1000;    //arp数据(28byte有效+18byte填充)
localparam ARP_END  = 5'b1_0000;    //停止

(* KEEP = "TRUE" *)reg [4:0] c_state,n_state;

//---中间寄存器定义---
reg        error   ;
(* KEEP = "TRUE" *)reg [5:0]  cnt_byte; //字节计数器寄存器
reg [15:0] eth_type; //以太网帧头的长度/类型：ARP 0806
reg [47:0] des_mac ; //目的mac地址
reg [31:0] des_ip  ; //目的ip 地址
reg [15:0] op_data ; //op操作码 表示该数据包是 ARP 请求包，还是 ARP 应答包，1 表示请求包，2 表示应答包。

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
                IDLE     : begin
                    if(gmii_rx_en && gmii_rxd == 8'h55)
                        n_state = PRE_DATA;
                    else
                        n_state = IDLE;
                end
                PRE_DATA : begin
                    if(error)
                        n_state = ARP_END;
                    else if(cnt_byte == 6)begin
                        if(gmii_rxd == 8'hd5)
                            n_state = ETH_HEAD; 
                        else
                            n_state = ARP_END;
                    end
                    else
                        n_state = PRE_DATA;
                end
                ETH_HEAD : begin
                    if(error)
                        n_state = ARP_END;
                    else if(cnt_byte == 13)begin
                        if(eth_type[7:0] == 8'h08 && gmii_rxd == 7'h06)
                            n_state = ARP_DATA;
                        else
                            n_state = ARP_END;
                    end
                    else
                        n_state = ETH_HEAD;
                end
                ARP_DATA : begin
                    if(cnt_byte == 28)  //??????
                        n_state = ARP_END;
                    else
                        n_state = ARP_DATA;
                end
                ARP_END  : begin
                    if(gmii_rx_en == 0)
                        n_state = IDLE;
                    else
                        n_state = ARP_END;
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
                ARP_DATA : begin
                    if(cnt_byte == 28)
                        cnt_byte <= 0;
                    else
                        cnt_byte <= cnt_byte + 1;
                end
            default: cnt_byte <= 0;
        endcase
    end
end

//错误信号赋值
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
                    if(cnt_byte == 6 && (des_mac != BOARD_MAC && des_mac != 48'hff_ff_ff_ff_ff_ff)) //判断目的mac地址是不是自己的或者是不是广播
                        error <= 1;
                    else
                        error <= 0;
                end
            default: error <= 0;
        endcase
    end
end

//解析长度/类型
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        eth_type <= 0;
    else if(c_state == ETH_HEAD && cnt_byte > 11)
        eth_type <= {eth_type[7:0],gmii_rxd};
    else
        eth_type <= eth_type;
end

//解析des_mac 目的mac地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        des_mac <= 0;
    else if(c_state == ETH_HEAD && cnt_byte < 6)
        des_mac <= {des_mac[39:0],gmii_rxd};
    else
        des_mac <= des_mac;
end

//解析des_ip 目的ip地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        des_ip <= 0;
    else if(c_state == ARP_DATA && cnt_byte > 23)
        des_ip <= {des_ip[23:0],gmii_rxd};
    else
        des_ip <= des_ip;
end

//解析op操作码
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        op_data <= 0;
    else if(c_state == ARP_DATA && cnt_byte > 5 && cnt_byte < 8)
        op_data <= {op_data[7:0],gmii_rxd};
    else
        op_data <= op_data;
end

//解析pc_mac 源mac地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        pc_mac <= 0;
    else if(c_state == ARP_DATA && cnt_byte > 7 && cnt_byte < 14)
        pc_mac <= {pc_mac[39:0],gmii_rxd};
    else
        pc_mac <= pc_mac;
end

//解析pc_ip 源ip地址
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        pc_ip <= 0;
    else if(c_state == ARP_DATA && cnt_byte > 13 && cnt_byte < 18)
        pc_ip <= {pc_ip[23:0],gmii_rxd};
    else
        pc_ip <= pc_ip;
end

//赋值arp_rx_type
always @(posedge gmii_rxc ) begin
    if(!rst_n)
        arp_rx_type <= 0;
    else if(op_data == 1)
        arp_rx_type <= 0;
    else if(op_data == 2)
        arp_rx_type <= 1;
    else
        arp_rx_type <= arp_rx_type;
end

//赋值arp_rx_done
always @(posedge gmii_rxc ) begin
    if(!rst_n)  
        arp_rx_done <= 0;
    else if(c_state == ARP_DATA && cnt_byte == 28 && des_ip == BOARD_IP)
        arp_rx_done <= 1;
    else
        arp_rx_done <= 0;
end

 
endmodule