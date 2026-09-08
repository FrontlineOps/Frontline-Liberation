/* Server-local AI soldiers, including mounted drivers, gunners and pilots.
   Skills follow the person through vehicle entry and exit. */
params [["_unit", objNull, [objNull]]];
isServer
    && {!isRemoteExecuted}
    && {!isNull _unit}
    && {local _unit}
    && {alive _unit}
    && {!isPlayer _unit}
    && {_unit isKindOf "CAManBase"}
    && {side group _unit in KPLIB_aiSkills_sides}
    && {!captive _unit}
    && {lifeState _unit != "INCAPACITATED"}
    && {!(_unit getVariable ["ACE_isUnconscious", false])}
    && {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}
    && {!(_unit getVariable ["KPLIB_surrenderInProgress", false])}
    && {!(_unit getVariable ["ace_captives_isSurrendering", false])}
