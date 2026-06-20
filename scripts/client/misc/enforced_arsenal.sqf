/*
	File: 
		scripts\client\misc\enforced_arsenal.sqf

	Author:
		Grom - https://github.com/a3r0id
	
	Description:
		> This handler is used to enforce the use of the specified weapons and magazines based on the players allowed loadout.
		> Primary/Secondary/Handgun are currently enforced as well as any items in player's cargo.
		> Auto-equips: Uniform, Android/Tablet, SR radio, Map if the respectable assignedItem slot is empty.

	Edit 03/26/2023:
		> Patched known exploit: players can use prohibited items if they don't open inventory.
		> Todo: Refactor my old, ugly code in here.
*/

// YOU CAN COPY & PASTE BELOW SCRIPT INTO DEBUG MENU FOR TESTING - EXECUTE LOCALLY

// player removeAllEventHandlers "InventoryClosed"; // For repetitive testing purposes
// player removeAllEventHandlers "Take"; 			// For repetitive testing purposes

_fnc_enforceArsenal = {
	params ["_unit", "_container", ["_item", 0]];

	if (isServer && hasInterface) then {
		systemChat "[DEBUG] _fnc_enforceArsenal fired";
	};

	// Allow for a global bypass to the arsenal, set through zeus action
	if (BYPASS_ENFORCED_ARSENAL) exitWith {};
	if (side player == GRLIB_side_enemy) exitWith {};

	fn_clean_array = {
		params["_array"];
		private _new_array = [];
		_new_array = _array select {_x isEqualType "STRING"};
		_new_array = _new_array select {_x != ""};
		_new_array
	};

	// Retrieve full arsenal 
	private _fullArsenal = [];
	{_fullArsenal pushBack (toLower _x)} forEach RA_FullArsenal;

	// Work out what the player is supposed to have
	private _loadout_full 	   = getUnitLoadout _unit;
	private _loadout      	   = [flatten(_loadout_full)] call fn_clean_array;
	private _items 		  	   = assignedItems _unit;
	private _allowed_loadout   = [[_unit] call RoleArsenal_DetermineRole] call RoleArsenal_DetermineGear;

	// Get Resupply crate items and add to allowed loadout whitelist
	{
		{
			if (typeName _x == "STRING") then {
				_allowed_loadout pushBack _x;
				_fullArsenal pushBack (toLower _x); // Add the crate items to the full whitelist - lowercase for easier comparison
			};
		} forEach (_y get "Items");
	} forEach ResupplyCrates; // global variable "ResupplyCrates" location: scripts\crate-resupply\config.sqf

	// Add all ammo types to the whitelist
	{
		_allowed_loadout pushBack _x;
	} forEach RA_AllAmmoTypes;

	private _allowed_loadout_lower = [];
	{_allowed_loadout_lower pushBack toLower(_x)} forEach _allowed_loadout;	

	// Find prohibited items in player's loadout.
	private _has_sr_radio = false;
	private _prohibited = [];
	{
		// Check if this is a SR radio, ignore if so TFAR_rf7800
		if ((toLower _x) find "tfar_anprc" > -1) then {
			_has_sr_radio = true;
		} else {
			// Check if the item is a valid item from our config, if not, ignore it.
			if ((toLower _x) in _fullArsenal) then {
				// If the item is in the player's loadout, but not in the allowed loadout, then its prohibited.
				if !((toLower _x) in _allowed_loadout_lower) then {
					// Add To Prohibited items
					_prohibited pushBack _x;	
				};
			};
		};
	} forEach _loadout;

	// Remove prohibited items from the player's loadout and replenish to the weapon holder.
	if (count _prohibited > 0) then {

		// Notify the unit
		[_prohibited] spawn {
			params["_prohibited"];
			[_prohibited joinString ", ", "You are not allowed the following items:"] call BIS_fnc_guiMessage;		
		};

		// https://community.bistudio.com/wiki/Category:Command_Group:_Unit_Inventory
		// https://community.bistudio.com/wiki/Unit_Loadout_Array

		// Create a groundWeaponHolder to drop our removed items into.
		// Todo: check for holders nearby and use that instead, if not full.
		private _holder       = "GroundWeaponHolder" createVehicle (position _unit);

		// Parse out loadout array - some stuff is redundant but it's easier to read/will be useful for future additions.
		private _primary_weapon   = _loadout_full#0;
		private _secondary_weapon = _loadout_full#1;	
		private _handgun_weapon   = _loadout_full#2;
		private _uniform          = _loadout_full#3;
		private _vest             = _loadout_full#4;
		private _backpack         = _loadout_full#5;
		private _headgear         = _loadout_full#6;
		private _goggles          = _loadout_full#7;
		private _binoculars		  = _loadout_full#8;
		private _assigned_items   = _loadout_full#9;

		// If unit has a primary Weapon and it's not in the allowed loadout, then drop it into the holder w/ all attachments.
		if (count _primary_weapon > 0) then {
			if ((_primary_weapon#0) in _prohibited) then {
				_unit removeWeaponGlobal (_primary_weapon#0);
				_holder addWeaponWithAttachmentsCargo [_primary_weapon, 1];
			};
		};

		// If unit has a secondary Weapon and it's not in the allowed loadout, then drop it into the holder w/ all attachments.
		if (count _secondary_weapon > 0) then {
			if ((_secondary_weapon#0) in _prohibited) then {
				_unit removeWeaponGlobal (_secondary_weapon#0);
				_holder addWeaponWithAttachmentsCargo [_secondary_weapon, 1];
			};
		};

		// If unit has a handgun Weapon and it's not in the allowed loadout, then drop it into the holder w/ all attachments.
		if (count _handgun_weapon > 0) then {
			if ((_handgun_weapon#0) in _prohibited) then {
				_unit removeWeaponGlobal (_handgun_weapon#0);
				_holder addWeaponWithAttachmentsCargo [_handgun_weapon, 1];
			};
		};

		// General Cargo Items - check cargo of uniform, vest, backpack
		private _cargo_items = (uniformItems _unit) + (backpackItems _unit) + (vestItems _unit);
		{
			if (_x in _prohibited) then {
				_holder addItemCargoGlobal [_x, 1];
				_unit unassignItem _x;
				_unit removeItem (_x);
			};
		} forEach _cargo_items;
		
		// TODO: Check if uniform/vest/backpack is prohibited - Necessary!

		// TODO: Check if headgear is prohibited - Probably not necessary

		// TODO: Check if goggles are prohibited - Probably not necessary

		// TODO: Check if bioculars are prohibited - Probably not necessary (?)

		// TODO: Check if assigned items are prohibited - Probably not necessary

	};

	// Ensure default gear, see: onPlayerRespawn.sqf

	// Uniform Check & Addition
	if !(count (uniform _unit) > 0) then {
		// Assign a default uniform to unit, consistent w/ onPlayerRespawn.
		_unit forceAddUniform selectRandom RA_StartingUniforms;
	};

	// Android/tab Check & Addition
	private _term = _loadout_full#9#1;
	if (count(_term) == 0) then {
		// Give them a tablet if they are allowed else give them an android.
		if ("ItemCtab" in _allowed_loadout_lower) then {/// ItemGPS
			_unit linkitem "ItemCtab";
		} else {
			_unit linkitem "ItemAndroid";
		};
	};

	// SR Radio Check & Addition
	if !(_has_sr_radio) then {
		_unit linkItem "TFAR_anprc152";//TFAR_anprc152
	};

	// Map Check Check & Addition
	if !("ItemMap" in (assigneditems _unit)) then {
		_unit addItem "ItemMap";
		_unit assignItem "ItemMap";
	};	

};

[player, "InventoryClosed", _fnc_enforceArsenal] 	call CBA_fnc_addBISEventHandler;
[player, "Take", _fnc_enforceArsenal] 				call CBA_fnc_addBISEventHandler;

