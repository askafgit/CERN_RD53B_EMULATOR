----------------------------------------------------------------------------------------
-- Project       : RD53B Emulator
-- File          : rd53b_tb_pkg.vhd
-- Description   : Package file for RD53B testbench
-- Author        : gjones
----------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;

use     work.rd53b_fpga_pkg.all;
use     work.rd53b_regmap_pkg.all;

package rd53b_tb_pkg is

-- A type for holding an array of the configuration and status registers in the FPGA, 138 addresses
type   t_arr_config_reg     is array (0 to 137) of std_logic_vector(15 downto 0);


----------------------------------------------------------------------------
-- Function Prototypes
----------------------------------------------------------------------------

-------------------------------------------------------------------------
-- Delay
-------------------------------------------------------------------------
procedure clk_delay     (
    signal   clk        : in    std_logic;
    constant nclks      : in    integer
);

-------------------------------------------------------------------------
-- Print a string with no time or instance path.
-------------------------------------------------------------------------
procedure cpu_print_msg (constant   msg     : in    string  );

-------------------------------------------------------------------------
-- Procedure to check expected hit data output from receiver
-------------------------------------------------------------------------
procedure check_hitdata (
    signal   clk                        : in  std_logic;
    signal   hitdata_dv                 : in  std_logic;
    signal   hitdata_rcv                : in  std_logic_vector(63 downto 0);    -- Actual data received
    constant hitdata_exp                : in  std_logic_vector(63 downto 0);    -- Expected data
    signal   fail                       : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to initialize the testbench copy (mirror) of the FPGA config regs
-------------------------------------------------------------------------
procedure init_config_regs  ( signal    arr_config_reg  : out t_arr_config_reg );

-------------------------------------------------------------------------
-- Procedure to send a trigger comand
-------------------------------------------------------------------------
procedure cmd_trigger       (
    signal   clk                        : in  std_logic;
    constant ntrig                      : in  integer;  -- Value 0 to 15
    constant ntagbase                   : in  integer;  -- 6-bit value 0 to 53

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to send a register write command
-- Address is std_logic_vector
-------------------------------------------------------------------------
procedure cmd_wr_reg    (
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant addr                       : in  std_logic_vector( 8 downto 0);
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to send a register write command
-- Address is integer
-------------------------------------------------------------------------
procedure cmd_wr_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to send a register read command
-- Address is std_logic_vector
-------------------------------------------------------------------------
procedure cmd_rd_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant addr                       : in  std_logic_vector( 8 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to send a register read command
-- Address is integer
-------------------------------------------------------------------------
procedure cmd_rd_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
);


-------------------------------------------------------------------------
-- Procedure to set the expected addr/data from a register read command
-------------------------------------------------------------------------
procedure set_rd_reg_exp(
    signal   clk                        : in  std_logic;

    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   rdexp_addr                 : out std_logic_vector( 9 downto 0);
    signal   rdexp_data                 : out std_logic_vector(15 downto 0);
    signal   rdexp_dv                   : out std_logic
);


-------------------------------------------------------------------------
-- Procedure to set an expected autoread addr/data pair
-------------------------------------------------------------------------
procedure set_autoread_exp(
    signal   clk                        : in  std_logic;

    constant nindex                     : in  integer;      -- 0 to 7
    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   exp_index                  : out integer;
    signal   exp_addr                   : out std_logic_vector( 9 downto 0);
    signal   exp_data                   : out std_logic_vector(15 downto 0);
    signal   exp_dv                     : out std_logic
);

-------------------------------------------------------------------------
-- Procedure to test the expected addr/data from a register read command
-- This procedure sends a register-read command and also updates the expected values
-------------------------------------------------------------------------
procedure cmd_rd_reg_test(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;
    constant exp_data                   : in  std_logic_vector(15 downto 0);

    signal   txdata                     : out std_logic_vector(15 downto 0);
    signal   txdata_dv                  : out std_logic;
    signal   ready                      : in  std_logic;                    -- Set high to continue
    signal   rdexp_addr                 : out std_logic_vector( 9 downto 0);
    signal   rdexp_data                 : out std_logic_vector(15 downto 0);
    signal   rdexp_dv                   : out std_logic
);


end package rd53b_tb_pkg;

--------------------------------------------------------------------------------
-- Package Body
--------------------------------------------------------------------------------
package body rd53b_tb_pkg is

-------------------------------------------------------------------------
-- Delay
-------------------------------------------------------------------------
procedure clk_delay( 
    signal   clk    : in  std_logic;
    constant nclks  : in  integer
) is
begin
    for I in 0 to nclks loop
        wait until clk'event and clk ='0';
    end loop;
end;


-------------------------------------------------------------------------
-- Print a string with no time or instance path.
-------------------------------------------------------------------------
procedure cpu_print_msg(
    constant msg    : in    string
) is
variable line_out   : line;
begin
    write(line_out, msg);
    writeline(output, line_out);
end procedure cpu_print_msg;


-------------------------------------------------------------------------
-- Procedure to check expected hit data output from receiver
-------------------------------------------------------------------------
procedure check_hitdata(
    signal   clk                        : in  std_logic;
    signal   hitdata_dv                 : in  std_logic;
    signal   hitdata_rcv                : in  std_logic_vector(63 downto 0);    -- Actual data received
    constant hitdata_exp                : in  std_logic_vector(63 downto 0);    -- Expected data
    signal   fail                       : out std_logic
) is
begin

    if (hitdata_dv = '1') then -- user data output
        if (hitdata_rcv = hitdata_exp) then
            cpu_print_msg("PASS HITDATA");
            fail    <= '0';
        else
            cpu_print_msg("FAIL HITDATA           *****");
            fail    <= '1';
        end if;
    end if;

end;

-------------------------------------------------------------------------
-- Procedure to initialize the config reg mirror
-------------------------------------------------------------------------
procedure init_config_regs(
    signal   arr_config_reg             : out t_arr_config_reg
) is
begin

    ----------------------------------------------------------------------------------------
    -- Initialize all registers at reset
    ----------------------------------------------------------------------------------------
    arr_config_reg(ADR_REG_PIX_PORTAL               )  <= DEF_REG_PIX_PORTAL               ;
    arr_config_reg(ADR_REG_REGION_COL               )  <= DEF_REG_REGION_COL               ;
    arr_config_reg(ADR_REG_REGION_ROW               )  <= DEF_REG_REGION_ROW               ;
    arr_config_reg(ADR_REG_PIX_MODE                 )  <= DEF_REG_PIX_MODE                 ;
    arr_config_reg(ADR_REG_PIX_DEFAULT_CONFIG       )  <= DEF_REG_PIX_DEFAULT_CONFIG       ;
    arr_config_reg(ADR_REG_PIX_DEFAULT_CONFIG_B     )  <= DEF_REG_PIX_DEFAULT_CONFIG_B     ;
    arr_config_reg(ADR_REG_GCR_DEFAULT_CONFIG       )  <= DEF_REG_GCR_DEFAULT_CONFIG       ;
    arr_config_reg(ADR_REG_GCR_DEFAULT_CONFIG_B     )  <= DEF_REG_GCR_DEFAULT_CONFIG_B     ;
    
    -- Analog Front End (5 )
    arr_config_reg(ADR_REG_DAC_PREAMP_L_DIFF        )  <= DEF_REG_DAC_PREAMP_L_DIFF        ;
    arr_config_reg(ADR_REG_DAC_PREAMP_R_DIFF        )  <= DEF_REG_DAC_PREAMP_R_DIFF        ;
    arr_config_reg(ADR_REG_DAC_PREAMP_TL_DIFF       )  <= DEF_REG_DAC_PREAMP_TL_DIFF       ;
    arr_config_reg(ADR_REG_DAC_PREAMP_TR_DIFF       )  <= DEF_REG_DAC_PREAMP_TR_DIFF       ;
    arr_config_reg(ADR_REG_DAC_PREAMP_T_DIFF        )  <= DEF_REG_DAC_PREAMP_T_DIFF        ;
    arr_config_reg(ADR_REG_DAC_PREAMP_M_DIFF        )  <= DEF_REG_DAC_PREAMP_M_DIFF        ;
    arr_config_reg(ADR_REG_DAC_PRECOMP_DIFF         )  <= DEF_REG_DAC_PRECOMP_DIFF         ;
    arr_config_reg(ADR_REG_DAC_COMP_DIFF            )  <= DEF_REG_DAC_COMP_DIFF            ;
    arr_config_reg(ADR_REG_DAC_VFF_DIFF             )  <= DEF_REG_DAC_VFF_DIFF             ;
    arr_config_reg(ADR_REG_DAC_TH1_L_DIFF           )  <= DEF_REG_DAC_TH1_L_DIFF           ;
    arr_config_reg(ADR_REG_DAC_TH1_R_DIFF           )  <= DEF_REG_DAC_TH1_R_DIFF           ;
    arr_config_reg(ADR_REG_DAC_TH1_M_DIFF           )  <= DEF_REG_DAC_TH1_M_DIFF           ;
    arr_config_reg(ADR_REG_DAC_TH2_DIFF             )  <= DEF_REG_DAC_TH2_DIFF             ;
    arr_config_reg(ADR_REG_DAC_LCC_DIFF             )  <= DEF_REG_DAC_LCC_DIFF             ;
    arr_config_reg(ADR_REG_DAC_PREAMP_L_LIN         )  <= DEF_REG_DAC_PREAMP_L_LIN         ;
    arr_config_reg(ADR_REG_DAC_PREAMP_R_LIN         )  <= DEF_REG_DAC_PREAMP_R_LIN         ;
    arr_config_reg(ADR_REG_DAC_PREAMP_TL_LIN        )  <= DEF_REG_DAC_PREAMP_TL_LIN        ;
    arr_config_reg(ADR_REG_DAC_PREAMP_TR_LIN        )  <= DEF_REG_DAC_PREAMP_TR_LIN        ;
    arr_config_reg(ADR_REG_DAC_PREAMP_T_LIN         )  <= DEF_REG_DAC_PREAMP_T_LIN         ;
    arr_config_reg(ADR_REG_DAC_PREAMP_M_LIN         )  <= DEF_REG_DAC_PREAMP_M_LIN         ;
    arr_config_reg(ADR_REG_DAC_FC_LIN               )  <= DEF_REG_DAC_FC_LIN               ;
    arr_config_reg(ADR_REG_DAC_KRUM_CURR_LIN        )  <= DEF_REG_DAC_KRUM_CURR_LIN        ;
    arr_config_reg(ADR_REG_DAC_REF_KRUM_LIN         )  <= DEF_REG_DAC_REF_KRUM_LIN         ;
    arr_config_reg(ADR_REG_DAC_COMP_LIN             )  <= DEF_REG_DAC_COMP_LIN             ;
    arr_config_reg(ADR_REG_DAC_COMP_TA_LIN          )  <= DEF_REG_DAC_COMP_TA_LIN          ;
    arr_config_reg(ADR_REG_DAC_GDAC_L_LIN           )  <= DEF_REG_DAC_GDAC_L_LIN           ;
    arr_config_reg(ADR_REG_DAC_GDAC_R_LIN           )  <= DEF_REG_DAC_GDAC_R_LIN           ;
    arr_config_reg(ADR_REG_DAC_GDAC_M_LIN           )  <= DEF_REG_DAC_GDAC_M_LIN           ;
    arr_config_reg(ADR_REG_DAC_LDAC_LIN             )  <= DEF_REG_DAC_LDAC_LIN             ;
    arr_config_reg(ADR_REG_LEAKAGE_FEEDBACK         )  <= DEF_REG_LEAKAGE_FEEDBACK         ;
    
    -- Internal Power (4 )
    arr_config_reg(ADR_REG_VOLTAGE_TRIM             )  <= DEF_REG_VOLTAGE_TRIM             ;
    
    -- Pixel Matrix Control
    arr_config_reg(ADR_REG_ENCORECOL_3              )  <= DEF_REG_ENCORECOL_3              ;
    arr_config_reg(ADR_REG_ENCORECOL_2              )  <= DEF_REG_ENCORECOL_2              ;
    arr_config_reg(ADR_REG_ENCORECOL_1              )  <= DEF_REG_ENCORECOL_1              ;
    arr_config_reg(ADR_REG_ENCORECOL_0              )  <= DEF_REG_ENCORECOL_0              ;
    arr_config_reg(ADR_REG_ENCORECOLUMNRESET_3      )  <= DEF_REG_ENCORECOLUMNRESET_3      ;
    arr_config_reg(ADR_REG_ENCORECOLUMNRESET_2      )  <= DEF_REG_ENCORECOLUMNRESET_2      ;
    arr_config_reg(ADR_REG_ENCORECOLUMNRESET_1      )  <= DEF_REG_ENCORECOLUMNRESET_1      ;
    arr_config_reg(ADR_REG_ENCORECOLUMNRESET_0      )  <= DEF_REG_ENCORECOLUMNRESET_0      ;
    arr_config_reg(ADR_REG_TRIGGERCONFIG            )  <= DEF_REG_TRIGGERCONFIG            ;
    arr_config_reg(ADR_REG_SELFTRIGGERCONFIG_1      )  <= DEF_REG_SELFTRIGGERCONFIG_1      ;
    arr_config_reg(ADR_REG_SELFTRIGGERCONFIG_0      )  <= DEF_REG_SELFTRIGGERCONFIG_0      ;
    arr_config_reg(ADR_REG_HITORPATTERNLUT          )  <= DEF_REG_HITORPATTERNLUT          ;
    arr_config_reg(ADR_REG_READTRIGGERCONFIG        )  <= DEF_REG_READTRIGGERCONFIG        ;
    arr_config_reg(ADR_REG_TRUNCATIONTIMEOUTCONF    )  <= DEF_REG_TRUNCATIONTIMEOUTCONF    ;
    arr_config_reg(ADR_REG_CALIBRATIONCONFIG        )  <= DEF_REG_CALIBRATIONCONFIG        ;
    arr_config_reg(ADR_REG_CLK_DATA_FINE_DELAY      )  <= DEF_REG_CLK_DATA_FINE_DELAY      ;
    arr_config_reg(ADR_REG_VCAL_HIGH                )  <= DEF_REG_VCAL_HIGH                ;
    arr_config_reg(ADR_REG_VCAL_MED                 )  <= DEF_REG_VCAL_MED                 ;
    arr_config_reg(ADR_REG_MEAS_CAP                 )  <= DEF_REG_MEAS_CAP                 ;
    arr_config_reg(ADR_REG_CDRCONF                  )  <= DEF_REG_CDRCONF                  ;
    arr_config_reg(ADR_REG_CHSYNCCONF               )  <= DEF_REG_CHSYNCCONF               ;
    arr_config_reg(ADR_REG_GLOBALPULSECONF          )  <= DEF_REG_GLOBALPULSECONF          ;
    arr_config_reg(ADR_REG_GLOBALPULSEWIDTH         )  <= DEF_REG_GLOBALPULSEWIDTH         ;
    arr_config_reg(ADR_REG_SERVICEDATACONF          )  <= DEF_REG_SERVICEDATACONF          ;
    arr_config_reg(ADR_REG_TOTCONFIG                )  <= DEF_REG_TOTCONFIG                ;
    arr_config_reg(ADR_REG_PRECISIONTOTENABLE_3     )  <= DEF_REG_PRECISIONTOTENABLE_3     ;
    arr_config_reg(ADR_REG_PRECISIONTOTENABLE_2     )  <= DEF_REG_PRECISIONTOTENABLE_2     ;
    arr_config_reg(ADR_REG_PRECISIONTOTENABLE_1     )  <= DEF_REG_PRECISIONTOTENABLE_1     ;
    arr_config_reg(ADR_REG_PRECISIONTOTENABLE_0     )  <= DEF_REG_PRECISIONTOTENABLE_0     ;
    arr_config_reg(ADR_REG_DATAMERGING              )  <= DEF_REG_DATAMERGING              ;
    arr_config_reg(ADR_REG_DATAMERGINGMUX           )  <= DEF_REG_DATAMERGINGMUX           ;
    arr_config_reg(ADR_REG_ENCORECOLUMNCALIBRATION_3)  <= DEF_REG_ENCORECOLUMNCALIBRATION_3;
    arr_config_reg(ADR_REG_ENCORECOLUMNCALIBRATION_2)  <= DEF_REG_ENCORECOLUMNCALIBRATION_2;
    arr_config_reg(ADR_REG_ENCORECOLUMNCALIBRATION_1)  <= DEF_REG_ENCORECOLUMNCALIBRATION_1;
    arr_config_reg(ADR_REG_ENCORECOLUMNCALIBRATION_0)  <= DEF_REG_ENCORECOLUMNCALIBRATION_0;
    arr_config_reg(ADR_REG_DATACONCENTRATORCONF     )  <= DEF_REG_DATACONCENTRATORCONF     ;
    arr_config_reg(ADR_REG_CORECOLENCODERCONF       )  <= DEF_REG_CORECOLENCODERCONF       ;
    arr_config_reg(ADR_REG_EVENMASK                 )  <= DEF_REG_EVENMASK                 ;
    arr_config_reg(ADR_REG_ODDMASK                  )  <= DEF_REG_ODDMASK                  ;
    arr_config_reg(ADR_REG_EFUSESCONFIG             )  <= DEF_REG_EFUSESCONFIG             ;
    arr_config_reg(ADR_REG_EFUSESWRITEDATA1         )  <= DEF_REG_EFUSESWRITEDATA1         ;
    arr_config_reg(ADR_REG_EFUSESWRITEDATA0         )  <= DEF_REG_EFUSESWRITEDATA0         ;
    arr_config_reg(ADR_REG_AURORACONFIG             )  <= DEF_REG_AURORACONFIG             ;
    arr_config_reg(ADR_REG_AURORA_CB_CONFIG1        )  <= DEF_REG_AURORA_CB_CONFIG1        ;
    arr_config_reg(ADR_REG_AURORA_CB_CONFIG0        )  <= DEF_REG_AURORA_CB_CONFIG0        ;
    arr_config_reg(ADR_REG_AURORA_INIT_WAIT         )  <= DEF_REG_AURORA_INIT_WAIT         ;
    arr_config_reg(ADR_REG_OUTPUT_PAD_CONFIG        )  <= DEF_REG_OUTPUT_PAD_CONFIG        ;
    arr_config_reg(ADR_REG_GP_CMOS_ROUTE            )  <= DEF_REG_GP_CMOS_ROUTE            ;
    arr_config_reg(ADR_REG_GP_LVDS_ROUTE_1          )  <= DEF_REG_GP_LVDS_ROUTE_1          ;
    arr_config_reg(ADR_REG_GP_LVDS_ROUTE_0          )  <= DEF_REG_GP_LVDS_ROUTE_0          ;
    arr_config_reg(ADR_REG_DAC_CP_CDR               )  <= DEF_REG_DAC_CP_CDR               ;
    arr_config_reg(ADR_REG_DAC_CP_FD_CDR            )  <= DEF_REG_DAC_CP_FD_CDR            ;
    arr_config_reg(ADR_REG_DAC_CP_BUFF_CDR          )  <= DEF_REG_DAC_CP_BUFF_CDR          ;
    arr_config_reg(ADR_REG_DAC_VCO_CDR              )  <= DEF_REG_DAC_VCO_CDR              ;
    arr_config_reg(ADR_REG_DAC_VCOBUFF_CDR          )  <= DEF_REG_DAC_VCOBUFF_CDR          ;
    arr_config_reg(ADR_REG_SER_SEL_OUT              )  <= DEF_REG_SER_SEL_OUT              ;
    arr_config_reg(ADR_REG_CML_CONFIG               )  <= DEF_REG_CML_CONFIG               ;
    arr_config_reg(ADR_REG_DAC_CML_BIAS_2           )  <= DEF_REG_DAC_CML_BIAS_2           ;
    arr_config_reg(ADR_REG_DAC_CML_BIAS_1           )  <= DEF_REG_DAC_CML_BIAS_1           ;
    arr_config_reg(ADR_REG_DAC_CML_BIAS_0           )  <= DEF_REG_DAC_CML_BIAS_0           ;
    
    -- Monitoring and Testing                  
    arr_config_reg(ADR_REG_MONITORCONFIG            )  <= DEF_REG_MONITORCONFIG            ;
    arr_config_reg(ADR_REG_ERRWNGMASK               )  <= DEF_REG_ERRWNGMASK               ;
    arr_config_reg(ADR_REG_MON_SENS_SLDO            )  <= DEF_REG_MON_SENS_SLDO            ;
    arr_config_reg(ADR_REG_MON_SENS_ACB             )  <= DEF_REG_MON_SENS_ACB             ;
    arr_config_reg(ADR_REG_MON_ADC                  )  <= DEF_REG_MON_ADC                  ;
    arr_config_reg(ADR_REG_DAC_NTC                  )  <= DEF_REG_DAC_NTC                  ;
    arr_config_reg(ADR_REG_HITOR_MASK_3             )  <= DEF_REG_HITOR_MASK_3             ;
    arr_config_reg(ADR_REG_HITOR_MASK_2             )  <= DEF_REG_HITOR_MASK_2             ;
    arr_config_reg(ADR_REG_HITOR_MASK_1             )  <= DEF_REG_HITOR_MASK_1             ;
    arr_config_reg(ADR_REG_HITOR_MASK_0             )  <= DEF_REG_HITOR_MASK_0             ;
    arr_config_reg(ADR_REG_AUTOREAD0                )  <= DEF_REG_AUTOREAD0                ;
    arr_config_reg(ADR_REG_AUTOREAD1                )  <= DEF_REG_AUTOREAD1                ;
    arr_config_reg(ADR_REG_AUTOREAD2                )  <= DEF_REG_AUTOREAD2                ;
    arr_config_reg(ADR_REG_AUTOREAD3                )  <= DEF_REG_AUTOREAD3                ;
    arr_config_reg(ADR_REG_AUTOREAD4                )  <= DEF_REG_AUTOREAD4                ;
    arr_config_reg(ADR_REG_AUTOREAD5                )  <= DEF_REG_AUTOREAD5                ;
    arr_config_reg(ADR_REG_AUTOREAD6                )  <= DEF_REG_AUTOREAD6                ;
    arr_config_reg(ADR_REG_AUTOREAD7                )  <= DEF_REG_AUTOREAD7                ;
    arr_config_reg(ADR_REG_RINGOSCCONFIG            )  <= DEF_REG_RINGOSCCONFIG            ;
    arr_config_reg(ADR_REG_RINGOSCROUTE             )  <= DEF_REG_RINGOSCROUTE             ;
    arr_config_reg(ADR_REG_RING_OSC_A_OUT           )  <= DEF_REG_RING_OSC_A_OUT           ;
    arr_config_reg(ADR_REG_RING_OSC_B_OUT           )  <= DEF_REG_RING_OSC_B_OUT           ;
    arr_config_reg(ADR_REG_BCIDCNT                  )  <= DEF_REG_BCIDCNT                  ;
    arr_config_reg(ADR_REG_TRIGCNT                  )  <= DEF_REG_TRIGCNT                  ;
    arr_config_reg(ADR_REG_READTRIGCNT              )  <= DEF_REG_READTRIGCNT              ;
    arr_config_reg(ADR_REG_LOCKLOSSCNT              )  <= DEF_REG_LOCKLOSSCNT              ;
    arr_config_reg(ADR_REG_BITFLIPWNGCNT            )  <= DEF_REG_BITFLIPWNGCNT            ;
    arr_config_reg(ADR_REG_BITFLIPERRCNT            )  <= DEF_REG_BITFLIPERRCNT            ;
    arr_config_reg(ADR_REG_CMDERRCNT                )  <= DEF_REG_CMDERRCNT                ;
    arr_config_reg(ADR_REG_RDWRFIFOERRORCOUNT       )  <= DEF_REG_RDWRFIFOERRORCOUNT       ;
    arr_config_reg(ADR_REG_AI_REGION_ROW            )  <= DEF_REG_AI_REGION_ROW            ;
    arr_config_reg(ADR_REG_HITOR_3_CNT              )  <= DEF_REG_HITOR_3_CNT              ;
    arr_config_reg(ADR_REG_HITOR_2_CNT              )  <= DEF_REG_HITOR_2_CNT              ;
    arr_config_reg(ADR_REG_HITOR_1_CNT              )  <= DEF_REG_HITOR_1_CNT              ;
    arr_config_reg(ADR_REG_HITOR_0_CNT              )  <= DEF_REG_HITOR_0_CNT              ;
    arr_config_reg(ADR_REG_SKIPPEDTRIGGERCNT        )  <= DEF_REG_SKIPPEDTRIGGERCNT        ;
    arr_config_reg(ADR_REG_EFUSESREADDATA1          )  <= DEF_REG_EFUSESREADDATA1          ;
    arr_config_reg(ADR_REG_EFUSESREADDATA0          )  <= DEF_REG_EFUSESREADDATA0          ;
    arr_config_reg(ADR_REG_MONITORINGDATAADC        )  <= DEF_REG_MONITORINGDATAADC        ;
    -- SEU registers not implemented

end;

-------------------------------------------------------------------------
-- Procedure to send a trigger comand
-------------------------------------------------------------------------
procedure cmd_trigger(
    signal   clk                        : in  std_logic;

    constant ntrig                      : in  integer;  -- Value 0 to 15
    constant ntagbase                   : in  integer;  -- 6-bit value 0 to 53

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
) is
begin

    wait until clk'event and clk='0'; 
    
    -- Build trigger command with tag. Tag base is NOT encoded from 6-bit to 8-bits
    -- Tag base is limited to range 0 to 53
    if    (ntagbase <  0) then
        reg     <= C_ARR_CMD_TRIGGER(ntrig) & std_logic_vector(to_unsigned(0,8));
    elsif (ntagbase > 53) then
        reg     <= C_ARR_CMD_TRIGGER(ntrig) & std_logic_vector(to_unsigned(53,8));
    else
        reg     <= C_ARR_CMD_TRIGGER(ntrig) & std_logic_vector(to_unsigned(ntagbase,8));
    end if;

    reg_dv  <= '1';

    wait until clk'event and clk='0';
    reg     <= (others=>'0');
    reg_dv  <= '0';

end;


-------------------------------------------------------------------------
-- Procedure to send a register write command
-- Address is std_logic_vector
-------------------------------------------------------------------------
procedure cmd_wr_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant addr                       : in  std_logic_vector( 8 downto 0);
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
) is
variable v_data0 : std_logic_vector(4 downto 0);
begin

    -- First word is command with chip_id. ID is encoded from 5-bit to 8-bits.
    wait until clk'event and clk='0';
    reg     <= C_CMD_WRREG_0(15 downto 8) & C_ENC_5BIT_TO_8BIT(chip_id);
    reg_dv  <= '1';

    -- Second word is {0,addr[8:5]}, addr[4:0]. Each encoded from 5-bit to 8-bits.
    wait until clk'event and clk='0';
    reg     <= std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(addr(8 downto 5))))) & std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(addr(4 downto 0)))));
    reg_dv  <= '1';

    -- Third word is data[15:11], data[10:6]. Each encoded from 5-bit to 8-bits.
    wait until clk'event and clk='0';
    reg     <= std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(data(15 downto 11))))) & std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(data(10 downto 6)))));
    reg_dv  <= '1';

    -- Fourth word is data[5:1], {data[0],0000} . Each encoded from 5-bit to 8-bits.
    v_data0 := data(0) & "0000";
    wait until clk'event and clk='0';
    reg     <= std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(data(5 downto 1))))) & std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(v_data0))));
    reg_dv  <= '1';

    wait until clk'event and clk='0';
    reg     <= (others=>'0');
    reg_dv  <= '0';

end;

-------------------------------------------------------------------------
-- Procedure to send a register write command
-- Address is integer
-------------------------------------------------------------------------
procedure cmd_wr_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
) is
variable v_reg_addr : std_logic_vector(8 downto 0);
begin
    -- convert integer address into std_logic_vector(8 downto 0)
    v_reg_addr  := std_logic_vector(to_unsigned(naddr, 9));

    cmd_wr_reg   (clk,  chip_id, v_reg_addr , data,  reg, reg_dv);

end;


-------------------------------------------------------------------------
-- Procedure to send a register read command
-- Address is std_logic_vector
-------------------------------------------------------------------------
procedure cmd_rd_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant addr                       : in  std_logic_vector( 8 downto 0);

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
) is
variable v_data0 : std_logic_vector(4 downto 0);
begin

    -- First word is command with chip_id. ID is encoded from 5-bit to 8-bits.
    wait until clk'event and clk='0';
    reg     <= C_CMD_RDREG(15 downto 8) & C_ENC_5BIT_TO_8BIT(chip_id);
    reg_dv  <= '1';

    -- Second word is {0,addr[8:5]}, addr[4:0]. Each encoded from 5-bit to 8-bits.
    wait until clk'event and clk='0';
    reg     <= std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(addr(8 downto 5))))) & std_logic_vector(C_ENC_5BIT_TO_8BIT(to_integer(unsigned(addr(4 downto 0)))));
    reg_dv  <= '1';

    wait until clk'event and clk='0';
    reg     <= (others=>'0');
    reg_dv  <= '0';

end;


-------------------------------------------------------------------------
-- Procedure to send a register read command
-- Address is integer
-------------------------------------------------------------------------
procedure cmd_rd_reg(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;

    signal   reg                        : out std_logic_vector(15 downto 0);
    signal   reg_dv                     : out std_logic
) is
variable v_reg_addr : std_logic_vector(8 downto 0);
begin
    -- convert integer address into std_logic_vector(8 downto 0)
    v_reg_addr  := std_logic_vector(to_unsigned(naddr, 9));

    cmd_rd_reg   (clk,  chip_id, v_reg_addr , reg, reg_dv);

end;


-------------------------------------------------------------------------
-- Procedure to set the expected addr/data from a register read command
-------------------------------------------------------------------------
procedure set_rd_reg_exp(
    signal   clk                        : in  std_logic;

    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   rdexp_addr                 : out std_logic_vector( 9 downto 0);
    signal   rdexp_data                 : out std_logic_vector(15 downto 0);
    signal   rdexp_dv                   : out std_logic
) is
begin

    wait until clk'event and clk='0';
    rdexp_addr  <= std_logic_vector(to_unsigned(naddr, 10)); -- Convert integer address into std_logic_vector(9 downto 0)
    rdexp_data  <= data;
    rdexp_dv    <= '1';

    wait until clk'event and clk='0';
    rdexp_dv    <= '0';

end;


-------------------------------------------------------------------------
-- Procedure to set an expected autoread addr/data pair
-------------------------------------------------------------------------
procedure set_autoread_exp(
    signal   clk                        : in  std_logic;

    constant nindex                     : in  integer;      -- 0 to 7
    constant naddr                      : in  integer;
    constant data                       : in  std_logic_vector(15 downto 0);

    signal   exp_index                  : out integer;
    signal   exp_addr                   : out std_logic_vector( 9 downto 0);
    signal   exp_data                   : out std_logic_vector(15 downto 0);
    signal   exp_dv                     : out std_logic
) is
begin

    wait until clk'event and clk='0';
    exp_index   <= nindex;
    exp_addr    <= std_logic_vector(to_unsigned(naddr, 10)); -- Convert integer address into std_logic_vector(9 downto 0)
    exp_data    <= data;
    exp_dv      <= '1';

    wait until clk'event and clk='0';
    exp_dv      <= '0';

end;


-------------------------------------------------------------------------
-- Procedure to test the expected addr/data from a register read command
-- This procedure sends a register-read command and also updates the expected values
-------------------------------------------------------------------------
procedure cmd_rd_reg_test(
    signal   clk                        : in  std_logic;

    constant chip_id                    : in  integer;
    constant naddr                      : in  integer;
    constant exp_data                   : in  std_logic_vector(15 downto 0);

    signal   txdata                     : out std_logic_vector(15 downto 0);
    signal   txdata_dv                  : out std_logic;
    signal   ready                      : in  std_logic;                    -- Set high to continue
    signal   rdexp_addr                 : out std_logic_vector( 9 downto 0);
    signal   rdexp_data                 : out std_logic_vector(15 downto 0);
    signal   rdexp_dv                   : out std_logic
) is
begin
    cmd_rd_reg      (clk,  chip_id, naddr, txdata, txdata_dv); 
    set_rd_reg_exp  (clk,  naddr,exp_data , rdexp_addr, rdexp_data, rdexp_dv);         -- Set expected readback value
    wait until ready = '1';
end;


end package body rd53b_tb_pkg;
