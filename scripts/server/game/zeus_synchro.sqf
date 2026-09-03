waitUntil {!isNil "huron_typename"};

// Classnames of objects which should be added as editable for Zeus
private _vehicleClassnames = [toLower huron_typename];
{
    _vehicleClassnames append _x;
} forEach [
    KPLIB_crates,
    KPLIB_b_light_classes,
    KPLIB_b_recon_classes,
    KPLIB_b_medical_classes,
    KPLIB_b_groundlogi_classes,
    KPLIB_b_artillery_classes,
    KPLIB_b_atgm_classes,
    KPLIB_b_aa_classes,
    KPLIB_b_heavy_classes,
    KPLIB_b_air_classes,
    KPLIB_b_static_classes,
    KPLIB_b_support_classes
];
if (KP_liberation_enemies_zeus) then {_vehicleClassnames append KPLIB_o_allVeh_classes;};

private _vehicleClassIndex = createHashMap;
{
    _vehicleClassIndex set [_x, true];
} forEach (_vehicleClassnames arrayIntersect _vehicleClassnames);

private _reconcileInterval = missionNamespace getVariable ["KP_liberation_zeus_sync_interval", 15];
private _batchSize = 1 max floor (missionNamespace getVariable ["KP_liberation_zeus_sync_batch_size", 32]);
private _batchInterval = 0 max (missionNamespace getVariable ["KP_liberation_zeus_sync_batch_interval", 0.2]);
private _syncBatches = {
    params ["_curator", "_objects", "_add"];
    private _remaining = +_objects;
    if (count _remaining > _batchSize) then {
        [
            format [
                "Pacing %1 Zeus editable-object %2 across %3 batches",
                count _remaining,
                ["removals", "additions"] select _add,
                ceil (count _remaining / _batchSize)
            ],
            "ZEUS"
        ] call KPLIB_fnc_log;
    };
    while {_remaining isNotEqualTo [] && {!isNull _curator}} do {
        private _count = _batchSize min count _remaining;
        private _batch = _remaining select [0, _count];
        _remaining deleteRange [0, _count];
        _batch = _batch select {
            !isNull _x && {(!_add) || {alive _x && {isNull (attachedTo _x)}}}
        };
        if (_batch isNotEqualTo []) then {
            if (_add) then {
                _curator addCuratorEditableObjects [_batch, false];
            } else {
                _curator removeCuratorEditableObjects [_batch, false];
            };
        };
        if (_remaining isNotEqualTo [] && {_batchInterval > 0}) then {
            sleep _batchInterval;
        };
    };
};

[
    format ["Zeus editable-object synchronization initialized (reconcile=%1s, batch=%2, batchInterval=%3s)", _reconcileInterval, _batchSize, _batchInterval],
    "ZEUS"
] call KPLIB_fnc_log;

while {true} do {
    private _curators = allCurators;
    if (_curators isEqualTo []) then {
        sleep 1;
        continue;
    };

    // Add units
    private _validUnits = allUnits select {
        (alive _x)                                                                              // Alive
        && {
            (KP_liberation_enemies_zeus && {!(side (group _x) isEqualTo GRLIB_side_civilian)})  // Not civilian side, if enemy adding is enabled
            || {side (group _x) isEqualTo GRLIB_side_friendly}                                  // Player side if enemy adding is disabled
        }
        && {((str _x) find "BIS_SUPP_HQ_") isEqualTo -1}                                        // Not a HQ entity from support module
    };

    // Add vehicles
    private _validVehicles = vehicles select {
        (alive _x)                                                                              // Alive
        && {
            (_vehicleClassIndex getOrDefault [toLower (typeOf _x), false])                       // In valid classnames
            || (_x getVariable ["KPLIB_captured", false])                                       // or captured
            || (_x getVariable ["KPLIB_seized", false])                                         // or seized
        }
        && {isNull (attachedTo _x)}                                                             // Not attached to something
    };

    // Add vehicle crews explicitly so recursive curator additions never expand a batch.
    {
        _validUnits append (crew _x);
    } forEach _validVehicles;

    // Add playable units
    _validUnits append switchableUnits;
    _validUnits append playableUnits;
    _validUnits = _validUnits arrayIntersect _validUnits;
    _validVehicles = _validVehicles arrayIntersect _validVehicles;

    {
        private _curator = _x;
        private _editable = curatorEditableObjects _curator;

        // Remove death or attached units
        private _toRemove = _editable select {!(alive _x) || !(isNull (attachedTo _x))};

        private _vehiclesToAdd = _validVehicles - _editable;
        private _unitsToAdd = _validUnits - _editable;

        [_curator, _vehiclesToAdd, true] call _syncBatches;
        [_curator, _unitsToAdd, true] call _syncBatches;
        [_curator, _toRemove, false] call _syncBatches;
    } forEach _curators;
    sleep _reconcileInterval;
};
