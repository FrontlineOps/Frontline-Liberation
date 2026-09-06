/* Shared eligibility for the action and the final server transaction. */
params [["_object", objNull, [objNull]], ["_caller", objNull, [objNull]]];
if (isNull _object || {isNull _caller} || {!alive _caller}
    || {_caller distance2D _object > 10} || {!isNull objectParent _caller}
    || {_object getVariable ["KP_liberation_preplaced", false]}
    || {_object getVariable ["KP_liberation_edenObject", false]}
    || {getObjectType _object < 8} || {!isNull attachedTo _object}
    || {!isNull isVehicleCargo _object} || {getVehicleCargo _object isNotEqualTo []}
    // Virtual spare-wheel classnames disappear with the vehicle. Physical ACE
    // cargo objects must be unloaded first so hidden crates are not orphaned.
    || {(_object getVariable ["ace_cargo_loaded", []]) findIf {_x isEqualType objNull && {!isNull _x}} >= 0}
    || {ropeAttachedObjects _object isNotEqualTo []} || {ropes _object isNotEqualTo []}
    || {!isNull ropeAttachedTo _object}
    // ACE attaches an invisible fire source to wrecks; it is not transported cargo.
    || {attachedObjects _object findIf {!isNull _x && {typeOf _x != "ace_fire_logic"}} >= 0}
    || {abs speed _object > 1} || {(getPosATL _object select 2) > 3}) exitWith {false};

private _vehicle = _object isKindOf "LandVehicle" || {_object isKindOf "Air"} || {_object isKindOf "Ship"};
if (_vehicle) exitWith {
    // Unmanned drones have virtual AI crew. Never consume a player or a controlled drone.
    private _drone = unitIsUAV _object;
    (crew _object findIf {alive _x && {!_drone || {isPlayer _x}}}) < 0
        && {!_drone || {isNull ((UAVControl _object) param [0, objNull])}}
        && {!alive _object || {locked _object in [-1, 0, 1]}}
};

private _class = toLower typeOf _object;
alive _object && {_object distance2D startbase > 1000}
    && {(_class in KPLIB_b_buildings_classes)
        || {_class in KPLIB_upgradeBuildings}
        || {_class in KPLIB_storageBuildings && {(_object getVariable ["KP_liberation_storage_type", -1]) == 0}}
        || {((KPLIB_buildList select 6) + (KPLIB_buildList select 7)) findIf {toLower (_x select 0) == _class} >= 0}}
