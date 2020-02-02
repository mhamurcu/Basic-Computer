module ff(input reg  start,clk,clr,output reg out);
reg araeleman;
 always@(posedge clk)
begin
if(start == 1) araeleman <=1;
else araeleman <= 0;

end
 assign out = araeleman;
endmodule
	