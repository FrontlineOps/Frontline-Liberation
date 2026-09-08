params ["_status", "_remaining"];
private _timer = [ceil (_remaining max 0)] call KPLIB_fnc_secondsToTimer;
switch (_status) do {
    case "CAPTURING": {format ["Capturing - %1", _timer]};
    case "CONTESTED": {format ["Contested - %1 remaining", _timer]};
    case "CAPTURED": {"Captured by enemy"};
    case "STOPPED": {"Capture stopped"};
    default {"Awaiting capture update"};
}
