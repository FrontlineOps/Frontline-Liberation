params ["_vehicle"];

// AIM SLOTS
_vehicle setPylonLoadout [1, "rhs_mag_Sidewinder_heli_2", true]; // Left
_vehicle setPylonLoadout [6, "rhs_mag_Sidewinder_heli_2", true]; // Right

// LEFT HYDRA POD
_vehicle setPylonLoadout [3, "FIR_Hydra_M229_P_19rnd_M", true];

// RIGHT HYDRA POD
_vehicle setPylonLoadout [4, "FIR_Hydra_M229_P_19rnd_M", true];

// LEFT HELLFIRE RACK
_vehicle setPylonLoadout [2, "FIR_APKWS_M282_P_7rnd_M", true];

// RIGHT HELLFIRE RACK
_vehicle setPylonLoadout [5, "FIR_APKWS_M282_P_7rnd_M", true];

// Chaff
_vehicle setPylonLoadout [7, "rhsusf_ANALE39_CMFlare_Chaff_Magazine_x4", true];
