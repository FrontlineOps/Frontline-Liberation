class KPLIB {
    class module_factory_depots {
        file = "modules\factory_depots";

        class factoryInit    {};
        class factoryEnsure  {};
        class factoryLayout  {};
        class factoryClear   {};
        class factoryPlan    {};
        class factorySave    {};
        class factoryRestore {};
        class factoryStatus  {};
        class factoryTick    {};
        class factoryReceive {};
    };
    class module_ai_skills {
        file = "modules\ai_skills";

        class aiSkillsInit     {};
        class aiSkillsRegister {};
        class aiSkillsEligible {};
        class aiSkillsTick     {};
        class aiSkillsUpdate   {};
        class aiSkillsCompose  {};
        class aiSkillsThreat   {};
        class aiSkillsFired    {};
        class aiSkillsInspect  {};
        class aiSkillsReceive  {};
    };
    class functions_capture {
        file = "functions\capture";

        class captureStatusInit    {};
        class captureStatusSet     {};
        class captureStatusPublish {};
        class captureStatusReceive {};
        class captureStatusRender  {};
        class captureStatusText    {};
    };
    class functions_actions {
        file = "functions\actions";

        class actionLabel            {};
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
        class getNearbyPlayers  {};
        class getPlayerCount    {};
        class ensurePlayerRadio {};
    };
    class functions_resources {
        file = "functions\resources";

        class checkCrateValue     {};
        class canRecycle          {};
        class clearCargo          {};
        class crateFromStorage    {};
        class crateToStorage      {};
        class createCrate         {};
        class fillStorage         {};
        class getCrateHeight      {};
        class getRecycleDepot     {};
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

        class applyFactionPresets          {};
        class loadFactionProfiles          {};
        class normalizeGearClass           {};
        class getPlayerRole                {};
        class getAutomaticRole             {};
        class initPlayerArsenal            {};
        class getRoleGear                  {};
        class filterRoleLoadout            {};
        class buildAutomaticResupplyCrates {};
        class buildFactionCatalog          {};
        class buildFactionIndex            {};
        class classifyFactionVehicle       {};
        class getVehicleAirDefense         {};
        class collectFactionArsenal        {};
        class getAutomaticFactionPrice     {};
        class getMagazineResourceValue     {};
        class getVehicleResourceProfile    {};
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
        class garrisonSelect               {};
        class garrisonAssign               {};
        class garrisonMove                 {};
        class garrisonRetry                {};
        class garrison                     {}; // [] call KPLIB_fnc_garrison
        class isIndoor                     {}; // [] call KPLIB_fnc_isIndoor
        class removeLambsEventHandlers     {}; // [] call KPLIB_fnc_removeLambsEventHandlers
        class taskPatrol                   {}; // [] call KPLIB_fnc_taskPatrol
        class taskPatrolWaypointStatement  {};
        class taskReset                    {}; // [] call KPLIB_fnc_taskReset
    };
    #include "scripts\server\CfgFunctions.hpp"
};
