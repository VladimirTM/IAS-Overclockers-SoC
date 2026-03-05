module rca(
  input [16:0] x,
  input [16:0] y,
  input cin,
  output [16:0] z,
  output cout
);

wire [16:0] carryIntermediar;

generate
  genvar i;
  for(i = 0; i < 17; i = i + 1) begin : vect
    if(i == 0) // cazul initial in care cin este cin de la intrare
      fac FAC0(
        .x(x[0]),
        .y(y[0]),
        .cin(cin),
        .z(z[0]),
        .cout(carryIntermediar[0])
      );
    else // in rest cin actual este cout anterior
      fac FAC(
        .x(x[i]),
        .y(y[i]),
        .cin(carryIntermediar[i - 1]),
        .z(z[i]),
        .cout(carryIntermediar[i])
      );
  end
endgenerate

assign cout = carryIntermediar[16]; // asignez valoarea lui cout final

endmodule