// Repair missing OPFOR uniforms every two minutes. Spawn-time object init
// owns the RTO loadout; maintenance must not replenish combat ammunition.
if (!isServer) exitWith {};

KC_FIX_AI_LOADOUT = {
    {
        if (!local _x || {!alive _x} || {isPlayer _x} || {!(_x isKindOf "Man")}) then {continue};
        if (side group _x != GRLIB_side_enemy || {captive _x}) then {continue};
        if (_x getVariable ["KPLIB_intelligencePrisoner", false] || {_x getVariable ["KPLIB_surrenderInProgress", false]}) then {continue};

        private _nightVision = if (missionNamespace getVariable ["KPLIB_autoFactionActive", false]) then {
            missionNamespace getVariable ["KPLIB_autoFactionOpforNightVision", ""]
        } else {
            "rhs_1PN138"
        };
        if (_nightVision != "" && {!(_nightVision in assignedItems _x)}) then {
            _x linkItem _nightVision;
        };

        if (uniform _x == "" && {opfor_uniforms isNotEqualTo []}) then {
            // Restore only the missing garment, preserving current weapons,
            // remaining magazines and all other carried equipment.
            _x forceAddUniform (selectRandom opfor_uniforms);
        };
    } forEach allUnits;
};

while {true} do {
    [] call KC_FIX_AI_LOADOUT;
    sleep 120;
};
