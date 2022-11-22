//-------------------------------------------------------------------
// The purpose of this module is to process all data, excluding trigger 
// data, coming from chip_output.sv. Some of the commands that are directed
// toward front end chips are simply flagged on their respective
// output flags. Other commands, like reading and writing to the
// configuration registers, change the state of the system, e.g.
// a write to address 0 will change the value in the register
// at zero, which a read of address 0 will reflect.
//
// Note: Only partial implementation for 'pulse' and 'cal' commands,
//       beyond countdown
//
// testing file: command_process.do
//-------------------------------------------------------------------

`timescale 1ps/1ps
`include "RD53B_const_regmap.v"
`include "RD53B_const_io_encode.v"


module command_process(
   
    input               reset               ,
    input               clk                 , 

    input       [3:0]   chip_id             ,

    input               data_in_valid       ,
    input       [7:0]   data_in             ,
                        
    // Pulses for received commands. Used for debug
    output reg          cmd_clear           , 
                        cmd_pulse           , 
                        cmd_cal             , 
                        cmd_wrreg           , 
                        cmd_rdreg           , 
                        cmd_sync            ,

    // Result of register read command. Reg content and address output
    output reg          rdreg_valid         ,
    output reg  [15:0]  rdreg_data          ,
    output reg   [8:0]  rdreg_addr          ,

    // Auto read data, send to command_out block
    output reg  [7:0][25:0] auto_read_o     ,

    // Unused outputs. Reserved for future use?
    output reg          cal_edge            , 
                        cal_aux 
); 
    // States
    localparam  S_NEUTRAL   = 4'd0, 
                S_PULSE     = 4'd1, 
                S_CAL       = 4'd2, 
                S_WRREG     = 4'd3, 
                S_NOOP      = 4'd4, 
                S_RDREG     = 4'd5, 
                S_SYNC      = 4'd6, 
                S_CLEAR     = 4'd7;


    // Command encodings, found in RD53B command protocol:
    localparam  CMD_CLEAR       = 8'h5A, 
                CMD_G_PULSE     = 8'h5C,   // Global pulse
                CMD_CAL         = 8'h63,  
                CMD_NOOP        = 8'hAA, 
                CMD_RDREG       = 8'h65,
                CMD_WRREG       = 8'h66, 
                CMD_SYNC_PAT    = 16'b1000_0001_0111_1110;

    reg [3:0]   state;
    reg [3:0]   state_storage_sync;      // State storage during sync process
    reg [3:0]   state_storage_noop;

    reg [4:0]   dataword;

    reg [15:0]  config_reg [137:0]; // Configuration and status registers, 138 addresses
    reg [8:0]   config_reg_addr;   
    reg [15:0]  config_reg_write;

    reg [4:0]   words_left;         // Data words left to be processed
    reg [4:0]   words_store;        // Storage during sync process
    reg [4:0]   cnt_global_pulse;  
    reg [7:0]   cnt_cal_edge;
    reg [4:0]   cal_aux_delay;  
    reg [4:0]   cal_edge_delay;

    reg         cal_pulse;
    reg         cal_aux_active; 
    reg         cmd_noop;    
     

    //-------------------------------------------------------------------
    // TODO Probably an RD53A function.  Check this function and reg used
    // Incrementing counter to approximately 1 GHz (8 * 160MHz = 1.28 GHz).
    // This counter is used when setting config_reg[114][15:3]
    //-------------------------------------------------------------------    
    //logic   [11:0]  count; 
    //always_ff @(posedge clk) begin
    //    if (reset | cmd_pulse)
    //        count <= 0;
    //    else
    //        count <= count + 8; 
    //end

 
    //-------------------------------------------------------------------
    // TODO Probably an RD53A function.  Check this function and reg used
    // num_pulses used when setting config_reg[114][3:0],
    // and increments here every time a new pulse command is received
    //-------------------------------------------------------------------
    //logic [3:0] num_pulses;
    //always_ff @(posedge clk) begin
    //    if (reset) begin
    //        num_pulses  <= 0;
    //    end 
    //    else if (cmd_pulse) begin
    //        num_pulses  <= num_pulses + 1;
    //    end
    //end


    //-------------------------------------------------------------------
    // Auto_read register addresses
    // A set of eight config register address/data pairs is output.
    // The set are chosen by values in other config registers.
    //-------------------------------------------------------------------
    always_ff @(posedge clk)
    begin
       auto_read_o[0] <= {config_reg[`ADR_REG_AUTOREAD0][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD0]]};
       auto_read_o[1] <= {config_reg[`ADR_REG_AUTOREAD1][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD1]]};                                                
       auto_read_o[2] <= {config_reg[`ADR_REG_AUTOREAD2][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD2]]};
       auto_read_o[3] <= {config_reg[`ADR_REG_AUTOREAD3][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD3]]};
       auto_read_o[4] <= {config_reg[`ADR_REG_AUTOREAD4][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD4]]};
       auto_read_o[5] <= {config_reg[`ADR_REG_AUTOREAD5][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD5]]};
       auto_read_o[6] <= {config_reg[`ADR_REG_AUTOREAD6][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD6]]};
       auto_read_o[7] <= {config_reg[`ADR_REG_AUTOREAD7][9:0], config_reg[config_reg[`ADR_REG_AUTOREAD7]]};
    end


    //-------------------------------------------------------------------
    // Data stream decoding
    // note: encodings can be found in RD53B_Main6 Table 18
    //-------------------------------------------------------------------
    always @(*) begin : decode_dataword
        if      (data_in == `ENC_DATA_00)      dataword = 5'd0;
        else if (data_in == `ENC_DATA_01)      dataword = 5'd1;
        else if (data_in == `ENC_DATA_02)      dataword = 5'd2;
        else if (data_in == `ENC_DATA_03)      dataword = 5'd3;
        else if (data_in == `ENC_DATA_04)      dataword = 5'd4;
        else if (data_in == `ENC_DATA_05)      dataword = 5'd5;
        else if (data_in == `ENC_DATA_06)      dataword = 5'd6;
        else if (data_in == `ENC_DATA_07)      dataword = 5'd7;
        else if (data_in == `ENC_DATA_08)      dataword = 5'd8;
        else if (data_in == `ENC_DATA_09)      dataword = 5'd9;
        else if (data_in == `ENC_DATA_10)      dataword = 5'd10;
        else if (data_in == `ENC_DATA_11)      dataword = 5'd11;
        else if (data_in == `ENC_DATA_12)      dataword = 5'd12;
        else if (data_in == `ENC_DATA_13)      dataword = 5'd13;
        else if (data_in == `ENC_DATA_14)      dataword = 5'd14;
        else if (data_in == `ENC_DATA_15)      dataword = 5'd15;
        else if (data_in == `ENC_DATA_16)      dataword = 5'd16;
        else if (data_in == `ENC_DATA_17)      dataword = 5'd17;
        else if (data_in == `ENC_DATA_18)      dataword = 5'd18;
        else if (data_in == `ENC_DATA_19)      dataword = 5'd19;
        else if (data_in == `ENC_DATA_20)      dataword = 5'd20;
        else if (data_in == `ENC_DATA_21)      dataword = 5'd21;
        else if (data_in == `ENC_DATA_22)      dataword = 5'd22;
        else if (data_in == `ENC_DATA_23)      dataword = 5'd23;
        else if (data_in == `ENC_DATA_24)      dataword = 5'd24;
        else if (data_in == `ENC_DATA_25)      dataword = 5'd25;
        else if (data_in == `ENC_DATA_26)      dataword = 5'd26;
        else if (data_in == `ENC_DATA_27)      dataword = 5'd27;
        else if (data_in == `ENC_DATA_28)      dataword = 5'd28;
        else if (data_in == `ENC_DATA_29)      dataword = 5'd29;
        else if (data_in == `ENC_DATA_30)      dataword = 5'd30;
        else if (data_in == `ENC_DATA_31)      dataword = 5'd31;
   		else                                   dataword = 5'd31;
    end : decode_dataword


    //-------------------------------------------------------------------
    // Main module logic: 
    // This block decoded data_in values to look for command and 
    // then executes appropriate actions such as reading and writing registers.
    // This can be expanded to perform actions on other commands later.
    //-------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin        

        if (reset) begin
            cmd_clear           <= 1'b0;
            cmd_wrreg           <= 1'b0;
            cmd_rdreg           <= 1'b0;
            cmd_sync            <= 1'b0;
            cmd_cal             <= 1'b0;
            cmd_noop            <= 1'b0;
            
            rdreg_data          <= 16'b0;
            rdreg_addr          <=  9'b0;

            state               <= S_NEUTRAL;
            state_storage_sync  <= S_NEUTRAL;
            state_storage_noop  <= S_NEUTRAL;
            words_store         <= 5'd0;
            
            config_reg_addr     <= 9'b0;
            config_reg_write    <= 16'b0;

            cnt_global_pulse    <= 5'b0;
            cmd_pulse           <= 1'b0;
            words_left          <= 5'b0;
            
            cnt_cal_edge        <= 8'd0;
            cal_aux_delay       <= 5'd0;
            cal_edge_delay      <= 5'd0;
            cal_pulse           <= 1'b1;
            cal_aux_active      <= 1'b0;
            cal_edge            <= 1'b0;
            cal_aux             <= 1'b0;

            //--------------------------------------------------------------------------------------------------------------------------------------------------------------
            // Initialize all registers at reset
            //--------------------------------------------------------------------------------------------------------------------------------------------------------------
            config_reg[`ADR_REG_PIX_PORTAL               ]  <= `DEF_PIX_PORTAL               ;
            config_reg[`ADR_REG_REGION_COL               ]  <= `DEF_REGION_COL               ;
            config_reg[`ADR_REG_REGION_ROW               ]  <= `DEF_REGION_ROW               ;
            config_reg[`ADR_REG_PIX_MODE                 ]  <= `DEF_PIX_MODE                 ;
            config_reg[`ADR_REG_PIX_DEFAULT_CONFIG       ]  <= `DEF_PIX_DEFAULT_CONFIG       ;
            config_reg[`ADR_REG_PIX_DEFAULT_CONFIG_B     ]  <= `DEF_PIX_DEFAULT_CONFIG_B     ;
            config_reg[`ADR_REG_GCR_DEFAULT_CONFIG       ]  <= `DEF_GCR_DEFAULT_CONFIG       ;
            config_reg[`ADR_REG_GCR_DEFAULT_CONFIG_B     ]  <= `DEF_GCR_DEFAULT_CONFIG_B     ;
            
            // Analog Front End [5 ]
            config_reg[`ADR_REG_DAC_PREAMP_L_DIFF        ]  <= `DEF_DAC_PREAMP_L_DIFF        ;
            config_reg[`ADR_REG_DAC_PREAMP_R_DIFF        ]  <= `DEF_DAC_PREAMP_R_DIFF        ;
            config_reg[`ADR_REG_DAC_PREAMP_TL_DIFF       ]  <= `DEF_DAC_PREAMP_TL_DIFF       ;
            config_reg[`ADR_REG_DAC_PREAMP_TR_DIFF       ]  <= `DEF_DAC_PREAMP_TR_DIFF       ;
            config_reg[`ADR_REG_DAC_PREAMP_T_DIFF        ]  <= `DEF_DAC_PREAMP_T_DIFF        ;
            config_reg[`ADR_REG_DAC_PREAMP_M_DIFF        ]  <= `DEF_DAC_PREAMP_M_DIFF        ;
            config_reg[`ADR_REG_DAC_PRECOMP_DIFF         ]  <= `DEF_DAC_PRECOMP_DIFF         ;
            config_reg[`ADR_REG_DAC_COMP_DIFF            ]  <= `DEF_DAC_COMP_DIFF            ;
            config_reg[`ADR_REG_DAC_VFF_DIFF             ]  <= `DEF_DAC_VFF_DIFF             ;
            config_reg[`ADR_REG_DAC_TH1_L_DIFF           ]  <= `DEF_DAC_TH1_L_DIFF           ;
            config_reg[`ADR_REG_DAC_TH1_R_DIFF           ]  <= `DEF_DAC_TH1_R_DIFF           ;
            config_reg[`ADR_REG_DAC_TH1_M_DIFF           ]  <= `DEF_DAC_TH1_M_DIFF           ;
            config_reg[`ADR_REG_DAC_TH2_DIFF             ]  <= `DEF_DAC_TH2_DIFF             ;
            config_reg[`ADR_REG_DAC_LCC_DIFF             ]  <= `DEF_DAC_LCC_DIFF             ;
            config_reg[`ADR_REG_DAC_PREAMP_L_LIN         ]  <= `DEF_DAC_PREAMP_L_LIN         ;
            config_reg[`ADR_REG_DAC_PREAMP_R_LIN         ]  <= `DEF_DAC_PREAMP_R_LIN         ;
            config_reg[`ADR_REG_DAC_PREAMP_TL_LIN        ]  <= `DEF_DAC_PREAMP_TL_LIN        ;
            config_reg[`ADR_REG_DAC_PREAMP_TR_LIN        ]  <= `DEF_DAC_PREAMP_TR_LIN        ;
            config_reg[`ADR_REG_DAC_PREAMP_T_LIN         ]  <= `DEF_DAC_PREAMP_T_LIN         ;
            config_reg[`ADR_REG_DAC_PREAMP_M_LIN         ]  <= `DEF_DAC_PREAMP_M_LIN         ;
            config_reg[`ADR_REG_DAC_FC_LIN               ]  <= `DEF_DAC_FC_LIN               ;
            config_reg[`ADR_REG_DAC_KRUM_CURR_LIN        ]  <= `DEF_DAC_KRUM_CURR_LIN        ;
            config_reg[`ADR_REG_DAC_REF_KRUM_LIN         ]  <= `DEF_DAC_REF_KRUM_LIN         ;
            config_reg[`ADR_REG_DAC_COMP_LIN             ]  <= `DEF_DAC_COMP_LIN             ;
            config_reg[`ADR_REG_DAC_COMP_TA_LIN          ]  <= `DEF_DAC_COMP_TA_LIN          ;
            config_reg[`ADR_REG_DAC_GDAC_L_LIN           ]  <= `DEF_DAC_GDAC_L_LIN           ;
            config_reg[`ADR_REG_DAC_GDAC_R_LIN           ]  <= `DEF_DAC_GDAC_R_LIN           ;
            config_reg[`ADR_REG_DAC_GDAC_M_LIN           ]  <= `DEF_DAC_GDAC_M_LIN           ;
            config_reg[`ADR_REG_DAC_LDAC_LIN             ]  <= `DEF_DAC_LDAC_LIN             ;
            config_reg[`ADR_REG_LEAKAGE_FEEDBACK         ]  <= `DEF_LEAKAGE_FEEDBACK         ;
            
            // Internal Power [4 ]
            config_reg[`ADR_REG_VOLTAGE_TRIM             ]  <= `DEF_VOLTAGE_TRIM             ;
            
            // Pixel Matrix Control
            config_reg[`ADR_REG_ENCORECOL_3              ]  <= `DEF_ENCORECOL_3              ;
            config_reg[`ADR_REG_ENCORECOL_2              ]  <= `DEF_ENCORECOL_2              ;
            config_reg[`ADR_REG_ENCORECOL_1              ]  <= `DEF_ENCORECOL_1              ;
            config_reg[`ADR_REG_ENCORECOL_0              ]  <= `DEF_ENCORECOL_0              ;
            config_reg[`ADR_REG_ENCORECOLUMNRESET_3      ]  <= `DEF_ENCORECOLUMNRESET_3      ;
            config_reg[`ADR_REG_ENCORECOLUMNRESET_2      ]  <= `DEF_ENCORECOLUMNRESET_2      ;
            config_reg[`ADR_REG_ENCORECOLUMNRESET_1      ]  <= `DEF_ENCORECOLUMNRESET_1      ;
            config_reg[`ADR_REG_ENCORECOLUMNRESET_0      ]  <= `DEF_ENCORECOLUMNRESET_0      ;
            config_reg[`ADR_REG_TRIGGERCONFIG            ]  <= `DEF_TRIGGERCONFIG            ;
            config_reg[`ADR_REG_SELFTRIGGERCONFIG_1      ]  <= `DEF_SELFTRIGGERCONFIG_1      ;
            config_reg[`ADR_REG_SELFTRIGGERCONFIG_0      ]  <= `DEF_SELFTRIGGERCONFIG_0      ;
            config_reg[`ADR_REG_HITORPATTERNLUT          ]  <= `DEF_HITORPATTERNLUT          ;
            config_reg[`ADR_REG_READTRIGGERCONFIG        ]  <= `DEF_READTRIGGERCONFIG        ;
            config_reg[`ADR_REG_TRUNCATIONTIMEOUTCONF    ]  <= `DEF_TRUNCATIONTIMEOUTCONF    ;
            config_reg[`ADR_REG_CALIBRATIONCONFIG        ]  <= `DEF_CALIBRATIONCONFIG        ;
            config_reg[`ADR_REG_CLK_DATA_FINE_DELAY      ]  <= `DEF_CLK_DATA_FINE_DELAY      ;
            config_reg[`ADR_REG_VCAL_HIGH                ]  <= `DEF_VCAL_HIGH                ;
            config_reg[`ADR_REG_VCAL_MED                 ]  <= `DEF_VCAL_MED                 ;
            config_reg[`ADR_REG_MEAS_CAP                 ]  <= `DEF_MEAS_CAP                 ;
            config_reg[`ADR_REG_CDRCONF                  ]  <= `DEF_CDRCONF                  ;
            config_reg[`ADR_REG_CHSYNCCONF               ]  <= `DEF_CHSYNCCONF               ;
            config_reg[`ADR_REG_GLOBALPULSECONF          ]  <= `DEF_GLOBALPULSECONF          ;
            config_reg[`ADR_REG_GLOBALPULSEWIDTH         ]  <= `DEF_GLOBALPULSEWIDTH         ;
            config_reg[`ADR_REG_SERVICEDATACONF          ]  <= `DEF_SERVICEDATACONF          ;
            config_reg[`ADR_REG_TOTCONFIG                ]  <= `DEF_TOTCONFIG                ;
            config_reg[`ADR_REG_PRECISIONTOTENABLE_3     ]  <= `DEF_PRECISIONTOTENABLE_3     ;
            config_reg[`ADR_REG_PRECISIONTOTENABLE_2     ]  <= `DEF_PRECISIONTOTENABLE_2     ;
            config_reg[`ADR_REG_PRECISIONTOTENABLE_1     ]  <= `DEF_PRECISIONTOTENABLE_1     ;
            config_reg[`ADR_REG_PRECISIONTOTENABLE_0     ]  <= `DEF_PRECISIONTOTENABLE_0     ;
            config_reg[`ADR_REG_DATAMERGING              ]  <= `DEF_DATAMERGING              ;
            config_reg[`ADR_REG_DATAMERGINGMUX           ]  <= `DEF_DATAMERGINGMUX           ;
            config_reg[`ADR_REG_ENCORECOLUMNCALIBRATION_3]  <= `DEF_ENCORECOLUMNCALIBRATION_3;
            config_reg[`ADR_REG_ENCORECOLUMNCALIBRATION_2]  <= `DEF_ENCORECOLUMNCALIBRATION_2;
            config_reg[`ADR_REG_ENCORECOLUMNCALIBRATION_1]  <= `DEF_ENCORECOLUMNCALIBRATION_1;
            config_reg[`ADR_REG_ENCORECOLUMNCALIBRATION_0]  <= `DEF_ENCORECOLUMNCALIBRATION_0;
            config_reg[`ADR_REG_DATACONCENTRATORCONF     ]  <= `DEF_DATACONCENTRATORCONF     ;
            config_reg[`ADR_REG_CORECOLENCODERCONF       ]  <= `DEF_CORECOLENCODERCONF       ;
            config_reg[`ADR_REG_EVENMASK                 ]  <= `DEF_EVENMASK                 ;
            config_reg[`ADR_REG_ODDMASK                  ]  <= `DEF_ODDMASK                  ;
            config_reg[`ADR_REG_EFUSESCONFIG             ]  <= `DEF_EFUSESCONFIG             ;
            config_reg[`ADR_REG_EFUSESWRITEDATA1         ]  <= `DEF_EFUSESWRITEDATA1         ;
            config_reg[`ADR_REG_EFUSESWRITEDATA0         ]  <= `DEF_EFUSESWRITEDATA0         ;
            config_reg[`ADR_REG_AURORACONFIG             ]  <= `DEF_AURORACONFIG             ;
            config_reg[`ADR_REG_AURORA_CB_CONFIG1        ]  <= `DEF_AURORA_CB_CONFIG1        ;
            config_reg[`ADR_REG_AURORA_CB_CONFIG0        ]  <= `DEF_AURORA_CB_CONFIG0        ;
            config_reg[`ADR_REG_AURORA_INIT_WAIT         ]  <= `DEF_AURORA_INIT_WAIT         ;
            config_reg[`ADR_REG_OUTPUT_PAD_CONFIG        ]  <= `DEF_OUTPUT_PAD_CONFIG        ;
            config_reg[`ADR_REG_GP_CMOS_ROUTE            ]  <= `DEF_GP_CMOS_ROUTE            ;
            config_reg[`ADR_REG_GP_LVDS_ROUTE_1          ]  <= `DEF_GP_LVDS_ROUTE_1          ;
            config_reg[`ADR_REG_GP_LVDS_ROUTE_0          ]  <= `DEF_GP_LVDS_ROUTE_0          ;
            config_reg[`ADR_REG_DAC_CP_CDR               ]  <= `DEF_DAC_CP_CDR               ;
            config_reg[`ADR_REG_DAC_CP_FD_CDR            ]  <= `DEF_DAC_CP_FD_CDR            ;
            config_reg[`ADR_REG_DAC_CP_BUFF_CDR          ]  <= `DEF_DAC_CP_BUFF_CDR          ;
            config_reg[`ADR_REG_DAC_VCO_CDR              ]  <= `DEF_DAC_VCO_CDR              ;
            config_reg[`ADR_REG_DAC_VCOBUFF_CDR          ]  <= `DEF_DAC_VCOBUFF_CDR          ;
            config_reg[`ADR_REG_SER_SEL_OUT              ]  <= `DEF_SER_SEL_OUT              ;
            config_reg[`ADR_REG_CML_CONFIG               ]  <= `DEF_CML_CONFIG               ;
            config_reg[`ADR_REG_DAC_CML_BIAS_2           ]  <= `DEF_DAC_CML_BIAS_2           ;
            config_reg[`ADR_REG_DAC_CML_BIAS_1           ]  <= `DEF_DAC_CML_BIAS_1           ;
            config_reg[`ADR_REG_DAC_CML_BIAS_0           ]  <= `DEF_DAC_CML_BIAS_0           ;
            
            // Monitoring and Testing                  
            config_reg[`ADR_REG_MONITORCONFIG            ]  <= `DEF_MONITORCONFIG            ;
            config_reg[`ADR_REG_ERRWNGMASK               ]  <= `DEF_ERRWNGMASK               ;
            config_reg[`ADR_REG_MON_SENS_SLDO            ]  <= `DEF_MON_SENS_SLDO            ;
            config_reg[`ADR_REG_MON_SENS_ACB             ]  <= `DEF_MON_SENS_ACB             ;
            config_reg[`ADR_REG_MON_ADC                  ]  <= `DEF_MON_ADC                  ;
            config_reg[`ADR_REG_DAC_NTC                  ]  <= `DEF_DAC_NTC                  ;
            config_reg[`ADR_REG_HITOR_MASK_3             ]  <= `DEF_HITOR_MASK_3             ;
            config_reg[`ADR_REG_HITOR_MASK_2             ]  <= `DEF_HITOR_MASK_2             ;
            config_reg[`ADR_REG_HITOR_MASK_1             ]  <= `DEF_HITOR_MASK_1             ;
            config_reg[`ADR_REG_HITOR_MASK_0             ]  <= `DEF_HITOR_MASK_0             ;
            config_reg[`ADR_REG_AUTOREAD0                ]  <= `DEF_AUTOREAD0                ;
            config_reg[`ADR_REG_AUTOREAD1                ]  <= `DEF_AUTOREAD1                ;
            config_reg[`ADR_REG_AUTOREAD2                ]  <= `DEF_AUTOREAD2                ;
            config_reg[`ADR_REG_AUTOREAD3                ]  <= `DEF_AUTOREAD3                ;
            config_reg[`ADR_REG_AUTOREAD4                ]  <= `DEF_AUTOREAD4                ;
            config_reg[`ADR_REG_AUTOREAD5                ]  <= `DEF_AUTOREAD5                ;
            config_reg[`ADR_REG_AUTOREAD6                ]  <= `DEF_AUTOREAD6                ;
            config_reg[`ADR_REG_AUTOREAD7                ]  <= `DEF_AUTOREAD7                ;
            config_reg[`ADR_REG_RINGOSCCONFIG            ]  <= `DEF_RINGOSCCONFIG            ;
            config_reg[`ADR_REG_RINGOSCROUTE             ]  <= `DEF_RINGOSCROUTE             ;
            config_reg[`ADR_REG_RING_OSC_A_OUT           ]  <= `DEF_RING_OSC_A_OUT           ;
            config_reg[`ADR_REG_RING_OSC_B_OUT           ]  <= `DEF_RING_OSC_B_OUT           ;
            config_reg[`ADR_REG_BCIDCNT                  ]  <= `DEF_BCIDCNT                  ;
            config_reg[`ADR_REG_TRIGCNT                  ]  <= `DEF_TRIGCNT                  ;
            config_reg[`ADR_REG_READTRIGCNT              ]  <= `DEF_READTRIGCNT              ;
            config_reg[`ADR_REG_LOCKLOSSCNT              ]  <= `DEF_LOCKLOSSCNT              ;
            config_reg[`ADR_REG_BITFLIPWNGCNT            ]  <= `DEF_BITFLIPWNGCNT            ;
            config_reg[`ADR_REG_BITFLIPERRCNT            ]  <= `DEF_BITFLIPERRCNT            ;
            config_reg[`ADR_REG_CMDERRCNT                ]  <= `DEF_CMDERRCNT                ;
            config_reg[`ADR_REG_RDWRFIFOERRORCOUNT       ]  <= `DEF_RDWRFIFOERRORCOUNT       ;
            config_reg[`ADR_REG_AI_REGION_ROW            ]  <= `DEF_AI_REGION_ROW            ;
            config_reg[`ADR_REG_HITOR_3_CNT              ]  <= `DEF_HITOR_3_CNT              ;
            config_reg[`ADR_REG_HITOR_2_CNT              ]  <= `DEF_HITOR_2_CNT              ;
            config_reg[`ADR_REG_HITOR_1_CNT              ]  <= `DEF_HITOR_1_CNT              ;
            config_reg[`ADR_REG_HITOR_0_CNT              ]  <= `DEF_HITOR_0_CNT              ;
            config_reg[`ADR_REG_SKIPPEDTRIGGERCNT        ]  <= `DEF_SKIPPEDTRIGGERCNT        ;
            config_reg[`ADR_REG_EFUSESREADDATA1          ]  <= `DEF_EFUSESREADDATA1          ;
            config_reg[`ADR_REG_EFUSESREADDATA0          ]  <= `DEF_EFUSESREADDATA0          ;
            config_reg[`ADR_REG_MONITORINGDATAADC        ]  <= `DEF_MONITORINGDATAADC        ;
            // SEU registers not implemented
        end            

        else begin  

            // Count pulse commands ?
            if (cnt_global_pulse != 5'b0) begin
               cnt_global_pulse    <= cnt_global_pulse - 1;
               cmd_pulse           <= 1'b1;
            end
            else begin
               cmd_pulse           <= 1'b0;
            end
            
            if (|cal_edge_delay) begin   
               cal_edge_delay <= cal_edge_delay - 5'b1;
            end            
            else if ((|cnt_cal_edge) | (~cal_pulse)) begin 
            // if pulse is still active, or step
               cal_edge        <= 1'b1;
               if (|cnt_cal_edge) 
                    cnt_cal_edge  <= cnt_cal_edge - 5'b1;
            end 

            if (|cal_aux_delay) begin
               cal_aux_delay     <= cal_aux_delay - 5'b1;
            end
            else if (cal_aux_active) begin
               cal_aux         <= 1'b1;
            end

            // We want to set these signals low in the neutral state 
            // even if there is no new incoming data
            if (state == S_NEUTRAL) begin

                cmd_clear   <= 1'b0;
                cmd_pulse   <= 1'b0;
                cmd_cal     <= 1'b0;
                cmd_wrreg   <= 1'b0;
                cmd_rdreg   <= 1'b0;
                cmd_sync    <= 1'b0;
                cmd_noop    <= 1'b0;

                rdreg_valid <= 1'b0;
            end

            if (data_in_valid) begin

                if (words_left) begin 
                    words_left <= words_left - 1;   //<= this assignment doesnot work  
                end

                if (data_in == CMD_SYNC_PAT[15:8] & cmd_sync == 0) begin
                    cmd_sync           <= 1'b1;
                    state              <= S_SYNC;
                    state_storage_sync <= state;
                    words_left         <= 5'b0;
                    words_store        <= words_left;
                end 

                else if (data_in == CMD_NOOP & cmd_noop == 1'b0) begin
                    cmd_noop        <= 1'b1;
                    state           <= S_NOOP;
                    words_left      <= 5'b0;
                    words_store     <= words_left;

                    // This makes it so we do not store back to back NOOPs creating a NOOP loop
                    if (state != S_NOOP) begin
                        state_storage_noop   <= state;
                    end else begin
                        state_storage_noop   <= state_storage_noop;
                    end
                end 

                else begin
                    case (state) 

                        //-----------------------------------------------------------
                        // Receive of the first half of a SYNC command,
                        // because SYNC is a 16b signal compared to other 8b commands
                        //-----------------------------------------------------------
                        S_SYNC : begin

                            if (words_left == 5'd0) begin
                                if (data_in == CMD_SYNC_PAT[7:0]) begin
                                    cmd_sync    <= 1'b0;
                                    state       <= state_storage_sync;
                                    words_left  <= words_store;
                                end

                                else begin
                                    $display("ASSERTION FAILED at %d, state = %d, sync mismatch", $time, state);
                                end
                            end

                            else begin  // invalid, notify simulator
                                $display("ASSERTION FAILED at %d, state = %d, words_left too large", $time, state);
                            end
                        end

                        //-----------------------------------------------------------
                        // Upon receipt of a PLLlock, or "no operation," command
                        //-----------------------------------------------------------
                        S_NOOP : begin

                            if (words_left == 5'd0) begin
                                if (data_in != CMD_NOOP) begin
                                    $display("Repeated command not found in state %d, time %d", state, $time);
                                end 

                                else begin
                                    cmd_noop    <= 1'b0;
                                    state       <= state_storage_noop;
                                    words_left  <= words_store;
                                end
                            end
                        end

                        //-----------------------------------------------------------
                        // Words_left determined by required data words 
                        // corresponding to the state being set:
                        //-----------------------------------------------------------
                        S_NEUTRAL : begin

                            if (data_in == CMD_CLEAR) begin               
                                state       <= S_CLEAR;
                                words_left  <= 5'd0;
                            end

                            else if (data_in == CMD_G_PULSE) begin
                                state       <= S_PULSE;
                                words_left  <= 5'd0;
                            end

                            else if (data_in == CMD_CAL) begin
                                state       <= S_CAL;
                                words_left  <= 5'd4;
                            end

                            else if (data_in == CMD_RDREG) begin
                                state       <= S_RDREG;
                                words_left  <= 5'd2;        // Changed from 5'd3 
                            end

                            else if (data_in == CMD_WRREG) begin 
                                state       <= S_WRREG;
                                words_left  <= 5'd6;
                            end
                        end
                        
                        //-----------------------------------------------------------
                        // Upon receipt of a CLEAR command.
                        //-----------------------------------------------------------
                        S_CLEAR : begin

                            if (!(dataword[4] | (dataword[3:0] == chip_id[3:0]))) begin  // if ID does not match
                                cmd_clear   <= 1'b0;
                                words_left  <= 5'b0;
                                $display("Chip ID mismatch at %d", $time);
                            end

                            else begin
                                cmd_clear       <= 1'b1;
                            end
                            state       <= S_NEUTRAL;  
                        end
                                            
                        //-----------------------------------------------------------
                        // Upon receipt of a GLOBAL PULSE command. Not fully implemented;
                        // Loads cnt_global_pulse register based on second word, and 
                        // returns control to neutral.globalpulsecount flags
                        // reg pulse and counts down. 
                        //----------------------------------------------------------- 
                        S_PULSE : begin

                            if (!(dataword[4] | (dataword[3:0] == chip_id[3:0]))) begin  // if ID does not match
                                state   <= S_NEUTRAL;
                                $display("Chip ID mismatch at %d", $time);
                            end 

                            else begin
                                cmd_pulse   <= 1'b1;
                            end

                            words_left  <= 5'b0;
                            state = S_NEUTRAL;
                            // Use the duration register to set the cnt_global_pulse
                            cnt_global_pulse <= 1'b1; // Which configreg[?]
                        end 
                        
                        //-----------------------------------------------------------
                        // Upon receipt of a CAL command. Since there is no bunch crossing clock
                        // in the emulator, bunch crossings are approximated using the recovered clock.
                        // Note: CAL not fully implemented
                        //-----------------------------------------------------------
                        S_CAL : begin

                            if (words_left == 5'd4) begin
                                // if ID doesn't match
                                if (!(dataword[4] | (dataword[3:0] == chip_id[3:0]))) begin 
                                    state       <= S_NEUTRAL;
                                    words_left  <= 5'b0;
                                    $display("Chip ID mismatch at %d", $time);
                                end 

                                else begin
                                    cmd_cal         <= 1'b1;
                                end
                            end
                            
                            else if (words_left == 5'd3) begin
                                cal_pulse               <= dataword[4];
                                cal_edge_delay[4:0]     <= 2 * dataword[3:0];  // counts down at 40Mhz, therefore value set to 4x
                            end

                            else if (words_left == 5'd2) begin
                                cal_edge_delay[0]       <= dataword[0];  
                                cnt_cal_edge[7:4]       <= 2 * dataword;
                            end

                            else if (words_left == 5'd1) begin
                                cal_aux_active          <= dataword[0];
                                cnt_cal_edge[3:0]       <= 2 * dataword[4:1];
                            end

                            else if (words_left == 5'd0) begin
                                cal_aux_delay           <= 2 * dataword[4:0];
                                state                   <= S_NEUTRAL;
                            end

                            else begin  // invalid, notify simulator
                                $display("ASSERTION FAILED at %d, state = %d, words_left too large", $time, state);
                            end
                        end

                        //-----------------------------------------------------------
                        // Read data from a config register.
                        //-----------------------------------------------------------
                        S_RDREG : begin

                            if (words_left == 5'd2) begin
                                if (!(dataword[4] | (dataword[3:0] == chip_id[3:0]))) begin  // if ID doesn't match
                                    state       <= S_NEUTRAL;
                                    words_left  <= 5'b0;
                                    $display("Chip ID mismatch at %d", $time);
                                end

                                else begin
                                    cmd_rdreg       <= 1'b1;
                                end
                            end

                            else if (words_left == 5'd1) begin
                                config_reg_addr[8:5]        <= dataword[3:0];
                                if (dataword[4] != 1'b0) begin
                                    $display("ASSERTION FAILED at %d, state = %d, dataword[4] != 0", $time, state);
                                end
                            end

                            else if (words_left == 5'd0) begin
                                rdreg_valid                 <= 1'b1;
                                config_reg_addr[4:0]        <= dataword;
                                rdreg_data                  <= config_reg[{config_reg_addr[8:5], dataword}];
                                rdreg_addr                  <= {config_reg_addr[8:5], dataword};

                                $display("New read at %d, addr %h", $time, {config_reg_addr[8:5], dataword});
                                cmd_rdreg                   <= 1'b0;
                                state                       <= S_NEUTRAL;
                            end

                            else begin  // invalid, notify simulator
                                $display("ASSERTION FAILED at %d, state = %d, words_left too large", $time, state);
                            end
                        end
                        
                        //-----------------------------------------------------------
                        // Write data to a config register
                        //-----------------------------------------------------------
                        S_WRREG : begin

                            if (words_left == 5'd6) begin
                                if (!(dataword[4] | (dataword[3:0] == chip_id[3:0]))) begin  // if ID doesn't match
                                    state           <= S_NEUTRAL;
                                    words_left      <= 5'b0;
                                    cmd_wrreg       <= 1'b0;
                                    $display("Chip ID mismatch at %d", $time);
                                end

                                else begin 
                                    cmd_wrreg       <= 1'b1;
                                end
                            end 

                            else if (words_left == 5'd5) begin
                                config_reg_addr[8:5]        <= dataword;
                                if (dataword[4] != 1'b0) begin
                                    $display("ASSERTION FAILED at %d, state = %d, dataword[4] != 0", $time, state);
                                end
                            end

                            else if (words_left == 5'd4) begin
                                config_reg_addr[4:0]        <= dataword;
                            end

                            else if (words_left == 5'd3) begin
                                config_reg_write[15:11]     <= dataword;
                            end

                            else if (words_left == 5'd2) begin
                                config_reg_write[10:6]      <= dataword;
                            end

                            else if (words_left == 5'd1) begin
                                config_reg_write[5:1]       <= dataword;
                            end

                            // On last word of command, write to the selected register
                            else if (words_left == 5'd0) begin
                                config_reg[config_reg_addr]    <= {config_reg_write[15:1], dataword[4]};
                                state           <= S_NEUTRAL;
                                cmd_wrreg       <= 1'b0;

                                if (dataword[3:0] != 4'b0) begin
                                    $display("ASSERTION FAILED at %d, state = %d, dataword[3:0] != 4'b0", $time, state);
                                end

                                $display("New write at %d, adx %h: %h", $time, config_reg_addr,
                                    {config_reg_write[15:1], dataword[4]}); 
                            end

                            else begin  // invalid, notify simulator
                                $display("ASSERTION FAILED at %d, state = %d, words_left too large", $time, state);
                            end
                        end

                        //-----------------------------------------------------------
                        // Default for 'state' case statement
                        //-----------------------------------------------------------
                        default : begin
                            cmd_clear   <= 1'b0;
                            cmd_pulse   <= 1'b0;
                            cmd_cal     <= 1'b0;
                            cmd_wrreg   <= 1'b0;
                            cmd_rdreg   <= 1'b0;
                            cmd_sync    <= 1'b0;
                            
                            rdreg_valid <= 1'b0;
                            
                            state       <= S_NEUTRAL;
                            words_left  <= 5'd0;      
                            
                            $display("UNKNOWN COMMAND at %d", $time);      
                        end
                    endcase
                end  // else (!sync)
            end  // data_in_valid
        end // not reset  
                
        // Count down the global pulse, ignores data_in_valid
        // TODO: take out reset case, test to see if it still works
        if (reset) begin
            cnt_global_pulse    <= 5'b0;
            cmd_pulse           <= 1'b0;
        end
        else if (cnt_global_pulse != 5'b0) begin
            cnt_global_pulse    <= cnt_global_pulse - 1;
            cmd_pulse           <= 1'b1;
        end
        else begin
            cmd_pulse           <= 1'b0;
        end
        
        // Decrement words left
        if (reset) begin
            words_left <= 5'b0;
        end
        else if (data_in_valid && words_left) begin 
            words_left  = words_left - 1;   
        end

        // Count down cal, approximated to match Bunch Crossing (BX) clock
        if (reset) begin
            cnt_cal_edge        <= 8'd0;
            cal_aux_delay       <= 5'd0;
            cal_edge_delay      <= 5'd0;
            cal_pulse           <= 1'b1;
            cal_aux_active      <= 1'b0;
            cal_edge            <= 1'b0;
            cal_aux             <= 1'b0;
        end
        else begin
            if (|cal_edge_delay) begin   
                cal_edge_delay <= cal_edge_delay - 5'b1;
            end

            else if ((|cnt_cal_edge) | (~cal_pulse)) begin 
                // if pulse is still active, or step
                cal_edge        <= 1'b1;
                if (|cnt_cal_edge) 
                    cnt_cal_edge  <= cnt_cal_edge - 5'b1;
            end 

            if (|cal_aux_delay) begin
                cal_aux_delay     <= cal_aux_delay - 5'b1;
            end

            else if (cal_aux_active) begin
                cal_aux         <= 1'b1;
            end
        end

    end   // End of main command processing


    //---------------------------------------------------------------
    // ILA for probing combinational logic and current state
    //---------------------------------------------------------------
   
//    ila_command_process u_ila_command_process 
//    (
//        .clk            (clk  )             ,
//        .probe0         (cmd_sync       )   ,
//        .probe1         (cmd_wrreg      )   ,
//        .probe2         (cmd_rdreg      )   ,
//        .probe3         (cmd_cal        )   ,  
//        .probe4         (config_reg_addr)   ,
//        .probe5         (config_reg_write)  ,
//        .probe6         (data_in)           ,
//        .probe7         (rdreg_data)        ,
//        .probe8         (data_in_valid)     ,
//        .probe9         (dataword)          ,
//        .probe10        (state)             ,
//        .probe11        (words_left)        ,
//        .probe12        (cmd_pulse)         ,
//        .probe13        (config_reg[114])   ,
//        .probe14        (state_storage_sync)     
//    );
    
    
 
endmodule
