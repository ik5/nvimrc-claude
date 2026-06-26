-- Resolve Flutter SDK for flutter-tools.nvim.
-- Called before dart LSP attach so FVM and global installs are both handled.

local M = {}

local function exists(path)
	return path and path ~= "" and vim.uv.fs_stat(path) ~= nil
end

local function read_fvm_version(project_root)
	local cfg_file = project_root .. "/.fvm/fvm_config.json"
	if not exists(cfg_file) then
		return nil
	end
	local lines = vim.fn.readfile(cfg_file)
	if not lines or #lines == 0 then
		return nil
	end
	local ok, cfg = pcall(vim.json.decode, table.concat(lines, "\n"))
	if ok and cfg and cfg.flutterSdkVersion then
		return cfg.flutterSdkVersion
	end
	return nil
end

---@param start_path? string Directory to search upward from (defaults to cwd)
---@return { flutter_path: string, source: string }?
function M.resolve(start_path)
	start_path = start_path or vim.uv.cwd()
	local home = vim.env.HOME or vim.fn.expand("~")

	-- 1. Project FVM: <root>/.fvm/flutter_sdk/bin/flutter
	local fvm_marker = vim.fs.find(".fvm", { path = start_path, upward = true, type = "directory" })[1]
	if fvm_marker then
		local project_root = vim.fs.dirname(fvm_marker)
		local flutter_bin = project_root .. "/.fvm/flutter_sdk/bin/flutter"
		if exists(flutter_bin) then
			return { flutter_path = vim.fn.resolve(flutter_bin), source = "project .fvm/flutter_sdk" }
		end

		-- .fvm present but symlink missing — try FVM global cache via fvm_config.json
		local version = read_fvm_version(project_root)
		if version then
			for _, base in ipairs({
				home .. "/fvm/versions",
				home .. "/.fvm/versions",
				vim.env.FVM_HOME and (vim.env.FVM_HOME .. "/versions"),
			}) do
				if base then
					local bin = base .. "/" .. version .. "/bin/flutter"
					if exists(bin) then
						return { flutter_path = vim.fn.resolve(bin), source = "fvm cache (" .. version .. ")" }
					end
				end
			end
		end
	end

	-- 2. FLUTTER_ROOT environment variable
	local flutter_root = vim.env.FLUTTER_ROOT
	if flutter_root and exists(flutter_root .. "/bin/flutter") then
		return { flutter_path = vim.fn.resolve(flutter_root .. "/bin/flutter"), source = "FLUTTER_ROOT" }
	end

	-- 3. flutter on $PATH (what :!which flutter uses)
	local path_flutter = vim.fn.exepath("flutter")
	if path_flutter ~= "" then
		return { flutter_path = vim.fn.resolve(path_flutter), source = "PATH" }
	end

	-- 4. Common manual install locations
	for _, base in ipairs({
		home .. "/flutter",
		home .. "/development/flutter",
		home .. "/sdk/flutter",
		"/opt/flutter",
	}) do
		local bin = base .. "/bin/flutter"
		if exists(bin) then
			return { flutter_path = vim.fn.resolve(bin), source = base }
		end
	end

	return nil
end

--- Apply resolved SDK to flutter-tools and clear its path cache.
---@param start_path? string
---@return { flutter_path: string, source: string }?
function M.apply(start_path)
	local resolved = M.resolve(start_path)
	local cfg = require("flutter-tools.config")
	if resolved then
		cfg.set({
			fvm = false,
			flutter_path = resolved.flutter_path,
		})
		require("flutter-tools.executable").reset_paths()
		return resolved
	end
	cfg.set({ fvm = true, flutter_path = nil })
	require("flutter-tools.executable").reset_paths()
	return nil
end

function M.diagnose(start_path)
	local resolved = M.resolve(start_path)
	if resolved then
		return string.format("Flutter SDK: %s (%s)", resolved.flutter_path, resolved.source)
	end
	local cwd = start_path or vim.uv.cwd()
	return table.concat({
		"Flutter SDK not found for " .. cwd,
		"",
		"Install one of:",
		"  • Global: install Flutter and ensure `flutter` is on $PATH",
		"  • Env:    export FLUTTER_ROOT=/path/to/flutter  (contains bin/flutter)",
		"  • FVM:    install fvm, then in project: fvm use <version>",
		"",
		"Checks inside Neovim:",
		"  :!which flutter",
		"  :!ls -la .fvm/flutter_sdk/bin/flutter",
	}, "\n")
end

return M