class KPLIB {
    class module_settings {
        file = "modules\settings";

        class settingsPreInit {preInit = 1;};
        class settingsValidate {};
        class settingsDerive {};
        class settingsApply {};
        class settingsCommit {};
        class settingsReceive {};
    };
    class module_gas {
        file = "modules\munitions\gas";

        class gasCreate    {};
        class gasPrimitive {};
        class gasFlux      {};
        class gasStep      {};
        class gasInject    {};
        class gasSample    {};
        class gasNative    {};
        class gasNativeReport {};
        class gasMetadata  {};
        class gasPosition {};
        class gasBlastStart {};
        class gasBlastStep {};
        class gasBlastDose {};
        class gasTargetSamples {};
        class gasTargetsStep {};
        class gasOpeningStep {};
        class gasDust {};
        class gasDustReceive {};
        class gasBlastFinish {};
        class gasDraw {};
        class gasPublish {};
        class gasJobReport {};
        class gasFrame {};
        class gasColor {};
        class gasPayload {};
        class gasAssetEligible {};
        class gasAssetsFind {};
        class gasAssetProfile {};
        class gasAssetStep {};
        class gasAssetApply {};
        class gasAssetReport {};
    };
    class module_blast {
        file = "modules\munitions\blast";

        class blastInit     {};
        class blastProfile  {};
        class blastObserve  {};
        class blastRequest  {};
        class blastStart    {};
        class blastTick     {};
        class blastStep     {};
        class blastPrimary  {};
        class blastExposure {};
        class blastClear    {};
        class blastClearBatch {};
        class blastEnvelope {};
        class blastView     {};
        class blastAccount  {};
        class blastWound    {};
        class blastApply    {};
        class blastTrace    {};
        class blastTraumaInit {};
        class blastTrauma {};
        class blastTraumaDecay {};
        class blastTraumaSend {};
        class blastTraumaReceive {};
        class blastTraumaReset {};
        class blastTraumaTick {};
    };
    class module_munitions {
        file = "modules\munitions";

        class munitionsSettingsInit {preInit = 1;};
        class munitionsSettings {};
        class munitionsFragProfile {};
        class munitionsEmit {};
        class munitionsParticleTick {};
        class munitionsMaterial {};
        class munitionsSpallHit {};
        class munitionsImpact {};
        class munitionsDebris {};
        class munitionsDebrisTick {};
        class munitionsSurfaceDebris {};
        class munitionsBackfaceEvent {};
        class munitionsBackfaceTick {};
        class munitionsBackfaceSurface {};
        class munitionsInit     {};
        class munitionsFragInit {};
        class munitionsFrag     {};
        class munitionsFragDirections {};
        class munitionsFragSpatial {};
        class munitionsSpall    {};
        class munitionsControl  {};
        class munitionsTrack    {};
        class munitionsEvent    {};
        class munitionsTick     {};
        class munitionsAmmo     {};
        class munitionsSnapshot {};
        class munitionsReport   {};
        class munitionsRequest  {};
        class munitionsCollect  {};
        class munitionsDeliver  {};
        class munitionsDisplay  {};
        class munitionsKind {};
        class munitionsPoint {};
        class munitionsBurst {};
        class munitionsRecent {};
        class munitionsPaths {};
        class munitionsLivePaths {};
        class munitionsPayload {};
        class munitionsDraw {};
        class munitionsHud {};
        class munitionsMerge {};
        class munitionsDebugState {};
        class munitionsDebugTick {};
        class munitionsLiveTick {};
        class munitionsLiveCollect {};
        class munitionsLiveDeliver {};
        class munitionsLiveReceive {};
        class munitionsLiveField {};
        class munitionsLog {};

    };
    class module_combat_fire {
        file = "modules\ai_combat\combat_fire";

        class combatFireInit {};
        class combatFireModes {};
        class combatFirePlan {};
        class combatFireStep {};
        class combatFireFired {};
        class combatFireTick {};
    };
    class module_vehicle_combat {
        file = "modules\ai_combat\vehicle_combat";

        class vehicleCombatInit {};
        class vehicleCombatRegister {};
        class vehicleCombatEligible {};
        class vehicleCombatProfile {};
        class vehicleCombatWeapons {};
        class vehicleCombatChoose {};
        class vehicleCombatVisible {};
        class vehicleCombatSafe {};
        class vehicleCombatRequest {};
        class vehicleCombatPeer {};
        class vehicleCombatLease {};
        class vehicleCombatRelease {};
        class vehicleCombatRestoreLocal {};
        class vehicleCombatUpdate {};
        class vehicleCombatFire {};
        class vehicleCombatTick {};
        class vehicleCombatInspect {};
    };
    class module_ai_combat {
        file = "modules\ai_combat";

        class aiCombatInit     {};
        class aiCombatRegister {};
        class aiCombatEligible {};
        class aiCombatProfile  {};
        class aiCombatWeapons  {};
        class aiCombatVisible  {};
        class aiCombatSafe     {};
        class aiCombatStart    {};
        class aiCombatSolution {};
        class aiCombatFinish   {};
        class aiCombatRestore  {};
        class aiCombatUpdate   {};
        class aiCombatFire {};
        class aiCombatTick     {};
        class aiCombatFired    {};
        class aiCombatSound    {};
        class aiCombatHear     {};
        class aiCombatInvestigate {};
        class aiCombatInspect  {};
    };
    class module_guidance {
        file = "modules\missileGuidance";

        class guidanceInit       {};
        class guidanceResolve    {};
        class guidanceBackend    {};
        class guidanceRegister   {};
        class guidanceStart      {};
        class guidanceRetire     {};
        class guidanceTick       {};
        class guidanceCandidates {};
        class guidanceVisible    {};
        class guidanceSupport    {};
        class guidanceSeeker     {};
        class guidanceNavigation {};
        class guidanceSteer      {};
        class guidanceFuze       {};
        class guidanceNotify     {};
        class guidanceReceive    {};
        class guidanceInspect    {};
    };
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
        class initUavCrew   {};
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

        class initFactions                 {};
        class applyFactionPresets          {};
        class loadFactionProfiles          {};
        class normalizeGearClass           {};
        class getPlayerRole                {};
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
