// Input sequencer: 3-cycle protocol (opcode, operand1, operand2)
module input_sequencer (
    input clk,
    input rst_b,
    input start,
    input [15:0] INBUS,
    output reg [5:0] opcode,
    output reg [15:0] operand1,
    output reg [15:0] operand2,
    output reg core_start,
    output reg sequencing_done
);

    localparam IDLE     = 3'd0;
    localparam LOAD_OPC = 3'd1;
    localparam LOAD_OP1 = 3'd2;
    localparam LOAD_OP2 = 3'd3;
    localparam DONE     = 3'd4;
    localparam WAIT     = 3'd5;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD_OPC;
            end

            LOAD_OPC: begin
                if (start)
                    next_state = LOAD_OP1;
            end

            LOAD_OP1: begin
                if (start)
                    next_state = LOAD_OP2;
            end

            LOAD_OP2: begin
                if (start)
                    next_state = DONE;
            end

            DONE: begin
                next_state = WAIT;
            end

            WAIT: begin
                if (!start)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            opcode <= 6'd0;
            operand1 <= 16'd0;
            operand2 <= 16'd0;
            core_start <= 1'b0;
            sequencing_done <= 1'b0;
        end
        else begin
            if (state == IDLE && start) begin
                opcode <= INBUS[5:0];
                core_start <= 1'b0;
                sequencing_done <= 1'b0;
            end
            else if (state == LOAD_OPC && start) begin
                operand1 <= INBUS;
                core_start <= 1'b0;
                sequencing_done <= 1'b0;
            end
            else if (state == LOAD_OP1 && start) begin
                operand2 <= INBUS;
                core_start <= 1'b0;
                sequencing_done <= 1'b0;
            end
            else if (state == LOAD_OP2 && start) begin
                core_start <= 1'b1;
                sequencing_done <= 1'b1;
            end
            else if (state == DONE) begin
                core_start <= 1'b1;
                sequencing_done <= 1'b1;
            end
            else if (state == WAIT && !start) begin
                core_start <= 1'b0;
                sequencing_done <= 1'b0;
            end
            else begin
                core_start <= 1'b0;
                sequencing_done <= 1'b0;
            end
        end
    end

endmodule
