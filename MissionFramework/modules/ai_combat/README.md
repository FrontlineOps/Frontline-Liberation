# Infantry combat, illumination and hearing

Enabled by default for server-owned OPFOR and resistance infantry. Settings are
in CBA Configure Addons -> Frontline - AI, under Infantry combat.
The registration source is `../settings/sections/ai.sqf`.

| Setting | Default |
| --- | ---: |
| Rifle engagement ceiling | 1,200 m |
| Unguided explosive launcher ceiling | 700 m |
| HE grenade-launcher ceiling | 450 m |
| Native weapon range multiplier | 2 |
| Explosive shot cooldown, soldier / group | 25 / 8 seconds |
| Illumination cooldown per group | 90 seconds |
| Reference unsuppressed muzzle hearing | 1,200 m |
| Suppressed muzzle hearing ceiling | 180 m |

These are ceilings, not guaranteed effective ranges. Loaded weapon modes,
magazine speed, projectile lifetime and a reachable low trajectory also limit
engagements. Grenade launchers take priority over RPGs, then rifles. Rifle
assistance begins at 300 m; ordinary close combat continues through Arma.

## Ammunition and aiming

`fn_aiCombatWeapons.sqf` reads carried and loaded magazines, including magazine
wells. `fn_aiCombatProfile.sqf` classifies their loaded configuration without
faction, era or weapon classname lists. It supports bullets, explosive unguided
rockets, HE shells/grenades and `shotIlluminating` rounds. Guided missiles,
smoke, virtual disposable magazines and unsupported simulations retain their
native behavior. Mod compatibility depends on usable configuration metadata;
this is not a claim that every addon has been tested.

AI draw and fire their actual weapons. RPG/GL/flare jobs apply **one initial
direction correction** to the real fired projectile. Its speed magnitude and
ammunition cost remain unchanged; Arma and the installed mods control subsequent
flight, explosions, fragmentation and damage. Rifles receive firing orders only.
There are no additional rounds, inventory substitutions or homing updates.

`fn_aiCombatSolution.sqf` estimates a low arc in a bounded scheduled job. Rocket
drag is an approximation checked against native CUP/vanilla trajectories, not
an exact reconstruction of the engine. Short motor burns, weather, addon physics,
skill and target movement can cause substantial long-range misses. Rockets aim
at the lower body; grenades aim near the feet. Targets that move more than 8 m
during preparation require another solution. This does not guarantee a hit or kill.

## Automatic fire and vehicle submodules

`vehicle_combat/` controls AI tanks, tracked APCs/IFVs and wheeled APCs on the
server or their headless owner. It selects actual turret ammunition by target,
loaded metadata and range, preserving native aiming, reloads and guidance.
Player crews, artillery and hold-fire orders remain excluded. CBA Vehicle combat
controls retain the 2x range multiplier, 5,000 m gun/missile cap, 1,800 m MG cap
and 12 active turret defaults. Both visibility distances on AI-only hosts have a
3,000 m baseline and rise with the gun cap; interface hosts retain their settings.

Acquisition considers only native known targets, then checks current hostility
and visibility. A stale perceived side after transfer cannot hide a known hostile
vehicle from that check. Explicit target/watch orders restore turret tracking on
the new owner; the native alignment threshold still gates each shot.

`combat_fire/` supplies one shared owner-local CBA frame callback for active
rifle and turret bursts. Target selection and inventory work remain on their
slower existing callbacks. Loaded mode ranges determine the burst policy;
`burst`, `burstRangeMax`, `reloadTime` and `aiRateOfFire` supply burst lengths,
cyclic timing and pauses. A supported one-round trigger mode emits each real
round, because forcing hidden AI burst modes does not reliably complete a burst.
Actual Fired events count rounds; native cycling and magazine reloads always
remain authoritative. Burst-only muzzles with no suitable one-round trigger
return to native control. Long-range semi-auto modes retain deliberate pauses.

The fast path services only active authorized actors (at most 24 turrets and
32 infantry with maximum settings), rechecks eligibility, aim and cover before
each trigger, and never fires several catch-up rounds after a slow frame. Normal
engine scheduling/cycling can reduce achieved rate below the configured cycle.
Infantry actions may now complete multiple bursts and reload during their
25-second action window. The final burst pause survives reacquisition. RPG,
GL and illumination releases retain their existing single-release path.

ZEN inspections include selected burst policy, trigger mode and remaining rounds.
Native cadence, ammo, interruption and ownership evidence is retained in
`.agent-notes/rapid-fire-2026-09-13/REPORT.md` at repository root.

## Night and sound

Soldiers without configured NVG/thermal vision can use their carried illumination
rounds after seeing an enemy or hearing recent hostile fire. The controller aims
upward, shares a group cooldown and avoids overlapping illumination. It tracks
the real flare until expiry/deletion. It never supplies missing flare ammunition.
While enabled, it replaces the automatic flare branch in the mission's LAMBS hunt.

`fn_aiCombatSound.sqf` uses real owner-side `FiredMan` events, ammo `audibleFire`
and the equipped suppressor's `ItemInfo/AmmoCoef/audibleFire`. Walls and terrain
attenuate the cue. Integral suppression follows whatever acoustic metadata its
addon supplies. Hearing yields an uncertain position and a brief look toward it;
it does not reveal the shooter or authorize explosives through cover. Native
bullet fly-by suppression remains active, including suppressed supersonic shots,
and its `Suppressed` event is recorded for inspection.

## Authority, lifecycle and work limits

The server controls dismounted nonplayer AI. Captivity, unconsciousness,
surrender, hold fire, suspended simulation, scripted movement and locality loss
cancel or exclude assistance. Visual geometry, nearby friendly/civilian blast
clearance and RPG backblast are checked before aiming and again at release.
An unsafe late release removes that already-spent round. These checks do not
guarantee every possible downstream ricochet or impact is safe.

One 0.25-second CBA callback visits at most eight registry entries and updates at
most twelve active jobs. Each decision examines at most four visual candidates.
The sound queue holds at most 64 sources for 20 seconds. Solvers are scheduled,
bounded and terminated with their jobs. Original AI flags, stance and weapon
selection are restored; a server-authenticated restoration RPC handles a changed
owner. Dismounted infantry assistance remains server-only; mounted vehicle
assistance also runs on headless owners through `vehicle_combat/`.

## ZEN debug

In Zeus, right-click within **50 m** of an AI and select
**Inspect Frontline AI Combat**. It reports:

- Eligibility or the current reason for waiting/cancellation.
- Visual target, range, native knowledge and supported carried rounds.
- Recent suppressed/unsuppressed sound, age and positional uncertainty.
- Native near misses, actual fired events and the last assisted launch speed.
- Aiming attempts, muzzle state, estimated trajectory and recent outcomes.
- Registered AI, active-job budget, sound count and the last callback duration.

The server authenticates a living assigned player curator and returns a bounded,
read-only report. `KPLIB_aiCombat_debug = true` additionally enables shot and
cancellation RPT messages; the ZEN action does not require that flag.

For a live check, place a rifle-carrying RPG soldier facing visible enemy infantry
at 400–650 m, or a grenadier at 350–400 m. Add the intended rounds to their kit.
At night, remove NVGs and carry illumination ammunition. Compare suppressed and
unsuppressed fire from behind cover; inspect the listener before approaching.
Check a friendly near the target, blocked backblast, capture, Zeus possession,
JIP and reconnect as separate scenarios.

Native test captures, source hashes, measured impact positions, rejected trials
and remaining multiplayer checks are indexed in the repository-local
`.agent-notes/ai-combat-2026-09-11/REPORT.md`. The isolated server tests do not
replace a human campaign/Zeus/JIP playtest.

Native command/config references: [weaponState](https://community.bistudio.com/wiki/weaponState),
[forceWeaponFire](https://community.bistudio.com/wiki/forceWeaponFire),
[compatibleMagazines](https://community.bistudio.com/wiki/compatibleMagazines),
[CfgAmmo](https://community.bistudio.com/wiki/CfgAmmo_Config_Reference) and
[suppression](https://community.bistudio.com/wiki/Arma_3:_Suppression).
