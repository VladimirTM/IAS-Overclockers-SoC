`timescale 1ns / 1ns

module opcode_decoder_tb;

reg [5:0] opcode;
wire [3:0] operation_type;
wire is_compare;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

opcode_decoder CUT (
    .opcode(opcode),
    .operation_type(operation_type),
    .is_compare(is_compare)
);

// Task-ul de verificare
task check_decoder;
    input [511:0] test_name;
    input [3:0] exp_op;
    input exp_comp;
    
    begin
        test_count = test_count + 1;
        if (operation_type === exp_op && is_compare === exp_comp) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> EROARE: S-a primit Op=%d Comp=%b, se astepta Op=%d Comp=%b", 
                     operation_type, is_compare, exp_op, exp_comp);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    opcode = 6'b000000;

    $display("========== INCEPERE TESTARE OPCODE DECODER ==========");

    // --- TEST 1: Adunare (CPU_ADD) ---
    @(negedge clk);
    opcode = 6'b001010; // 001010 = CPU_ADD
    #5;
    check_decoder("CPU_ADD (Trebuie sa fie OP_ADD, Comp=0)", 4'd0, 1'b0);

    // --- TEST 2: Scadere Immediata (CPU_SUBI) ---
    @(negedge clk);
    opcode = 6'b101011; // 101011 = CPU_SUBI
    #5;
    check_decoder("CPU_SUBI (Trebuie sa fie OP_SUB, Comp=0)", 4'd1, 1'b0);

    // --- TEST 3: Operatie Logica AND (CPU_AND) ---
    @(negedge clk);
    opcode = 6'b010011;
    #5;
    check_decoder("CPU_AND (Trebuie sa fie OP_AND, Comp=0)", 4'd5, 1'b0);

    // --- TEST 4: Comparare (CPU_CMP) - Caz Special ---
    // CMP trebuie sa seteze tipul pe SUB dar is_compare pe 1
    @(negedge clk);
    opcode = 6'b010111; 
    #5;
    check_decoder("CPU_CMP (Trebuie sa fie OP_SUB, Comp=1)", 4'd1, 1'b1);

    // --- TEST 5: Test Logic (CPU_TSTI) - Caz Special ---
    // TST trebuie sa seteze tipul pe AND dar is_compare pe 1
    @(negedge clk);
    opcode = 6'b111000; 
    #5;
    check_decoder("CPU_TSTI (Trebuie sa fie OP_AND, Comp=1)", 4'd5, 1'b1);

    // --- TEST 6: Shift Left (CPU_LSL) ---
    @(negedge clk);
    opcode = 6'b001111;
    #5;
    check_decoder("CPU_LSL (Trebuie sa fie OP_LSL)", 4'd9, 1'b0);

    // --- TEST 7: Cazul Default (Opcode invalid) ---
    @(negedge clk);
    opcode = 6'b111111; // Opcode nedefinit
    #5;
    check_decoder("OPCODE INVALID (Default: OP_ADD)", 4'd0, 1'b0);

    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");
    
    #50; $stop;
end

endmodule