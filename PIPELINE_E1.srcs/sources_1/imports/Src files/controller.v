module controller(input  [6:0] op,
                  input  [2:0] funct3,
                  input        funct7b5,
                  input        Zero,
                  output [1:0] ResultSrc, 
                  output       MemWrite,
                  output       PCSrc, ALUSrc,
                  output       RegWrite, Jump,
                  // CHANGE: ImmSrc is now 3 bits instead of 2 bits.
                  // Reason: lui needs a new U-type immediate encoding.
                  // New ImmSrc encoding:
                  // 000 = I-type
                  // 001 = S-type
                  // 010 = B-type
                  // 011 = J-type
                  // 100 = U-type, used by lui
                  output [2:0] ImmSrc, 
                  output [3:0] ALUControl);
  
  wire [1:0] ALUOp; 
  wire       Branch; 
  
  maindec md(
    .op(op), 
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite), 
    .Branch(Branch),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump), 

    // CHANGE: connects the new 3-bit ImmSrc from maindec to datapath.
    .ImmSrc(ImmSrc), 

    .ALUOp(ALUOp)
  ); 

  aludec ad(
    .opb5(op[5]), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .ALUOp(ALUOp), 
    .ALUControl(ALUControl)
  ); 

  // No change needed here.
  // beq uses Branch & Zero.
  // jal uses Jump.
  // lui does not branch or jump, so PCSrc = 0 for lui.
  assign PCSrc = (Branch & Zero) | Jump; 

endmodule