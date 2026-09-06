waitUntil {sleep 1; !isNil "active_sectors"};

while {true} do {
    uiSleep 600;

    {
        if !(isGroupDeletedWhenEmpty _x) then {
            if (local _x) then {
                _x deleteGroupWhenEmpty true;
            } else {
                [_x, true] remoteExec ["deleteGroupWhenEmpty", groupOwner _x];
            };
        };
    } forEach allGroups;
};
