class KPLIB {
    class functions_actions {
        file = "functions\actions";

        class addActionsFob          {};
        class addActionsPlayer       {};
        class createClearanceConfirm {};
    };
    class functions_civilian {
        file = "functions\civilian";

        class civKillWarning     {};
        class crAddAceAction     {};
        class crGlobalMsg        {};
    };
    class functions_common {
        file = "functions\common";

        class addObjectInit  {};
        class checkClass     {};
        class log            {};
        class protectObject  {};
        class secondsToTimer {};
    };
    class functions_fob {
        file = "functions\fob";

        class createClearance   {};
        class getFobName        {};
        class getFobResources   {};
        class getMobileRespawns {};
        class getNearestFob     {};
        class potatoScan        {};
        class repackageFob      {};
        class setFobMass        {};
    };
    class functions_players {
        file = "functions\players";

        class bluforKillWarning {};
        class configureChatChannels {
            postInit = 1;
        };
        class getCommander      {};
        class getLocalCap       {};
        class getNearbyPlayers  {};
        class getPlayerCount    {};
    };
    class functions_resources {
        file = "functions\resources";

        class checkCrateValue     {};
        class clearCargo          {};
        class crateFromStorage    {};
        class crateToStorage      {};
        class createCrate         {};
        class fillStorage         {};
        class getCrateHeight      {};
        class getStoragePositions {};
        class sortStorage         {};
    };
    class functions_save {
        file = "functions\save";

        class doSave           {};
        class getSaveableParam {};
        class getSaveData      {};
    };
    class functions_sectors {
        file = "functions\sectors";

        class countUnitsBySide          {};
        class getBluforRatio            {};
        class getLocationName           {};
        class getNearestOpforSector     {};
        class getNearestSector          {};
        class getNearestTower           {};
        class getOpforCap               {};
        class getSectorOwnership        {};
        class getSectorRange            {};
        class getUnitsCount             {};
        class initSectors               {};
    };
    class functions_units {
        file = "functions\units";

        class createManagedUnit {};
        class forceBluforCrew   {};
        class getGroupType      {};
    };
    class functions_vehicles {
        file = "functions\vehicles";

        class addRopeAttachEh        {};
        class getNearestViVTransport {};
        class isClassUAV             {};
        class setLoadableViV         {};
        class setVehicleCaptured     {};
        class setVehicleSeized       {};
    };
    class functions_curator {
        file = "functions\curator";

        class initCuratorHandlers       {
            postInit = 1;
        };
        class handlePlacedZeusObject    {};
        class requestZeus               {};
    };
    class functions_ui {
        file = "functions\ui";

        class overlayUpdateResources    {};
    };
    class functions_factions {
        file = "functions\factions";

        class applyAutomaticFactionPresets {};
        class buildAutomaticResupplyCrates {};
        class buildFactionCatalog          {};
        class buildFactionIndex            {};
        class classifyFactionVehicle       {};
        class getVehicleAirDefense         {};
        class collectFactionArsenal        {};
        class getAutomaticFactionPrice     {};
        class getConfigCargo               {};
        class pickFactionUnit              {};
    };
    class functions_lambs
    {
        file = "functions\lambs";
        class findClosestTarget	{};		// [] call KPLIB_fnc_findClosestTarget
        class findBuildings		{};		// [] call KPLIB_fnc_findBuildings
        class doUgl 			{};		// [] call KPLIB_fnc_doUgl
        class checkMagazineAiUsageFlags {};
        class doAnimation                   {};
        class getLauncherUnits              {};
        class isAlive                       {};
        class hunt                         {}; // [] call KPLIB_fnc_hunt
        class rush                         {}; // [] call KPLIB_fnc_rush
        class garrison                     {}; // [] call KPLIB_fnc_garrison
        class isIndoor                     {}; // [] call KPLIB_fnc_isIndoor
        class removeLambsEventHandlers     {}; // [] call KPLIB_fnc_removeLambsEventHandlers
        class taskPatrol                   {}; // [] call KPLIB_fnc_taskPatrol
        class taskPatrolWaypointStatement  {};
        class taskReset                    {}; // [] call KPLIB_fnc_taskReset
    };
    #include "scripts\server\CfgFunctions.hpp"
};
