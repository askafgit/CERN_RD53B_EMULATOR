//----------------------------------------------------------------------
// SR16 - 16 bit SR

// 16-bit shift reg, parameterized to channel
//----------------------------------------------------------------------
`timescale 1ps/1ps

module SR16 #(parameter channel = 4'h0)(
   input            clk          ,
   input            reset        ,
   input            datain       ,
   output           valid_o      ,
   output   [15:0]  dataout      ,
   output   [ 3:0]  shift_count_o
);

    reg [16:0] shift_reg;
    reg [ 3:0] shift_count;
    reg        valid;

    assign shift_count_o = shift_count;

    // Shift Register
    always @ (posedge clk or posedge reset) begin

        if (reset) begin
            shift_reg   <= 17'h00000;
            shift_count <= channel;
            valid       <= 1'b0;
        end 

        else begin
            shift_reg   <= {shift_reg[15:0], datain};
            if (shift_count == 4'hf) begin 
                shift_count <= 4'h0;
                valid       <= 1'b1;
            end else begin
                shift_count <= shift_count + 1;
                valid       <= 1'b0;
            end
        end
        
    end

    assign valid_o = valid;
    assign dataout = shift_reg[15:0];

endmodule
