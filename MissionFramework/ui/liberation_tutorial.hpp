class liberation_tutorial {
    idd = 5353;
    movingEnable = false;
    objects[] = {};
    controlsBackground[] = {"Backdrop", "Sidebar", "ReadingPanel", "Accent"};
    controls[] = {"Brand", "GuideLabel", "ContentsLabel", "TutorialList", "HeaderTuto", "TutoControlGroup", "PageNumber", "PreviousButton", "NextButton", "CloseButton"};

    class Backdrop: StdBG {
        x = safezoneX + 0.10 * safezoneW;
        y = safezoneY + 0.10 * safezoneH;
        w = 0.80 * safezoneW;
        h = 0.80 * safezoneH;
        colorBackground[] = {0.045, 0.055, 0.045, 0.98};
    };
    class Sidebar: Backdrop {
        x = safezoneX + 0.112 * safezoneW;
        y = safezoneY + 0.22 * safezoneH;
        w = 0.23 * safezoneW;
        h = 0.60 * safezoneH;
        colorBackground[] = {0.10, 0.12, 0.095, 1};
    };
    class ReadingPanel: Sidebar {
        x = safezoneX + 0.355 * safezoneW;
        w = 0.533 * safezoneW;
        colorBackground[] = {0.13, 0.15, 0.12, 1};
    };
    class Accent: Backdrop {
        y = safezoneY + 0.10 * safezoneH;
        h = 0.004 * safezoneH;
        colorBackground[] = {0.80, 0.69, 0.43, 1};
    };
    class Brand: StdText {
        x = safezoneX + 0.125 * safezoneW;
        y = safezoneY + 0.12 * safezoneH;
        w = 0.70 * safezoneW;
        h = 0.045 * safezoneH;
        text = "FRONTLINE LIBERATION";
        font = "PuristaBold";
        sizeEx = 0.032 * safezoneH;
        shadow = 0;
    };
    class GuideLabel: Brand {
        y = safezoneY + 0.169 * safezoneH;
        h = 0.028 * safezoneH;
        text = $STR_TUTO_TITLE;
        font = FontM;
        sizeEx = 0.017 * safezoneH;
        colorText[] = {0.80, 0.69, 0.43, 1};
    };
    class ContentsLabel: GuideLabel {
        y = safezoneY + 0.233 * safezoneH;
        w = 0.20 * safezoneW;
        text = $STR_TUTO_CONTENTS;
    };
    class TutorialList: StdListBox {
        idc = 513;
        x = safezoneX + 0.12 * safezoneW;
        y = safezoneY + 0.274 * safezoneH;
        w = 0.214 * safezoneW;
        h = 0.526 * safezoneH;
        sizeEx = 0.018 * safezoneH;
        rowHeight = 0.030 * safezoneH;
        colorBackground[] = {0, 0, 0, 0};
        colorSelect[] = {0.96, 0.91, 0.77, 1};
        colorSelect2[] = {0.96, 0.91, 0.77, 1};
        colorSelectBackground[] = {0.28, 0.31, 0.23, 1};
        colorSelectBackground2[] = {0.28, 0.31, 0.23, 1};
        shadow = 0;
    };
    class HeaderTuto: Brand {
        idc = 514;
        x = safezoneX + 0.372 * safezoneW;
        y = safezoneY + 0.233 * safezoneH;
        w = 0.494 * safezoneW;
        h = 0.043 * safezoneH;
        sizeEx = 0.027 * safezoneH;
        text = "";
    };
    class TutoControlGroup {
        idc = 516;
        type = CT_CONTROLS_GROUP;
        style = 0;
        x = safezoneX + 0.372 * safezoneW;
        y = safezoneY + 0.289 * safezoneH;
        w = 0.504 * safezoneW;
        h = 0.515 * safezoneH;
        class VScrollbar {
            color[] = {0.80, 0.69, 0.43, 1};
            width = 0.008 * safezoneW;
            autoScrollEnabled = 0;
        };
        class HScrollbar {
            color[] = {0, 0, 0, 0};
            height = 0;
        };
        class ScrollBar {
            color[] = {0.80, 0.69, 0.43, 1};
            colorActive[] = {0.96, 0.91, 0.77, 1};
            colorDisabled[] = {0.3, 0.3, 0.3, 0.4};
            thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
            arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
            arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
            border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
        };
        class Controls {
            class TutoStructuredText {
                idc = 515;
                type = CT_STRUCTURED_TEXT;
                style = ST_LEFT;
                x = 0;
                y = 0;
                w = 0.483 * safezoneW;
                h = 0.50 * safezoneH;
                size = 0.019 * safezoneH;
                text = "";
                colorBackground[] = {0, 0, 0, 0};
                class Attributes {
                    font = FontM;
                    color = "#E3E7DC";
                    align = "left";
                    valign = "top";
                    shadow = 0;
                };
            };
        };
    };
    class PageNumber: GuideLabel {
        idc = 517;
        x = safezoneX + 0.37 * safezoneW;
        y = safezoneY + 0.84 * safezoneH;
        w = 0.21 * safezoneW;
        text = "";
    };
    class CloseButton: StdButton {
        idc = 512;
        x = safezoneX + 0.12 * safezoneW;
        y = safezoneY + 0.835 * safezoneH;
        w = 0.214 * safezoneW;
        h = 0.04 * safezoneH;
        sizeEx = 0.018 * safezoneH;
        text = $STR_TUTO_GOTIT;
        colorBackground[] = {0.80, 0.69, 0.43, 1};
        colorBackgroundActive[] = {0.96, 0.85, 0.58, 1};
        shadow = 0;
        action = "howtoplay = 0";
    };
    class PreviousButton: CloseButton {
        idc = 518;
        x = safezoneX + 0.655 * safezoneW;
        w = 0.105 * safezoneW;
        text = $STR_TUTO_PREVIOUS;
        action = "";
    };
    class NextButton: PreviousButton {
        idc = 519;
        x = safezoneX + 0.77 * safezoneW;
        text = $STR_TUTO_NEXT;
    };
};
