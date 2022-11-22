//----------------------------------------------------------------
// Engineer: Lev Kurilenko
// Date: 4/13/2018
// Module: aurora_tx_four_lane
// Description: Four Lane instantiation of the Aurora Tx core
//----------------------------------------------------------------
`timescale 1ps/1ps

module aurora_tx_four_lane 
(
    input           reset       ,
    input           clk         ,       // Logic clock 

    output  [3:0]   data_next   ,       // Block requests more data_in
    
    // 4 x 64-bit parallel input with 4 x 2-bit data type
    input   [63:0]  data_in[4]  ,
    input   [ 1:0]  sync   [4]  ,

    // High speed serial differential output
    input           clk_tx      ,       // Serial output clock. Data output rate is twice this clock frequency
    output  [3:0]   data_out_p  ,       // Differential pad outputs
    output  [3:0]   data_out_n
);


    genvar i;

    logic [65:0] data_in_full [4];      // Four 66-bit words with sync and data

    //----------------------------------------------------------------
    // Combine 2-bit syncs and 64-bit datas into four 66-bit words
    //----------------------------------------------------------------
    assign data_in_full[3][65:64] = sync[3];
    assign data_in_full[2][65:64] = sync[2];
    assign data_in_full[1][65:64] = sync[1];
    assign data_in_full[0][65:64] = sync[0];


    assign data_in_full[3][63:0] = data_in[3];
    assign data_in_full[2][63:0] = data_in[2];
    assign data_in_full[1][63:0] = data_in[1];
    assign data_in_full[0][63:0] = data_in[0];


    //----------------------------------------------------------------
    //  Instantiation of 4 channels
    //----------------------------------------------------------------
    generate

        for (i = 0 ; i <= 3 ; i = i+1) begin

            begin : g_tx_lanes

                aurora_tx_lane128   u_aurora_tx_lane128   // (VHDL)
                (
                    .reset          (reset              ),  // in  std_logic;
                    .clk            (clk                ),  // in  std_logic;   Logic clock for parallel input data

                    .request_tx_data(data_next[i]       ),  // out std_logic;
                    .tx_data_in     (data_in_full[i]    ),  // in  std_logic_vector(65 downto 0);

                    // Serial output
                    .clk_tx         (clk_tx             ),  // in  std_logic; Clock for high speed serial links. Output is DDR i.e. 2x this clock
                    .dataout_p      (data_out_p[i]      ),  // out std_logic;
                    .dataout_n      (data_out_n[i]      )   // out std_logic;
                );
            end
        end

    endgenerate


endmodule