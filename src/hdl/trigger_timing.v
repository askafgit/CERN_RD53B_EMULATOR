//-------------------------------------------------------------
// Converts a 4-bit trigger data word into a series of trigger
// pulses at the bunch crossing rate.
// i.e. A datain trigger pattern of 0xF (TTTT) produces 4 pulses
// at 25 nsec intervals
//-------------------------------------------------------------
`timescale 1ps/1ps

module trigger_timing (
   input        reset       ,
   input        clk         ,

   input  [3:0] datain      ,
   input        datain_dv   ,

   output reg   trig_out    ,
   output reg   busy     
);

reg [3:0]   sreg;
reg [1:0]   cnt_shift;
reg [1:0]   cnt_rate;   // Trigger rate (bunch-crossing frequency) is 40MHz, clk is 160MHz so trigger interval is 4

localparam N_BX_DIV  = 2'b11;   // Bunch crossing divisor (N-1) to set output pulse rate. Rate is 40 MHz so value = 4
localparam N_SIZE    = 2'b11;   // Trigger pattern length (N-1) 4

//-------------------------------------------------------------
// Load or shift the shift register
//-------------------------------------------------------------
always @ (posedge clk or posedge reset) begin

    if (reset) begin

        sreg        <= 4'h0;
        trig_out    <= 1'b0;
        cnt_shift   <= 2'b00;
        cnt_rate    <= 2'b00;
        busy        <= 1'b0;

    end

    else begin

        cnt_rate    <= cnt_rate + 1;    // 

        // Load trigger pattern if not busy.
        if (busy == 1'b0 && datain_dv == 1'b1) begin
            sreg        <= datain;
            busy        <= 1'b1;
            cnt_shift   <= 2'b00;
            trig_out    <= 1'b0;
        end

        // Shift the sreg every N cycles. 
        else if (busy == 1'b1) begin
            if (cnt_rate == N_BX_DIV) begin
                trig_out = sreg[3];     // MSB enables output pulse 

                if (cnt_shift == N_SIZE) begin
                    busy        <= 1'b0;
                    cnt_shift   <= 2'b00;
                end 
                else begin
                    sreg        <= {sreg[2:0], 1'b0};
                    cnt_shift   <= cnt_shift + 1;
                end

            end
            else begin
                trig_out = 1'b0;
            end
        end
        else begin
            trig_out = 1'b0;
        end
    end
end

endmodule

