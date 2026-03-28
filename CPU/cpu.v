// CPU: 16-bit processor with MMIO and mining support
module cpu (
    input clk,
    input rst_n,
    output [15:0] pc_out,
    output [15:0] A_out,
    output [15:0] X_out,
    output [15:0] Y_out,
    output [15:0] dr_out,
    output [15:0] mem_out,
    output mining_done,
    // I/O peripheral ports
    input         ext_irq,
    input  [15:0] kbd_data_in,
    input         kbd_strobe,
    output [15:0] disp_data_out,
    output        disp_we
);

    wire [15:0] ar_out, ir_out;
    wire [5:0] opcode;
    wire regaddr;
    wire [15:0] sp_out;

    assign opcode = ir_out[15:10];
    assign regaddr = ir_out[9];

    wire [15:0] mux_ar_out, mux_dr_out, mux_alu_out;
    wire [15:0] imm_sign_extended;

    wire ldAR, ldDR, ldIR, incPC, ldPC, ldPCfromDR;
    wire ldX, ldY, ldA, memWR, finish, ldFLAG;
    wire incSP, decSP, alu_start;
    wire [1:0] condAR, condALU;
    wire [2:0] condDR;
    wire incrX, decrX, incrY, decrY;
    wire use_direct_flag, use_imm_a, use_xy_for_flags;

    wire Z_flag, N_flag, C_flag, O_flag;
    wire [15:0] alu_out;
    wire alu_zero, alu_neg, alu_carry, alu_overflow, alu_end, alu_exc;

    wire mining_start, use_mining_result;
    wire [15:0] mining_hash_out, mining_result_nonce;

    wire use_dr_for_a, use_movr_flags;

    // I/O control signals from CU
    wire io_we_cu, io_re, ivt_mode;

    // MMIO routing: ar_out[10]=1 → I/O space, =0 → RAM
    wire io_access    = ar_out[10];
    wire mem_we_gated = memWR & ~io_access;           // suppress RAM write on I/O address
    wire io_we_sig    = io_we_cu | (memWR & io_access);

    // AR_EXT for condAR=2'b11: sets bit10=1 (I/O page), low 10 bits from IR operand
    wire [15:0] ar_ext_in = {5'b00001, ir_out[9:0]};

    // IRQ lines unused until interrupt_controller added (v3.1)
    wire [15:0] io_data_out_w;
    wire        kbd_irq_w, timer_irq_w, mining_irq_w;
    wire [3:0]  ier_out_w;

    // Source for flags in direct mode: MOVR uses IR register fields, INC/DEC use X/Y, else DR
    wire [15:0] direct_flag_value;
    assign direct_flag_value = use_movr_flags ?
                               (ir_out[7:6] == 2'b00 ? A_out :
                                ir_out[7:6] == 2'b01 ? X_out : Y_out) :
                               (use_xy_for_flags ? (regaddr ? Y_out : X_out) : dr_out);

    program_counter pc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .incPC(incPC),
        .ldPC(ldPC),
        .ldPCfromDR(ldPCfromDR),
        .in_pc_imm({6'b000000, ir_out[9:0]}),
        .in_pc_dr(dr_out),
        .pc_out(pc_out)
    );

    address_register ar_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ldAR(ldAR),
        .in_address(mux_ar_out),
        .out_address(ar_out)
    );

    data_register dr_inst (
        .clk(clk),
        .rst(rst_n),
        .ldDR(ldDR),
        .DR_in(mux_dr_out),
        .DR_out(dr_out)
    );

    memory mem_inst (
        .clk(clk),
        .addr(ar_out[9:0]),
        .data_in(dr_out),
        .we(mem_we_gated),
        .data_out(mem_out)
    );

    instruction_register ir_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ldIR(ldIR),
        .in_instruction(mem_out),
        .instruction(ir_out)
    );

    wire [15:0] a_data_in;
    wire use_imm_a_internal;
    assign a_data_in = use_mining_result ? mining_hash_out :
                       use_dr_for_a ? dr_out :
                       alu_out;
    assign use_imm_a_internal = use_imm_a & ~use_mining_result;

    accumulator a_inst (
        .clk(clk),
        .reset(rst_n),
        .ldA(ldA),
        .use_imm(use_imm_a_internal),
        .D_in(a_data_in),
        .imm_in(imm_sign_extended),
        .A(A_out)
    );

    wire [15:0] x_data_in;
    assign x_data_in = use_mining_result ? mining_result_nonce : dr_out;

    register_x x_inst (
        .clk(clk),
        .reset(rst_n),
        .ldX(ldX),
        .incrX(incrX),
        .decrX(decrX),
        .D_in(x_data_in),
        .X(X_out)
    );

    register_y y_inst (
        .clk(clk),
        .reset(rst_n),
        .ldY(ldY),
        .incrY(incrY),
        .decrY(decrY),
        .D_in(dr_out),
        .Y(Y_out)
    );

    stack_pointer sp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .incSP(incSP),
        .decSP(decSP),
        .sp_out(sp_out)
    );

    flags flags_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ldFLAG(ldFLAG),
        .alu_zero(alu_zero),
        .alu_neg(alu_neg),
        .alu_carry(alu_carry),
        .alu_overflow(alu_overflow),
        .use_direct_value(use_direct_flag),
        .direct_value(direct_flag_value),
        .Z(Z_flag),
        .N(N_flag),
        .C(C_flag),
        .O(O_flag)
    );

    seu seu_inst (
        .in_imm(ir_out[8:0]),
        .out_ext(imm_sign_extended)
    );

    mux_ar mux_ar_inst (
        .PC(pc_out),
        .SP(sp_out),
        .IMM({7'b0000000, ir_out[8:0]}),
        .AR_EXT(ar_ext_in),
        .CondAR(condAR),
        .out(mux_ar_out)
    );

    mux_dr mux_dr_inst (
        .mem(mem_out),
        .X(X_out),
        .Y(Y_out),
        .PC(pc_out),
        .IMM(imm_sign_extended),
        .A(A_out),
        .io_data(io_data_out_w),
        .flags_Z(Z_flag),
        .flags_N(N_flag),
        .flags_C(C_flag),
        .flags_O(O_flag),
        .CondDR(condDR),
        .out(mux_dr_out)
    );

    mux_alu mux_alu_inst (
        .opcode({10'b0000000000, opcode}),
        .A(A_out),
        .X(X_out),
        .Y(Y_out),
        .IMM(imm_sign_extended),
        .regaddr(regaddr),
        .CondALU(condALU),
        .out(mux_alu_out)
    );

    ALU alu_inst (
        .clk(clk),
        .rst_b(rst_n),
        .start(alu_start),
        .INBUS(mux_alu_out),
        .OUTBUS(alu_out),
        .Z(alu_zero),
        .N(alu_neg),
        .C(alu_carry),
        .O(alu_overflow),
        .EXC(alu_exc),
        .END(alu_end)
    );

    mining_core mining_inst (
        .clk(clk),
        .reset(rst_n),
        .start(mining_start),
        .data_in(X_out),
        .nonce_in(Y_out),
        .target(A_out),
        .hash_out(mining_hash_out),
        .result_nonce(mining_result_nonce),
        .done(mining_done)
    );

    io_controller io_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .io_addr(ar_out[9:0]),
        .io_data_in(dr_out),
        .io_we(io_we_sig),
        .io_re(io_re),
        .io_data_out(io_data_out_w),
        .kbd_data_in(kbd_data_in),
        .kbd_strobe(kbd_strobe),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we),
        .mining_hash_in(mining_hash_out),
        .mining_nonce_in(mining_result_nonce),
        .mining_done_in(mining_done),
        .kbd_irq(kbd_irq_w),
        .timer_irq(timer_irq_w),
        .mining_irq(mining_irq_w),
        .ier_out(ier_out_w)
    );

    cu cu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .regaddr(regaddr),
        .ir_out(ir_out),
        .Z(Z_flag),
        .N(N_flag),
        .C(C_flag),
        .O(O_flag),
        .alu_end(alu_end),
        .alu_exc(alu_exc),
        .mining_done(mining_done),
        .ldAR(ldAR),
        .condAR(condAR),
        .ldDR(ldDR),
        .condDR(condDR),
        .ldIR(ldIR),
        .incPC(incPC),
        .ldPC(ldPC),
        .ldPCfromDR(ldPCfromDR),
        .ldX(ldX),
        .ldY(ldY),
        .ldA(ldA),
        .memWR(memWR),
        .ldFLAG(ldFLAG),
        .incSP(incSP),
        .decSP(decSP),
        .alu_start(alu_start),
        .condALU(condALU),
        .incrX(incrX),
        .decrX(decrX),
        .incrY(incrY),
        .decrY(decrY),
        .use_direct_flag(use_direct_flag),
        .use_imm_a(use_imm_a),
        .use_xy_for_flags(use_xy_for_flags),
        .mining_start(mining_start),
        .use_mining_result(use_mining_result),
        .use_dr_for_a(use_dr_for_a),
        .use_movr_flags(use_movr_flags),
        .finish(finish),
        .io_we(io_we_cu),
        .io_re(io_re),
        .ivt_mode(ivt_mode)
    );

    reg halt_msg_printed;
    initial halt_msg_printed = 0;

    always @(posedge clk) begin
        if (finish && !halt_msg_printed) begin
            halt_msg_printed = 1;
            $display("========== CPU HALTED ==========");
            $display("PC = %h", pc_out);
            $display("X  = %h", X_out);
            $display("Y  = %h", Y_out);
            $display("A  = %h", A_out);
            $display("SP = %h", sp_out);
            $display("Flags: Z=%b N=%b C=%b O=%b", Z_flag, N_flag, C_flag, O_flag);
            $display("================================");
        end
    end

endmodule
