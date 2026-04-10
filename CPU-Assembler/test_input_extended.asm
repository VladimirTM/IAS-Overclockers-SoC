; Extended assembler test — verifies encoding of interrupt, I/O,
; immediate, and branch instructions not covered by input2.txt
EI
DI
IRET
WAIT
IN 0
OUT 16
MOVI 42
ADDI 10
LSLI 3
BRA end_prog
end_prog:
END
