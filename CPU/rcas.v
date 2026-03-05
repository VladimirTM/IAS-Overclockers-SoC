module rcas(
  input [16:0] x,
  input [16:0] y,
  input op,
  output [16:0] z
);

wire cout;

// modul care face adunare sau scadere in functie de operator
rca RCA(
  .x(x),
  .y(y ^ {17{op}}),
  .cin(op),
  .z(z),
  .cout(cout)
);

endmodule