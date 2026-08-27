class KPLIB {
    class functions {
        file = "functions";

        class addActionsFob             {};
        class addActionsPlayer          {};
        class addObjectInit             {};
        class addRopeAttachEh           {};
        class allowCrewInImmobile       {};
        class bluforKillWarning         {};
        class checkClass                {};
        class checkCrateValue           {};
        class checkGear                 {};
        class checkWeaponCargo          {};
        class civKillWarning            {};
        class cleanOpforVehicle         {};
        class clearCargo                {};
        class crAddAceAction            {};
        class crateFromStorage          {};
        class crateToStorage            {};
        class crawlAllItems             {};
        class createClearance           {};
        class createClearanceConfirm    {};
        class createCrate               {};
        class createManagedUnit         {};
        class createPBMarker            {};
        class crGetMulti                {};
        class crGlobalMsg               {};
        class doSave                    {};
        class fillStorage               {};
        class forceBluforCrew           {};
        class getAdaptiveVehicle        {};
        class getBluforRatio            {};
        class getCommander              {};
        class getCrateHeight            {};
        class getFobName                {};
        class getFobResources           {};
        class getGroupType              {};
        class getLessLoadedHC           {};
        class getLoadout                {};
        class getLocalCap               {};
        class getLocationName           {};
        class getMilitaryId             {};
        class getMobileRespawns         {};
        class getNearbyPlayers          {};
        class getNearestBluforObjective {};
        class getNearestBluforSector    {};
        class getNearestFob             {};
        class getNearestOpforSector     {};
        class getNearestSector          {};
        class getNearestTower           {};
        class getNearestViVTransport    {};
        class getOpforCap               {};
        class getOpforFactor            {};
        class getOpforSpawnPoint        {};
        class getPlayerCount            {};
        class getResistanceTier         {};
        class getSaveableParam          {};
        class getSaveData               {};
        class getSectorOwnership        {};
        class getSectorRange            {};
        class getSquadComp              {};
        class getStoragePositions       {};
        class getUnitPositionId         {};
        class getUnitsCount             {};
        class getWeaponComponents       {};
        class handlePlacedZeusObject    {};
        class hasPermission             {};
        class initSectors               {};
        class isBigtownActive           {};
        class isClassUAV                {};
        class isRadio                   {};
        class isNearFriendlyPB          {};
        class log                       {};
        class onPause                   {};
        class potatoScan                {};
        class protectObject             {};
        class secondsToTimer            {};
        class setFobMass                {};
        class setLoadableViV            {};
        class setLoadout                {};
        class setupVehicle              {};
        class setVehicleCaptured        {};
        class setVehicleSeized          {};
        class sortStorage               {};
        class spawnBuildingSquad        {};
        class spawnCivilians            {};
        class spawnGuerillaGroup        {};
        class spawnMilitaryPostSquad    {};
        class spawnMilitiaCrew          {};
        class spawnRegularSquad         {};
        class spawnVehicle              {};
        class swapInventory             {};
    };
    class functions_curator {
        file = "functions\curator";

        class initCuratorHandlers       {
            postInit = 1;
        };
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
    #include "scripts\client\CfgFunctions.hpp"
    #include "scripts\server\CfgFunctions.hpp"
};
