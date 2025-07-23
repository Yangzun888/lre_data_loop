`timescale 1ns / 1ps
module udp_ctrl
#(      parameter       LEN = 113)
(
        input           gmii_clk,
        input           clk,
        input           rst_n ,
        input   [903:0] data_frame_packer_out_up,
        input           udp_tx_data_en,      //udp在data发送数据状态 发送使能
        input           data_valid,  
        input   wire    arp_done,

        output          udp_tx_start,        //udp发送开始信号    
        output  [15:0]  ip_data_len,
        output  [7:0]   tx_data           //发送的8位数据

    );


        wire            wr_rst_busy;
        wire            rd_rst_busy;
        wire   [903:0]  data_frame_packer_out_up_fifo;
 
        wire            wr_en;
        wire            rd_en;
        wire            empty;
        wire            full;

        assign          ip_data_len  = LEN + 28;     // 输出IP数据长度
        assign          rd_en        = udp_tx_data_en & !rd_rst_busy & !empty;
        assign          wr_en        = data_valid & !wr_rst_busy ; 
        assign          udp_tx_start = data_valid & arp_done    ;   //本地一帧打包完成并且arp接收完成 开始发送
       
    fifo_generator_0 fifo_generator_0_u (
        .rst(~rst_n),                    // input wire rst
        .wr_clk(clk),                   // input wire wr_clk
        .rd_clk(gmii_clk),              // input wire rd_clk
        .din(data_frame_packer_out_up),                  // input wire [903 : 0] din
        .wr_en(wr_en),                  // input wire wr_en
        .rd_en(rd_en),                  // input wire rd_en
        .dout(data_frame_packer_out_up_fifo),                // output wire [903 : 0] dout
        .full(full),                    // output wire full
        .empty(empty),                  // output wire empty
        .wr_rst_busy(wr_rst_busy),      // output wire wr_rst_busy
        .rd_rst_busy(rd_rst_busy)       // output wire rd_rst_busy
);

    ram_904_to_8 ram_904_to_8_u(
    .clk         (gmii_clk   )   ,            // 时钟
    .rst_n       (rst_n      )   ,          // 复位
    .load        (wr_en      )   ,           // 加载数据
    .din         (data_frame_packer_out_up_fifo  )   ,            // 904 位输入
    .read        (rd_en      )   ,           // 读取使能 
    .dout        (tx_data    )              // 8 位输出

);
endmodule
