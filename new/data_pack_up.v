`timescale 1ns / 1ps
module data_pack_up(                    
    (* KEEP = "TRUE" *)input                clk,                        // 16.384 MHz
    (* KEEP = "TRUE" *)input                rst_n, 
    // input             adc_clk,                    // ADC时钟信号
    // input             adc_rst_n,                  // ADC复位信号
    input   [903:0]      data_frame_packer_in,       // 主机输入的数据帧
    input                packer_up_ask,              // 上游打包帧接受完成信号
    (* KEEP = "TRUE" *)input                data_up_valid ,             // 以太网接受数据完成信号

    output               ready_up_in,                // 以太网数据帧打包器准备接收信号  (idel时准备接收)
    (* KEEP = "TRUE" *)output  reg          data_up_done,              // 数据帧打包器数据有效信号  (打包完成进行上传)
    (* KEEP = "TRUE" *)output  [903:0]      data_frame_packer_out_up,   // 本地向上游主机发送的数据帧
    output               data_down_en              // 下游数字包转发使能信号

    //output  [15:0]      adc_sample_rate            //ADC采样率输出   （连接ADC端）   
    //output  [7:0]       adc_gain_value,            //ADC增益值输出   （连接ADC端）
    //output reg          data_frame_packer_ready,   //数据帧打包完成标志
    //output reg          data_frame_packer_error,   //数据帧打包错误
    //output reg          data_frame_packer_done     //数据帧打包完成信号                          

    );
    
    //状态定义
    parameter            IDEL       =  7'b000_0001;  // 空闲状态 根据主机发送帧前[7:0]位判断帧类型
    parameter            SYNC_STAT  =  7'b000_0010;  // 同步状态帧
    parameter            PACK_NUM   =  7'b000_0100;  // 包号设置帧  
    parameter            SAMP_DATA  =  7'b000_1000;  // 采集数据帧 
    parameter            ERROR      =  7'b001_0000;  // 错误状态
    parameter            DONE       =  7'b010_0000;  // 完成状态
    parameter            DOWN_OUT   =  7'b100_0000;  // 直接转发状态 (转发至下级数字包)

    wire                    trigger          ;   // 触发信号
    wire   [31:0]           adc_data[0:23]   ;   // 24个ADC数据输出 
    wire                    adc_down         ;   // adc 一次采集结束信号

    // 输入24个ADC数据
    wire   [31:0]           adc_0;
    wire   [31:0]           adc_1;
    wire   [31:0]           adc_2;
    wire   [31:0]           adc_3;
    wire   [31:0]           adc_4;
    wire   [31:0]           adc_5;
    wire   [31:0]           adc_6;
    wire   [31:0]           adc_7;
    wire   [31:0]           adc_8;
    wire   [31:0]           adc_9;
    wire   [31:0]           adc_10;
    wire   [31:0]           adc_11;
    wire   [31:0]           adc_12;
    wire   [31:0]           adc_13;
    wire   [31:0]           adc_14;
    wire   [31:0]           adc_15;
    wire   [31:0]           adc_16;
    wire   [31:0]           adc_17;
    wire   [31:0]           adc_18;
    wire   [31:0]           adc_19;
    wire   [31:0]           adc_20;
    wire   [31:0]           adc_21;
    wire   [31:0]           adc_22;
    wire   [31:0]           adc_23;                     // 24个ADC数据输入 
    (* KEEP = "TRUE" *)wire                    adc_en;                     //ADC采集使能信号,当处于采集数据状态且 frame_num<= 2000 时，ADC采集使能

    //帧类型  8'h01 ： 同步状态帧 ;  8'h02 ： 包号设置帧; 8'h03： 采集数据帧 ; 1字节
    wire  [7:0]           frame_type;     
    //包号  2字节
    reg  [15:0]          packed_num;  //
    //帧编号  3字节
    reg  [23:0]          frame_num;   //trigger信号触发时，帧编号加1
    //时间戳  2字节
    reg  [15:0]          timestamp;
    //增益值  1字节
    reg  [7:0]           gain_value;
    //采样率  1字节
    reg  [7:0]           sample_rate;   
    // ASK校验  2字节
    reg  [15:0]          ask_check;     // 高8位为 同步校验，低8位为数据包校验 ; 有效则为8'h01;无效则为8'h00
    //数字帧发送完成  一字节
    wire  [7:0]          frame_done;     //当帧编号为2000时，表示一秒的数据帧发送完成  1为完成，0为未完成
    //数据包  24个ADC数据  72字节
    reg  [31:0]          adc_data_pack[0:23]; // 24个ADC数据打包 (本地设置)
    //拓展位   3字节
    reg  [31:0]          ext_bits; 

    reg  [903:0]         data_frame_packer_out_up_reg ;      // 输出数据帧打包寄存器

    //  //数据帧打包输入
    //  reg  [31:0]          data_frame_packer_in[0:23]; // 主机输入的数据帧 (24个ADC数据输入)

    //状态机
    (* KEEP = "TRUE" *)reg [6:0]            state;      // 状态寄存器
    (* KEEP = "TRUE" *)reg [6:0]            next_state; // 下一个状态寄存器

    assign adc_data[0 ] =  adc_0 ; 
    assign adc_data[1 ] =  adc_1 ; 
    assign adc_data[2 ] =  adc_2 ; 
    assign adc_data[3 ] =  adc_3 ; 
    assign adc_data[4 ] =  adc_4 ; 
    assign adc_data[5 ] =  adc_5 ; 
    assign adc_data[6 ] =  adc_6 ; 
    assign adc_data[7 ] =  adc_7 ; 
    assign adc_data[8 ] =  adc_8 ; 
    assign adc_data[9 ] =  adc_9 ; 
    assign adc_data[10] =  adc_10; 
    assign adc_data[11] =  adc_11; 
    assign adc_data[12] =  adc_12; 
    assign adc_data[13] =  adc_13; 
    assign adc_data[14] =  adc_14; 
    assign adc_data[15] =  adc_15; 
    assign adc_data[16] =  adc_16; 
    assign adc_data[17] =  adc_17; 
    assign adc_data[18] =  adc_18; 
    assign adc_data[19] =  adc_19; 
    assign adc_data[20] =  adc_20; 
    assign adc_data[21] =  adc_21; 
    assign adc_data[22] =  adc_22;  
    assign adc_data[23] =  adc_23;
     
    assign frame_type   =  8'h03 ;
    assign data_down_en = (state == DOWN_OUT) ? 1'b1:1'b0; // 当处于DOWN_OUT状态时，直接转发输入数据帧
    assign ready_up_in  = (state == IDEL)     ? 1'b1:1'b0; // 当处于IDEL状态时，准备接受上游数据帧
    assign adc_en       = (state == SAMP_DATA && frame_num <= 24'd2000) ? 1'b1:1'b0; // 当处于采集数据状态且帧编号小于等于2000时，ADC采集使能
    assign adc_down     = (adc_en && trigger) ? 1'b1:1'b0; // 当处于采集数据状态且触发信号有效时，ADC采集结束信号
    //  输出数据帧打包
    assign data_frame_packer_out_up[903:0] = data_frame_packer_out_up_reg[903:0];

    //状态机   一 状态转移
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            state <= IDEL; // 复位时进入IDEL状态
        else
            state <= next_state; // 否则进入下一个状态
    end

    //状态机   二 状态转移逻辑
    always @(*) begin
        case(state)
            IDEL: begin //帧类型 
                if( frame_type == 8'h01) 
                    next_state = SYNC_STAT;   // 8'h01 ： 同步状态 ; 
                else if(frame_type == 8'h02)
                    next_state = PACK_NUM;  // 8'h02 ：   包号设置帧;
                else if(frame_type == 8'h03 )
                    next_state = SAMP_DATA;  // 8'h03：  采集数据帧
                else if(frame_type == 8'h04) 
                    next_state = DOWN_OUT; // 8'h04： 直接转发状态
                else
                    next_state = ERROR;      // 错误状态
            end
            SYNC_STAT: begin // 同步状态帧
                if(ask_check[15:8] == 8'h01 ) 
                    next_state = DONE; //  时间同步完成后 进入CRC校验状态
                else
                    next_state = ERROR; // 否则进入错误状态
            end
            PACK_NUM: begin // 包号设置帧 
                if(ask_check[7:0] == 8'h01) // 如果包号设置有效
                    next_state = DONE; 
                else
                    next_state = ERROR; // 否则进入错误状态
            end
            SAMP_DATA: begin 
                if(adc_down)// 一次采集结束
                    next_state = DONE; 
                else
                    next_state = SAMP_DATA; // 继续采集数据帧
            end 

            DONE: begin // 完成状态
                if(data_up_valid) // 如果上游接受完成
                    next_state = IDEL; // 进入IDEL状态，准备接收下一帧
                else
                    next_state = DONE;              
            end
            ERROR: begin // 错误状态
                next_state = IDEL; // 进入IDEL状态，等待下一帧
            end
            DOWN_OUT: begin // 下行发送
                next_state = IDEL; // 进入IDEL状态，等待下一帧
            end
            default: begin // 默认状态
                next_state = ERROR; // 进入错误状态
            end
        endcase
    end

    //状态机   三 状态逻辑
    //  帧类型转换                                     
   //always @(posedge clk or negedge rst_n) begin
   //    if(~rst_n)
   //        frame_type <= 8'h00; // 复位时帧类型为0 
   //    else if(state == IDEL) begin
   //        if(data_frame_packer_in[7:0] == 8'h01 )         //主机启动 同步状态帧
   //               frame_type <= 8'h01; // 同步状态帧
   //        else if(data_frame_packer_in[23:8] != 16'h0001)
   //               frame_type <= 8'h04; // 非本地帧，直接转发      
   //        else if(data_frame_packer_in[7:0] == 8'h02 && data_frame_packer_in[103:88] == 16'h0100
   //                &&  data_frame_packer_in[23:8] == 16'h0001)
   //               frame_type <= 8'h02; // 包号设置帧
   //        else if(data_frame_packer_in[7:0] == 8'h03 && data_frame_packer_in[103:88] == 16'h0101)
   //               frame_type <= 8'h03; // 采集数据帧
   //    end
   //    else        
   //               frame_type <= frame_type; // 保持当前帧类型
   //end

    //  包号设置                                   
    always @(posedge clk or negedge rst_n) begin    
        if(~rst_n)
            packed_num <= 16'd0; // 复位时包号为0  
        else if(state == PACK_NUM) begin
            packed_num <= data_frame_packer_in[23:8]; // 包号设置
        end
    end

    //  帧编号
    always @(posedge clk or negedge rst_n) begin       
        if(~rst_n)
            frame_num <= 24'd0; 
        else if(frame_type == 8'h03 && state == DONE && frame_num == 24'd2000 && data_up_valid) // 如果是采集数据帧且帧编号为2000
            frame_num <= 24'd0; // 则帧编号归零，准备下一秒的数据采集
        else if(state == SAMP_DATA && trigger ) 
            frame_num <= frame_num + 1; // 触发信号有效时，
        else 
            frame_num <= frame_num; // 其余状态保持帧编号不变
    end   

    //  时间戳  2字节
    always @(posedge clk or negedge rst_n) begin   
        if(~rst_n)      
            timestamp <={8'h00,8'h00}; // 复位时时间戳为0
        else if(state == SYNC_STAT) begin
            timestamp <= data_frame_packer_in[63:48]; // 时间戳设置
        end
    end

    //  增益值                          
    always @(posedge clk or negedge rst_n) begin         
        if(~rst_n)
            gain_value <=  8'h00; // 复位时增益值为0
        else if(state == PACK_NUM) begin
            gain_value <= data_frame_packer_in[71:64]; // 增益值设置
        end
    end

    //  采样率
    always @(posedge clk or negedge rst_n) begin    
        if(~rst_n)
            sample_rate <=  8'h00; // 复位时采样率为0
        else if(state == PACK_NUM) begin
            sample_rate <= data_frame_packer_in[79:72]; // 采样率设置
        end
    end

    //  ASK校验  2字节
    always @(posedge clk or negedge rst_n) begin   
        if(~rst_n)      
            ask_check <= {8'h00,8'h00}; // 复位时ASK校验为0
        else if(state == SYNC_STAT) 
            ask_check <= {8'h01,data_frame_packer_in[87:80]}; // 高八位01  ASK同步校验有效
        else if(state == PACK_NUM ) 
            ask_check <= {data_frame_packer_in[95:88],8'h01}; // 低八位01  ASK包号设置校验有效
    end

    // 数字帧发送完成1s的数据帧  一字节
    
   assign   frame_done= (frame_num == 24'd2000)? 8'b1:8'b0;

    integer j;

    //  数据包  24个ADC数据  
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for (j = 0; j < 24; j = j + 1) begin
                adc_data_pack[j] <= 32'h00; // 复位时ADC数据包为0
            end
        end
        else if(state == IDEL && state  == PACK_NUM && state == SYNC_STAT) begin
            for (j = 0; j < 24; j = j + 1) begin
                adc_data_pack[j] <= 32'h00; 
            end
        end
        else if(state == SAMP_DATA && trigger) begin
            for (j = 0; j < 24; j = j + 1) begin
                adc_data_pack[j] <= adc_data[j]; // 将ADC数据打包到adc_data_pack中
            end
        end
        else begin
            for (j = 0; j < 24; j = j + 1) begin
                adc_data_pack[j] <= adc_data_pack[j]; // 当数据没有处于采集状态的时候，填充28.5控制位
            end
        end
    end

    
   

    //  输出数据帧打包寄存器   
    always @(posedge clk ) begin
        if(state != DONE ) begin
            data_frame_packer_out_up_reg [903:0] <= {113{8'h55}}; 
            data_up_done <= 1'b0;
        end
        else if(state == DONE) begin
            data_frame_packer_out_up_reg[7:0]          <=  frame_type       ;  //03 
            data_frame_packer_out_up_reg[23:8]         <=  packed_num       ;  //00 01
            data_frame_packer_out_up_reg[47:24]        <=  frame_num        ;  //000 7d0
            data_frame_packer_out_up_reg[63:48]        <=  timestamp        ;  //00 01
            data_frame_packer_out_up_reg[71:64]        <=  gain_value       ;  
            data_frame_packer_out_up_reg[79:72]        <=  sample_rate      ; 
            data_frame_packer_out_up_reg[95:80]        <=  ask_check        ;
            data_frame_packer_out_up_reg[103:96]       <=  frame_done       ;  
            
            data_frame_packer_out_up_reg[135:104]      <=  adc_data_pack[23]; 
            data_frame_packer_out_up_reg[167:136]      <=  adc_data_pack[22];
            data_frame_packer_out_up_reg[199:168]      <=  adc_data_pack[21];
            data_frame_packer_out_up_reg[231:200]      <=  adc_data_pack[20];
            data_frame_packer_out_up_reg[263:232]      <=  adc_data_pack[19];
            data_frame_packer_out_up_reg[295:264]      <=  adc_data_pack[18];
            data_frame_packer_out_up_reg[327:296]      <=  adc_data_pack[17];
            data_frame_packer_out_up_reg[359:328]      <=  adc_data_pack[16];
            data_frame_packer_out_up_reg[391:360]      <=  adc_data_pack[15];
            data_frame_packer_out_up_reg[423:392]      <=  adc_data_pack[14];
            data_frame_packer_out_up_reg[455:424]      <=  adc_data_pack[13];
            data_frame_packer_out_up_reg[487:456]      <=  adc_data_pack[12];
            data_frame_packer_out_up_reg[519:488]      <=  adc_data_pack[11];
            data_frame_packer_out_up_reg[551:520]      <=  adc_data_pack[10];
            data_frame_packer_out_up_reg[583:552]      <=  adc_data_pack[9] ;
            data_frame_packer_out_up_reg[615:584]      <=  adc_data_pack[8] ;
            data_frame_packer_out_up_reg[627:616]      <=  adc_data_pack[7] ;
            data_frame_packer_out_up_reg[679:628]      <=  adc_data_pack[6] ;
            data_frame_packer_out_up_reg[711:680]      <=  adc_data_pack[5] ;
            data_frame_packer_out_up_reg[743:712]      <=  adc_data_pack[4] ;
            data_frame_packer_out_up_reg[775:744]      <=  adc_data_pack[3] ;
            data_frame_packer_out_up_reg[807:776]      <=  adc_data_pack[2] ;
            data_frame_packer_out_up_reg[839:808]      <=  adc_data_pack[1] ;
            data_frame_packer_out_up_reg[871:840]      <=  adc_data_pack[0] ;
            data_frame_packer_out_up_reg[903:872]      <=  32'h00;      // 预留拓展位，暂时未使用                
                                         
            data_up_done <= 1'b1;                   
        end
        end            

ila_data_pack u_ila_data_pack (
	.clk(clk), // input wire clk
	.probe0(adc_en), // input wire [0:0]  probe0  
	.probe1(state), // input wire [903:0]  probe1 
	.probe2(data_up_valid), // input wire [0:0]  probe2 
	.probe3(data_up_done),// input wire [0:0]  probe3
    .probe4(frame_num) // input wire [0:0]  probe2 
);

    lfsr_adc24#(
            . FREQ     (2)    // 2KHz采样频率
        ) lfsr_adc24_u (
            .clk      (clk     )   ,       // 16.384 Mhz
            .rst_n    (rst_n   )   ,
            .adc_en   (adc_en  )   ,    // ADC使能信号   
            .trigger  (trigger )   ,   // 触发信号
            .adc_0    (adc_0   )   ,
            .adc_1    (adc_1   )   ,
            .adc_2    (adc_2   )   ,
            .adc_3    (adc_3   )   ,
            .adc_4    (adc_4   )   ,
            .adc_5    (adc_5   )   ,
            .adc_6    (adc_6   )   ,
            .adc_7    (adc_7   )   ,
            .adc_8    (adc_8   )   ,
            .adc_9    (adc_9   )   ,
            .adc_10   (adc_10  )   ,
            .adc_11   (adc_11  )   ,
            .adc_12   (adc_12  )   ,
            .adc_13   (adc_13  )   ,
            .adc_14   (adc_14  )   ,
            .adc_15   (adc_15  )   ,
            .adc_16   (adc_16  )   ,
            .adc_17   (adc_17  )   ,
            .adc_18   (adc_18  )   ,
            .adc_19   (adc_19  )   ,
            .adc_20   (adc_20  )   ,
            .adc_21   (adc_21  )   ,
            .adc_22   (adc_22  )   ,
            .adc_23   (adc_23  )           // 24个ADC数据输出                         
            );


endmodule


