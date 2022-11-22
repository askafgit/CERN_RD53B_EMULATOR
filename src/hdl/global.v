`ifndef _global_config_map_
`define _global_config_map_

//
// Name:              PIX_PORTAL
// Size:              8
// Address:           0
`define PIX_PORTAL 0
// Name:              REGION_COL
// Size:              8
// Address:           1
`define REGION_COL 1
//
// Name:              REGION_ROW
// Size:              9
// Address:           2
`define REGION_ROW 2
//
// Name:              PIX_MODE
// Size:              6
// Address:           3
`define PIX_MODE 3
//
// Name:              PIX_DEFAULT_CONFIG
// Size:              16
// Address:           4s
`define PIX_DEFAULT_CONFIG 4
//
// Name:              IBIASP1_SYNC
// Size:              9
// Address:           5
`define IBIASP1_SYNC 5
//
// Name:              IBIASP2_SYNC
// Size:              9
// Address:           6
`define IBIASP2_SYNC 6
//
// Name:              IBIAS_SF_SYNC
// Size:              9
// Address:           7
`define IBIAS_SF_SYNC 7
//
// Name:              IBIAS_KRUM_SYNC
// Size:              9
// Address:           8
`define IBIAS_KRUM_SYNC 8
//
// Name:              IBIAS_DISC_SYNC
// Size:              9
// Address:           9
`define IBIAS_DISC_SYNC 9
//
// Name:              ICTRL_SYNCT_SYNC
// Size:              10
// Address:           10
`define ICTRL_SYNCT_SYNC 10
//
// Name:              VBL_SYNC
// Size:              10
// Address:           11
`define VBL_SYNC 11
//
// Name:              VTH_SYNC
// Size:              10
// Address:           12
`define VTH_SYNC 12
//
// Name:              VREF_KRUM_SYNC
// Size:              10
// Address:           13
`define VREF_KRUM_SYNC 13
//
// Name:              PA_IN_BIAS_LIN
// Size:              9
// Address:           14
`define PA_IN_BIAS_LIN 14
//
// Name:              FC_BIAS_LIN
// Size:              8
// Address:           15
`define FC_BIAS_LIN 15
//
// Name:              KRUM_CURR_LIN
// Size:              9
// Address:           16
`define KRUM_CURR_LIN 16
//
// Name:              LDAC_LIN
// Size:              10
// Address:           17
`define LDAC_LIN 17
//
// Name:              COMP_LIN
// Size:              9
// Address:           18
`define COMP_LIN 18
//
// Name:              REF_KRUM_LIN
// Size:              10
// Address:           19
`define REF_KRUM_LIN 19
//
// Name:              Vthreshold_LIN
// Size:              10
// Address:           20
`define Vthreshold_LIN 20
//
// Name:              PRMP_DIFF
// Size:              10
// Address:           21
`define PRMP_DIFF 21
//
// Name:              FOL_DIFF
// Size:              10
// Address:           22
`define FOL_DIFF 22
//
// Name:              PRECOMP_DIFF
// Size:              10
// Address:           23
`define PRECOMP_DIFF 23
//
// Name:              COMP_DIFF
// Size:              10
// Address:           24
`define COMP_DIFF 24
//
// Name:              VFF_DIFF
// Size:              10
// Address:           25
`define VFF_DIFF 25
//
// Name:              VTH1_DIFF
// Size:              10
// Address:           26
`define VTH1_DIFF 26
//
// Name:              VTH2_DIFF
// Size:              10
// Address:           27
`define VTH2_DIFF 27
//
// Name:              LCC_DIFF
// Size:              10
// Address:           28
`define LCC_DIFF 28
//
// Name:              CONF_FE_DIFF
// Size:              2
// Address:           29
`define CONF_FE_DIFF 29
//
// Name:              CONF_FE_SYNC
// Size:              5
// Address:           30
`define CONF_FE_SYNC 30 
//
// Name:              VOLTAGE_TRIM
// SLDO_ANALOG_TRIM [9:5] 
// SLDO_DIGITAL_TRIM [4:0]
// Size:              10
// Address:           31
`define VOLTAGE_TRIM 31 
//
// Name:              EN_CORE_COL_SYNC
// Size:              16
// Address:           32
`define EN_CORE_COL_SYNC 32
//
// Name:              EN_CORE_COL_LIN_1
// Size:              16
// Address:           33
`define EN_CORE_COL_LIN_1 33
//
// Name:              EN_CORE_COL_LIN_2
// Size:              1
// Address:           34
`define EN_CORE_COL_LIN_2 34
//
// Name:              EN_CORE_COL_DIFF_1
// Size:              16
// Address:           35
`define EN_CORE_COL_DIFF_1 35
//
// Name:              EN_CORE_COL_DIFF_2
// Size:              1
// Address:           36
`define EN_CORE_COL_DIFF_2 36
//
// Name:              LATENCY_CONFIG
// Size:              9
// Address:           37
`define LATENCY_CONFIG 37 
//
// Name:              WR_SYNC_DELAY_SYNC
// Size:              5
// Address:           38
`define WR_SYNC_DELAY_SYNC 38
//
// Name:              INJ_MODE_DEL 
// Size:              6
// Address:           39
`define INJ_MODE_DEL  39 
//
// Name:              CLK_DATA_DELAY
// Size:              9
// Address:           40
`define CLK_DATA_DELAY 40
//
// Name:              VCAL_HIGH
// Size:              12
// Address:           41
`define VCAL_HIGH 41
//
// Name:              VCAL_MED
// Size:              12
// Address:           42
`define VCAL_MED 42
//
// Name:              CH_SYNC_CONF
// Size:              12
// Address:           43
`define CH_SYNC_CONF 43
//
// Name:              GLOBAL_PULSE_RT
// Size:              16
// Address:           44
`define GLOBAL_PULSE_RT 44
//
// Size:              8
// Address:           45
`define MONITOR_FRAME_SKIP 45

// Name:              CAL_COLPR_SYNC_1
// Size:              16
// Address:           46
`define CAL_COLPR_SYNC_1 46
//
// Name:              CAL_COLPR_SYNC_2
// Size:              16
// Address:           47
`define CAL_COLPR_SYNC_2 47
//
// Name:              CAL_COLPR_SYNC_3
// Size:              16
// Address:           48
`define CAL_COLPR_SYNC_3 48
//
// Name:              CAL_COLPR_SYNC_4
// Size:              16
// Address:           49
`define CAL_COLPR_SYNC_4 49
//
// Name:              CAL_COLPR_LIN_1
// Size:              16
// Address:           50
`define CAL_COLPR_LIN_1 50
//
// Name:              CAL_COLPR_LIN_2
// Size:              16
// Address:           51
`define CAL_COLPR_LIN_2 51
//
// Name:              CAL_COLPR_LIN_3
// Size:              16
// Address:           52
`define CAL_COLPR_LIN_3 52
//
// Name:              CAL_COLPR_LIN_4
// Size:              16
// Address:           53
`define CAL_COLPR_LIN_4 53
//
// Name:              CAL_COLPR_LIN_5
// Size:              4
// Address:           54
`define CAL_COLPR_LIN_5 54
//
// Name:              CAL_COLPR_DIFF_1
// Size:              16
// Address:           55
`define CAL_COLPR_DIFF_1 55
//
// Name:              CAL_COLPR_DIFF_2
// Size:              16
// Address:           56
`define CAL_COLPR_DIFF_2 56
//
// Name:              CAL_COLPR_DIFF_3
// Size:              16
// Address:           57
`define CAL_COLPR_DIFF_3 57
//
// Name:              CAL_COLPR_DIFF_4
// Size:              16
// Address:           58
`define CAL_COLPR_DIFF_4 58
//
// Name:              CAL_COLPR_DIFF_5
// Size:              4
// Address:           59
`define CAL_COLPR_DIFF_5 59
//
// Name:              DEBUG_CONFIG
// Size:              2
// Address:           60
`define DEBUG_CONFIG 60
//
// Name:              OUTPUT_CONFIG
// Size:              7
// Address:           61
`define OUTPUT_CONFIG 61
//
// Name:              OUT_PAD_CONFIG
// Size:              14
// Address:           62
`define OUT_PAD_CONFIG 62
//
// Name:              GP_LVDS_ROUTE
// Size:              16
// Address:           63
`define GP_LVDS_ROUTE 63
//
// Name:              CDR_CONFIG
// Size:              14
// Address:           64
`define CDR_CONFIG 64
//
// Name:              VCO_BUFF_BIAS
// Size:              10
// Address:           65
`define VCO_BUFF_BIAS 65
//
// Name:              CDR_CP_IBIAS
// Size:              10
// Address:           66
`define CDR_CP_IBIAS 66
//
// Name:              CDR_VCO_IBIAS
// Size:              10
// Address:           67
`define CDR_VCO_IBIAS 67
//
// Name:              SER_SEL_OUT
// Size:              8
// Address:           68
`define SER_SEL_OUT 68
//
// Name:              CML_CONFIG
// Size:              8
// Address:           69
`define CML_CONFIG 69
//
// Name:              CML_TAP_BIAS_1
// Size:              10
// Address:           70
`define CML_TAP_BIAS_1 70
//
// Name:              CML_TAP1_BIAS_2
// Size:              10
// Address:           71
`define CML_TAP_BIAS_2 71
//
// Name:              CML_TAP2_BIAS_3
// Size:              10
// Address:           72
`define CML_TAP_BIAS_3 72
//
// Name:              AURORA_CC_CFG
// Size:              8
// Address:           73
`define AURORA_CC_CFG 73
//
// Name:              AURORA_CC_CFG0
// Size:              8
// Address:           74
`define AURORA_CC_CFG0 74
//
// Name:              AURORA_CC_CFG1
// Size:              16
// Address:           75
`define AURORA_CC_CFG1 75
//
// Name:              AURORA_INIT_WAIT
// Size:              11
// Address:           76
`define AURORA_INIT_WAIT 76
//
// Name:              MONITOR_MUX
// Size:              14
// Address:           77
`define MONITOR_MUX 77
//
// Name:              HITOR_0_MASK_SYNC
// Size:              16
// Address:           78
`define HITOR_0_MASK_SYNC 78
//
// Name:              HITOR_1_MASK_SYNC
// Size:              16
// Address:           79
`define HITOR_1_MASK_SYNC 79
//
// Name:              HITOR_2_MASK_SYNC
// Size:              16
// Address:           80
`define HITOR_2_MASK_SYNC 80
//
// Name:              HITOR_3_MASK_SYNC
// Size:              16
// Address:           81
`define HITOR_3_MASK_SYNC 81
//
// Name:              HITOR_0_MASK_LIN_0
// Size:              16
// Address:           82
`define HITOR_0_MASK_LIN_0 82
//
// Name:              HITOR_0_MASK_LIN_1
// Size:              1
// Address:           83
`define HITOR_0_MASK_LIN_1 83
//
// Name:              HITOR_1_MASK_LIN_0
// Size:              16
// Address:           84
`define HITOR_1_MASK_LIN_0 84
//
// Name:              HITOR_1_MASK_LIN_1
// Size:              1
// Address:           85
`define HITOR_1_MASK_LIN_1 85
//
// Name:              HITOR_2_MASK_LIN_0
// Size:              16
// Address:           86
`define HITOR_2_MASK_LIN_0 86
//
// Name:              HITOR_2_MASK_LIN_1
// Size:              1
// Address:           87
`define HITOR_2_MASK_LIN_1 87
//
// Name:              HITOR_3_MASK_LIN_0
// Size:              16
// Address:           88
`define HITOR_3_MASK_LIN_0 88
//
// Name:              HITOR_3_MASK_LIN_1
// Size:              1
// Address:           89
`define HITOR_3_MASK_LIN_1 89
//
// Name:              HITOR_0_MASK_DIFF_0
// Size:              16
// Address:           90
`define HITOR_0_MASK_DIFF_0 90
//
// Name:              HITOR_0_MASK_DIFF_1
// Size:              1
// Address:           91
`define HITOR_0_MASK_DIFF_1 91
//
// Name:              HITOR_1_MASK_DIFF_0
// Size:              16
// Address:           92
`define HITOR_1_MASK_DIFF_0 92
//
// Name:              HITOR_1_MASK_DIFF_1
// Size:              1
// Address:           93
`define HITOR_1_MASK_DIFF_1 93
//
// Name:              HITOR_2_MASK_DIFF_0
// Size:              16
// Address:           94
`define HITOR_2_MASK_DIFF_0 94
//
// Name:              HITOR_2_MASK_DIFF_1
// Size:              1
// Address:           95
`define HITOR_2_MASK_DIFF_1 95
//
// Name:              HITOR_3_MASK_DIFF_0
// Size:              16
// Address:           96
`define HITOR_3_MASK_DIFF_0 96
//
// Name:              HITOR_3_MASK_DIFF_1
// Size:              1
// Address:           97
`define HITOR_3_MASK_DIFF_1 97
//
// Name:              ADC_CONFIG
// Size:              11
// Address:           98
`define ADC_CONFIG 98
//
// Name:              SENSOR_CONFIG_0
// Size:              12
// Address:           99
`define SENSOR_CONFIG_0 99
//
// Name:              SENSOR_CONFIG_1
// Size:              12
// Address:           100
`define SENSOR_CONFIG_1 100
//
// Name:              AutoRead0
// Size:              9
// Address:           101
`define AutoRead0 101
//
// Name:              AutoRead1
// Size:              9
// Address:           102
`define AutoRead1 102
//
// Name:              AutoRead2
// Size:              9
// Address:           103
`define AutoRead2 103
//
// Name:              AutoRead3
// Size:              9
// Address:           104
`define AutoRead3 104
//
// Name:              AutoRead4
// Size:              9
// Address:           105
`define AutoRead4 105
//
// Name:              AutoRead5
// Size:              9
// Address:           106
`define AutoRead5 106
//
// Name:              AutoRead6
// Size:              9
// Address:           107
`define AutoRead6 107
//
// Name:              AutoRead7
// Size:              9
// Address:           108
`define AutoRead7 108
//
// Name:              RING_OSC_ENABLE
// Size:              8
// Address:           109
`define RING_OSC_ENABLE 109
//
// Name:              RING_OSC_0
// Size:              16
// Address:           110
`define RING_OSC_0 110
//
// Name:              RING_OSC_1
// Size:              16
// Address:           111
`define RING_OSC_1 111
//
// Name:              RING_OSC_2
// Size:              16
// Address:           112
`define RING_OSC_2 112
//
// Name:              RING_OSC_3
// Size:              16
// Address:           113
`define RING_OSC_3 113
//
// Name:              RING_OSC_4
// Size:              16
// Address:           114
`define RING_OSC_4 114
//
// Name:              RING_OSC_5
// Size:              16
// Address:           115
`define RING_OSC_5 115
//
// Name:              RING_OSC_6
// Size:              16
// Address:           116
`define RING_OSC_6 116
//
// Name:              RING_OSC_7
// Size:              16
// Address:           117
`define RING_OSC_7 117
//
// Name:              BC_CTR
// Size:              16
// Address:           118
`define BC_CTR 118
//
// Name:              TRIG_CTR
// Size:              16
// Address:           119
`define TRIG_CTR 119
//
// Name:              LCK_LOSS_CTR
// Size:              16
// Address:           120
`define LCK_LOSS_CTR 120
//
// Name:              BFLIP_WARN_CTR
// Size:              16
// Address:           121
`define BFLIP_WARN_CTR 121
//
// Name:              BFLIP_ERR_CTR
// Size:              16
// Address:           122
`define BFLIP_ERR_CTR 122
//
// Name:              CMD_ERR_CTR
// Size:              16
// Address:           123
`define CMD_ERR_CTR 123
//
// Name:              FIFO_FULL_CTR _0
// Size:              16
// Address:           124
`define FIFO_FULL_CTR _0 124
//
// Name:              FIFO_FULL_CTR _1
// Size:              16
// Address:           125
`define FIFO_FULL_CTR _1 125
//
// Name:              FIFO_FULL_CTR _2
// Size:              16
// Address:           126
`define FIFO_FULL_CTR _2 126
//
// Name:              FIFO_FULL_CTR _3
// Size:              16
// Address:           127
`define FIFO_FULL_CTR _3 127
//
// Name:              AI_PIX_COL 
// Size:              8
// Address:           128
`define AI_PIX_COL  128
//
// Name:              AI_PIX_ROW
// Size:              9
// Address:           129
`define AI_PIX_ROW 129
//
// Name:              HitOr_0_Cnt
// Size:              16
// Address:           130
`define HitOr_0_Cnt 130
//
// Name:              HitOr_1_Cnt
// Size:              16
// Address:           131
`define HitOr_1_Cnt 131
//
// Name:              HitOr_2_Cnt
// Size:              16
// Address:           132
`define HitOr_2_Cnt 132
//
// Name:              HitOr_3_Cnt
// Size:              16
// Address:           133
`define HitOr_3_Cnt 133
//
// Name:              SKP_TRIG_CNT
// Size:              16
// Address:           134
`define SKP_TRIG_CNT 134
//
// Name:              ERR_MASK
// Size:              14
// Address:           135
`define ERR_MASK 135
//
// Name:              ADC_READ
// Size:              12
// Address:           136
`define ADC_READ 136
//
// Name:              SELF_TRIG_EN
// Size:              12
// Address:           137
`define SELF_TRIG_EN 137
`endif