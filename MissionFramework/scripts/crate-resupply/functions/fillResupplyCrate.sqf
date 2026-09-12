localNamespace setVariable ["KPLIB_fillResupplyCrate", {

	params ["_crate"];
    if (!isServer) exitWith {};


    private _record = (localNamespace getVariable "KPLIB_resupplyRegistry") getOrDefault [netId _crate, []];
    if (_record isEqualTo []) exitWith {};
    private _crateType = _record select 0;

	diag_log format ["Fill Crate Exec [%1, %2]", _crate, _crateType];
	if( !isNil{ _crateType }) then {
        private _crateInfo = (localNamespace getVariable "KPLIB_resupplyDefinitions") get _crateType;

		clearItemCargoGlobal _crate;
		clearMagazineCargoGlobal _crate;
		clearWeaponCargoGlobal _crate;
		clearBackpackCargoGlobal _crate;

		{
			_crate addWeaponCargoGlobal [_x, _y];
		} forEach (_crateInfo getOrDefault ["Weapons", createHashMap]);
		{
			_crate addMagazineCargoGlobal [_x, _y];
		} forEach (_crateInfo getOrDefault ["Magazines", createHashMap]);
		{
			_crate addBackpackCargoGlobal [_x, _y];
		} forEach (_crateInfo getOrDefault ["Backpacks", createHashMap]);

		private _itemsMap = _crateInfo getOrDefault ["Items", createHashMap];
		{
            private _itemClass = _x;
            private _itemAmount = _y;
			
			// Check if the item is a backpack
			// https://community.bistudio.com/wiki/BIS_fnc_itemType
			_itemClass call BIS_fnc_itemType params[ "_type", "_subType" ];

			switch (_subType) do {
				case "Backpack": { _crate addBackpackCargoGlobal  [_itemClass, _itemAmount]; };
				default { _crate addItemCargoGlobal [_itemClass, _itemAmount]; };
			};

		} forEach _itemsMap;
	};
}];
