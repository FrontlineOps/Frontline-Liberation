params [["_lines", [], [[]]]];
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}
    || {count _lines > 24} || {_lines findIf {!(_x isEqualType "") || {count _x > 400}} >= 0}) exitWith {};
// Escape class display names and other returned text before structured rendering.
private _rows = [];
{
    private _line = ((_x splitString "&") joinString "&amp;");
    _line = (_line splitString "<") joinString "&lt;";
    _line = (_line splitString ">") joinString "&gt;";
    private _color = if (_forEachIndex == 0) then {"#6EDBE8"} else {"#E4E9ED"};
    private _size = if (_forEachIndex == 0) then {1.15} else {0.85};
    _rows pushBack format ["<t align='left' color='%1' size='%2'>%3</t>", _color, _size, _line];
} forEach _lines;
hintSilent parseText (_rows joinString "<br/>");
