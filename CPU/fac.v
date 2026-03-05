module fac(
  input x, y, cin,
  output z, cout
);

assign z = x ^ y ^ cin;
assign cout = (x & y) | (x & cin) | (y & cin);

endmodule