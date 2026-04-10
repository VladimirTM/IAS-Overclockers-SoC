; io_interrupt_demo.asm
; Demonstrates interrupt system: keyboard IRQ + timer IRQ
;
; IVT layout (pre-loaded at addresses 190-193 via data_init.py or Makefile):
;   mem[190] = address of timer_isr   (= 13)
;   mem[191] = address of kbd_isr     (= 18)
;   mem[192] = address of mine_isr (not used here, but IVT slot reserved)
;   mem[193] = address of ext_isr  (not used here)
;
; Memory results after ISRs fire:
;   mem[200] = keyboard key code received
;   mem[201] = timer tick count
;
; Program layout (instruction addresses):
;   0   MOVI 0           ; A = 0
;   1   OUT  48          ; IER = 0 (disable all while setting up)
;   2   MOVI 3           ; A = 3 (enable TIMER bit0 + KBD bit1)
;   3   OUT  48          ; IER = 3
;   4   MOVI 0
;   5   ST   X, 200      ; mem[200] = 0 (key store init)
;   6   ST   X, 201      ; mem[201] = 0 (tick count init)
;   7   EI               ; enable interrupts (I_flag = 1)
; main_loop (addr 8):
;   8   WAIT             ; idle — wakes on any interrupt → INTR_CHECK
;   9   BRA  main_loop   ; loop back after IRET returns here
;
; Timer ISR (addr 10):
;  10   LD   X, 201      ; X = tick_count
;  11   INC  X           ; X++
;  12   ST   X, 201      ; mem[201] = tick_count + 1
;  13   IRET
;
; Keyboard ISR (addr 14):
;  14   IN   0           ; A = KBD_DATA (also clears kbd_irq level signal)
;  15   MOVR X, A        ; X = keycode
;  16   ST   X, 200      ; mem[200] = keycode
;  17   IRET
;
; Halt (addr 18):
;  18   END

        MOVI 0
        OUT  48
        MOVI 3
        OUT  48
        MOVI 0
        ST   X, 200
        ST   X, 201
        EI
main_loop:
        WAIT
        BRA  main_loop

; ---- Timer ISR (IVT[0] must point here = address 10) ----
timer_isr:
        LD   X, 201
        INC  X
        ST   X, 201
        IRET

; ---- Keyboard ISR (IVT[1] must point here = address 14) ----
kbd_isr:
        IN   0
        MOVR X, A
        ST   X, 200
        IRET

        END
