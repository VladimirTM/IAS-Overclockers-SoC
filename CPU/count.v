module count #(parameter w = 3)(
  input clk, clr, incr, decr,
  output reg [w-1:0] q
);

always@(posedge clk) begin
  if(clr)
    q <= 0;
  else if(incr)
    q <= q + 1;
  else if(decr)
    q <= q - 1;
end
  
endmodule