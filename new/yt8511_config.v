`timescale 1ns / 1ps
module yt8511_config(
    input       wire    clk_45      ,    //50mhz
    input       wire    rst_n       ,

    output      wire    mdio        ,
    output      reg     mdc
);

    // 内部信号
    wire            busy;
    wire [4:0]      phy_addr = 5'b00100;  // PHY 地址，根据实际连接设置

    reg             write_en;
    reg [4:0]       reg_addr;
    reg [15:0]      data;
    reg             config_done;
    reg [4:0]       config_step;
    reg             RST_N;
    reg [19:0]      reset_delay_cnt;
    reg [2:0]       div_cnt;


 // 10ms延迟复位逻辑（满足芯片RESET_N至少10ms低电平要求）
    always @(posedge clk_45 or negedge rst_n) begin
        if (!rst_n) begin
            reset_delay_cnt <= 19'd0;
            RST_N <= 1'b0; // 初始复位有效
        end 
        else if (reset_delay_cnt < 20'd599_999) begin // 50MHz*10ms=500,000周期
            reset_delay_cnt <= reset_delay_cnt + 1'b1;
            RST_N <= 1'b0; // 保持复位有效
        end 
        else 
            RST_N            <= 1'b1; // 延迟结束，释放复位
    end

    
    // 1. 分频生成mdc（50MHz → 10MHz，满足≤12.5MHz要求）
        always @(posedge clk_45 or negedge RST_N) begin
        if (!RST_N) begin
                div_cnt <= 3'd0;
                mdc     <= 0;
        end 
        else  if (div_cnt == 3'd4)  
            begin// 45MHz/5=9MHz
                    div_cnt <= 3'd0;
                    mdc     <= ~mdc;
            end
        else begin    
                    div_cnt <= div_cnt + 1'b1;
                    mdc     <= mdc;
            end
           
    end

    // 配置状态机
    always @(posedge mdc or negedge RST_N) begin
        if (!RST_N) begin
            config_step         <= 3'd0;
            write_en            <= 1'b0;
            config_done         <= 1'b0;
        end 
        else if (!config_done) begin
            case (config_step)
                5'd0: begin  // 
                    if (!busy) begin
                        reg_addr    <= 5'h1E;  // 扩展位寄存器设置 偏移地址
                        data        <= 16'h0027;  //控制睡眠模式偏移地址
                        write_en    <= 1'b1;
                        config_step <= 5'd1;
                    end
                end
                5'd1: begin  // 
                    if (!busy) begin
                        write_en    <= 1'b0;
                        config_step <= 5'd2;
                    end
                end
                5'd2: begin  // 配置LDS寄存器使能
                    if (!busy) begin
                        reg_addr    <= 5'h1F;   // 设置偏移地址的写入值
                        data        <= 16'h0000;  // 关闭睡眠模式
                        write_en    <= 1'b1;
                        config_step <= 5'd3;
                    end
                end
                5'd3: begin  // 
                    if (!busy) begin
                        write_en    <= 1'b0;
                        config_step <= 5'd4;
                    end
                end
                5'd4: begin  
                    if (!busy) begin    //配置LDS寄存器
                        reg_addr    <= 5'h1E;  // 扩展位寄存器设置 偏移地址
                        data        <= 16'h000A;  //偏移地址位16’h0100
                        write_en    <= 1'b1;
                        config_step <= 5'd5;
                    end
                end
                5'd5: begin  // 等
                    if (!busy) begin
                        write_en    <= 1'b0;
                        config_step <= 5'd6;
                    end
                end
                5'd6: begin  // 等  
                    if (!busy) begin
                        reg_addr    <= 5'h1F;  //设置成外部环回模式
                        data        <= 16'h10;
                        write_en    <= 1'b1;
                        config_step <= 5'd7;
                    end
                end
                5'd7: begin  // 等
                    if (!busy) begin
                        write_en    <= 1'b0;
                        config_step <= 5'd8;
                    end
                end
                5'd8: begin  // 等
                    if (!busy) begin
                        reg_addr    <= 5'h00;  //设置成100mhz
                        data        <= 16'h9210;
                        write_en    <= 1'b1;
                        config_step <= 5'd9;
                    end
                end
                5'd9: begin  // 等
                    if (!busy) begin
                        write_en    <= 1'b0;
                        config_done <= 1'b1;
                    end
                end
            endcase
        end
    end

      // MDIO 写模块实例化
    mdio_writer mdio_writer_u(
        .RST_N          (RST_N),
        .phy_addr       (phy_addr),
        .data           (data),
        .reg_addr       (reg_addr),
        .write_en       (write_en),
        .mdio           (mdio),
        .mdc            (mdc),
        .busy           (busy)
    );
    
endmodule