module rgst #(parameter w=8)(
    input clk, rst_b, ld, clr, shftL1, shftL2, shftR1, shftR2, incr,
    input in1,
    input [1:0] in2,
    input [w-1:0] d,
    output reg [w-1:0] q
);

generate
  if (w == 1) begin
    // 1-bit register - no shifting
    always @ (posedge clk, negedge rst_b) begin
      if (!rst_b)
        q <= 0;
      else if (clr)
        q <= 0;
      else if (ld)
        q <= d;
      else if (incr)
        q <= q + 1;
    end
  end else if (w == 2) begin
    // 2-bit register - only shftL1 and shftR1
    always @ (posedge clk, negedge rst_b) begin
      if (!rst_b)
        q <= 0;
      else if (clr)
        q <= 0;
      else if (ld)
        q <= d;
      else if (shftL1)
        q <= {q[0], in1};
      else if (shftR1)
        q <= {in1, q[1]};
      else if (incr)
        q <= q + 1;
    end
  end else begin
    // Full width register - all shift operations
    always @ (posedge clk, negedge rst_b) begin
      if (!rst_b)
        q <= 0;
      else if (clr)
        q <= 0;
      else if (ld)
        q <= d;
      else if (shftL1)
        q <= {q[w-2:0], in1};
      else if (shftL2)
        q <= {q[w-3:0], in2};
      else if (shftR1)
        q <= {in1, q[w-1:1]};
      else if (shftR2)
        q <= {in2, q[w-1:2]};
      else if (incr)
        q <= q + 1;
    end
  end
endgenerate

endmodule