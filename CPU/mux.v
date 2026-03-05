module mux(
  input [16:0] x,
  input [16:0] y,
  input sel,
  output reg [16:0] z
);

always@(*) begin
  if(sel == 0)
    z = x;
  else
    z = y;
end
  
endmodule