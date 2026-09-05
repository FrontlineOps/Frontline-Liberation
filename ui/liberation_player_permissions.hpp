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
        class Build {
            idc = 110;
            type = 77;
            style = 0;
            checked = 0;
            color[] = {1, 1, 1, 0.8};
            colorFocused[] = {1, 1, 1, 1};
            colorHover[] = {1, 1, 1, 1};
            colorPressed[] = {1, 1, 1, 1};
            colorDisabled[] = {1, 1, 1, 0.25};
            colorBackground[] = {0, 0, 0, 0};
            colorBackgroundFocused[] = {0, 0, 0, 0};
            colorBackgroundHover[] = {0, 0, 0, 0};
            colorBackgroundPressed[] = {0, 0, 0, 0};
            colorBackgroundDisabled[] = {0, 0, 0, 0};
            textureChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
            textureUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
            textureFocusedChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
            textureFocusedUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
            textureHoverChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
            textureHoverUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
            texturePressedChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
            texturePressedUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
            textureDisabledChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
            textureDisabledUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
            tooltipColorText[] = {1, 1, 1, 1};
            tooltipColorBox[] = {1, 1, 1, 1};
            tooltipColorShade[] = {0, 0, 0, 0.8};
            soundEnter[] = {"", 0, 1};
            soundPush[] = {"", 0, 1};
            soundClick[] = {"", 0, 1};
            soundEscape[] = {"", 0, 1};
            x = 0.46 * safezoneW + safezoneX;
            y = 0.33 * safezoneH + safezoneY;
            w = 0.025 * safezoneW;
            h = 0.035 * safezoneH;
        };
        class Recycle: Build {idc = 111; y = 0.40 * safezoneH + safezoneY;};
        class Production: Build {idc = 112; y = 0.47 * safezoneH + safezoneY;};
        class Intelligence: Build {idc = 113; y = 0.54 * safezoneH + safezoneY;};
        class BuildLabel: PlayerName {
            idc = -1;
            text = "Building and FOB construction";
            x = 0.49 * safezoneW + safezoneX;
            y = 0.33 * safezoneH + safezoneY;
            w = 0.31 * safezoneW;
        };
        class RecycleLabel: BuildLabel {text = "Recycling"; y = 0.40 * safezoneH + safezoneY;};
        class ProductionLabel: BuildLabel {text = "Production management"; y = 0.47 * safezoneH + safezoneY;};
        class IntelligenceLabel: BuildLabel {text = "Intelligence analysis spending"; y = 0.54 * safezoneH + safezoneY;};
        class All: StdButton {
            idc = 121;
            text = "Select all";
            x = 0.46 * safezoneW + safezoneX;
            y = 0.63 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
            action = "[true] call KPLIB_fnc_toggleAllPermissions";
        };
        class None: All {
            idc = 122;
            text = "Clear all";
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
