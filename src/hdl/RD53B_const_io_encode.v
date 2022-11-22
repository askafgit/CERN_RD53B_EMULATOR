//--------------------------------------------------------------------------------------------------------------------------------------------------------------
//
// Create defines for RD53B command fnd output data fields
//
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Input command encoding
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Command encodings, found in RD53B command protocol:
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define   CMD_CLEAR           8'h5A
`define   CMD_G_PULSE         8'h5C   // Global pulse
`define   CMD_CAL             8'h63
`define   CMD_NOOP            8'hAA
`define   CMD_RDREG           8'h65
`define   CMD_WRREG           8'h66
                
                
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Command encodings, found in RD53B command protocol:
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define   C_SYNC_PAT          16'b1000_0001_0111_1110;


//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Trigger encoding. 4-bit trigger pattern is encoded as an 8-bit value in the command messages
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define   ENC_TRIG_01         8'b0010_1011    // 000T     Single trigger0 is encoded as 8'h2B
`define   ENC_TRIG_02         8'b0010_1101    // 00T0
`define   ENC_TRIG_03         8'b0010_1110    // 00TT
`define   ENC_TRIG_04         8'b0011_0011    // 0T00
`define   ENC_TRIG_05         8'b0011_0101    // 0T0T
`define   ENC_TRIG_06         8'b0011_0110    // 0TT0
`define   ENC_TRIG_07         8'b0011_1001    // 0TTT
`define   ENC_TRIG_08         8'b0011_1100    // T000
`define   ENC_TRIG_09         8'b0011_1100    // T00T
`define   ENC_TRIG_10         8'b0100_1011    // T0T0
`define   ENC_TRIG_11         8'b0100_1101    // T0TT
`define   ENC_TRIG_12         8'b0100_1110    // TT00
`define   ENC_TRIG_13         8'b0101_0011    // TT0T
`define   ENC_TRIG_14         8'b0101_0101    // TTT0
`define   ENC_TRIG_15         8'b0101_0110    // TTTT     Four triggers encoded as 8'h56


//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Data encoding. 5-bit data (0 to 31) encoded as an 8-bit value in the command messages
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define   ENC_DATA_00         8'b0110_1010    // 00000     Value 0 is encoded as 8h'6A
`define   ENC_DATA_01         8'b0110_1100    // 00001
`define   ENC_DATA_02         8'b0111_0001    // 00010
`define   ENC_DATA_03         8'b0111_0010    // 00011
`define   ENC_DATA_04         8'b0111_0100    // 00100
`define   ENC_DATA_05         8'b1000_1011    // 00101
`define   ENC_DATA_06         8'b1000_1101    // 00110
`define   ENC_DATA_07         8'b1000_1110    // 00111
`define   ENC_DATA_08         8'b1001_0011    // 01000
`define   ENC_DATA_09         8'b1001_0101    // 01001
`define   ENC_DATA_10         8'b1001_0110    // 01010
`define   ENC_DATA_11         8'b1001_1001    // 01011
`define   ENC_DATA_12         8'b1001_1010    // 01100
`define   ENC_DATA_13         8'b1001_1100    // 01101
`define   ENC_DATA_14         8'b1010_0011    // 01110
`define   ENC_DATA_15         8'b1010_0101    // 01111
`define   ENC_DATA_16         8'b1010_0110    // 10000
`define   ENC_DATA_17         8'b1010_1001    // 10001
`define   ENC_DATA_18         8'b0101_1001    // 10010
`define   ENC_DATA_19         8'b1010_1100    // 10011
`define   ENC_DATA_20         8'b1011_0001    // 10100
`define   ENC_DATA_21         8'b1011_0010    // 10101
`define   ENC_DATA_22         8'b1011_0100    // 10110
`define   ENC_DATA_23         8'b1100_0011    // 10111
`define   ENC_DATA_24         8'b1100_0101    // 11000
`define   ENC_DATA_25         8'b1100_0110    // 11001
`define   ENC_DATA_26         8'b1100_1001    // 11010
`define   ENC_DATA_27         8'b1100_1010    // 11011
`define   ENC_DATA_28         8'b1100_1100    // 11100
`define   ENC_DATA_29         8'b1101_0001    // 11101
`define   ENC_DATA_30         8'b1101_0010    // 11110
`define   ENC_DATA_31         8'b1101_0100    // 11111     Value 31 is encoded as 8h'D4


//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Output data encoding
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
// Encoding of MSBs in service blocks to indicate which fields are Autoread and User-requested register reads. 
//          Aurora code        (hex)                        Meaning
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`define   AUTO_BOTH           8'hB4           // Both register fields are of type AutoRead

// Define two `defines for this code
`define   AUTO_FIRST          8'h55           // First field is AutoRead, second is from a read register command
`define   RREG_SECOND         8'h55           // First field is AutoRead, second is from a read register command

// Define two `defines for this code
`define   AUTO_SECOND         8'h99           // First is from a read register command, second field is AutoRead
`define   RREG_FIRST          8'h99           // First is from a read register command, second field is AutoRead

`define   RREG_BOTH           8'hD2           // Both register fields are from read register commands

`define   RREG_ERROR          8'hCC           // Indicates an error. Fields are meaningless


