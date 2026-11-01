# GameMaker version switcher

switch_gamemaker_version.py switches this project between the two IDE versions recorded for it:

- **Windows installed:** GameMaker 2024.14.4.222. Its extension resources use the legacy v0 record.
- **Linux beta:** GameMaker 2026.100.0.1139. This is the IDEVersion recorded before the compatibility downgrade; its extension resources use the v1 record.

The script updates the project IDEVersion and the Simple_Game_Engine and Static_Inventory extension metadata together. It uses the project's lossless python_tools/gm parser, preserves all other project and extension fields, and refuses to remove non-default extension settings.

## Use

Close GameMaker before switching. Python 3.11 or newer is recommended.

From PowerShell on Windows:

    py -3 .\switch_gamemaker_version.py
    py -3 .\switch_gamemaker_version.py linux-beta --dry-run
    py -3 .\switch_gamemaker_version.py windows

From a shell on Linux:

    python3 ./switch_gamemaker_version.py
    python3 ./switch_gamemaker_version.py linux-beta --dry-run
    python3 ./switch_gamemaker_version.py windows

Without a version argument, the script shows the two choices. With a version argument, it prints the metadata diff and asks for confirmation before writing. Use --yes for a deliberate non-interactive switch. --force bypasses the running-IDE check; use it only when GameMaker is open on a different project.

Each successful switch backs up the .yyp and both extension files under .gm-version-switcher/backups/. Those backups are ignored by Git and are not registered as GameMaker assets. The script does not change game code, sprites, rooms, or the project's starting room.

After switching, open the project with the selected GameMaker installation. Save and close it before switching again.