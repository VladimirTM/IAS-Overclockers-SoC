module mux(
  input [16:0] x,
  input [16:0] y,
  input sel,
  output [16:0] z
);

assign z = sel ? y : x;

endmodule