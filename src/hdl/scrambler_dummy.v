//========================================================================================
//=============================          SCRAMBLER           =============================
//========================================================================================
`timescale 1ps/1ps

// Scrambler that passes data through unchanged. Use for simulation. 
module scrambler #
(
    parameter TX_DATA_WIDTH = 64
)
(
    input                           clk  ,
    input                           reset,
    
    input                           enable,
    input   [1:0]                   sync_info,
    input   [0:(TX_DATA_WIDTH-1)]   data_in,
    output  [(TX_DATA_WIDTH+1):0]   data_out
);

    assign data_out = {sync_info, data_in};

endmodule