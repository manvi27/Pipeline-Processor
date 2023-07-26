module processor_testbench;
reg clk1,clk2;
processor_pipe 	P(clk1,clk2);
initial
begin
clk1=1'b0;
clk2=1'b0;
P.HALTED=0;
P.TAKEN_BRANCH=0;
end
always begin
#5 clk1=1'b1; #5 clk1=1'b0;
#5 clk2=1'b1; #5 clk2=1'b0;
end
integer k,myseed;
initial
begin
 for(k=0;k<31;k=k+1) 
 begin
  P.Reg[k]=$urandom%30;
  //$display("Address=%d value= %d\n",k,P.Reg[k]);
 end
 P.mem[0]={P.ADD,5'b00000,5'b00001,5'b00010,11'b00000000000};
 
P.PC=0;
 
 $monitor($time," instruction=%d %d %d %d insttype=%d opcode=%d a=%d b=%d value=%d",P.IF_ID_IR,P.ID_EX_IR,P.EX_MEM_IR,P.MEM_WB_IR,P.ID_EX_type,P.ID_EX_IR[31:26] ,P.ID_EX_A,P.ID_EX_B,P.EX_MEM_ALUout);
 #500 $finish;
end
endmodule
