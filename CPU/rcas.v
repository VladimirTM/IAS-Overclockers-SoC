module rcas(
  input [16:0] x,
  input [16:0] y,
  input op,
  output [16:0] z
);

rca RCA(
  .x(x),
  .y(y ^ {17{op}}),
  .cin(op),
  .z(z),
  .cout()
);

endmodule