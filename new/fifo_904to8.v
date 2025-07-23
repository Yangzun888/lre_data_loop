`timescale 1ns / 1ps
module ram_904_to_8(
    input  wire                 clk,            // 时钟
    input  wire                 rst_n,          // 复位
    input  wire                 load,           // 加载数据
    input  wire [903:0]         din,            // 904 位输入
    input  wire                 read,           // 读取使能
    output reg  [7:0]           dout           // 8 位输出
   
);

    reg [7:0] buffer0 [0:112];      // 缓冲区 0
    reg [7:0] buffer1 [0:112];      // 缓冲区 1
    reg       writing_buffer0;      // 写缓冲区 0 标志
    reg [6:0] read_addr;
    reg        buffer_sel  ; // 当前活动缓冲区

    //读操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_addr <= 7'd0;
        end
        else if (read  ) begin
               if(read_addr == 7'd112)
                    read_addr <= 7'd0;
            else     
                read_addr <= read_addr + 1;  // 自动递增地址
        end
    end


    // 写操作
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            writing_buffer0 <= 1'b1;
            buffer_sel      <= 1'b0;
        end
        else if (load) begin
            if (writing_buffer0) begin
                for (i = 0; i < 113; i = i + 1) begin
                    buffer0[i] <= din[(i*8)+:8];
                end
                writing_buffer0 <= 1'b0;
                buffer_sel      <= 1'b1; // 切换到 buffer1 读取
            end
            else begin
                for (i = 0; i < 113; i = i + 1) begin
                    buffer1[i] <= din[(i*8)+:8];
                end
                writing_buffer0 <= 1'b1;
                buffer_sel      <= 1'b0; // 切换到 buffer0 读取
            end
        end
    end

    // 读操作
    always @(posedge clk) begin
        if (read) begin
            dout <= buffer_sel ? buffer1[read_addr] : buffer0[read_addr];
        end
    end

endmodule

