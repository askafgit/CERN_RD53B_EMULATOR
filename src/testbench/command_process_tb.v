`timescale 1ns / 1ps
`include "global.v"
module command_process_tb();

reg reset;
reg clk80;
reg data_in_valid;
reg [7:0] data_in;
reg [3:0] chip_id;

wire   clear, pulse, cal,
       wrreg, rdreg, sync;
wire data_out_valid;
wire [15:0] data_out;
wire [8:0] register_address;
wire register_address_valid;
wire CAL_edge, CAL_aux;

command_process dut (
        .reset(reset),
        .clk80(clk80),
        .data_in_valid(data_in_valid),
        .data_in(data_in),
        .chip_id(chip_id),
        .clear(clear), .pulse(pulse),
        .cal(cal), .wrreg(wrreg),
        .rdreg(rdreg), .sync(sync),
        .data_out_valid(data_out_valid),
        .data_out(data_out),
        .register_address(register_address),
        .register_address_valid(register_address_valid),
        .CAL_edge(CAL_edge),
        .CAL_aux(CAL_aux)
);

reg [7:0] dataword;
reg [8:0] adx;
reg [15:0] to_write;

parameter half_clk80 = 6.25;

localparam CLEAR_C = 8'h5A, G_PULSE_C = 8'h5C,
           CAL_C = 8'h63, NOOP_C = 8'hAA, WRREG_C = 8'h66,
           RDREG_C = 8'h65, sync_pattern = 16'b1000_0001_0111_1110;

localparam array = {CLEAR_C, G_PULSE_C, CAL_C, NOOP_C};

// convert data_ins to encoded version to make life easier
always @(*) begin: encode_data_in
   if      (dataword == CLEAR_C)               data_in = CLEAR_C;
   else if (dataword == G_PULSE_C)           data_in = G_PULSE_C;
   else if (dataword == CAL_C)               data_in = CAL_C;
   else if (dataword == NOOP_C)              data_in = NOOP_C;
   else if (dataword == RDREG_C)             data_in = RDREG_C;
   else if (dataword == WRREG_C)             data_in = WRREG_C;
   else if (dataword == sync_pattern[15:8])  data_in = sync_pattern[15:8];
   else if (dataword == sync_pattern[7:0])   data_in = sync_pattern[7:0];
   else if (dataword == 'd0) data_in = 8'h6A;
   else if (dataword == 'd1) data_in = 8'h6C;
   else if (dataword == 'd2) data_in = 8'h71;
   else if (dataword == 'd3) data_in = 8'h72;
   else if (dataword == 'd4) data_in = 8'h74;
   else if (dataword == 'd5) data_in = 8'h8B;
   else if (dataword == 'd6) data_in = 8'h8D;
   else if (dataword == 'd7) data_in = 8'h8E;
   else if (dataword == 'd8) data_in = 8'h93;
   else if (dataword == 'd9) data_in = 8'h95;
   else if (dataword == 'd10) data_in = 8'h96;
   else if (dataword == 'd11) data_in = 8'h99;
   else if (dataword == 'd12) data_in = 8'h9A;
   else if (dataword == 'd13) data_in = 8'h9C;
   else if (dataword == 'd14) data_in = 8'hA3;
   else if (dataword == 'd15) data_in = 8'hA5;
   else if (dataword == 'd16) data_in = 8'hA6;
   else if (dataword == 'd17) data_in = 8'hA9;
   else if (dataword == 'd18) data_in = 8'h59;
   else if (dataword == 'd19) data_in = 8'hAC;
   else if (dataword == 'd20) data_in = 8'hB1;
   else if (dataword == 'd21) data_in = 8'hB2;
   else if (dataword == 'd22) data_in = 8'hB4;
   else if (dataword == 'd23) data_in = 8'hC3;
   else if (dataword == 'd24) data_in = 8'hC5;
   else if (dataword == 'd25) data_in = 8'hC6;
   else if (dataword == 'd26) data_in = 8'hC9;
   else if (dataword == 'd27) data_in = 8'hCA;
   else if (dataword == 'd28) data_in = 8'hCC;
   else if (dataword == 'd29) data_in = 8'hD1;
   else if (dataword == 'd30) data_in = 8'hD2;
   else if (dataword == 'd31) data_in = 8'hD4;
end: encode_data_in

integer seed;
integer ran;
integer array_pick;

always #half_clk80 clk80 = ~clk80;

initial begin
    clk80 <= 1'b1;
    data_in_valid <= 1'b0;
    dataword <= 5'b0;
    chip_id <= 4'b0;
end

initial begin
    @(posedge clk80);
    reset <= 1'b1;
    repeat (4) @(posedge clk80);
    reset <= 1'b0;
    repeat (8) @(posedge clk80);

    // test valid low
    dataword <= CLEAR_C;
    repeat (3) @(posedge clk80);

    // test valid transitioning high
    data_in_valid <= 1'b1;
    repeat (2) @(posedge clk80);

    // test valid going low during cycle
    dataword <= G_PULSE_C;
    repeat (2) @(posedge clk80);
    dataword <= 8'd0;
    @(posedge clk80);
    data_in_valid <= 1'b0;
    dataword <= 8'd1;
    repeat (3) @(posedge clk80);
    data_in_valid <= 1'b1;
    @(posedge clk80);
    data_in_valid <= 1'b0;
    repeat (2) @(posedge clk80);  // let PULSE signal clear

    // wrong chip_id
    data_in_valid <= 1'b1;
    dataword <= G_PULSE_C;
    repeat(2) @(posedge clk80);
    dataword <= 8'd14;
    @(posedge clk80);
    dataword <= G_PULSE_C;
    chip_id <= 4'hF;
    repeat(2) @(posedge clk80);
    dataword <= 8'h00;
    @(posedge clk80);
    chip_id <= 4'b0;

    // no trailing zero after chip_id
    dataword <= G_PULSE_C;
    repeat (2) @(posedge clk80);
    dataword <= 8'd0;
    @(posedge clk80);
	dataword <= 8'd2;
	@(posedge clk80);
    data_in_valid <= 1'b0;
    repeat (2) @(posedge clk80);
    
    // test writing to and reading from an adx
    // write sync_pattern to 9'b0
    dataword <= WRREG_C;
    data_in_valid <= 1'b1;
    @(posedge clk80);
    dataword <= 8'd0;//0
    @(posedge clk80);
    dataword <= 8'd0;//0
    @(posedge clk80);
    dataword <= 8'd0; //0
	@(posedge clk80);
    //dataword[4:1] <= `PIX_MODE;
    dataword <= sync_pattern[15:11];
    @(posedge clk80);
    dataword <= sync_pattern[10:6];
    @(posedge clk80);
    dataword <= sync_pattern[5:1];
    @(posedge clk80);
    dataword[4] <= sync_pattern[0];
	dataword[3:0] <= 4'b0;
    @(posedge clk80);
    // read sync_pattern from 9'b0
    dataword <= RDREG_C;
    @(posedge clk80);
    dataword <= 8'b0;
    @(posedge clk80);
    dataword <= 8'b0;
    @(posedge clk80);
    dataword <= 8'b0;
    repeat (3) @(posedge clk80);
    data_in_valid <= 1'b0;
	
	@(posedge clk80);
	data_in_valid = 1'b1;
	dataword = NOOP_C;
	repeat (2) @(posedge clk80);
	dataword = 8'b0;
	
    // test flag reset while waiting for next valid data
    /*@(posedge clk80);
    dataword <= ECR_C;
    data_in_valid <= 1'b1;
    @(posedge clk80);
    data_in_valid <= 1'b0;
    repeat (3) @(posedge clk80);
    dataword <= sync_pattern[15:8];
    data_in_valid <= 1'b1;
    @(posedge clk80);
    data_in_valid <= 1'b0;
    repeat (3) @(posedge clk80);
    dataword <= sync_pattern[7:0];
    data_in_valid <= 1'b1;
    @(posedge clk80);
    data_in_valid <= 1'b0;
    @(posedge clk80);*/
    
    // divide waveform
    reset <= 1'b1;
    repeat (4) @(posedge clk80);
    reset <= 1'b0;
    repeat (4) @(posedge clk80);

    // test various commands
    forever begin
        @(posedge clk80);
        data_in_valid <= 1'b0;
        repeat ($urandom%4) @(posedge clk80);
        ran <= $urandom%4;
        if (ran == 32'b0  || ran == 32'b1) begin
            data_in_valid <= 1'b1;
            dataword <= sync_pattern[15:8];
            @(posedge clk80);
            data_in_valid <= 1'b0;
            repeat ($urandom%4) @(posedge clk80);
            data_in_valid <= 1'b1;
            dataword <= sync_pattern[7:0];
        end
        else if (ran == 32'd2) begin
            data_in_valid <= 1'b1;
            dataword <= array[(8 * ($urandom%5)) +: 8];
            repeat (2) @(posedge clk80);
            $display("Starting test word %h at %d", dataword, $time);
            data_in_valid <= 1'b0;
            repeat ($urandom%4) @(posedge clk80);
            case (dataword)
                G_PULSE_C: begin
                    data_in_valid <= 1'b1;
                    dataword <= 8'd0;
                    @(posedge clk80);
                    data_in_valid <= 1'b0;
                    repeat ($urandom%4) @(posedge clk80);
                    data_in_valid <= 1'b1;
                    dataword <= $urandom%32;
                end
                CAL_C: begin
                    data_in_valid <= 1'b1; 
                    dataword <= 8'd0;  // chip_id
                    @(posedge clk80);
                    data_in_valid <= 1'b0;
                    repeat ($urandom%4) @(posedge clk80);
                    data_in_valid <= 1'b1;
                    dataword <= $urandom%32;  // calpulse and caledgedelay
                    @(posedge clk80);
                    data_in_valid <= 1'b0;
                    repeat ($urandom%4) @(posedge clk80);
                    data_in_valid <= 1'b1;
                    dataword <= $urandom%32;  // caledgecount
                    @(posedge clk80);
                    data_in_valid <= 1'b0;
                    repeat ($urandom%4) @(posedge clk80);
                    data_in_valid <= 1'b1;
                    dataword <= $urandom%32;  // aux and auxedgedelay
                end
                // ECR, BCR, and NOOP have no further fields to send
            endcase
        end
        else begin
            adx <= $urandom%512;
            to_write <= $urandom%65536;
            ran <= $urandom%2;
            @(posedge clk80);
			
			
        
            data_in_valid <= 1'b1;
            if (ran) dataword <= RDREG_C;  // read
            else dataword <= WRREG_C;  // write
            @(posedge clk80);
            data_in_valid <= 1'b0;
            repeat ($urandom%4) @(posedge clk80);
            data_in_valid <= 1'b1;
            dataword <= 8'd0;
            @(posedge clk80);
            data_in_valid <= 1'b0;
            repeat ($urandom%4) @(posedge clk80);
            data_in_valid <= 1'b1;
			dataword[4] <= 1'b0;
            dataword[3:0] <= adx[8:5];
            @(posedge clk80);
            data_in_valid <= 1'b0;
            repeat ($urandom%4) @(posedge clk80);
            data_in_valid <= 1'b1;
            dataword <= adx[4:0];
            if (!ran) begin // write
                dataword <= to_write[15:11];
                @(posedge clk80);
                data_in_valid <= 1'b0;
                repeat ($urandom%4) @(posedge clk80);
                data_in_valid <= 1'b1;
                dataword <= to_write[10:6];
                @(posedge clk80);
                data_in_valid <= 1'b0;
                repeat ($urandom%4) @(posedge clk80);
                data_in_valid <= 1'b1;
                dataword <= to_write[5:1];
                @(posedge clk80);
                data_in_valid <= 1'b0;
                repeat ($urandom%4) @(posedge clk80);
                data_in_valid <= 1'b1;
                dataword[4] <= to_write[1];
				dataword[3:0] <= 4'b0;
            end
        end
    end
end

endmodule