module key_flag #(
    parameter delay = 100_000_0,
    parameter M     = 0
)(
    (* KEEP = "TRUE" *)input   wire    clk     ,
   (* KEEP = "TRUE" *) input   wire    rst_n   ,
   (* KEEP = "TRUE" *) input   wire    rest_n  ,
   (* KEEP = "TRUE" *) input   wire    locked  ,
    (* KEEP = "TRUE" *)input   wire    clk_45  ,
   (* KEEP = "TRUE" *) input   wire    clk_out ,
    input   wire    key     ,
    output  wire    key_flag
);

reg [31:0] cnt;

always @(posedge clk ) begin
    if(!rst_n)
        cnt <= 0;
    else if(key == M)begin
        if(cnt == delay - 1)
            cnt <= cnt ;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;
end

assign key_flag = (cnt == delay - 2) ? 1 : 0;

   
endmodule