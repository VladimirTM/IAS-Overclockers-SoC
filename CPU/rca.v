module rca(
  input [16:0] x,
  input [16:0] y,
  input cin,
  output [16:0] z,
  output cout
);

wire [16:0] carryIntermediate;

generate
  genvar i;
  for(i = 0; i < 17; i = i + 1) begin : vect
    if(i == 0)
      fac FAC0(
        .x(x[0]),
        .y(y[0]),
        .cin(cin),
        .z(z[0]),
        .cout(carryIntermediate[0])
      );
    else
      fac FAC(
        .x(x[i]),
        .y(y[i]),
        .cin(carryIntermediate[i - 1]),
        .z(z[i]),
        .cout(carryIntermediate[i])
      );
  end
endgenerate

assign cout = carryIntermediate[16];

endmodule