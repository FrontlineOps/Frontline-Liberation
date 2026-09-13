/* Pure eligibility, also used by the server when authorizing a turret lease. */
params ["_unit", ["_requireLocal", true]];
if (!(missionNamespace getVariable ["KPLIB_vehicleCombat_enabled", false])) exitWith {"Disabled"};
if (isNull _unit || {!alive _unit} || {isPlayer _unit}) exitWith {"No living AI operator"};
private _vehicle = objectParent _unit;
if (isNull _vehicle || {!alive _vehicle} || {!(simulationEnabled _vehicle)}) exitWith {"Vehicle unavailable"};
if (!(_vehicle isKindOf "Tank" || {_vehicle isKindOf "Wheeled_APC_F"})) exitWith {"Not a tank/APC/IFV"};
if (getNumber (configOf _vehicle >> "artilleryScanner") > 0) exitWith {"Artillery retains native control"};
private _role = assignedVehicleRole _unit;
if (count _role < 2 || {_role select 0 != "Turret"}) exitWith {"Not a turret operator"};
private _path = _role select 1;
if (_vehicle turretUnit _path != _unit) exitWith {"Turret changed"};
if (_requireLocal && {!local _unit || {!(_vehicle turretLocal _path)}}) exitWith {"Other turret owner"};
if (crew _vehicle findIf {isPlayer _x || {local _x && {!isNull remoteControlled _x}}} >= 0) exitWith {"Player controls vehicle"};
if (!(side group _unit in [west, east, resistance])) exitWith {"Noncombatant crew"};
if (captive _unit || {lifeState _unit == "INCAPACITATED"} || {_unit getVariable ["ACE_isUnconscious", false]}
    || {_unit getVariable ["KPLIB_intelligencePrisoner", false]} || {_unit getVariable ["KPLIB_surrenderInProgress", false]}
    || {_unit getVariable ["ace_captives_isSurrendering", false]}) exitWith {"Operator incapacitated or surrendered"};
private _mode = unitCombatMode _unit;
if (!(combatMode group _unit in ["YELLOW", "RED"])
    || {_mode != "" && {!(_mode in ["YELLOW", "RED"])}}) exitWith {"Hold fire"};
if (behaviour _unit == "STEALTH" || {group _unit getVariable ["KPLIB_lambs_forceMove", false]}) exitWith {"Stealth or forced movement"};
// AI feature state is meaningful on the operator's owner. Server validation of
// an HC request checks identity/ROE; the HC also runs this local feature gate.
if (local _unit && {!(_unit checkAIFeature "WEAPONAIM") || {!(_unit checkAIFeature "TARGET")}}) exitWith {"Aiming or targeting disabled"};
""
