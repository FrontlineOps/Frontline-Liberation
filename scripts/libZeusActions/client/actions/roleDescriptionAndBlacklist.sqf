

KC_DEBUG_ROLES = false;

KC_DEBUG_SKIP_ITEMS = [
	"rhs_fgm148_magazine_AT",
	"rhs_weap_fgm148",
	"rhs_fim92_mag",
	"rhs_weap_fim92",
	"rhs_weap_M136_hp",
	"rhs_weap_m72a7",
	"ACE_Chemlight_Shield_Red",
	"ACE_Chemlight_Shield_Blue",
	"ACE_Chemlight_Shield_Green",
	"ACE_Chemlight_Shield_Yellow",
	"ACE_Chemlight_Shield_White",
	"ACE_Chemlight_Shield_Orange"
];
KC_BLACKLIST_COLOR = [1,0.1,0.1,1];
KC_DEBUG_ROLE_PFH = {

	if(KC_DEBUG_ROLES == true) then {
		{
			private _items = itemsWithMagazines _x;
			_items = _items + (assignedItems _x);

			

			private _role = [_x] call RoleArsenal_DetermineRole;

			private _GearToAdd = [_role] call RoleArsenal_DetermineGear;
			
			private _itemsNotInRA = _items select {
				private _exists = false;
						if(!("TFAR" in _x)) then {
							if(!(_x in KC_DEBUG_SKIP_ITEMS)) then {

								private _item = _x;

								{
									if((toLowerANSI _x) == (toLowerANSI _item)) exitWith {
										_exists = true;
									};
									
								} forEach _GearToAdd;
				} else {
					_exists = true;
				};
				} else {
					_exists = true;
				};

				_exists == false
			};

			_itemsNotInRA = _itemsNotInRA arrayIntersect _itemsNotInRA;

	
			

			if((count _itemsNotInRA) > 0) then {
				drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", KC_BLACKLIST_COLOR, (ASLtoAGL getPosASLVisual _x) vectorAdd [0,0,5], 0.75, 0.75, 0, format ["HAS BLACKLISTED ITEMS: %1", _itemsNotInRA], 1, 0.025, "TahomaB"];
			};
			drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], ASLtoAGL getPosASLVisual _x, 0.75, 0.75, 0, format ["R %1", roleDescription _x], 1, 0.025, "RobotoCondensed"];
		} forEach allPlayers;
	} else {

		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};
};

private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	KC_DEBUG_ROLES = !KC_DEBUG_ROLES;

	if(KC_DEBUG_ROLES == true) then {

		[
			KC_DEBUG_ROLE_PFH,
			0,
			[]
		] call CBA_fnc_addPerFrameHandler;
	};
};


private _action = ["WTFIsTheRole", "Toggle Items Blacklist + Role Description Debug", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;


