maxGamma = 1.05;
gammaWarned = false;

lib_terrain_handler = [{

    private _terrainQuality = 3.125; // desired value 
 
    if (getTerrainGrid != _terrainQuality) then { setTerrainGrid _terrainQuality; };

}, 1] call CBA_fnc_addPerFrameHandler;

kog_handler_restrictGamma = [{
	private _gamma = getVideoOptions getOrDefault ["gamma", 1.1];
	private _brightness = getVideoOptions getOrDefault ["brightness", 1.1];
	private _ppBrightness = getVideoOptions getOrDefault ["ppBrightness", 1.1];

	if ((_gamma > maxGamma || _brightness > maxGamma || _ppBrightness > maxGamma) && !gammaWarned) then {
		_msg = format ["Gamma/Brightness/AA PP Brightness cannot exceed %1 for this mission, please go into settings and lower the value", maxGamma];
		cutText ["<t font ='RobotoCondensedLight' align = 'center' size='2.3' color='#d6d6d6'>" + _msg + "</t>", "BLACK", -1, true, true];
		
		gammaWarned = true;
	} else 
	{
		if ((_gamma <= maxGamma && _brightness <= maxGamma && _ppBrightness <= maxGamma) && gammaWarned) then {
			cutText ["", "BLACK IN"];
			gammaWarned = false;
		};
	};
	
} , 0.3] call CBA_fnc_addPerFrameHandler;