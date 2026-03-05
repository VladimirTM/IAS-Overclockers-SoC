// 16-bit ALU with arithmetic, logical, shift/rotate operations
module ALU (
    input clk,
    input rst_b,
    input start,
    input [15:0] INBUS,
    output reg [15:0] OUTBUS,
    output Z,
    output N,
    output C,
    output O,
    output EXC,
    output END
);

    // Input sequencing (3-cycle protocol)
    wire [5:0] opcode;
    wire [15:0] operand1, operand2;
    wire core_start, sequencing_done;

    input_sequencer seq (
        .clk(clk),
        .rst_b(rst_b),
        .start(start),
        .INBUS(INBUS),
        .opcode(opcode),
        .operand1(operand1),
        .operand2(operand2),
        .core_start(core_start),
        .sequencing_done(sequencing_done)
    );

    // Opcode decoding
    wire [3:0] operation_type;
    wire is_compare;

    opcode_decoder decoder (
        .opcode(opcode),
        .operation_type(operation_type),
        .is_compare(is_compare)
    );

    // Arithmetic datapath (16-bit)
    wire a0;
    wire s0, s1, s2, s3, s4;
    wire m0, m1, m2, m3, m4, m5, m6, m7, m8;
    wire d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17;
    wire d18;
    wire l0, l1;
    wire sh0, sh1;

    wire [16:0] A;
    wire [15:0] Q;
    wire Q0;
    wire [15:0] Qprim;
    wire [15:0] M;
    wire [16:0] adder_result;
    wire [2:0] CNTM;
    wire [3:0] CNTD;
    wire CNT3;
    wire CNT0;
    wire [16:0] SEL;

    // Signed division: Extract signs → SRT4 on abs values → Apply result sign
    wire d_pre1, d_pre2, d_post;
    wire sign_dividend, sign_divisor, sign_result;
    wire [15:0] abs_operand1, abs_operand2;
    wire [15:0] neg_Q;

    assign abs_operand1 = operand1[15] ? (~operand1 + 16'd1) : operand1;
    assign abs_operand2 = operand2[15] ? (~operand2 + 16'd1) : operand2;

    wire in_signed_div_mode;
    rgst #(.w(1)) R_div_mode (
        .clk(clk),
        .rst_b(rst_b),
        .ld(d_pre1 | d17 | d18),
        .d(d_pre1),
        .q(in_signed_div_mode)
    );

    rgst #(.w(1)) R_sign_dividend (
        .clk(clk),
        .rst_b(rst_b),
        .ld(d_pre1),
        .d(operand1[15]),
        .q(sign_dividend)
    );

    rgst #(.w(1)) R_sign_divisor (
        .clk(clk),
        .rst_b(rst_b),
        .ld(d_pre1),
        .d(operand2[15]),
        .q(sign_divisor)
    );

    assign sign_result = sign_dividend ^ sign_divisor;
    assign neg_Q = ~Q + 16'd1;

    // Accumulator register
    rgst #(.w(17)) RA (
        .clk(clk),
        .rst_b(rst_b),
        .ld(s0 | s2 | m2 | d9),
        .clr(m0 | d0),
        .shftL1(d2),
        .shftL2(d4),
        .shftR1(d15),
        .shftR2(m5),
        .in1(d2 & Q[15] | d15 & 1'b0),
        .in2({2{m5}} & {A[16], A[16]} | {2{d4}} & Q[15:14]),
        .d({17{s0}} & {1'b0, operand1} | {17{s2 | m2 | d9}} & adder_result),
        .q(A)
    );

    // Quotient register (uses abs value for signed division)
    wire [15:0] operand1_selected;
    assign operand1_selected = in_signed_div_mode ? abs_operand1 : operand1;

    rgst #(.w(16)) RQ (
        .clk(clk),
        .rst_b(rst_b),
        .ld(m1 | d0 | d14),
        .shftL1(d2),
        .shftL2(d4),
        .shftR2(m5),
        .in1(M[15]),
        .in2({2{m5}} & A[1:0] | {2{d4}} & {d8, d7}),
        .d({16{m1 | d0}} & operand1_selected | {16{d14}} & adder_result[15:0]),
        .q(Q)
    );

    // Quotient LSB extension
    rgst #(.w(1)) RQ0 (
        .clk(clk),
        .rst_b(rst_b),
        .ld(m5),
        .clr(m0),
        .d(Q[1]),
        .q(Q0)
    );

    // Quotient prime register
    rgst #(.w(16)) RQprim (
        .clk(clk),
        .rst_b(rst_b),
        .clr(d0),
        .incr(d13),
        .shftL2(d4),
        .in2({d5, d6}),
        .q(Qprim)
    );

    // Divisor register (uses abs value for signed division)
    wire [15:0] operand2_selected;
    assign operand2_selected = in_signed_div_mode ? abs_operand2 : operand2;

    rgst #(.w(16)) RM (
        .clk(clk),
        .rst_b(rst_b),
        .ld(s1 | m0 | d1),
        .shftL1(d2),
        .in1(1'b0),
        .d(operand2_selected),
        .q(M)
    );

    // Operand multiplexer
    mux MUX (
        .x({m3 & M[15], M}),
        .y({M, 1'b0}),
        .sel(m3 | d10),
        .z(SEL)
    );

    // Adder/subtractor
    rcas AS (
        .x(~{17{d14}} & A | {17{d14}} & {1'b0, Q}),
        .y({17{s2}} & {1'b0, M} | {17{m2 | d9}} & SEL | {17{d14}} & {1'b0, Qprim}),
        .op(s3 | m4 | d11),
        .z(adder_result)
    );

    // Multiplication counter
    count #(.w(3)) CNT1 (
        .clk(clk),
        .clr(m0 | d0),
        .incr(m6 | d12),
        .q(CNTM)
    );

    assign CNT3 = (CNTM == 3'd7);

    // Division counter
    count #(.w(4)) CNT2 (
        .clk(clk),
        .clr(d0),
        .incr(d2),
        .decr(d15),
        .q(CNTD)
    );

    assign CNT0 = ~CNTD[3] & ~CNTD[2] & ~CNTD[1] & ~CNTD[0];

    // SRT4 division logic
    wire [2:0] q;
    wire [2:0] aux;

    SRT4_PLA cazd (
        .P(A[16:11]),
        .b(M[15:12]),
        .q(aux)
    );

    rgst #(.w(3)) Rq (
        .clk(clk),
        .rst_b(rst_b),
        .ld(d3),
        .d(aux),
        .q(q)
    );

    // Logic unit
    wire [15:0] logic_result;
    wire [1:0] logic_op_select;

    assign logic_op_select = (operation_type == 4'd5) ? 2'b00 :
                             (operation_type == 4'd6) ? 2'b01 :
                             (operation_type == 4'd7) ? 2'b10 :
                             (operation_type == 4'd8) ? 2'b11 :
                             2'b00;

    logic_unit logic_u (
        .operand1(operand1),
        .operand2(operand2),
        .op_select(logic_op_select),
        .result(logic_result)
    );

    // Barrel shifter
    wire [15:0] shift_result;
    wire shift_carry_out;
    wire [1:0] shift_type;
    wire shift_done;

    assign shift_type = (operation_type == 4'd9)  ? 2'b00 :
                        (operation_type == 4'd10) ? 2'b01 :
                        (operation_type == 4'd11) ? 2'b10 :
                        (operation_type == 4'd12) ? 2'b11 :
                        2'b00;

    barrel_shifter shifter (
        .operand(operand1),
        .shift_amount(operand2[4:0]),
        .shift_type(shift_type),
        .result(shift_result),
        .carry_out(shift_carry_out)
    );

    assign shift_done = 1'b1;

    // Control unit
    wire logic_enable, shift_start;

    controlUnit cu (
        .clk(clk),
        .rst_b(rst_b),
        .core_start(core_start),
        .operation_type(operation_type),
        .is_compare(is_compare),
        .cazM({Q[1], Q[0], Q0}),
        .M_7(M[15]),
        .A_8(A[16]),
        .q(q),
        .CNT3(CNT3),
        .CNT0(CNT0),
        .shift_done(shift_done),
        .s0(s0),
        .s1(s1),
        .s2(s2),
        .s3(s3),
        .s4(s4),
        .m0(m0),
        .m1(m1),
        .m2(m2),
        .m3(m3),
        .m4(m4),
        .m5(m5),
        .m6(m6),
        .m7(m7),
        .m8(m8),
        .d0(d0),
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .d4(d4),
        .d5(d5),
        .d6(d6),
        .d7(d7),
        .d8(d8),
        .d9(d9),
        .d10(d10),
        .d11(d11),
        .d12(d12),
        .d13(d13),
        .d14(d14),
        .d15(d15),
        .d16(d16),
        .d17(d17),
        .d18(d18),
        .d_pre1(d_pre1),
        .d_pre2(d_pre2),
        .d_post(d_post),
        .l0(l0),
        .l1(l1),
        .sh0(sh0),
        .sh1(sh1),
        .logic_enable(logic_enable),
        .shift_start(shift_start),
        .END(END),
        .idle(a0)
    );

    // Output (apply sign for DIV/MOD)
    wire [15:0] result_comb;
    wire [15:0] neg_A_remainder;
    assign neg_A_remainder = ~A[15:0] + 16'd1;

    assign result_comb =
        (operation_type == 4'd0 || operation_type == 4'd1) ? A[15:0] :
        (operation_type == 4'd2) ? Q :
        (operation_type == 4'd3) ? (sign_result ? neg_Q : Q) :  // DIV: quotient sign
        (operation_type == 4'd4) ? (sign_dividend ? neg_A_remainder : A[15:0]) :  // MOD: remainder follows dividend
        (operation_type >= 4'd5 && operation_type <= 4'd8) ? logic_result :
        (operation_type >= 4'd9 && operation_type <= 4'd12) ? shift_result :
        16'd0;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            OUTBUS <= 16'd0;
        else if (END & ~is_compare)
            OUTBUS <= result_comb;
    end

    // Flag generation
    wire flag_Z, flag_N, flag_C, flag_O;

    flag_generator flags_gen (
        .result(result_comb),
        .extended_result(A),
        .operation_type(operation_type),
        .operand1(operand1),
        .operand2(operand2),
        .shift_carry(shift_carry_out),
        .Z(flag_Z),
        .N(flag_N),
        .C(flag_C),
        .O(flag_O)
    );

    reg reg_Z, reg_N, reg_C, reg_O;
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            {reg_Z, reg_N, reg_C, reg_O} <= 4'b0000;
        else if (END)
            {reg_Z, reg_N, reg_C, reg_O} <= {flag_Z, flag_N, flag_C, flag_O};
    end

    assign {Z, N, C, O} = {reg_Z, reg_N, reg_C, reg_O};

    // Exception handling
    reg exception;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            exception <= 1'b0;
        else if ((operation_type == 4'd3 | operation_type == 4'd4) &
                 (operand2 == 16'd0) & core_start)
            exception <= 1'b1;
        else if (a0 & ~core_start)
            exception <= 1'b0;
    end

    assign EXC = exception;

endmodule
