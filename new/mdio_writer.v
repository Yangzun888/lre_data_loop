`timescale 1ns / 1ps
module mdio_writer(
    input wire        RST_N         ,    // 复位，低电平有效    rst_n 拉低后延迟10ms
    input wire [4:0]  phy_addr      ,    // PHY地址（0-7，）
    input wire [4:0]  reg_addr      ,    // 寄存器地址
    input wire [15:0] data          ,    // 待写入的数据
    input wire        write_en      ,    // 写使能（高电平触发）

    output wire       mdio          ,    // 双向数据信号
    input             mdc           ,    // 管理接口时钟（≤12.5MHz）
    output reg        busy               // 忙信号（高电平表示操作中）
);

//

    // 2. 帧结构拼接（按顺序拼接所有字段）
    wire [63:0] frame;  // 总长度：32（前导）+2+2+5+5+2+16=64位
   
    assign    frame[63:32] = 32'hFFFFFFFF;                   // 前导码（32位1）
    assign    frame[31:30] = 2'b01;                          // 起始符
    assign    frame[29:28] = 2'b01;                          // 操作码（写）
    assign    frame[27:23] = phy_addr;                       // PHY地址
    assign    frame[22:18] = reg_addr;                       // 寄存器地址
    assign    frame[17:16] = 2'b10;                          // Turnaround
    assign    frame[15:0]  = data;                           // 数据
  

    // 3. 状态机控制发送流程
    localparam IDLE         = 3'b001;
    localparam SEND_FRAME   = 3'b010;
    localparam DONE         = 3'b100;

    reg [5:0] bit_cnt;  // 比特计数器（0-63）
    reg [2:0] state, n_state;
    reg       mdio_out;       // mdio输出缓冲（控制三态）

    always @(posedge mdc or negedge RST_N ) begin
        if(~RST_N)
            state <= IDLE;
        else    
            state <= n_state;
    end

    // 状态机逻辑
    always @(*) begin
        if (!RST_N) begin
            n_state       <= IDLE;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (write_en) 
                        n_state   <= SEND_FRAME;
                    else 
                        n_state   <= IDLE;
                end
                SEND_FRAME: begin
                    if (bit_cnt == 6'd0) 
                        n_state    <= DONE;
                    else
                        n_state    <= SEND_FRAME;
                end           
                DONE: 
                    n_state <= IDLE;
                default : n_state <= IDLE ;
            endcase
        end
    end

    always @(posedge mdc or negedge RST_N) begin
        if(~RST_N)
            bit_cnt <= 0;
        else begin
            case (state)
                IDLE : begin
                if(write_en)
                    bit_cnt <= 6'd63;  // 从最高位开始发送
                else    
                    bit_cnt <= 6'd0;
                end
                SEND_FRAME: begin
                if(bit_cnt != 0)
                    bit_cnt  <= bit_cnt - 1'b1;
                else
                    bit_cnt  <= bit_cnt;
                end
                default: bit_cnt  <= bit_cnt;
            endcase
        end
    end

    //
    always @(posedge mdc or negedge RST_N) begin
        if(~RST_N)
            busy   <= 1'b0;
        else if( (state == SEND_FRAME )||(state == IDLE && write_en ) )
            busy   <= 1'b1;
        else    
            busy   <= 1'b0;
    end
   
   always @(posedge mdc or negedge RST_N ) begin
        if(~RST_N)
            mdio_out    <= 1'b1;
        else if (state ==  SEND_FRAME )
            mdio_out    <= frame[bit_cnt];
        else    
            mdio_out    <= 1'b1;
   end

    // 4. 控制mdio三态（发送时输出，否则高阻）
    assign mdio = (state == SEND_FRAME) ? mdio_out : 1'bz;

    endmodule

