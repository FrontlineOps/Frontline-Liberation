# Frontline Liberation

Frontline Liberation is an Arma 3 Liberation mission. Beketov is currently included.

## Build missions

On Windows, install **Arma 3 Tools** from Steam's Library > Tools once. Then double-click **Build Missions.cmd**. No command line, manual merging or PBO configuration is needed. Git and the game do not need to be running.

The builder finds Bohemia's FileBank automatically, builds every terrain in `Missionbasefiles`, and opens `build` when finished:

```text
build/
    frontline_liberation.beketov.pbo    Ready for a server's MPMissions folder
    frontline_liberation.beketov/      Complete unpacked mission
```

The contents of `build` are generated. Edit the source folders below, then build again. Each successful build replaces the output and keeps the previous successful build in `.build/previous`. Failed builds leave the current output intact. Generated files are excluded from Git.

For a nonstandard Tools installation, run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Missions.ps1 -FileBankPath "D:\Tools\FileBank\FileBank.exe"`.

This uses FileBank's direct PBO packing. It does not binarize, rewrite or preprocess the mission source. HEMTT is not required; its normal build pipeline is aimed at addons.

## Source layout

```text
MissionFramework/                     Shared scripts, configuration, UI and assets
Missionbasefiles/
    frontline_liberation.beketov/
        mission.sqm                   Beketov's Eden mission composition
tools/Build-Missions.ps1               Windows build script
Build Missions.cmd                    Double-click launcher
LICENSE
```

Change gameplay settings in `MissionFramework/kp_liberation_config.sqf`. Runtime paths inside SQF remain relative to the assembled mission root.

To add a terrain, add a folder named `frontline_liberation.<worldName>` under `Missionbasefiles`, containing that terrain's Eden-created `mission.sqm`. The folder suffix must match Arma's world name. Terrain files overlay the shared framework during assembly, so terrain-specific files can be included there. Do not create a second copy of the entire framework.

For Eden editing, use the complete unpacked build in your Arma profile's `missions` folder. Save the edited `mission.sqm` back to the corresponding `Missionbasefiles` folder before rebuilding; generated output is not the source of truth. The repository itself can live anywhere and should not be used directly as an Arma mission folder.

## Git history

The framework and terrain relocation is a separate commit containing unchanged file renames. Existing commits and file history are preserved. In GitKraken, review the relocation separately from subsequent edits; Git can follow renamed files because their contents were preserved.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full license text.

Anyone may copy, modify, and redistribute the mission under the terms of the GPLv3. Files that include their own license headers retain those notices.
