class KPLIB_MunitionsOverlay: StdText {
    // ctrlCreate reads these before munitionsHud sets the visible layout.
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    style = 16;
    lineSpacing = 1;
    sizeEx = 0.017 * safezoneH;
    colorBackground[] = {0.015,0.02,0.025,0.78};
    colorText[] = {0.95,0.97,1,1};
    shadow = 1;
};
class KPLIB_MunitionsReport {
    idd = 7100;
    movingEnable = false;
    class controlsBackground {
        class Background: StdBG {
            x = safezoneX + 0.06 * safezoneW;
            y = safezoneY + 0.06 * safezoneH;
            w = 0.88 * safezoneW;
            h = 0.88 * safezoneH;
            colorBackground[] = {0.025, 0.035, 0.035, 0.98};
        };
    };
    class controls {
        class Title: StdText {
            text = "FRONTLINE | Munitions and guidance evidence";
            x = safezoneX + 0.08 * safezoneW;
            y = safezoneY + 0.075 * safezoneH;
            w = 0.8 * safezoneW;
            h = 0.045 * safezoneH;
        };
        class Report: StdEdit {
            idc = 7101;
            style = 16;
            x = safezoneX + 0.08 * safezoneW;
            y = safezoneY + 0.13 * safezoneH;
            w = 0.84 * safezoneW;
            h = 0.71 * safezoneH;
            sizeEx = 0.017 * safezoneH;
            canModify = 0;
            autocomplete = "";
        };
        class Copy: StdButton {
            text = "Copy report";
            x = safezoneX + 0.08 * safezoneW;
            y = safezoneY + 0.865 * safezoneH;
            w = 0.19 * safezoneW;
            h = 0.045 * safezoneH;
            action = "copyToClipboard (uiNamespace getVariable ['KPLIB_munitionsReportText', ''])";
        };
        class Close: Copy {
            text = "Close";
            x = safezoneX + 0.73 * safezoneW;
            action = "(uiNamespace getVariable ['KPLIB_munitionsDisplay', displayNull]) closeDisplay 2";
        };
    };
};
