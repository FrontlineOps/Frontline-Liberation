KC_DEBUG_WH = false;

KC_DEBUG_WH_PFH = { 
 
    if(KC_DEBUG_WH == true) then { 
        { 
   private _obj = cameraOn; 
   private _dist = _x distance2D _obj; 
 
   private _size = 1; 
 
   _size = _size - (0.1 * floor((_dist / 250))); 
 
   _size = _size max 0.1; 
            drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,_size * 0.6], ASLToAGL (_x modelToWorldVisualWorld (getCenterOfMass _x)), _size, _size, 0, name _x, 0, _size * 0.03, "TahomaB"]; 
        } forEach allPlayers;
    } else { 
 
        [_this select 1] call CBA_fnc_removePerFrameHandler; 
    }; 
}; 



private _statement = {
    params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
    KC_DEBUG_WH = !KC_DEBUG_WH;

    if(KC_DEBUG_WH == true) then {

        [
            KC_DEBUG_WH_PFH,
            0,
            []
        ] call CBA_fnc_addPerFrameHandler;
    };
};


private _action = ["lolwallhack", "Toggle Wallhacks", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;
