//--------------------------------------------------------------------------------------------------------------------------------------------------------------
//
// Create `defines for all RD53B register address values and register default values after reset
//
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Name                                        Addr.      Description                                                 Default         Type
// Types :  (T)rigger and timing,     (I)nput/ouput, (C)alibration, (M)asking, () Other
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define ADR_REG_PIX_PORTAL                     0    // Pixel portal: virtual reg. to access pix config (8.8)       0                 
`define ADR_REG_REGION_COL                     1    // Pixel column pair connected to pixel portal (8.8)           0                 
`define ADR_REG_REGION_ROW                     2    // Pixel row connected to pixel portal (8.8)                   0                 
`define ADR_REG_PIX_MODE                       3    // Pix config: Broadcast, Mask(0) or TDAC(1), Auto Row         0,1,0             
`define ADR_REG_PIX_DEFAULT_CONFIG             4    // Key 1 of 2: hex 9CE2 to exit pix default config.            0                 
`define ADR_REG_PIX_DEFAULT_CONFIG_B           5    // Key 2 of 2: hex 631D to exit pix default config.            0                 
`define ADR_REG_GCR_DEFAULT_CONFIG             6    // Key 1 of 2: hex AC75 to exit glob default config.           0                 
`define ADR_REG_GCR_DEFAULT_CONFIG_B           7    // Key 2 of 2. hex 538A to exit glob default config.           0                 
                           
// Analog Front End (5)   
`define ADR_REG_DAC_PREAMP_L_DIFF              8    // Input transistor bias for left 2 cols                       50                
`define ADR_REG_DAC_PREAMP_R_DIFF              9    // Input transistor bias for right 2 cols                      50                
`define ADR_REG_DAC_PREAMP_TL_DIFF            10    // Input transistor bias for top left 2x2                      50                
`define ADR_REG_DAC_PREAMP_TR_DIFF            11    // Input transistor bias for top right 2x2                     50                
`define ADR_REG_DAC_PREAMP_T_DIFF             12    // Input transistor bias for top 2 rows                        50                
`define ADR_REG_DAC_PREAMP_M_DIFF             13    // Input transistor bias for all other pixels                  50                
`define ADR_REG_DAC_PRECOMP_DIFF              14    // Precomparator tail current bias                             50                
`define ADR_REG_DAC_COMP_DIFF                 15    // Comparator total current bias                               50                
`define ADR_REG_DAC_VFF_DIFF                  16    // Preamp feedback (return to baseline)                        100               
`define ADR_REG_DAC_TH1_L_DIFF                17    // Neg. Vth offset for left 2 cols                             100               
`define ADR_REG_DAC_TH1_R_DIFF                18    // Neg. Vth offset for right 2 cols                            100               
`define ADR_REG_DAC_TH1_M_DIFF                19    // Neg. Vth offset all other pixels                            100               
`define ADR_REG_DAC_TH2_DIFF                  20    // Pos. Vth offset for all pixels                              0                 
`define ADR_REG_DAC_LCC_DIFF                  21    // Leakage current compensation bias                           100               
`define ADR_REG_DAC_PREAMP_L_LIN              22    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_PREAMP_R_LIN              23    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_PREAMP_TL_LIN             24    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_PREAMP_TR_LIN             25    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_PREAMP_T_LIN              26    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_PREAMP_M_LIN              27    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_FC_LIN                    28    // not used in RD53B-ATLAS                                     20                
`define ADR_REG_DAC_KRUM_CURR_LIN             29    // not used in RD53B-ATLAS                                     50                
`define ADR_REG_DAC_REF_KRUM_LIN              30    // not used in RD53B-ATLAS                                     300               
`define ADR_REG_DAC_COMP_LIN                  31    // not used in RD53B-ATLAS                                     110               
`define ADR_REG_DAC_COMP_TA_LIN               32    // not used in RD53B-ATLAS                                     110               
`define ADR_REG_DAC_GDAC_L_LIN                33    // not used in RD53B-ATLAS                                     408               
`define ADR_REG_DAC_GDAC_R_LIN                34    // not used in RD53B-ATLAS                                     408               
`define ADR_REG_DAC_GDAC_M_LIN                35    // not used in RD53B-ATLAS                                     408               
`define ADR_REG_DAC_LDAC_LIN                  36    // not used in RD53B-ATLAS                                     100               
`define ADR_REG_LEAKAGE_FEEDBACK              37    // enable leakage curr. Comp; low gain mode                    0,0               
                                      
// Internal Power (4)                
`define ADR_REG_VOLTAGE_TRIM                  38    // Regulator: En. Undershunt A, D; Ana.Vtrim, Dig.Vtrim        0,0,8,8           
                                    
// Pixel Matrix Control            
`define ADR_REG_ENCORECOL_3                   39    // Enable Core Columns 53:48                                   0                 
`define ADR_REG_ENCORECOL_2                   40    // Enable Core Columns 47:32                                   0                 
`define ADR_REG_ENCORECOL_1                   41    // Enable Core Column 31:16                                    0                 
`define ADR_REG_ENCORECOL_0                   42    // Enable Core Column 15:0                                     0                 
`define ADR_REG_ENCORECOLUMNRESET_3           43    // Enable Reset for core cols. 53:48                           0                 
`define ADR_REG_ENCORECOLUMNRESET_2           44    // Enable Reset for core cols. 47:32                           0                 
`define ADR_REG_ENCORECOLUMNRESET_1           45    // Enable Reset for core cols. 31:16                           0                 
`define ADR_REG_ENCORECOLUMNRESET_0           46    // Enable Reset for core cols. 15:0                            0                 
`define ADR_REG_TRIGGERCONFIG                 47    // Trigger mode, Latency (9)                                   0,500             T
`define ADR_REG_SELFTRIGGERCONFIG_1           48    // Self Trig.: En., ToT thresh.: En., value (9.4)              0,1,1             T
`define ADR_REG_SELFTRIGGERCONFIG_0           49    // Self Trig.: delay, multiplier (9.4)                         100,1             T
`define ADR_REG_HITORPATTERNLUT               50    // Self Trig. HitOR logic program (9.4)                        0                 T
`define ADR_REG_READTRIGGERCONFIG             51    // Col. Read delay, Read Trig. Decision time (BXs)             0,1000            T
`define ADR_REG_TRUNCATIONTIMEOUTCONF         52    // Event truncation timeout (BXs, 0=off)                       0                 T
`define ADR_REG_CALIBRATIONCONFIG             53    // Cal injection: En. Dig., En. An., fine delay                0,1,0             C
`define ADR_REG_CLK_DATA_FINE_DELAY           54    // Fine delays for Clock, Data                                 0,0               T
`define ADR_REG_VCAL_HIGH                     55    // VCAL high level                                             500               C
`define ADR_REG_VCAL_MED                      56    // VCAL medium level                                           300               C
`define ADR_REG_MEAS_CAP                      57    // Cap Meas: En. Par, En.; VCAL range bit                      0,0,0             C
`define ADR_REG_CDRCONF                       58    // CDR: overwrite limit, phase det sel., CLK sel.              0,0,0             I
`define ADR_REG_CHSYNCCONF                    59    // Chan. Synch. Lock Thresh. (unlock is 2)                    16                I
`define ADR_REG_GLOBALPULSECONF               60    // Global pulse routing                                        0                  
`define ADR_REG_GLOBALPULSEWIDTH              61    // Global Pulse Width (in BX)                                  1                  
`define ADR_REG_SERVICEDATACONF               62    // Monitoring frame En., Period                                0,50              I
`define ADR_REG_TOTCONFIG                     63    // En: PtoT, PToA, 80MHz, 6b to 4b; PToT Latency               0,0,0,0,500        
`define ADR_REG_PRECISIONTOTENABLE_3          64    // Enable PToT for core cols. 53:48                            0                 M
`define ADR_REG_PRECISIONTOTENABLE_2          65    // Enable PToT for core cols. 47:32                            0                 M
`define ADR_REG_PRECISIONTOTENABLE_1          66    // Enable PToT for core cols. 31:16                            0                 M
`define ADR_REG_PRECISIONTOTENABLE_0          67    // Enable PToT for core cols. 15:0                             0                 M
`define ADR_REG_DATAMERGING                   68    // D.Merge: pol, Ch.ID, 1.28 CK gate, CK sel, En, Ch.bond      0,1,1,0,0,0       I
`define ADR_REG_DATAMERGINGMUX                69    // Input and Output Lane mapping                               3,2,1,0,3,2,1,0   I
`define ADR_REG_ENCORECOLUMNCALIBRATION_3     70    // CAL enable for core cols. 53:48                             6x1               M
`define ADR_REG_ENCORECOLUMNCALIBRATION_2     71    // CAL enable for core cols. 47:32                             16x1              M
`define ADR_REG_ENCORECOLUMNCALIBRATION_1     72    // CAL enable for core cols. 31:16                             16x1              M
`define ADR_REG_ENCORECOLUMNCALIBRATION_0     73    // CAL enable for core cols. 15:0                              16x1              M
`define ADR_REG_DATACONCENTRATORCONF          74    // In stream En: BCID, L1ID, EoS marker; evts/strm             0,0,1,16          I
`define ADR_REG_CORECOLENCODERCONF            75    // Drop ToT, raw map, rem. hits, MaxHits, En. Isol., MaxToT    0,0,0,0,0,0       I
`define ADR_REG_EVENMASK                      76    // Isolated hit filter mask: Even cols.                        0                 I
`define ADR_REG_ODDMASK                       77    // Isolated hit filter mask: Odd cols.                         0                 I
`define ADR_REG_EFUSESCONFIG                  78    // Efuses En. (to Read set 0F0F, to Write set F0F0)            0                 
`define ADR_REG_EFUSESWRITEDATA1              79    // Data to be written to Efuses (1 of 2)                       0                 
`define ADR_REG_EFUSESWRITEDATA0              80    // Data to be written to Efuses (2 of 2)                       0                 
`define ADR_REG_AURORACONFIG                  81    // AURORA: En. PRBS, En. Lanes, CCWait, CCSend                 0,0001,25,3       I
`define ADR_REG_AURORA_CB_CONFIG1             82    // Aurora Chann. Bonding Wait [19:12]                          255               I
`define ADR_REG_AURORA_CB_CONFIG0             83    // Aurora Chann. Bond Wait [11:0], CBSend                      4095,0            I
`define ADR_REG_AURORA_INIT_WAIT              84    // Aurora Initialization Delay                                 32                I
`define ADR_REG_OUTPUT_PAD_CONFIG             85    // GP_CMOS: pattern, En, DS, GP_LVDS: Enables, strength        5,1,0,15,7        I
`define ADR_REG_GP_CMOS_ROUTE                 86    // GP_CMOS MUX select                                          34                I
`define ADR_REG_GP_LVDS_ROUTE_1               87    // GP_LVDS(3), GP_LVDS(2) MUX select                           35,33             I
`define ADR_REG_GP_LVDS_ROUTE_0               88    // GP_LVDS(1), GP_LVDS(0) MUX select                           1,0               I
`define ADR_REG_DAC_CP_CDR                    89    // CDR CP Bias (values <15 are set to 15)                      40                I
`define ADR_REG_DAC_CP_FD_CDR                 90    // CDR FD CP bias (values <100 are set to 100)                 400               I
`define ADR_REG_DAC_CP_BUFF_CDR               91    // CDR unity gain buffer bias                                  200               I
`define ADR_REG_DAC_VCO_CDR                   92    // CDR VCO bias (values <700 are set to 700)                   1023              I
`define ADR_REG_DAC_VCOBUFF_CDR               93    // CDR VCO buffer bias (values <200 are set to 200)            500               I
`define ADR_REG_SER_SEL_OUT                   94    // CML 3-0 content. 0=CK/2, 1=AURORA, 2=PRBS7, 3=0             1,1,1,1           I
`define ADR_REG_CML_CONFIG                    95    // CML out: Inv. Tap 2,1; En. Tap 2,1; En. Lane 3,2,1,0        0,0,0001          I
`define ADR_REG_DAC_CML_BIAS_2                96    // CML drivers tap 2 amplitude (pre-emph)                      0                 I
`define ADR_REG_DAC_CML_BIAS_1                97    // CML drivers tap 1 amplitude (pre-emph)                      0                 I
`define ADR_REG_DAC_CML_BIAS_0                98    // CML drivers tap 0 amplitude (main)                          500               I
                                        
// Monitoring and Test                 
`define ADR_REG_MONITORCONFIG                 99    // Monitor pin: En., I. MUX sel., V. MUX sel.                  0,63,63           
`define ADR_REG_ERRWNGMASK                   100    // Error and Warning Message disable Mask                      0                 
`define ADR_REG_MON_SENS_SLDO                101    // Reg. I. Mon.: En.A, DEM bits, Bias sel, En.D, DEM, Bias     0,0,0,0,0,0       
`define ADR_REG_MON_SENS_ACB                 102    // ACB I. Mon.: En., DEM bits, Bias sel.                       0,0,0             
`define ADR_REG_MON_ADC                      103    // Vref for Rsense: bot., top.; Vref in; ADC trim bits         0,0,0,0           
`define ADR_REG_DAC_NTC                      104    // Current output DAC for the external NTC                     100               
`define ADR_REG_HITOR_MASK_3                 105    // HitOR enable for core cols. 53:48                           0                 M
`define ADR_REG_HITOR_MASK_2                 106    // HitOR enable for core cols. 47:32                           0                 M
`define ADR_REG_HITOR_MASK_1                 107    // HitOR enable for core cols. 31:16                           0                 M
`define ADR_REG_HITOR_MASK_0                 108    // HitOR enable for core cols. 15:0                            0                 M
`define ADR_REG_AUTOREAD0                    109    // Auto-Read register address A for lane 0                     137               I
`define ADR_REG_AUTOREAD1                    110    // Auto-Read register address B for lane 0                     133               I
`define ADR_REG_AUTOREAD2                    111    // Auto-Read register address A for lane 1                     121               I
`define ADR_REG_AUTOREAD3                    112    // Auto-Read register address B for lane 1                     122               I
`define ADR_REG_AUTOREAD4                    113    // Auto-Read register address A for lane 2                     124               I
`define ADR_REG_AUTOREAD5                    114    // Auto-Read register address B for lane 2                     127               I
`define ADR_REG_AUTOREAD6                    115    // Auto-Read register address A for lane 3                     126               I
`define ADR_REG_AUTOREAD7                    116    // Auto-Read register address B for lane 3                     125               I
`define ADR_REG_RINGOSCCONFIG                117    // Ring oscillator enable bits                                 1,5x0,1,8x0       
`define ADR_REG_RINGOSCROUTE                 118    // Select which RO to read from block A, B                     0,0               
`define ADR_REG_RING_OSC_A_OUT               119    // Ring oscillator block A output (rd. only)                   n/a               
`define ADR_REG_RING_OSC_B_OUT               120    // Ring oscillator block B output (rd. only)                   n/a               
`define ADR_REG_BCIDCNT                      121    // Bunch counter (rd. only)                                    n/a               
`define ADR_REG_TRIGCNT                      122    // Received trigger counter (rd. only)                         n/a               
`define ADR_REG_READTRIGCNT                  123    // Received or internal ReadTrigger ctr (rd. only)             n/a               
`define ADR_REG_LOCKLOSSCNT                  124    // Channel Sync lost lock counter (rd. only)                   n/a               
`define ADR_REG_BITFLIPWNGCNT                125    // Bit Flip Warning counter (rd. only)                         n/a               
`define ADR_REG_BITFLIPERRCNT                126    // Bit Flip Error counter (rd. only)                           n/a               
`define ADR_REG_CMDERRCNT                    127    // Command Decoder error message ctr (rd. only)                n/a               
`define ADR_REG_RDWRFIFOERRORCOUNT           128    // Writes and Reads when fifo was full ctr (rd. only)          n/a               
`define ADR_REG_AI_REGION_ROW                129    // Auto Increment current row value (rd. only)                 n/a               
`define ADR_REG_HITOR_3_CNT                  130    // HitOr_3 Counter (rd. only)                                  n/a               
`define ADR_REG_HITOR_2_CNT                  131    // HitOr_2 Counter (rd. only)                                  n/a               
`define ADR_REG_HITOR_1_CNT                  132    // HitOr_1 Counter (rd. only)                                  n/a               
`define ADR_REG_HITOR_0_CNT                  133    // HitOr_0 Counter (rd. only)                                  n/a               
`define ADR_REG_SKIPPEDTRIGGERCNT            134    // Skipped Trigger counter (rd. only)                          n/a               
`define ADR_REG_EFUSESREADDATA1              135    // Readback of efuses 1 of 2 (Read Only)                       n/a               
`define ADR_REG_EFUSESREADDATA0              136    // Readback of efuses 2 of 2 (Read Only)                       n/a               
`define ADR_REG_MONITORINGDATAADC            137    // ADC value (rd. only)                                        n/a               
`define ADR_REG_SEU00_NOTMR                  138    // Dummies for SEU meas. Not triple redundant                  0                 
// Regs SEU01_NOTMR to SEU62_NOTMR go here
`define ADR_REG_SEU63_NOTMR                  201    // Dummies for SEU meas. Not triple redundant (xx=1-63)        0                 
`define ADR_REG_SEU00                        202    // Dummies for SEU meas. Triple redundant                      0                 
// Regs SEU01 to SEU52 go here
`define ADR_REG_SEU53                        255    // Dummies for SEU meas. Triple redundant (xx=1-53)            0                 



//---------------------------------------------------------------------
// Default register values
//---------------------------------------------------------------------
`define DEF_PIX_PORTAL                     16'h0000;   //  0                 
`define DEF_REGION_COL                     16'h0000;   //  0                 
`define DEF_REGION_ROW                     16'h0000;   //  0                 
`define DEF_PIX_MODE                       16'h0002;   //  0,1,0             
`define DEF_PIX_DEFAULT_CONFIG             16'h0000;   //  0                 
`define DEF_PIX_DEFAULT_CONFIG_B           16'h0000;   //  0                 
`define DEF_GCR_DEFAULT_CONFIG             16'h0000;   //  0                 
`define DEF_GCR_DEFAULT_CONFIG_B           16'h0000;   //  0                 

// Analog Front End (5)    
`define DEF_DAC_PREAMP_L_DIFF              16'h0032;   //  50                
`define DEF_DAC_PREAMP_R_DIFF              16'h0032;   //  50                
`define DEF_DAC_PREAMP_TL_DIFF             16'h0032;   //  50                
`define DEF_DAC_PREAMP_TR_DIFF             16'h0032;   //  50                
`define DEF_DAC_PREAMP_T_DIFF              16'h0032;   //  50                
`define DEF_DAC_PREAMP_M_DIFF              16'h0032;   //  50                
`define DEF_DAC_PRECOMP_DIFF               16'h0032;   //  50                
`define DEF_DAC_COMP_DIFF                  16'h0032;   //  50                
`define DEF_DAC_VFF_DIFF                   16'h0064;   //  100               
`define DEF_DAC_TH1_L_DIFF                 16'h0064;   //  100               
`define DEF_DAC_TH1_R_DIFF                 16'h0064;   //  100               
`define DEF_DAC_TH1_M_DIFF                 16'h0064;   //  100               
`define DEF_DAC_TH2_DIFF                   16'h0000;   //  0                 
`define DEF_DAC_LCC_DIFF                   16'h0064;   //  100               
`define DEF_DAC_PREAMP_L_LIN               16'h012C;   //  300               
`define DEF_DAC_PREAMP_R_LIN               16'h012C;   //  300               
`define DEF_DAC_PREAMP_TL_LIN              16'h012C;   //  300               
`define DEF_DAC_PREAMP_TR_LIN              16'h012C;   //  300               
`define DEF_DAC_PREAMP_T_LIN               16'h012C;   //  300               
`define DEF_DAC_PREAMP_M_LIN               16'h012C;   //  300               
`define DEF_DAC_FC_LIN                     16'h0014;   //  20                
`define DEF_DAC_KRUM_CURR_LIN              16'h0032;   //  50                
`define DEF_DAC_REF_KRUM_LIN               16'h012C;   //  300               
`define DEF_DAC_COMP_LIN                   16'h006E;   //  110               
`define DEF_DAC_COMP_TA_LIN                16'h006E;   //  110               
`define DEF_DAC_GDAC_L_LIN                 16'h0198;   //  408               
`define DEF_DAC_GDAC_R_LIN                 16'h0198;   //  408               
`define DEF_DAC_GDAC_M_LIN                 16'h0198;   //  408               
`define DEF_DAC_LDAC_LIN                   16'h0064;   //  100               
`define DEF_LEAKAGE_FEEDBACK               16'h0000;   //  0,0               

// Internal Power (4)  
`define DEF_VOLTAGE_TRIM                   16'h0088;   //  0,0,8,8           

// Pixel Matrix Control
`define DEF_ENCORECOL_3                    16'h0000;   //  0                 
`define DEF_ENCORECOL_2                    16'h0000;   //  0                 
`define DEF_ENCORECOL_1                    16'h0000;   //  0                 
`define DEF_ENCORECOL_0                    16'h0000;   //  0                 
`define DEF_ENCORECOLUMNRESET_3            16'h0000;   //  0                 
`define DEF_ENCORECOLUMNRESET_2            16'h0000;   //  0                 
`define DEF_ENCORECOLUMNRESET_1            16'h0000;   //  0                 
`define DEF_ENCORECOLUMNRESET_0            16'h0000;   //  0                 
`define DEF_TRIGGERCONFIG                  16'h01F4;   //  0,500             
`define DEF_SELFTRIGGERCONFIG_1            16'h0011;   //  0,1,1             
`define DEF_SELFTRIGGERCONFIG_0            16'h0C81;   //  100,1             
`define DEF_HITORPATTERNLUT                16'h0000;   //  0                 
`define DEF_READTRIGGERCONFIG              16'h03E8;   //  0,1000            
`define DEF_TRUNCATIONTIMEOUTCONF          16'h0000;   //  0                 
`define DEF_CALIBRATIONCONFIG              16'h0040;   //  0,1,0             
`define DEF_CLK_DATA_FINE_DELAY            16'h0000;   //  0,0               
`define DEF_VCAL_HIGH                      16'h01F4;   //  500               
`define DEF_VCAL_MED                       16'h012C;   //  300               
`define DEF_MEAS_CAP                       16'h0000;   //  0,0,0             
`define DEF_CDRCONF                        16'h0000;   //  0,0,0             
`define DEF_CHSYNCCONF                     16'h0010;   //  16                
`define DEF_GLOBALPULSECONF                16'h0000;   //  0                 
`define DEF_GLOBALPULSEWIDTH               16'h0001;   //  1                 
`define DEF_SERVICEDATACONF                16'h0032;   //  0,50              
`define DEF_TOTCONFIG                      16'h01F4;   //  0,0,0,0,500       
`define DEF_PRECISIONTOTENABLE_3           16'h0000;   //  0                 
`define DEF_PRECISIONTOTENABLE_2           16'h0000;   //  0                 
`define DEF_PRECISIONTOTENABLE_1           16'h0000;   //  0                 
`define DEF_PRECISIONTOTENABLE_0           16'h0000;   //  0                 
`define DEF_DATAMERGING                    16'h00C0;   //  0,1,1,0,0,0       
`define DEF_DATAMERGINGMUX                 16'hE4E4;   //  3,2,1,0,3,2,1,0   
`define DEF_ENCORECOLUMNCALIBRATION_3      16'h003F;   //  6x1               
`define DEF_ENCORECOLUMNCALIBRATION_2      16'hFFFF;   //  16x1              
`define DEF_ENCORECOLUMNCALIBRATION_1      16'hFFFF;   //  16x1              
`define DEF_ENCORECOLUMNCALIBRATION_0      16'hFFFF;   //  16x1              
`define DEF_DATACONCENTRATORCONF           16'h0110;   //  0,0,1,16          
`define DEF_CORECOLENCODERCONF             16'h0000;   //  0,0,0,0,0,0       
`define DEF_EVENMASK                       16'h0000;   //  0                 
`define DEF_ODDMASK                        16'h0000;   //  0                 
`define DEF_EFUSESCONFIG                   16'h0000;   //  0                 
`define DEF_EFUSESWRITEDATA1               16'h0000;   //  0                 
`define DEF_EFUSESWRITEDATA0               16'h0000;   //  0                 
`define DEF_AURORACONFIG                   16'h0167;   //  0,0001,25,3       
`define DEF_AURORA_CB_CONFIG1              16'h00FF;   //  255               
`define DEF_AURORA_CB_CONFIG0              16'h0FFF;   //  4095,0            
`define DEF_AURORA_INIT_WAIT               16'h0020;   //  32                
`define DEF_OUTPUT_PAD_CONFIG              16'h0B7F;   //  5,1,0,15,7        
`define DEF_GP_CMOS_ROUTE                  16'h0022;   //  34                
`define DEF_GP_LVDS_ROUTE_1                16'h08E1;   //  35,33             
`define DEF_GP_LVDS_ROUTE_0                16'h0040;   //  1,0               
`define DEF_DAC_CP_CDR                     16'h0037;   //  40                
`define DEF_DAC_CP_FD_CDR                  16'h0190;   //  400               
`define DEF_DAC_CP_BUFF_CDR                16'h00C8;   //  200               
`define DEF_DAC_VCO_CDR                    16'h03FF;   //  1023              
`define DEF_DAC_VCOBUFF_CDR                16'h01F4;   //  500               
`define DEF_SER_SEL_OUT                    16'h0055;   //  1,1,1,1           
`define DEF_CML_CONFIG                     16'h0001;   //  0,0,0001          
`define DEF_DAC_CML_BIAS_2                 16'h0000;   //  0                 
`define DEF_DAC_CML_BIAS_1                 16'h0000;   //  0                 
`define DEF_DAC_CML_BIAS_0                 16'h01F4;   //  500               

// Monitoring and Test                                       
`define DEF_MONITORCONFIG                  16'h0FFF;   //  0,63,63           
`define DEF_ERRWNGMASK                     16'h0000;   //  0                 
`define DEF_MON_SENS_SLDO                  16'h0000;   //  0,0,0,0,0,0       
`define DEF_MON_SENS_ACB                   16'h0000;   //  0,0,0             
`define DEF_MON_ADC                        16'h0000;   //  0,0,0,0           
`define DEF_DAC_NTC                        16'h0064;   //  100               
`define DEF_HITOR_MASK_3                   16'h0000;   //  0                 
`define DEF_HITOR_MASK_2                   16'h0000;   //  0                 
`define DEF_HITOR_MASK_1                   16'h0000;   //  0                 
`define DEF_HITOR_MASK_0                   16'h0000;   //  0                 
`define DEF_AUTOREAD0                      16'h0089;   //  137               
`define DEF_AUTOREAD1                      16'h0085;   //  133               
`define DEF_AUTOREAD2                      16'h0079;   //  121               
`define DEF_AUTOREAD3                      16'h007A;   //  122               
`define DEF_AUTOREAD4                      16'h007C;   //  124               
`define DEF_AUTOREAD5                      16'h007F;   //  127               
`define DEF_AUTOREAD6                      16'h007E;   //  126               
`define DEF_AUTOREAD7                      16'h007D;   //  125               
`define DEF_RINGOSCCONFIG                  16'h4100;   //  1,5x0,1,8x0       
`define DEF_RINGOSCROUTE                   16'h0000;   //  0,0               
`define DEF_RING_OSC_A_OUT                 16'h0000;   //  n/a               
`define DEF_RING_OSC_B_OUT                 16'h0000;   //  n/a               
`define DEF_BCIDCNT                        16'h0000;   //  n/a               
`define DEF_TRIGCNT                        16'h0000;   //  n/a               
`define DEF_READTRIGCNT                    16'h0000;   //  n/a               
`define DEF_LOCKLOSSCNT                    16'h0000;   //  n/a               
`define DEF_BITFLIPWNGCNT                  16'h0000;   //  n/a               
`define DEF_BITFLIPERRCNT                  16'h0000;   //  n/a               
`define DEF_CMDERRCNT                      16'h0000;   //  n/a               
`define DEF_RDWRFIFOERRORCOUNT             16'h0000;   //  n/a               
`define DEF_AI_REGION_ROW                  16'h0000;   //  n/a               
`define DEF_HITOR_3_CNT                    16'h0000;   //  n/a               
`define DEF_HITOR_2_CNT                    16'h0000;   //  n/a               
`define DEF_HITOR_1_CNT                    16'h0000;   //  n/a               
`define DEF_HITOR_0_CNT                    16'h0000;   //  n/a               
`define DEF_SKIPPEDTRIGGERCNT              16'h0000;   //  n/a               
`define DEF_EFUSESREADDATA1                16'h0000;   //  n/a               
`define DEF_EFUSESREADDATA0                16'h0000;   //  n/a               
`define DEF_MONITORINGDATAADC              16'h0000;   //  n/a 

// Registers for checking for Single Event Upsets. (64 + 53 regs)              
`define DEF_SEU_NOTMR                      16'h0000;   //  0     Use for all SEUxx_NOTMR regs            
`define DEF_SEU                            16'h0000;   //  0     Use for all SEUxx registers            




