module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrc,
               output RegWrite, Jump,

               // CHANGE: ImmSrc is now 3 bits instead of 2 bits
               // Reason: we need a new encoding for U-type immediates used by lui.
               output [2:0] ImmSrc, 

               output [1:0] ALUOp); 
  
  // CHANGE: controls is now 12 bits instead of 11 bits.
  // Old format:
  // RegWrite_ImmSrc[1:0]_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
  //
  // New format:
  // RegWrite_ImmSrc[2:0]_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
  reg [11:0] controls; 

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls; 

  always @* case(op)

    // New control format:
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
    //
    // ImmSrc encoding:
    // 000 = I-type immediate
    // 001 = S-type immediate
    // 010 = B-type immediate
    // 011 = J-type immediate
    // 100 = U-type immediate   // CHANGE: added for lui

      7'b0000011: controls = 12'b1_000_1_0_01_0_00_0; // lw
      // lw:
      // RegWrite = 1
      // ImmSrc   = 000, I-type immediate
      // ALUSrc   = 1, use immediate for address calculation
      // ResultSrc= 01, write ReadData to rd

      7'b0100011: controls = 12'b0_001_1_1_00_0_00_0; // sw
      // sw:
      // ImmSrc   = 001, S-type immediate
      // ALUSrc   = 1, use immediate for address calculation
      // MemWrite = 1

      7'b0110011: controls = 12'b1_xxx_0_0_00_0_10_0; // R-type: add, sub, and, or, slt, xor
      // R-type:
      // CHANGE/NOTE: xor uses this same row.
      // Main decoder does not distinguish add/sub/and/or/slt/xor.
      // ALUOp = 10 tells aludec.v to inspect funct3/funct7.
      // For xor: funct3 = 100, so aludec must output ALUControl = 100.

      7'b1100011: controls = 12'b0_010_0_0_00_1_01_0; // beq
      // beq:
      // ImmSrc = 010, B-type immediate
      // Branch = 1
      // ALUOp  = 01, subtract for comparison

      7'b0010011: controls = 12'b1_000_1_0_00_0_10_0; // I-type ALU: addi, slti, ori, andi, etc.
      // I-type ALU:
      // ImmSrc = 000, I-type immediate
      // ALUSrc = 1
      // ALUOp  = 10

      7'b1101111: controls = 12'b1_011_0_0_10_0_00_1; // jal
      // jal:
      // ImmSrc    = 011, J-type immediate
      // ResultSrc = 10, write PCPlus4 to rd
      // Jump      = 1

      // CHANGE: added lui instruction
      7'b0110111: controls = 12'b1_100_x_0_11_0_00_0; // lui
      // lui:
      // opcode    = 0110111
      // RegWrite  = 1, write to rd
      // ImmSrc    = 100, U-type immediate
      // ALUSrc    = x, ALU is not needed for this implementation
      // MemWrite  = 0, no data memory write
      // ResultSrc = 11, select ImmExt directly as Result
      // Branch    = 0
      // ALUOp     = 00, don't care practically, but safe default
      // Jump      = 0
      //
      // Datapath expectation:
      // Result = ImmExt = {Instr[31:12], 12'b0}

      default:    controls = 12'bx_xxx_x_x_xx_x_xx_x; // non-implemented instruction

    endcase
endmodule