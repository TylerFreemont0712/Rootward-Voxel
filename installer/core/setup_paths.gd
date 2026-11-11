class_name SetupPaths
extends RefCounted
## Where things go on this computer. Per user, no administrator needed: Windows puts per-user programs in
## %LOCALAPPDATA%\Programs (as VS Code and Discord do), Linux in the XDG data folder.

const MARKER := "rootward-voxel-install.json"
const FOLDER := "Rootward Voxel"
## The game's own save folder (project.godot: config/custom_user_dir_name). Setup never touches it.
const SAVES := "RootwardVoxelLab"


static func windows() -> bool:
	return OS.has_feature("windows")


static func platform() -> String:
	return "windows" if windows() else "linux"


static func default_dir() -> String:
	if windows():
		var local := OS.get_environment("LOCALAPPDATA")
		if local == "":
			local = OS.get_environment("USERPROFILE").path_join("AppData/Local")
		return local.replace("\\", "/").path_join("Programs").path_join(FOLDER)
	return _xdg_data().path_join("rootward-voxel")


## A folder the player picked: the game goes into a "Rootward Voxel" folder inside it, unless it is one already, so
## an uninstall can remove the whole folder without touching anything else that lives where the player pointed.
static func install_dir_for(chosen: String) -> String:
	var clean := chosen.replace("\\", "/").trim_suffix("/")
	var name := clean.get_file().to_lower()
	return clean if name == FOLDER.to_lower() or name == "rootward-voxel" else clean.path_join(FOLDER)


static func game_exe(dir: String) -> String:
	return dir.path_join("RootwardVoxel.exe" if windows() else "RootwardVoxel.x86_64")


## The program to run for a check whose output must be read: Windows GUI programs have no console, so the export's
## console wrapper is used there.
static func check_exe(dir: String) -> String:
	return dir.path_join("RootwardVoxel.console.exe" if windows() else "RootwardVoxel.x86_64")


static func setup_exe(dir: String) -> String:
	return dir.path_join("Rootward Voxel Setup.exe" if windows() else "rootward-voxel-setup")


static func marker(dir: String) -> String:
	return dir.path_join(MARKER)


static func saves_dir() -> String:
	if windows():
		return OS.get_environment("APPDATA").replace("\\", "/").path_join(SAVES)
	return _xdg_data().path_join(SAVES)


static func _xdg_data() -> String:
	var data := OS.get_environment("XDG_DATA_HOME")
	if data == "":
		data = OS.get_environment("HOME").path_join(".local/share")
	return data


static func human_size(bytes: float) -> String:
	if bytes >= 1e9:
		return "%.1f GB" % (bytes / 1e9)
	if bytes >= 1e6:
		return "%.0f MB" % (bytes / 1e6)
	return "%.0f KB" % (bytes / 1e3)
