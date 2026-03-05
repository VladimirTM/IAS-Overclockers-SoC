`timescale 1ns / 1ns

module mining_core_tb;

reg clk, reset, start;
reg [15:0] data_in, nonce_in, target;
wire [15:0] hash_out, result_nonce;
wire done;

integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

// Instantierea modulului 
mining_core CUT (
    .clk(clk),
    .reset(reset),
    .start(start),
    .data_in(data_in),
    .nonce_in(nonce_in),
    .target(target),
    .hash_out(hash_out),
    .result_nonce(result_nonce),
    .done(done)
);

// Task-ul de verificare 
task check_mining;
    input [511:0] test_name;
    input [15:0] exp_nonce; 
    input [15:0] exp_hash; 
    
    reg res_ok, hash_ok;
    begin
        test_count = test_count + 1;
        
        res_ok = (result_nonce == exp_nonce);
        hash_ok = (hash_out == exp_hash);

        if (res_ok && hash_ok && done) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            $display("  -> Nonce: %h, Hash: %h", result_nonce, hash_out);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            if (!done)
                $display("  -> EROARE: Modulul nu a activat semnalul DONE");
            if (!res_ok) 
                $display("  -> EROARE NONCE: S-a primit %h, se astepta %h", result_nonce, exp_nonce);
            if (!hash_ok)  
                $display("  -> EROARE HASH: S-a primit %h, se astepta %h", hash_out, exp_hash);
            
            fail_count = fail_count + 1;
        end
    end
endtask

// Generare clk
initial begin
    clk = 0;
    forever #10 clk = ~clk; // Perioada 20ns
end

// Initializari
initial begin
    reset = 1;
    start = 0;
    data_in = 0;
    nonce_in = 0;
    target = 0;
end

// Scenariul de Testare
initial begin
    $display("========== INCEPERE TESTARE MINING CORE ==========");

    // --- TEST 1: Cautare cu Target Mare (Solutie rapida) ---
    // Presupunem ca pentru data=AAAA, primul nonce (0000) produce un hash < FFFF
    @(negedge clk); reset = 0;
    @(negedge clk); reset = 1; start = 1;
    data_in = 16'hAAAA;
    nonce_in = 16'h0000;
    target = 16'hFFFF; // Orice hash va fi acceptat
    @(negedge clk); start = 0; // Oprim start conform protocolului tau
    
    @(posedge done); // Asteptam finalizarea calculului
    @ (negedge clk); // done like this for iverilog testing script
    check_mining("Mining: Target Maxim (Solutie imediata)", 16'h0000, 16'h7A59);


    // --- TEST 2: Cautare cu Target Specific (Dificultate Medie) ---
    @(negedge clk); reset = 0;
    @(negedge clk); reset = 1; start = 1;
    data_in = 16'h1234;
    nonce_in = 16'h0000;
    target = 16'h4000; // Cautam un hash destul de mic
    @(negedge clk); start = 0;
    
    // Asteptam finalizarea (poate dura mai multe cicluri de INIT-COMPUTE-CHECK)
    @(posedge done);
    @ (negedge clk); // done like this for iverilog testing script
    // Valorile exp_nonce si exp_hash de mai jos sunt ipotetice pentru exemplificare
    // In simulare reala, le inlocuiesti cu cele calculate de algoritm
    check_mining("Mining: Target 4000h (Dificultate Medie)", 16'h0001, 16'h376D);


    // --- TEST 3: Reluare din Nonce diferit ---
    @(negedge clk); reset = 0;
    @(negedge clk); reset = 1; start = 1;
    data_in = 16'hABCD;
    nonce_in = 16'h00FF; // Incepem cautarea de la FF in loc de 0
    target = 16'h7FFF;
    @(negedge clk); start = 0;
    
    @(posedge done);
    @ (negedge clk); // done like this for iverilog testing script
    check_mining("Mining: Start de la Nonce 00FFh", 16'h00FF, 16'h3B76);


    // Raport Final de Simulare
    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");
    
    #100; $stop;
end

// Monitorizare in timp real (Debug)
always @(posedge clk) begin
    if (CUT.state == 3) begin // Starea CHECK
        $display("[DEBUG] Round Done. Nonce: %h | Hash: %h", CUT.current_nonce, hash_out);
    end
end

endmodule