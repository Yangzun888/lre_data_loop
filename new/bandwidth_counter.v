`timescale 1ns / 1ps
module bandwidth_counter(
    input   wire                 clk,             // 12.5mhz
    input   wire                 rst_n,           // 复位
    input   wire                 data_valid,      // 数据有效信号
    input   wire [7:0]           data      ,      // 数据
    output  reg [31:0]           bandwidth               // 带宽值（Mbps）
);

    reg [31:0]           byte_count;              // 字节计数器
    reg [31:0]           cycle_count;             // 时钟周期计数器
    reg                  measuring;               // 测量状态
    
    // 1秒对应的时钟周期数
    parameter CYCLES_PER_SECOND = 32'd125_000_00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count  <= 32'b0;
            cycle_count <= 32'b0;
            bandwidth   <= 32'b0;
            measuring   <= 1'b0;
        end 
        else begin
            // 启动测量
            if (!measuring && data_valid) begin
                measuring   <= 1'b1;
                byte_count  <= 32'd1;  // 第一个有效字节
                cycle_count <= 32'd1;
            end 
            else if(measuring)begin
                if (cycle_count == CYCLES_PER_SECOND) begin

                    bandwidth   <= (byte_count * 8) / 32'd1_000_000;
                    // 重置计数器，继续测量
                    byte_count  <= 32'd0; 
                    cycle_count <= 32'd0;
                    measuring   <=1'b0;
            end
            else  if (data_valid) begin
                    byte_count  <= byte_count + 1;
                    cycle_count <= cycle_count + 1;
                end
                // 每1秒计算一次带宽
            end

                end
            end
      

endmodule

