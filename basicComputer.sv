typedef struct packed
{
 reg [15:0] outputdata;

}register;




module fetch #(parameter name) (input reg [7:0]INPR,input clk,  input reg FGI,FGO, input reg IEN,output reg [15:0] acdata, 
        output reg [7:0] OUTR, output reg E, output reg [2:0] seqcounter
);
reg I;
reg IRQ;
reg R;


reg fgiinp, fgiout;
reg FGIequal;

reg [7:0] d_out;
reg S;
reg start;
reg set;
reg setien;
reg setfg0;
reg [15:0]mem[31:0];
register pc;
register ar;
register ir;
register dr;
register tr;
decoder decode(.code(ir.outputdata[14:12]), .out(d_out));
ff ff(.start(set),.clk(clk),.out(FGI));
ff IENff(.start(setien), .clk(clk), .out(IEN));
ff FG0ff(.start(setfg0), .clk(clk), .out(FGO));
initial begin // sequence counter and clock initialization
    seqcounter <= -1;
    IRQ <= 0;
    R <= 0;
    S<=1;
   $readmemh(name, mem,0,255);
    pc.outputdata <= 0;
ir.outputdata[14:12] = 0;
start <= 1;
dr.outputdata <= 1;
end

always @(posedge clk ) begin // seq counter definition
  seqcounter = seqcounter + 1;
end


always @(posedge clk ) begin
if(S==1)begin
if((seqcounter >= 3)& IEN & (FGI | FGO)) 
IRQ<= 1;

if (~IRQ) begin
  	if(seqcounter == 0 & R==0) begin
   	    ar.outputdata <= pc.outputdata;
   	    end
	 if (seqcounter == 1 & R== 0)begin
        pc.outputdata <= pc.outputdata + 1;
	    ir.outputdata <= mem[ar.outputdata];

        //adress registerimin point etti?i datay? okuyup  instruction registera atma yeri. (done)
        end
     if (seqcounter == 2 & R == 0)begin
        I <= ir.outputdata[15];
        ar.outputdata <= ir.outputdata[11:0];
        
        //decoder <= ir.outputdata[14:12];(done)
                end
    if(d_out[7]==1) begin //register or io (done)
        if(I == 1) begin // 
            if(seqcounter == 3) begin
            seqcounter <= -1;
		
                case(ir.outputdata[15:0])
                    16'hF800: begin
                         acdata <= INPR;
                         set <= 1;
                         end
                    16'hF400: begin
                    OUTR <= acdata [7:0];
                    setfg0<= 0;
                    end
                    16'hF200: if(FGI== 1) pc.outputdata <= pc.outputdata +1;
                    16'hF100:if(FGO== 1) pc.outputdata <= pc.outputdata +1  ;
                    16'hF080: setien <= 1;
                    16'hF040: setien <= 0;
			default:;
                        
                    
                endcase
                end //if seqcounter == 3ün endi
            end //I==1 in endi
        else begin //I == 0
            if(seqcounter == 3)begin
           seqcounter <=-1;
                //RR instruction execution(done)
                case(ir.outputdata[15:0])
                    16'h7800: acdata<=0;
                    16'h7400: E <= 0;
                    16'h7200: acdata <= ~acdata;
                    16'h7100: E <= ~E;
                    16'h7080: begin
				E<=acdata[0];		
				acdata <= {{E}, {acdata[15:1]}}; //shift right
				end
                    16'h7040 :begin
				 E<=acdata[15];				
				 acdata <= {{acdata[14:0]}, {E}}; //shift left
				 end
                    16'h7020: acdata <= acdata +1 ;
                    16'h7010: if(acdata[15] == 0) pc.outputdata <= pc.outputdata +1;
                    16'h7008: if(acdata[15] == 1) pc.outputdata <= pc.outputdata +1;
                    16'h7004: if(acdata == 0) pc.outputdata <= pc.outputdata +1;
                    16'h7002: if (E == 0) pc.outputdata <= pc.outputdata+1;
                    16'h7001: start<=0;
			default: ;
		endcase
                end //seqcounter ==3ün endi
            end //I==0 nuun endi
	    end	
        else begin //d_out7 ==0
        //if(d_out[7]==0) begin //D7 != 1, memory ref
            if(I == 1) begin
                if (seqcounter == 3) begin //indirect cycle
                    //addres registerdaki memoryi oku, ar a geri assign et(done)
                    ar.outputdata <= mem[ar.outputdata];
                    end
                end
               /* else begin //direct
                    //idle
                    end*/
                
               // if(seqcounter>=4) begin
                    //execute memory ref instruction
                    
                    case(d_out[7:0])
                        8'h01: begin
				                if(seqcounter == 4) dr.outputdata <= mem[ar.outputdata];
                            	if(seqcounter == 5) begin
                                    acdata <= acdata & dr.outputdata;
                                    seqcounter <=-1;
                                 end
				                end
		            	8'h02:begin
                                if(seqcounter == 4)dr.outputdata <= mem[ar.outputdata];
                                if(seqcounter == 5) begin
                                    acdata <= acdata + dr.outputdata;
                                    seqcounter <=-1;
                                    //E<= Cout;
                                    end
			    				    end
                        8'h04:begin
                                if(seqcounter == 4) dr.outputdata <= mem[ar.outputdata];
                                if(seqcounter == 5) begin
                                   acdata <= dr.outputdata;
                                    seqcounter <= -1;
                                    end
                                    end
                        8'h08:begin
                            if(seqcounter == 4) begin
                                mem[ar.outputdata] <= acdata;
                                seqcounter <= -1;
                                end
                                end
			            8'h10:begin
			            	if(seqcounter == 4)begin
			            		pc.outputdata <= ar.outputdata;
			            		seqcounter <= -1;
			            		end
				            	end
                        8'h20: begin
                            if(seqcounter == 4) begin
                                mem[ar.outputdata] <= pc.outputdata;
                                ar.outputdata <= ar.outputdata +1;
                                end
                            if(seqcounter == 5) begin
                                pc.outputdata <= ar.outputdata;
                                seqcounter <= -1;
                                end
                                end
                        8'h40:begin
                            if(seqcounter == 4) dr.outputdata <= mem[ar.outputdata];
                            if(seqcounter == 5) dr.outputdata <= dr.outputdata +1;
                            if(seqcounter == 6)begin
                                mem[ar.outputdata] <= dr.outputdata;
                                    if(dr.outputdata ==0) pc.outputdata <= pc.outputdata +1;
                                seqcounter <= -1;

                                end
                                end
                                           
			
                            //end
                        default:;
                        endcase
                        
                        


                   end//end of D7
               end // end of IRQ
		//end
// end of IRQ
else begin // interrupt cycle 
    if(seqcounter == 0 & R== 0 ) begin
        tr.outputdata<=pc.outputdata;
        ar.outputdata <= 0;
        end
    if(seqcounter == 1 & R==0) begin
        pc.outputdata <= 0;
        //temp registerdakini götür memorye yaz ( M[AR] <- TR)
        end
    if(seqcounter == 2 & R == 0 ) begin
        pc.outputdata <= pc.outputdata +1 ;
        setien<= 0;
        IRQ <= 0;
        seqcounter <= 0;
        end
    end 

end //S
end // always


  
    

endmodule 