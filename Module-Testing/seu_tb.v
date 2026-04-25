//Testare seu_tb.v

`timescale 1ns / 1ns

module seu_tb;

    reg [8:0] in_imm;
    wire [15:0] out_ext;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    seu DUT (
        .in_imm(in_imm),
        .out_ext(out_ext)
    );

    task check_test;
        input [255:0] test_name;
        input [15:0] expected_ext;
        begin
            test_count = test_count + 1;
            if (out_ext === expected_ext) begin
                $display("Test %2d PASS: %s (In: %h -> Out: %h)", 
                          test_count, test_name, in_imm, out_ext);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s | In: %h | Asteptat: %h | Actual: %h", 
                          test_count, test_name, in_imm, expected_ext, out_ext);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("--- SEU Testbench (9-bit to 16-bit sign extend) ---");

        // --- TEST 1: Valoare pozitivă mică ---
        in_imm = 9'h005; // MSB (bit 8) este 0
        #10;
        check_test("Positive Small", 16'h0005);

        // --- TEST 2: Valoare pozitivă maximă (0 1111 1111) ---
        in_imm = 9'h0FF; // MSB este 0
        #10;
        check_test("Positive Max", 16'h00FF);

        // --- TEST 3: Valoare negativă (-1 în complement de 2 pe 9 biți: 1 1111 1111) ---
        in_imm = 9'h1FF; // MSB este 1
        #10;
        check_test("Negative (-1)", 16'hFFFF);

        // --- TEST 4: Valoare negativă mare (1 0000 0000) ---
        in_imm = 9'h100; // MSB este 1
        #10;
        check_test("Negative Max Magnitude", 16'hFF00);

        // --- TEST 5: Zero ---
        in_imm = 9'h000;
        #10;
        check_test("Zero", 16'h0000);

        // --- TEST 6: Bitul de semn este 1, restul 0 ---
        in_imm = 9'b1_0101_0101; 
        #10;
        check_test("Sign bit 1 with pattern", 16'hFF55);

        $display("\n-------------------------------------------");
        $display("Simulation done!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("-------------------------------------------");

        $finish;
    end

endmodule