module processor_pipe(clk1,clk2);
input clk1,clk2;
reg [31:0] PC,IF_ID_IR,ID_EX_IR,EX_MEM_IR,MEM_WB_IR,IF_ID_NPC,ID_EX_NPC;
reg [31:0] ID_EX_A,ID_EX_B,EX_MEM_B,ID_EX_Imm;
reg [2:0] ID_EX_type,EX_MEM_type,MEM_WB_type;
parameter ADD=6'b000000,SUB=6'b000001,MUL=6'b000010,SLT=6'b000011,OR=6'b000100,AND=6'b000101,ADI=6'b000110,SUBI=6'b000111,SLTI=6'b001000,LW=6'b001001,SW=6'b001010,BEQZ=6'b001100,BNEQZ=6'b001101,HLT=6'b001110;
parameter RR_ALU=0,RM_ALU=1,LOAD=2,STORE=3,BRANCH=4,HALT=5;
reg [31:0] EX_MEM_ALUout,MEM_WB_ALUout; 
reg [31:0] MEM_WB_LMD;
reg EX_MEM_cond;
reg TAKEN_BRANCH,HALTED;
reg [31:0] Reg [31:0];
reg [31:0] mem [1023:0];
always @ (posedge clk1) //stage IF
begin
 if(HALTED==0)
 begin
  if(((EX_MEM_cond) && (EX_MEM_IR[31:26]==BEQZ))||((EX_MEM_cond==0) && (EX_MEM_IR[31:26]==BNEQZ)))
  begin
   IF_ID_IR<=mem[EX_MEM_ALUout];
   IF_ID_NPC<=EX_MEM_ALUout+1;
   PC<=EX_MEM_ALUout+1;
   TAKEN_BRANCH=1;
  end
  else
  begin
   IF_ID_IR<=mem[PC];
   IF_ID_NPC<=PC+1;
   PC<=PC+1;
  end
 end
end
always @ (posedge clk2) //stage ID
begin
 if(HALTED==0)
 begin
  if(Reg[ID_EX_IR[25:21]]==5'b00000)
      ID_EX_A<=0;
  else
      ID_EX_A<=Reg[IF_ID_IR[25:21]];
  if(Reg[IF_ID_IR[20:16]]==5'b00000)
     ID_EX_B<=0;
  else
     ID_EX_B<=Reg[IF_ID_IR[20:16]];
  
  ID_EX_Imm<={{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
  
  case(IF_ID_IR[31:26])
   ADD,SUB,MUL,SLT,AND,OR: ID_EX_type<=RR_ALU;
   ADI,SUBI,SLTI: ID_EX_type<=RM_ALU;
   LW: ID_EX_type<=LOAD;
   SW: ID_EX_type<=STORE;
   BEQZ,BNEQZ: ID_EX_type<=BRANCH;
   HLT: ID_EX_type<=HALT;
   default:ID_EX_type<=HALT; 
  endcase
  ID_EX_IR<=IF_ID_IR;
 end
 
end
always @ (posedge clk1) //stage EX
begin
 if(HALTED==0)
 begin
  
  case(ID_EX_type)
  RR_ALU:begin
   case(ID_EX_IR[31:26])
   ADD: EX_MEM_ALUout<=ID_EX_A+ID_EX_B;
   SUB: EX_MEM_ALUout<=ID_EX_A-ID_EX_B;
   MUL: EX_MEM_ALUout<=ID_EX_A*ID_EX_B;
   SLT: EX_MEM_ALUout<=(ID_EX_A<ID_EX_B)?1:0;
   AND: EX_MEM_ALUout<=ID_EX_A&ID_EX_B;
   OR: EX_MEM_ALUout<=ID_EX_A|ID_EX_B;
   endcase
  end
  RM_ALU:begin
   case(ID_EX_IR[31:26])
   ADI: EX_MEM_ALUout<=ID_EX_A+ID_EX_Imm;
   SUB: EX_MEM_ALUout<=ID_EX_A-ID_EX_Imm;
   SLTI: EX_MEM_ALUout<=(ID_EX_A<ID_EX_Imm)?1:0;
   endcase
  end
  LOAD,STORE:begin 
   EX_MEM_ALUout<=ID_EX_A+ID_EX_Imm;
  end
  BRANCH:begin EX_MEM_cond<=(ID_EX_A==0); end
 endcase
 EX_MEM_type<=ID_EX_type;
 EX_MEM_IR<=ID_EX_IR;
 end
end
always @ (posedge clk2) //stage MEM
begin
 if(HALTED==0)
 begin
  case(EX_MEM_type)
  LOAD: MEM_WB_LMD<=mem[EX_MEM_ALUout];
  STORE: if(TAKEN_BRANCH==0) mem[EX_MEM_ALUout]<=EX_MEM_B;
  endcase
 MEM_WB_type<=EX_MEM_type;
 MEM_WB_IR<=EX_MEM_IR; 
 end
 
end         
always @ (posedge clk1) //stage WB 
begin
 if(!TAKEN_BRANCH)
 case(MEM_WB_type)
 RR_ALU: Reg[MEM_WB_IR[15:11]]<=MEM_WB_ALUout;
 RM_ALU: Reg[MEM_WB_IR[20:16]]<=MEM_WB_ALUout;
 LOAD:   Reg[MEM_WB_IR[20:16]]<=MEM_WB_LMD;
 HALT:   HALTED<=1'b1;
 endcase
end
endmodule