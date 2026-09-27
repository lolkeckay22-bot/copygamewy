Editable source is supplied for the entire game and the adapted GPL models.
Open Source/project.godot in Godot 3.6. Import textures before running.
Rebuild model resources: install Python numpy, run Tools/convert_assets.py,
then Godot --path <Source> --script res://scripts/BakeAssets.gd.
The Windows export preset uses ../Game.exe as its release template.
No external FlightGear executable, flight code or avionics are needed.
refine.py and fetch_assets.py are historical development utilities;
they expect the original development layout and are not needed to build.
