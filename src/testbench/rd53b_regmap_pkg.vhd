----------------------------------------------------------------------------------------
-- Project       : RD53B Emulator
-- File          : rd53b_regmap_pkg.vhd
-- Description   : Package file for RD53B register address map and initial reg content
-- Author        : gjones
----------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

package rd53b_regmap_pkg is

-- Last column Functions: (T)rigger and timing,     (I)nput/ouput, (C)alibration, (M)asking, () Other

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Register address values (9-bit addresses)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Name                            Addr.       Value     Size (bits)     Description                                                 Default            Function
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
constant ADR_REG_PIX_PORTAL                     : integer :=    0 ;       --  Pixel portal: virtual reg. to access pix config (8.8)       0                  
constant ADR_REG_REGION_COL                     : integer :=    1 ;       --  Pixel column pair connected to pixel portal (8.8)           0                  
constant ADR_REG_REGION_ROW                     : integer :=    2 ;       --  Pixel row connected to pixel portal (8.8)                   0                  
constant ADR_REG_PIX_MODE                       : integer :=    3 ;       --  Pix config: Broadcast, Mask(0) or TDAC(1), Auto Row         0,1,0              
constant ADR_REG_PIX_DEFAULT_CONFIG             : integer :=    4 ;       --  Key 1 of 2: hex 9CE2 to exit pix default config.            0                  
constant ADR_REG_PIX_DEFAULT_CONFIG_B           : integer :=    5 ;       --  Key 2 of 2: hex 631D to exit pix default config.            0                  
constant ADR_REG_GCR_DEFAULT_CONFIG             : integer :=    6 ;       --  Key 1 of 2: hex AC75 to exit glob default config.           0                  
constant ADR_REG_GCR_DEFAULT_CONFIG_B           : integer :=    7 ;       --  Key 2 of 2. hex 538A to exit glob default config.           0                  
 
-- Analog Front End (5)
constant ADR_REG_DAC_PREAMP_L_DIFF              : integer :=    8 ;       --  Input transistor bias for left 2 cols                       50                 
constant ADR_REG_DAC_PREAMP_R_DIFF              : integer :=    9 ;       --  Input transistor bias for right 2 cols                      50                 
constant ADR_REG_DAC_PREAMP_TL_DIFF             : integer :=   10 ;       --  Input transistor bias for top left 2x2                      50                 
constant ADR_REG_DAC_PREAMP_TR_DIFF             : integer :=   11 ;       --  Input transistor bias for top right 2x2                     50                 
constant ADR_REG_DAC_PREAMP_T_DIFF              : integer :=   12 ;       --  Input transistor bias for top 2 rows                        50                 
constant ADR_REG_DAC_PREAMP_M_DIFF              : integer :=   13 ;       --  Input transistor bias for all other pixels                  50                 
constant ADR_REG_DAC_PRECOMP_DIFF               : integer :=   14 ;       --  Precomparator tail current bias                             50                 
constant ADR_REG_DAC_COMP_DIFF                  : integer :=   15 ;       --  Comparator total current bias                               50                 
constant ADR_REG_DAC_VFF_DIFF                   : integer :=   16 ;       --  Preamp feedback (return to baseline)                        100                
constant ADR_REG_DAC_TH1_L_DIFF                 : integer :=   17 ;       --  Neg. Vth offset for left 2 cols                             100                
constant ADR_REG_DAC_TH1_R_DIFF                 : integer :=   18 ;       --  Neg. Vth offset for right 2 cols                            100                
constant ADR_REG_DAC_TH1_M_DIFF                 : integer :=   19 ;       --  Neg. Vth offset all other pixels                            100                
constant ADR_REG_DAC_TH2_DIFF                   : integer :=   20 ;       --  Pos. Vth offset for all pixels                              0                  
constant ADR_REG_DAC_LCC_DIFF                   : integer :=   21 ;       --  Leakage current compensation bias                           100                
constant ADR_REG_DAC_PREAMP_L_LIN               : integer :=   22 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_PREAMP_R_LIN               : integer :=   23 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_PREAMP_TL_LIN              : integer :=   24 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_PREAMP_TR_LIN              : integer :=   25 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_PREAMP_T_LIN               : integer :=   26 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_PREAMP_M_LIN               : integer :=   27 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_FC_LIN                     : integer :=   28 ;       --  not used in RD53B-ATLAS                                     20                 
constant ADR_REG_DAC_KRUM_CURR_LIN              : integer :=   29 ;       --  not used in RD53B-ATLAS                                     50                 
constant ADR_REG_DAC_REF_KRUM_LIN               : integer :=   30 ;       --  not used in RD53B-ATLAS                                     300                
constant ADR_REG_DAC_COMP_LIN                   : integer :=   31 ;       --  not used in RD53B-ATLAS                                     110                
constant ADR_REG_DAC_COMP_TA_LIN                : integer :=   32 ;       --  not used in RD53B-ATLAS                                     110                
constant ADR_REG_DAC_GDAC_L_LIN                 : integer :=   33 ;       --  not used in RD53B-ATLAS                                     408                
constant ADR_REG_DAC_GDAC_R_LIN                 : integer :=   34 ;       --  not used in RD53B-ATLAS                                     408                
constant ADR_REG_DAC_GDAC_M_LIN                 : integer :=   35 ;       --  not used in RD53B-ATLAS                                     408                
constant ADR_REG_DAC_LDAC_LIN                   : integer :=   36 ;       --  not used in RD53B-ATLAS                                     100                
constant ADR_REG_LEAKAGE_FEEDBACK               : integer :=   37 ;       --  enable leakage curr. Comp; low gain mode                    0,0                

-- Internal Power (4)
constant ADR_REG_VOLTAGE_TRIM                   : integer :=   38 ;       --  Regulator: En. Undershunt A, D; Ana.Vtrim, Dig.Vtrim        0,0,8,8            

-- Pixel Matrix Control
constant ADR_REG_ENCORECOL_3                    : integer :=   39 ;       --  Enable Core Columns 53:48                                   0                  
constant ADR_REG_ENCORECOL_2                    : integer :=   40 ;       --  Enable Core Columns 47:32                                   0                  
constant ADR_REG_ENCORECOL_1                    : integer :=   41 ;       --  Enable Core Column 31:16                                    0                  
constant ADR_REG_ENCORECOL_0                    : integer :=   42 ;       --  Enable Core Column 15:0                                     0                  
constant ADR_REG_ENCORECOLUMNRESET_3            : integer :=   43 ;       --  Enable Reset for core cols. 53:48                           0                  
constant ADR_REG_ENCORECOLUMNRESET_2            : integer :=   44 ;       --  Enable Reset for core cols. 47:32                           0                  
constant ADR_REG_ENCORECOLUMNRESET_1            : integer :=   45 ;       --  Enable Reset for core cols. 31:16                           0                  
constant ADR_REG_ENCORECOLUMNRESET_0            : integer :=   46 ;       --  Enable Reset for core cols. 15:0                            0                  
constant ADR_REG_TRIGGERCONFIG                  : integer :=   47 ;       --  Trigger mode, Latency (9)                                   0,500               T   
constant ADR_REG_SELFTRIGGERCONFIG_1            : integer :=   48 ;       --  Self Trig.: En., ToT thresh.: En., value (9.4)              0,1,1               T   
constant ADR_REG_SELFTRIGGERCONFIG_0            : integer :=   49 ;       --  Self Trig.: delay, multiplier (9.4)                         100,1               T   
constant ADR_REG_HITORPATTERNLUT                : integer :=   50 ;       --  Self Trig. HitOR logic program (9.4)                        0                   T   
constant ADR_REG_READTRIGGERCONFIG              : integer :=   51 ;       --  Col. Read delay, Read Trig. Decision time (BXs)             0,1000              T   
constant ADR_REG_TRUNCATIONTIMEOUTCONF          : integer :=   52 ;       --  Event truncation timeout (BXs, 0=off)                       0                   T   
constant ADR_REG_CALIBRATIONCONFIG              : integer :=   53 ;       --  Cal injection: En. Dig., En. An., fine delay                0,1,0               C   
constant ADR_REG_CLK_DATA_FINE_DELAY            : integer :=   54 ;       --  Fine delays for Clock, Data                                 0,0                 T   
constant ADR_REG_VCAL_HIGH                      : integer :=   55 ;       --  VCAL high level                                             500                 C   
constant ADR_REG_VCAL_MED                       : integer :=   56 ;       --  VCAL medium level                                           300                 C   
constant ADR_REG_MEAS_CAP                       : integer :=   57 ;       --  Cap Meas: En. Par, En.; VCAL range bit                      0,0,0               C   
constant ADR_REG_CDRCONF                        : integer :=   58 ;       --  CDR: overwrite limit, phase det sel., CLK sel.              0,0,0               I   
constant ADR_REG_CHSYNCCONF                     : integer :=   59 ;       --  Chan. Synch. Lock Thresh. (unlock is 2)                    16                  I   
constant ADR_REG_GLOBALPULSECONF                : integer :=   60 ;       --  Global pulse routing                                        0                       
constant ADR_REG_GLOBALPULSEWIDTH               : integer :=   61 ;       --  Global Pulse Width (in BX)                                  1                       
constant ADR_REG_SERVICEDATACONF                : integer :=   62 ;       --  Monitoring frame En., Period                                0,50                I   
constant ADR_REG_TOTCONFIG                      : integer :=   63 ;       --  En: PtoT, PToA, 80MHz, 6b to 4b; PToT Latency               0,0,0,0,500             
constant ADR_REG_PRECISIONTOTENABLE_3           : integer :=   64 ;       --  Enable PToT for core cols. 53:48                            0                   M   
constant ADR_REG_PRECISIONTOTENABLE_2           : integer :=   65 ;       --  Enable PToT for core cols. 47:32                            0                   M   
constant ADR_REG_PRECISIONTOTENABLE_1           : integer :=   66 ;       --  Enable PToT for core cols. 31:16                            0                   M   
constant ADR_REG_PRECISIONTOTENABLE_0           : integer :=   67 ;       --  Enable PToT for core cols. 15:0                             0                   M   
constant ADR_REG_DATAMERGING                    : integer :=   68 ;       --  D.Merge: pol, Ch.ID, 1.28 CK gate, CK sel, En, Ch.bond      0,1,1,0,0,0         I   
constant ADR_REG_DATAMERGINGMUX                 : integer :=   69 ;       --  Input and Output Lane mapping                               3,2,1,0,3,2,1,0     I   
constant ADR_REG_ENCORECOLUMNCALIBRATION_3      : integer :=   70 ;       --  CAL enable for core cols. 53:48                             6x1                 M   
constant ADR_REG_ENCORECOLUMNCALIBRATION_2      : integer :=   71 ;       --  CAL enable for core cols. 47:32                             16x1                M   
constant ADR_REG_ENCORECOLUMNCALIBRATION_1      : integer :=   72 ;       --  CAL enable for core cols. 31:16                             16x1                M   
constant ADR_REG_ENCORECOLUMNCALIBRATION_0      : integer :=   73 ;       --  CAL enable for core cols. 15:0                              16x1                M   
constant ADR_REG_DATACONCENTRATORCONF           : integer :=   74 ;       --  In stream En: BCID, L1ID, EoS marker; evts/strm             0,0,1,16            I   
constant ADR_REG_CORECOLENCODERCONF             : integer :=   75 ;       --  Drop ToT, raw map, rem. hits, MaxHits, En. Isol., MaxToT    0,0,0,0,0,0         I   
constant ADR_REG_EVENMASK                       : integer :=   76 ;       --  Isolated hit filter mask: Even cols.                        0                   I   
constant ADR_REG_ODDMASK                        : integer :=   77 ;       --  Isolated hit filter mask: Odd cols.                         0                   I   
constant ADR_REG_EFUSESCONFIG                   : integer :=   78 ;       --  Efuses En. (to Read set 0F0F, to Write set F0F0)            0                   
constant ADR_REG_EFUSESWRITEDATA1               : integer :=   79 ;       --  Data to be written to Efuses (1 of 2)                       0                   
constant ADR_REG_EFUSESWRITEDATA0               : integer :=   80 ;       --  Data to be written to Efuses (2 of 2)                       0                   
constant ADR_REG_AURORACONFIG                   : integer :=   81 ;       --  AURORA: En. PRBS, En. Lanes, CCWait, CCSend                 0,0001,25,3         I   
constant ADR_REG_AURORA_CB_CONFIG1              : integer :=   82 ;       --  Aurora Chann. Bonding Wait [19:12]                          255                 I   
constant ADR_REG_AURORA_CB_CONFIG0              : integer :=   83 ;       --  Aurora Chann. Bond Wait [11:0], CBSend                      4095,0              I   
constant ADR_REG_AURORA_INIT_WAIT               : integer :=   84 ;       --  Aurora Initialization Delay                                 32                  I   
                      
constant ADR_REG_OUTPUT_PAD_CONFIG              : integer :=   85 ;       --  GP_CMOS: pattern, En, DS, GP_LVDS: Enables, strength        5,1,0,15,7          I   
constant ADR_REG_GP_CMOS_ROUTE                  : integer :=   86 ;       --  GP_CMOS MUX select                                          34                  I   
constant ADR_REG_GP_LVDS_ROUTE_1                : integer :=   87 ;       --  GP_LVDS(3), GP_LVDS(2) MUX select                           35,33               I   
constant ADR_REG_GP_LVDS_ROUTE_0                : integer :=   88 ;       --  GP_LVDS(1), GP_LVDS(0) MUX select                           1,0                 I   
constant ADR_REG_DAC_CP_CDR                     : integer :=   89 ;       --  CDR CP Bias (values <15 are set to 15)                      40                  I   
constant ADR_REG_DAC_CP_FD_CDR                  : integer :=   90 ;       --  CDR FD CP bias (values <100 are set to 100)                 400                 I   
constant ADR_REG_DAC_CP_BUFF_CDR                : integer :=   91 ;       --  CDR unity gain buffer bias                                  200                 I   
constant ADR_REG_DAC_VCO_CDR                    : integer :=   92 ;       --  CDR VCO bias (values <700 are set to 700)                   1023                I   
constant ADR_REG_DAC_VCOBUFF_CDR                : integer :=   93 ;       --  CDR VCO buffer bias (values <200 are set to 200)            500                 I   
constant ADR_REG_SER_SEL_OUT                    : integer :=   94 ;       --  CML 3-0 content. 0=CK/2, 1=AURORA, 2=PRBS7, 3=0             1,1,1,1             I   
constant ADR_REG_CML_CONFIG                     : integer :=   95 ;       --  CML out: Inv. Tap 2,1; En. Tap 2,1; En. Lane 3,2,1,0        0,0,0001            I   
constant ADR_REG_DAC_CML_BIAS_2                 : integer :=   96 ;       --  CML drivers tap 2 amplitude (pre-emph)                      0                   I   
constant ADR_REG_DAC_CML_BIAS_1                 : integer :=   97 ;       --  CML drivers tap 1 amplitude (pre-emph)                      0                   I   
constant ADR_REG_DAC_CML_BIAS_0                 : integer :=   98 ;       --  CML drivers tap 0 amplitude (main)                          500                 I   
                     
-- Monitoring and Test
constant ADR_REG_MONITORCONFIG                  : integer :=   99 ;       --  Monitor pin: En., I. MUX sel., V. MUX sel.                  0,63,63            
constant ADR_REG_ERRWNGMASK                     : integer :=  100 ;       --  Error and Warning Message disable Mask                      0                  
constant ADR_REG_MON_SENS_SLDO                  : integer :=  101 ;       --  Reg. I. Mon.: En.A, DEM bits, Bias sel, En.D, DEM, Bias     0,0,0,0,0,0        
constant ADR_REG_MON_SENS_ACB                   : integer :=  102 ;       --  ACB I. Mon.: En., DEM bits, Bias sel.                       0,0,0              
constant ADR_REG_MON_ADC                        : integer :=  103 ;       --  Vref for Rsense: bot., top.; Vref in; ADC trim bits         0,0,0,0            
constant ADR_REG_DAC_NTC                        : integer :=  104 ;       --  Current output DAC for the external NTC                     100                
constant ADR_REG_HITOR_MASK_3                   : integer :=  105 ;       --  HitOR enable for core cols. 53:48                           0                   M 
constant ADR_REG_HITOR_MASK_2                   : integer :=  106 ;       --  HitOR enable for core cols. 47:32                           0                   M   
constant ADR_REG_HITOR_MASK_1                   : integer :=  107 ;       --  HitOR enable for core cols. 31:16                           0                   M   
constant ADR_REG_HITOR_MASK_0                   : integer :=  108 ;       --  HitOR enable for core cols. 15:0                            0                   M   
constant ADR_REG_AUTOREAD0                      : integer :=  109 ;       --  Auto-Read register address A for lane 0                     137                 I   
constant ADR_REG_AUTOREAD1                      : integer :=  110 ;       --  Auto-Read register address B for lane 0                     133                 I   
constant ADR_REG_AUTOREAD2                      : integer :=  111 ;       --  Auto-Read register address A for lane 1                     121                 I   
constant ADR_REG_AUTOREAD3                      : integer :=  112 ;       --  Auto-Read register address B for lane 1                     122                 I   
constant ADR_REG_AUTOREAD4                      : integer :=  113 ;       --  Auto-Read register address A for lane 2                     124                 I   
constant ADR_REG_AUTOREAD5                      : integer :=  114 ;       --  Auto-Read register address B for lane 2                     127                 I   
constant ADR_REG_AUTOREAD6                      : integer :=  115 ;       --  Auto-Read register address A for lane 3                     126                 I   
constant ADR_REG_AUTOREAD7                      : integer :=  116 ;       --  Auto-Read register address B for lane 3                     125                 I   
constant ADR_REG_RINGOSCCONFIG                  : integer :=  117 ;       --  Ring oscillator enable bits                                 1,5x0,1,8x0        
constant ADR_REG_RINGOSCROUTE                   : integer :=  118 ;       --  Select which RO to read from block A, B                     0,0                
constant ADR_REG_RING_OSC_A_OUT                 : integer :=  119 ;       --  Ring oscillator block A output (rd. only)                   n/a                
constant ADR_REG_RING_OSC_B_OUT                 : integer :=  120 ;       --  Ring oscillator block B output (rd. only)                   n/a                
constant ADR_REG_BCIDCNT                        : integer :=  121 ;       --  Bunch counter (rd. only)                                    n/a                
constant ADR_REG_TRIGCNT                        : integer :=  122 ;       --  Received trigger counter (rd. only)                         n/a                
constant ADR_REG_READTRIGCNT                    : integer :=  123 ;       --  Received or internal ReadTrigger ctr (rd. only)             n/a                
constant ADR_REG_LOCKLOSSCNT                    : integer :=  124 ;       --  Channel Sync lost lock counter (rd. only)                   n/a                
constant ADR_REG_BITFLIPWNGCNT                  : integer :=  125 ;       --  Bit Flip Warning counter (rd. only)                         n/a                
constant ADR_REG_BITFLIPERRCNT                  : integer :=  126 ;       --  Bit Flip Error counter (rd. only)                           n/a                
constant ADR_REG_CMDERRCNT                      : integer :=  127 ;       --  Command Decoder error message ctr (rd. only)                n/a                
constant ADR_REG_RDWRFIFOERRORCOUNT             : integer :=  128 ;       --  Writes and Reads when fifo was full ctr (rd. only)          n/a                
constant ADR_REG_AI_REGION_ROW                  : integer :=  129 ;       --  Auto Increment current row value (rd. only)                 n/a                
constant ADR_REG_HITOR_3_CNT                    : integer :=  130 ;       --  HitOr_3 Counter (rd. only)                                  n/a                
constant ADR_REG_HITOR_2_CNT                    : integer :=  131 ;       --  HitOr_2 Counter (rd. only)                                  n/a                
constant ADR_REG_HITOR_1_CNT                    : integer :=  132 ;       --  HitOr_1 Counter (rd. only)                                  n/a                
constant ADR_REG_HITOR_0_CNT                    : integer :=  133 ;       --  HitOr_0 Counter (rd. only)                                  n/a                
constant ADR_REG_SKIPPEDTRIGGERCNT              : integer :=  134 ;       --  Skipped Trigger counter (rd. only)                          n/a                
constant ADR_REG_EFUSESREADDATA1                : integer :=  135 ;       --  Readback of efuses 1 of 2 (Read Only)                       n/a                
constant ADR_REG_EFUSESREADDATA0                : integer :=  136 ;       --  Readback of efuses 2 of 2 (Read Only)                       n/a                
constant ADR_REG_MONITORINGDATAADC              : integer :=  137 ;       --  ADC value (rd. only)                                        n/a                
constant ADR_REG_SEU00_NOTMR                    : integer :=  138 ;       --  Addr 138 to 201 Dummies for SEU meas. Not triple redundant                  0                  
constant ADR_REG_SEU00                          : integer :=  202 ;       --  202 - 255 Dummies for SEU meas. Triple redundant                      0                  


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Register default values
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Name                                                                      Value     Size (bits)     Description                                                 Default            Function
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
constant DEF_REG_PIX_PORTAL                     : std_logic_vector(15 downto 0) := X"0000";   --  16          Pixel portal: virtual reg. to access pix config (8.8)       0                  
constant DEF_REG_REGION_COL                     : std_logic_vector(15 downto 0) := X"0000";   --  8           Pixel column pair connected to pixel portal (8.8)           0                  
constant DEF_REG_REGION_ROW                     : std_logic_vector(15 downto 0) := X"0000";   --  9           Pixel row connected to pixel portal (8.8)                   0                  
constant DEF_REG_PIX_MODE                       : std_logic_vector(15 downto 0) := X"0002";   --  1,1,1       Pix config: Broadcast, Mask(0) or TDAC(1), Auto Row         0,1,0              
constant DEF_REG_PIX_DEFAULT_CONFIG             : std_logic_vector(15 downto 0) := X"0000";   --  16          Key 1 of 2: hex 9CE2 to exit pix default config.            0                  
constant DEF_REG_PIX_DEFAULT_CONFIG_B           : std_logic_vector(15 downto 0) := X"0000";   --  16          Key 2 of 2: hex 631D to exit pix default config.            0                  
constant DEF_REG_GCR_DEFAULT_CONFIG             : std_logic_vector(15 downto 0) := X"0000";   --  16          Key 1 of 2: hex AC75 to exit glob default config.           0                  
constant DEF_REG_GCR_DEFAULT_CONFIG_B           : std_logic_vector(15 downto 0) := X"0000";   --  16          Key 2 of 2. hex 538A to exit glob default config.           0                  

-- Analog Front End (5)
constant DEF_REG_DAC_PREAMP_L_DIFF              : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for left 2 cols                       50                 
constant DEF_REG_DAC_PREAMP_R_DIFF              : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for right 2 cols                      50                 
constant DEF_REG_DAC_PREAMP_TL_DIFF             : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for top left 2x2                      50                 
constant DEF_REG_DAC_PREAMP_TR_DIFF             : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for top right 2x2                     50                 
constant DEF_REG_DAC_PREAMP_T_DIFF              : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for top 2 rows                        50                 
constant DEF_REG_DAC_PREAMP_M_DIFF              : std_logic_vector(15 downto 0) := X"0032";   --  10          Input transistor bias for all other pixels                  50                 
constant DEF_REG_DAC_PRECOMP_DIFF               : std_logic_vector(15 downto 0) := X"0032";   --  10          Precomparator tail current bias                             50                 
constant DEF_REG_DAC_COMP_DIFF                  : std_logic_vector(15 downto 0) := X"0032";   --  10          Comparator total current bias                               50                 
constant DEF_REG_DAC_VFF_DIFF                   : std_logic_vector(15 downto 0) := X"0064";   --  10          Preamp feedback (return to baseline)                        100                
constant DEF_REG_DAC_TH1_L_DIFF                 : std_logic_vector(15 downto 0) := X"0064";   --  10          Neg. Vth offset for left 2 cols                             100                
constant DEF_REG_DAC_TH1_R_DIFF                 : std_logic_vector(15 downto 0) := X"0064";   --  10          Neg. Vth offset for right 2 cols                            100                
constant DEF_REG_DAC_TH1_M_DIFF                 : std_logic_vector(15 downto 0) := X"0064";   --  10          Neg. Vth offset all other pixels                            100                
constant DEF_REG_DAC_TH2_DIFF                   : std_logic_vector(15 downto 0) := X"0000";   --  10          Pos. Vth offset for all pixels                              0                  
constant DEF_REG_DAC_LCC_DIFF                   : std_logic_vector(15 downto 0) := X"0064";   --  10          Leakage current compensation bias                           100                
constant DEF_REG_DAC_PREAMP_L_LIN               : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_PREAMP_R_LIN               : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_PREAMP_TL_LIN              : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_PREAMP_TR_LIN              : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_PREAMP_T_LIN               : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_PREAMP_M_LIN               : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_FC_LIN                     : std_logic_vector(15 downto 0) := X"0014";   --  10          not used in RD53B-ATLAS                                     20                 
constant DEF_REG_DAC_KRUM_CURR_LIN              : std_logic_vector(15 downto 0) := X"0032";   --  10          not used in RD53B-ATLAS                                     50                 
constant DEF_REG_DAC_REF_KRUM_LIN               : std_logic_vector(15 downto 0) := X"012C";   --  10          not used in RD53B-ATLAS                                     300                
constant DEF_REG_DAC_COMP_LIN                   : std_logic_vector(15 downto 0) := X"006E";   --  10          not used in RD53B-ATLAS                                     110                
constant DEF_REG_DAC_COMP_TA_LIN                : std_logic_vector(15 downto 0) := X"006E";   --  10          not used in RD53B-ATLAS                                     110                
constant DEF_REG_DAC_GDAC_L_LIN                 : std_logic_vector(15 downto 0) := X"0198";   --  10          not used in RD53B-ATLAS                                     408                
constant DEF_REG_DAC_GDAC_R_LIN                 : std_logic_vector(15 downto 0) := X"0198";   --  10          not used in RD53B-ATLAS                                     408                
constant DEF_REG_DAC_GDAC_M_LIN                 : std_logic_vector(15 downto 0) := X"0198";   --  10          not used in RD53B-ATLAS                                     408                
constant DEF_REG_DAC_LDAC_LIN                   : std_logic_vector(15 downto 0) := X"0064";   --  10          not used in RD53B-ATLAS                                     100                
constant DEF_REG_LEAKAGE_FEEDBACK               : std_logic_vector(15 downto 0) := X"0000";   --  1,1         enable leakage curr. Comp; low gain mode                    0,0                
                      
-- Internal Power (4)  
constant DEF_REG_VOLTAGE_TRIM                   : std_logic_vector(15 downto 0) := X"0088";   --  1,1,4,4     Regulator: En. Undershunt A, D; Ana.Vtrim, Dig.Vtrim        0,0,8,8            

-- Pixel Matrix Control 
constant DEF_REG_ENCORECOL_3                    : std_logic_vector(15 downto 0) := X"0000";   --  6x1         Enable Core Columns 53:48                                   0                  
constant DEF_REG_ENCORECOL_2                    : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Core Columns 47:32                                   0                  
constant DEF_REG_ENCORECOL_1                    : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Core Column 31:16                                    0                  
constant DEF_REG_ENCORECOL_0                    : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Core Column 15:0                                     0                  
constant DEF_REG_ENCORECOLUMNRESET_3            : std_logic_vector(15 downto 0) := X"0000";   --  6x1         Enable Reset for core cols. 53:48                           0                  
constant DEF_REG_ENCORECOLUMNRESET_2            : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Reset for core cols. 47:32                           0                  
constant DEF_REG_ENCORECOLUMNRESET_1            : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Reset for core cols. 31:16                           0                  
constant DEF_REG_ENCORECOLUMNRESET_0            : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable Reset for core cols. 15:0                            0                  
constant DEF_REG_TRIGGERCONFIG                  : std_logic_vector(15 downto 0) := X"01F4";   --  1,9         Trigger mode, Latency (9)                                   0,500               T   
constant DEF_REG_SELFTRIGGERCONFIG_1            : std_logic_vector(15 downto 0) := X"0011";   --  1,1,4       Self Trig.: En., ToT thresh.: En., value (9.4)              0,1,1               T   
constant DEF_REG_SELFTRIGGERCONFIG_0            : std_logic_vector(15 downto 0) := X"0C81";   --  10,5        Self Trig.: delay, multiplier (9.4)                         100,1               T   
constant DEF_REG_HITORPATTERNLUT                : std_logic_vector(15 downto 0) := X"0000";   --  16          Self Trig. HitOR logic program (9.4)                        0                   T   
constant DEF_REG_READTRIGGERCONFIG              : std_logic_vector(15 downto 0) := X"03E8";   --  2,12        Col. Read delay, Read Trig. Decision time (BXs)             0,1000              T   
constant DEF_REG_TRUNCATIONTIMEOUTCONF          : std_logic_vector(15 downto 0) := X"0000";   --  12          Event truncation timeout (BXs, 0=off)                       0                   T   
constant DEF_REG_CALIBRATIONCONFIG              : std_logic_vector(15 downto 0) := X"0040";   --  1,1,6       Cal injection: En. Dig., En. An., fine delay                0,1,0               C   
constant DEF_REG_CLK_DATA_FINE_DELAY            : std_logic_vector(15 downto 0) := X"0000";   --  6,6         Fine delays for Clock, Data                                 0,0                 T   
constant DEF_REG_VCAL_HIGH                      : std_logic_vector(15 downto 0) := X"01F4";   --  12          VCAL high level                                             500                 C   
constant DEF_REG_VCAL_MED                       : std_logic_vector(15 downto 0) := X"012C";   --  12          VCAL medium level                                           300                 C   
constant DEF_REG_MEAS_CAP                       : std_logic_vector(15 downto 0) := X"0000";   --  1,1,1       Cap Meas: En. Par, En.; VCAL range bit                      0,0,0               C   
constant DEF_REG_CDRCONF                        : std_logic_vector(15 downto 0) := X"0000";   --  1,1,3       CDR: overwrite limit, phase det sel., CLK sel.              0,0,0               I   
constant DEF_REG_CHSYNCCONF                     : std_logic_vector(15 downto 0) := X"0010";   --  5           Chan. Synch. Lock Thresh. (unlock is 2)                    16                  I   
constant DEF_REG_GLOBALPULSECONF                : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Global pulse routing                                        0                       
constant DEF_REG_GLOBALPULSEWIDTH               : std_logic_vector(15 downto 0) := X"0001";   --  8           Global Pulse Width (in BX)                                  1                       
constant DEF_REG_SERVICEDATACONF                : std_logic_vector(15 downto 0) := X"0032";   --  1,8         Monitoring frame En., Period                                0,50                I   
constant DEF_REG_TOTCONFIG                      : std_logic_vector(15 downto 0) := X"01F4";   --  1,1,1,1,9   En: PtoT, PToA, 80MHz, 6b to 4b; PToT Latency               0,0,0,0,500             
constant DEF_REG_PRECISIONTOTENABLE_3           : std_logic_vector(15 downto 0) := X"0000";   --  6x1         Enable PToT for core cols. 53:48                            0                   M   
constant DEF_REG_PRECISIONTOTENABLE_2           : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable PToT for core cols. 47:32                            0                   M   
constant DEF_REG_PRECISIONTOTENABLE_1           : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable PToT for core cols. 31:16                            0                   M   
constant DEF_REG_PRECISIONTOTENABLE_0           : std_logic_vector(15 downto 0) := X"0000";   --  16x1        Enable PToT for core cols. 15:0                             0                   M   
constant DEF_REG_DATAMERGING                    : std_logic_vector(15 downto 0) := X"00C0";   --  4,1,1,1,4,1 D.Merge: pol, Ch.ID, 1.28 CK gate, CK sel, En, Ch.bond      0,1,1,0,0,0         I   
constant DEF_REG_DATAMERGINGMUX                 : std_logic_vector(15 downto 0) := X"E4E4";   --  8x2         Input and Output Lane mapping                               3,2,1,0,3,2,1,0     I   
constant DEF_REG_ENCORECOLUMNCALIBRATION_3      : std_logic_vector(15 downto 0) := X"003F";   --  6x1         CAL enable for core cols. 53:48                             6x1                 M   
constant DEF_REG_ENCORECOLUMNCALIBRATION_2      : std_logic_vector(15 downto 0) := X"FFFF";   --  16x1        CAL enable for core cols. 47:32                             16x1                M   
constant DEF_REG_ENCORECOLUMNCALIBRATION_1      : std_logic_vector(15 downto 0) := X"FFFF";   --  16x1        CAL enable for core cols. 31:16                             16x1                M   
constant DEF_REG_ENCORECOLUMNCALIBRATION_0      : std_logic_vector(15 downto 0) := X"FFFF";   --  16x1        CAL enable for core cols. 15:0                              16x1                M   
constant DEF_REG_DATACONCENTRATORCONF           : std_logic_vector(15 downto 0) := X"0110";   --  1,1,1,8     In stream En: BCID, L1ID, EoS marker; evts/strm             0,0,1,16            I   
constant DEF_REG_CORECOLENCODERCONF             : std_logic_vector(15 downto 0) := X"0000";   --  1,1,1,3,1,3 Drop ToT, raw map, rem. hits, MaxHits, En. Isol., MaxToT    0,0,0,0,0,0         I   
constant DEF_REG_EVENMASK                       : std_logic_vector(15 downto 0) := X"0000";   --  16          Isolated hit filter mask: Even cols.                        0                   I   
constant DEF_REG_ODDMASK                        : std_logic_vector(15 downto 0) := X"0000";   --  16          Isolated hit filter mask: Odd cols.                         0                   I   
constant DEF_REG_EFUSESCONFIG                   : std_logic_vector(15 downto 0) := X"0000";   --  16          Efuses En. (to Read set 0F0F, to Write set F0F0)            0                   
constant DEF_REG_EFUSESWRITEDATA1               : std_logic_vector(15 downto 0) := X"0000";   --  16          Data to be written to Efuses (1 of 2)                       0                   
constant DEF_REG_EFUSESWRITEDATA0               : std_logic_vector(15 downto 0) := X"0000";   --  16          Data to be written to Efuses (2 of 2)                       0                   
constant DEF_REG_AURORACONFIG                   : std_logic_vector(15 downto 0) := X"0167";   --  1,4,6,2     AURORA: En. PRBS, En. Lanes, CCWait, CCSend                 0,0001,25,3         I   
constant DEF_REG_AURORA_CB_CONFIG1              : std_logic_vector(15 downto 0) := X"00FF";   --  8           Aurora Chann. Bonding Wait [19:12]                          255                 I   
constant DEF_REG_AURORA_CB_CONFIG0              : std_logic_vector(15 downto 0) := X"0FFF";   --  11,4        Aurora Chann. Bond Wait [11:0], CBSend                      4095,0              I   
constant DEF_REG_AURORA_INIT_WAIT               : std_logic_vector(15 downto 0) := X"0020";   --  11          Aurora Initialization Delay                                 32                  I   

constant DEF_REG_OUTPUT_PAD_CONFIG              : std_logic_vector(15 downto 0) := X"0B7F";   --  4,1,1,4,3   GP_CMOS: pattern, En, DS, GP_LVDS: Enables, strength        5,1,0,15,7          I   
constant DEF_REG_GP_CMOS_ROUTE                  : std_logic_vector(15 downto 0) := X"0022";   --  6           GP_CMOS MUX select                                          34                  I   
constant DEF_REG_GP_LVDS_ROUTE_1                : std_logic_vector(15 downto 0) := X"08E1";   --  6,6         GP_LVDS(3), GP_LVDS(2) MUX select                           35,33               I   
constant DEF_REG_GP_LVDS_ROUTE_0                : std_logic_vector(15 downto 0) := X"0040";   --  6,6         GP_LVDS(1), GP_LVDS(0) MUX select                           1,0                 I   
constant DEF_REG_DAC_CP_CDR                     : std_logic_vector(15 downto 0) := X"0037";   --  10          CDR CP Bias (values <15 are set to 15)                      40                  I   
constant DEF_REG_DAC_CP_FD_CDR                  : std_logic_vector(15 downto 0) := X"0190";   --  10          CDR FD CP bias (values <100 are set to 100)                 400                 I   
constant DEF_REG_DAC_CP_BUFF_CDR                : std_logic_vector(15 downto 0) := X"00C8";   --  10          CDR unity gain buffer bias                                  200                 I   
constant DEF_REG_DAC_VCO_CDR                    : std_logic_vector(15 downto 0) := X"03FF";   --  10          CDR VCO bias (values <700 are set to 700)                   1023                I   
constant DEF_REG_DAC_VCOBUFF_CDR                : std_logic_vector(15 downto 0) := X"01F4";   --  10          CDR VCO buffer bias (values <200 are set to 200)            500                 I   
constant DEF_REG_SER_SEL_OUT                    : std_logic_vector(15 downto 0) := X"0055";   --  4x2         CML 3-0 content. 0=CK/2, 1=AURORA, 2=PRBS7, 3=0             1,1,1,1             I   
constant DEF_REG_CML_CONFIG                     : std_logic_vector(15 downto 0) := X"0001";   --  2,2,4       CML out: Inv. Tap 2,1; En. Tap 2,1; En. Lane 3,2,1,0        0,0,0001            I   
constant DEF_REG_DAC_CML_BIAS_2                 : std_logic_vector(15 downto 0) := X"0000";   --  10          CML drivers tap 2 amplitude (pre-emph)                      0                   I   
constant DEF_REG_DAC_CML_BIAS_1                 : std_logic_vector(15 downto 0) := X"0000";   --  10          CML drivers tap 1 amplitude (pre-emph)                      0                   I   
constant DEF_REG_DAC_CML_BIAS_0                 : std_logic_vector(15 downto 0) := X"01F4";   --  10          CML drivers tap 0 amplitude (main)                          500                 I   
                    
-- Monitoring and Test
constant DEF_REG_MONITORCONFIG                  : std_logic_vector(15 downto 0) := X"0FFF";   --  1,6,6       Monitor pin: En., I. MUX sel., V. MUX sel.                  0,63,63            
constant DEF_REG_ERRWNGMASK                     : std_logic_vector(15 downto 0) := X"0000";   --  8x1         Error and Warning Message disable Mask                      0                  
constant DEF_REG_MON_SENS_SLDO                  : std_logic_vector(15 downto 0) := X"0000";   --  1,4,1,1,4,1 Reg. I. Mon.: En.A, DEM bits, Bias sel, En.D, DEM, Bias     0,0,0,0,0,0        
constant DEF_REG_MON_SENS_ACB                   : std_logic_vector(15 downto 0) := X"0000";   --  1,4,1       ACB I. Mon.: En., DEM bits, Bias sel.                       0,0,0              
constant DEF_REG_MON_ADC                        : std_logic_vector(15 downto 0) := X"0000";   --  1,1,1,6     Vref for Rsense: bot., top.; Vref in; ADC trim bits         0,0,0,0            
constant DEF_REG_DAC_NTC                        : std_logic_vector(15 downto 0) := X"0064";   --  10          Current output DAC for the external NTC                     100                
constant DEF_REG_HITOR_MASK_3                   : std_logic_vector(15 downto 0) := X"0000";   --  6x1         HitOR enable for core cols. 53:48                           0                   M 
constant DEF_REG_HITOR_MASK_2                   : std_logic_vector(15 downto 0) := X"0000";   --  16x1        HitOR enable for core cols. 47:32                           0                   M   
constant DEF_REG_HITOR_MASK_1                   : std_logic_vector(15 downto 0) := X"0000";   --  16x1        HitOR enable for core cols. 31:16                           0                   M   
constant DEF_REG_HITOR_MASK_0                   : std_logic_vector(15 downto 0) := X"0000";   --  16x1        HitOR enable for core cols. 15:0                            0                   M   
constant DEF_REG_AUTOREAD0                      : std_logic_vector(15 downto 0) := X"0089";   --  9           Auto-Read register address A for lane 0                     137                 I   
constant DEF_REG_AUTOREAD1                      : std_logic_vector(15 downto 0) := X"0085";   --  9           Auto-Read register address B for lane 0                     133                 I   
constant DEF_REG_AUTOREAD2                      : std_logic_vector(15 downto 0) := X"0079";   --  9           Auto-Read register address A for lane 1                     121                 I   
constant DEF_REG_AUTOREAD3                      : std_logic_vector(15 downto 0) := X"007A";   --  9           Auto-Read register address B for lane 1                     122                 I   
constant DEF_REG_AUTOREAD4                      : std_logic_vector(15 downto 0) := X"007C";   --  9           Auto-Read register address A for lane 2                     124                 I   
constant DEF_REG_AUTOREAD5                      : std_logic_vector(15 downto 0) := X"007F";   --  9           Auto-Read register address B for lane 2                     127                 I   
constant DEF_REG_AUTOREAD6                      : std_logic_vector(15 downto 0) := X"007E";   --  9           Auto-Read register address A for lane 3                     126                 I   
constant DEF_REG_AUTOREAD7                      : std_logic_vector(15 downto 0) := X"007D";   --  9           Auto-Read register address B for lane 3                     125                 I   
constant DEF_REG_RINGOSCCONFIG                  : std_logic_vector(15 downto 0) := X"4100";   --  15x1        Ring oscillator enable bits                                 1,5x0,1,8x0        
constant DEF_REG_RINGOSCROUTE                   : std_logic_vector(15 downto 0) := X"0000";   --  3,6         Select which RO to read from block A, B                     0,0                
constant DEF_REG_RING_OSC_A_OUT                 : std_logic_vector(15 downto 0) := X"0000";   --  16          Ring oscillator block A output (rd. only)                   n/a                
constant DEF_REG_RING_OSC_B_OUT                 : std_logic_vector(15 downto 0) := X"0000";   --  16          Ring oscillator block B output (rd. only)                   n/a                
constant DEF_REG_BCIDCNT                        : std_logic_vector(15 downto 0) := X"0000";   --  16          Bunch counter (rd. only)                                    n/a                
constant DEF_REG_TRIGCNT                        : std_logic_vector(15 downto 0) := X"0000";   --  16          Received trigger counter (rd. only)                         n/a                
constant DEF_REG_READTRIGCNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          Received or internal ReadTrigger ctr (rd. only)             n/a                
constant DEF_REG_LOCKLOSSCNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          Channel Sync lost lock counter (rd. only)                   n/a                
constant DEF_REG_BITFLIPWNGCNT                  : std_logic_vector(15 downto 0) := X"0000";   --  16          Bit Flip Warning counter (rd. only)                         n/a                
constant DEF_REG_BITFLIPERRCNT                  : std_logic_vector(15 downto 0) := X"0000";   --  16          Bit Flip Error counter (rd. only)                           n/a                
constant DEF_REG_CMDERRCNT                      : std_logic_vector(15 downto 0) := X"0000";   --  16          Command Decoder error message ctr (rd. only)                n/a                
constant DEF_REG_RDWRFIFOERRORCOUNT             : std_logic_vector(15 downto 0) := X"0000";   --  16          Writes and Reads when fifo was full ctr (rd. only)          n/a                
constant DEF_REG_AI_REGION_ROW                  : std_logic_vector(15 downto 0) := X"0000";   --  9           Auto Increment current row value (rd. only)                 n/a                
constant DEF_REG_HITOR_3_CNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          HitOr_3 Counter (rd. only)                                  n/a                
constant DEF_REG_HITOR_2_CNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          HitOr_2 Counter (rd. only)                                  n/a                
constant DEF_REG_HITOR_1_CNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          HitOr_1 Counter (rd. only)                                  n/a                
constant DEF_REG_HITOR_0_CNT                    : std_logic_vector(15 downto 0) := X"0000";   --  16          HitOr_0 Counter (rd. only)                                  n/a                
constant DEF_REG_SKIPPEDTRIGGERCNT              : std_logic_vector(15 downto 0) := X"0000";   --  16          Skipped Trigger counter (rd. only)                          n/a                
constant DEF_REG_EFUSESREADDATA1                : std_logic_vector(15 downto 0) := X"0000";   --  16          Readback of efuses 1 of 2 (Read Only)                       n/a                
constant DEF_REG_EFUSESREADDATA0                : std_logic_vector(15 downto 0) := X"0000";   --  16          Readback of efuses 2 of 2 (Read Only)                       n/a                
constant DEF_REG_MONITORINGDATAADC              : std_logic_vector(15 downto 0) := X"0000";   --  12          ADC value (rd. only)                                        n/a                
constant DEF_REG_SEU00_NOTMR                    : std_logic_vector(15 downto 0) := X"0000";   --  16          Dummies for SEU meas. Not triple redundant                  0                  
constant DEF_REG_SEUXX_NOTMR                    : std_logic_vector(15 downto 0) := X"0000";   --  16          Dummies for SEU meas. Not triple redundant (xx=1-63)        0                  
constant DEF_REG_SEU00                          : std_logic_vector(15 downto 0) := X"0000";   --  16          Dummies for SEU meas. Triple redundant                      0                  
constant DEF_REG_SEUXX                          : std_logic_vector(15 downto 0) := X"0000";   --  16          Dummies for SEU meas. Triple redundant (xx=1-53)            0                  


end package rd53b_regmap_pkg;
