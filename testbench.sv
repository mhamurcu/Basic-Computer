module testbench1();
reg clk;
wire y;
reg [15:0] memo[31:0];
reg [15:0]result;
reg E;
reg [15:0] expectedresult;
reg expected_E;
parameter string name="hw2Test.txt";
reg [2:0] seqcounter;
initial begin
clk = 1;
seqcounter <= -1;
end
always begin
#5 clk = ~clk;

end
always @(posedge clk)begin
//seqcounter <= seqcounter +1;
end
fetch #(.name(name)) DUT(.clk(clk), .E(E), .acdata(result),. seqcounter(seqcounter));






endmodule
