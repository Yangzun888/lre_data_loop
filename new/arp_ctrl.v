`timescale 1ns / 1ps
module arp_ctrl(         //该模块由key开始和arp接受模块的状态值来确定输出的arp发送状态
	input	wire		gmii_txc		,
	input	wire		rst_n			,
	input	wire		arp_key_flag	,
	input	wire		arp_rx_done		,
	input	wire		arp_rx_type		,
	
	output	reg			arp_tx_start	,
	output	reg			arp_tx_type		,  //0 发送请求包   1发送应答包
	(* KEEP = "TRUE" *)output	reg			arp_done			
    );
	
always @(posedge gmii_txc)
	if(!rst_n)	
		arp_done <= 0;
	else if(arp_rx_done && arp_rx_type == 1)	//外部接受应答  arp结束  为了控制本地发送端的数据何时发送
		arp_done <= 1;						
	else 
		arp_done <= arp_done;
		
always @(posedge gmii_txc)
	if(!rst_n)begin
		arp_tx_start <= 0;
		arp_tx_type <= 0;
	end 
	else if(arp_key_flag)begin			// 请求 应答
		arp_tx_start <= 1;
		arp_tx_type <= 0;
	end 
	else if(arp_rx_done && arp_rx_type == 0)begin   //接收到的信号是请求包
		arp_tx_start <= 1;
		arp_tx_type <= 1;   				 //应答报文
	end 
	else begin
		arp_tx_start <= 0;
		arp_tx_type <= arp_tx_type;
	end 

	ila_crtl ila_arp_ctrl (
	.clk(gmii_txc), // input wire clk
	.probe0(arp_done) // input wire [0:0] probe0
);

endmodule
