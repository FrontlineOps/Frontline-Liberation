/* Mission protections checked again on the object's actual owner. No changes
   to native damage handlers or eligibility for native explosions. */
params ["_object"];
if (isNull _object || {!alive _object} || {isSimpleObject _object} || {isObjectHidden _object}) exitWith {false};
if !(_object isKindOf "House" || {_object isKindOf "LandVehicle"} || {_object isKindOf "Air"}
    || {_object isKindOf "Ship"} || {_object isKindOf "StaticWeapon"}) exitWith {false};
if (typeOf _object == (missionNamespace getVariable ["FOB_typename", ""])) exitWith {false};
if ((_object getVariable ["KPLIB_pressure_ignore", false]) isEqualTo true) exitWith {false};
if (local _object && {!isDamageAllowed _object}) exitWith {false};
true
