class liberation_player_permissions {
    idd = 75820;
    movingEnable = false;
    class controlsBackground {
        class Background: StdBG {
            x = 0.18 * safezoneW + safezoneX;
            y = 0.19 * safezoneH + safezoneY;
            w = 0.64 * safezoneW;
            h = 0.62 * safezoneH;
            colorBackground[] = COLOR_GREEN;
        };
    };
    class controls {
        class Header: StdHeader {
            text = "PLAYER PERMISSIONS";
            x = 0.18 * safezoneW + safezoneX;
            y = 0.19 * safezoneH + safezoneY;
            w = 0.64 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = COLOR_BROWN;
        };
        class Players: StdListBox {
            idc = 101;
            x = 0.20 * safezoneW + safezoneX;
            y = 0.27 * safezoneH + safezoneY;
            w = 0.24 * safezoneW;
            h = 0.41 * safezoneH;
            onLBSelChanged = "[] call KPLIB_fnc_selectPermissionPlayer";
        };
        class PlayerName: StdText {
            idc = 104;
            text = "Loading players...";
            x = 0.46 * safezoneW + safezoneX;
            y = 0.27 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class Grants: StdListBox {
            idc = 110;
            x = 0.46 * safezoneW + safezoneX;
            y = 0.32 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.22 * safezoneH;
            onLBDblClick = "[] call KPLIB_fnc_togglePermission";
            tooltip = "Double-click a permission to toggle it.";
        };
        class Role: StdCombo {
            idc = 130;
            x = 0.46 * safezoneW + safezoneX;
            y = 0.57 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.04 * safezoneH;
            tooltip = "Manual role assignment; slot/default follows the faction configuration.";
        };
        class All: StdButton {
            idc = 121;
            text = "All grants";
            x = 0.46 * safezoneW + safezoneX;
            y = 0.63 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
            action = "[true] call KPLIB_fnc_toggleAllPermissions";
        };
        class None: All {
            idc = 122;
            text = "Clear grants";
            x = 0.64 * safezoneW + safezoneX;
            action = "[false] call KPLIB_fnc_toggleAllPermissions";
        };
        class Status: StdText {
            idc = 105;
            style = 16;
            lineSpacing = 1;
            text = "Grants persist across reconnects and server restarts.";
            x = 0.20 * safezoneW + safezoneX;
            y = 0.685 * safezoneH + safezoneY;
            w = 0.59 * safezoneW;
            h = 0.055 * safezoneH;
            sizeEx = 0.018 * safezoneH;
        };
        class Refresh: All {
            idc = 123;
            text = "Refresh";
            x = 0.20 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            action = "[true] remoteExecCall ['KPLIB_fnc_requestPermissions', 2]";
        };
        class Apply: Refresh {
            idc = 120;
            text = "Apply";
            x = 0.46 * safezoneW + safezoneX;
            action = "[] call KPLIB_fnc_applyPermissions";
        };
        class Close: Refresh {
            idc = 124;
            text = "Close";
            x = 0.64 * safezoneW + safezoneX;
            action = "closeDialog 0";
        };
    };
};
