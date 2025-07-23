`timescale 1ns / 1ps
module lfsr_adc24#(
    parameter FREQ  = 2     // 2KHz采样频率
)(
    input               clk,       // 16.384 Mhz
    input               rst_n,
    input               adc_en,    // ADC使能信号   

    output              trigger,   // 触发信号
    output  [31:0]      adc_0,
    output  [31:0]      adc_1,
    output  [31:0]      adc_2,
    output  [31:0]      adc_3,
    output  [31:0]      adc_4,
    output  [31:0]      adc_5,
    output  [31:0]      adc_6,
    output  [31:0]      adc_7,
    output  [31:0]      adc_8,
    output  [31:0]      adc_9,
    output  [31:0]      adc_10,
    output  [31:0]      adc_11,
    output  [31:0]      adc_12,
    output  [31:0]      adc_13,
    output  [31:0]      adc_14,
    output  [31:0]      adc_15,
    output  [31:0]      adc_16,
    output  [31:0]      adc_17,
    output  [31:0]      adc_18,
    output  [31:0]      adc_19,
    output  [31:0]      adc_20,
    output  [31:0]      adc_21,
    output  [31:0]      adc_22,
    output  [31:0]      adc_23   // 24个ADC数据输出                         
    
    );
    
    localparam CONT_MAX = 16384/FREQ - 1; // 计数器最大值，8192 = 16384khz/2khz

    integer j;
    genvar  i;

    reg [23:0]  lfsr_reg_[0:23];   //随机序列寄存器     
    reg [13:0]  freq_count;         //最大计数8192 = 16384khz/2khz 用于计数

    wire feedback_[0:23];
    
    //反馈信号生成
    assign   trigger = (freq_count == CONT_MAX );      // 触发信号在每8192个时钟周期产生一次 

     //输出数据
    assign adc_0  = {8'd1,  lfsr_reg_[0]};
    assign adc_1  = {8'd2,  lfsr_reg_[1]};   
    assign adc_2  = {8'd3,  lfsr_reg_[2]};
    assign adc_3  = {8'd4,  lfsr_reg_[3]};
    assign adc_4  = {8'd5,  lfsr_reg_[4]};
    assign adc_5  = {8'd6,  lfsr_reg_[5]};
    assign adc_6  = {8'd7,  lfsr_reg_[6]};
    assign adc_7  = {8'd8,  lfsr_reg_[7]};
    assign adc_8  = {8'd9,  lfsr_reg_[8]};
    assign adc_9  = {8'd10, lfsr_reg_[9]};
    assign adc_10 = {8'd11, lfsr_reg_[10]};
    assign adc_11 = {8'd12, lfsr_reg_[11]};
    assign adc_12 = {8'd13, lfsr_reg_[12]};
    assign adc_13 = {8'd14, lfsr_reg_[13]};
    assign adc_14 = {8'd15, lfsr_reg_[14]};
    assign adc_15 = {8'd16, lfsr_reg_[15]};
    assign adc_16 = {8'd17, lfsr_reg_[16]};
    assign adc_17 = {8'd18, lfsr_reg_[17]};
    assign adc_18 = {8'd19, lfsr_reg_[18]};
    assign adc_19 = {8'd20, lfsr_reg_[19]};
    assign adc_20 = {8'd21, lfsr_reg_[20]};
    assign adc_21 = {8'd22, lfsr_reg_[21]};
    assign adc_22 = {8'd23, lfsr_reg_[22]};
    assign adc_23 = {8'd24, lfsr_reg_[23]};

  generate
        for (i = 0;i < 24;i = i + 1) begin : lfsr_gen
            assign feedback_[i] = lfsr_reg_[i][23] ^ lfsr_reg_[i][22] ^ lfsr_reg_[i][21] ^ lfsr_reg_[i][16];
        end
    endgenerate

    //频率计数器
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            freq_count <= 14'd0;
        else  if( freq_count == CONT_MAX)
            freq_count <= 14'd0;
        else  if(adc_en) //当ADC使能时计数 
            freq_count <= freq_count + 1;
    end 

    //随机序列赋值
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin    
            for (j=0; j < 24; j = j+1)   begin//初始化时赋值种子
                lfsr_reg_[j]  <= 24'h5A5A50 + j;
            end
        end
        else if( trigger && (freq_count == CONT_MAX)) begin
            for (j=0; j < 24; j = j+1) begin //每8192个时钟周期更新一次随机序列
                lfsr_reg_[j]  <= {lfsr_reg_[j][22:0], feedback_[j]};
            end
        end 
    end
   
   
endmodule
