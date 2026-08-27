waitUntil { !isNil "save_is_loaded" };
waitUntil {save_is_loaded};

while {true} do {
    sleep (missionNamespace getVariable ["KP_liberation_resource_reconcile_interval", 15]);
    please_recalculate = true;
};
