/*
Could not do channel alignment with single shift register because of bit slips
*/

//--------------------------------------------------------
// TODO: Top-level Discription
//--------------------------------------------------------
`timescale 1ps/1ps
module shift_align 
(
    input            clk            ,
    input            reset          ,

    input   [15:0]   valid_in       ,
    input  [255:0]   datain         ,

    output           valid_o        ,
    output  [15:0]   dataout        
);

    localparam sync_pattern = 16'b1000_0001_0111_1110;
    parameter  lock_level   = 6'h10;
    parameter  unlock_level = 6'h08;

    //--------------------------------------------------
    // TODO: Fix _i variable naming
    //--------------------------------------------------
    reg  [15:0] valid_i    ;
    reg [255:0] data_i     ;
    reg         valid_ii   ;
    reg  [15:0] data_ii    ; 
    reg  [15:0] locked_i   ;
    reg  [15:0] rst_count  ; 
    reg  [15:0] rst_all    ;
    reg  [15:0] rst_other  ;

    reg  [ 5:0] sync_count [0:15];

    integer i, x;


    //--------------------------------------------------------
    // TODO: Describe block
    //--------------------------------------------------------
    always @(*) 
    begin
        rst_count[ 0] <= |rst_other[15: 1]                     ;
        rst_count[ 1] <= |rst_other[15: 2] ||   rst_other[0]   ;
        rst_count[ 2] <= |rst_other[15: 3] ||  |rst_other[ 1:0];
        rst_count[ 3] <= |rst_other[15: 4] ||  |rst_other[ 2:0];
        rst_count[ 4] <= |rst_other[15: 5] ||  |rst_other[ 3:0];
        rst_count[ 5] <= |rst_other[15: 6] ||  |rst_other[ 4:0];
        rst_count[ 6] <= |rst_other[15: 7] ||  |rst_other[ 5:0];
        rst_count[ 7] <= |rst_other[15: 8] ||  |rst_other[ 6:0];
        rst_count[ 8] <= |rst_other[15: 9] ||  |rst_other[ 7:0];
        rst_count[ 9] <= |rst_other[15:10] ||  |rst_other[ 8:0];
        rst_count[10] <= |rst_other[15:11] ||  |rst_other[ 9:0];
        rst_count[11] <= |rst_other[15:12] ||  |rst_other[10:0];
        rst_count[12] <= |rst_other[15:13] ||  |rst_other[11:0];
        rst_count[13] <= |rst_other[15:14] ||  |rst_other[12:0];
        rst_count[14] <=  rst_other[15]    ||  |rst_other[13:0];
        rst_count[15] <= |rst_other[14:0]                      ;
    end
    
    //--------------------------------------------------------
    // TODO: Describe block
    //--------------------------------------------------------
    always @ (posedge clk or posedge reset) begin
        
        // TODO: Description
        if (reset) begin
            locked_i  <= 16'h0000;
            rst_all   <= 16'h0000;
            rst_other <= 16'h0000;
            data_i    <= 255'd0;
            valid_i   <= 16'd0;

            for (x=0; x < 16; x=x+1) begin
                sync_count[x] <= 6'h00;
            end
        end

        // TODO: Description
        else begin
            for (i=0; i < 16; i=i+1) begin 

                // TODO: Description
                if (rst_count[i] == 1'b1 || |rst_all) begin
                    locked_i  [i] <= 1'b0;
                    sync_count[i] <= 6'h00;
                    rst_all   [i] <= 1'b0;
                    rst_other [i] <= 1'b0;
                end

                // TODO: Description
                else if (valid_in[i] == 1'b1 && datain[i*16+:16] == sync_pattern) begin
                    if (sync_count[i] >= lock_level) begin
                        locked_i  [i] <= 1'b1; 
                        sync_count[i] <= sync_count[i]; 
                        rst_all   [i] <= 1'b0;
                        rst_other [i] <= 1'b1;
                    end

                    // TODO: Description
                    else if (sync_count[i] >= unlock_level && |locked_i )  begin
                        locked_i  [i] <= locked_i[i];
                        sync_count[i] <= sync_count[i];
                        rst_all   [i] <= 1'b1;  
                        rst_other [i] <= 1'b0;
                    end

                    // TODO: Description
                    else begin
                        locked_i  [i] <= 1'b0; 
                        sync_count[i] <= sync_count[i] + 1; 
                        rst_all   [i] <= 1'b0;
                        rst_other [i] <= 1'b0;
                    end

                end

                // TODO: Description
                else begin
                    locked_i  [i] <= locked_i[i];
                    sync_count[i] <= sync_count[i];
                    rst_all   [i] <= 1'b0;
                    rst_other [i] <= 1'b0;
                end

                data_i [i*16+:16] <= datain  [i*16+:16];
                valid_i[i]        <= valid_in[i];
            end
        end
    end
    

    //--------------------------------------------------------
    // TODO: Describe block
    //--------------------------------------------------------
    always @ (*) 
    begin
        case (locked_i) 
            16'b0000000000000001  : begin valid_ii = valid_i[ 0]; data_ii = data_i[ 15:  0]; end
            16'b0000000000000010  : begin valid_ii = valid_i[ 1]; data_ii = data_i[ 31: 16]; end
            16'b0000000000000100  : begin valid_ii = valid_i[ 2]; data_ii = data_i[ 47: 32]; end
            16'b0000000000001000  : begin valid_ii = valid_i[ 3]; data_ii = data_i[ 63: 48]; end
            16'b0000000000010000  : begin valid_ii = valid_i[ 4]; data_ii = data_i[ 79: 64]; end
            16'b0000000000100000  : begin valid_ii = valid_i[ 5]; data_ii = data_i[ 95: 80]; end
            16'b0000000001000000  : begin valid_ii = valid_i[ 6]; data_ii = data_i[111: 96]; end
            16'b0000000010000000  : begin valid_ii = valid_i[ 7]; data_ii = data_i[127:112]; end
            16'b0000000100000000  : begin valid_ii = valid_i[ 8]; data_ii = data_i[143:128]; end
            16'b0000001000000000  : begin valid_ii = valid_i[ 9]; data_ii = data_i[159:144]; end
            16'b0000010000000000  : begin valid_ii = valid_i[10]; data_ii = data_i[175:160]; end
            16'b0000100000000000  : begin valid_ii = valid_i[11]; data_ii = data_i[191:176]; end
            16'b0001000000000000  : begin valid_ii = valid_i[12]; data_ii = data_i[207:192]; end
            16'b0010000000000000  : begin valid_ii = valid_i[13]; data_ii = data_i[223:208]; end
            16'b0100000000000000  : begin valid_ii = valid_i[14]; data_ii = data_i[239:224]; end
            16'b1000000000000000  : begin valid_ii = valid_i[15]; data_ii = data_i[255:240]; end
            default               : begin valid_ii = 1'b0;        data_ii = 16'h0000;        end
        endcase
    end
        
    assign dataout = data_ii;
    assign valid_o = valid_ii;
    //-------------------------------------
    // Debug ILAs
    //-------------------------------------
    /*
    ila_shift_align ila_3
    (
        .clk    (clk           ),
        .probe0 (sync_count[0] ),
        .probe1 (sync_count[1] ), 
        .probe2 (sync_count[2] ),
        .probe3 (sync_count[3] ),
        .probe4 (sync_count[4] ),
        .probe5 (sync_count[5] ),
        .probe6 (sync_count[6] ),
        .probe7 (sync_count[7] ),
        .probe8 (sync_count[8] ),
        .probe9 (sync_count[9] ),
        .probe10(sync_count[10]), 
        .probe11(sync_count[11]),
        .probe12(sync_count[12]),
        .probe13(sync_count[13]),
        .probe14(sync_count[14]),
        .probe15(sync_count[15]),
        .probe16(locked_i      )
    ); 
    */
    

endmodule
