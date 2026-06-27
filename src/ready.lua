---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

-- These are some sample code snippets of what you can do with our modding framework:
local file = rom.path.combine(rom.paths.Content, 'Game/Text/en/ShellText.en.sjson')
sjson.hook(file, function(data)
	if type(sjson_ShellText) == 'function' then
		return sjson_ShellText(data)
	else
		print("[WARN] sjson_ShellText not defined; skipping ShellText hook")
		return data
	end
end)

modutil.mod.Path.Wrap("SetupMap", function(base, ...)
	if type(prefix_SetupMap) == 'function' then
		prefix_SetupMap()
	end
	return base(...)
end)

game.OnControlPressed({'Gift', function()
    if type(trigger_Gift) == 'function' then
        return trigger_Gift()
    else
        print("[WARN] trigger_Gift not defined; Gift key ignored")
    end
end})


-- Aphrodite portrait replacement
-- Load the custom package that contains the blank portrait assets.
if type(mod.LoadAphroditePackage) == 'function' then
	mod.LoadAphroditePackage()
else
	print("[WARN] mod.LoadAphroditePackage not defined yet; package will be loaded later on reload if available")
end

-- lightweight deep-copy for saving original tables in-session
local function deepcopy(obj)
	if type(obj) ~= 'table' then return obj end
	local res = {}
	for k,v in pairs(obj) do res[deepcopy(k)] = deepcopy(v) end
	return res
end

local function overrideAphroditePortraitEntries(data)
	for _, entry in ipairs(data.Animations or {}) do
		if type(entry.Name) == "string" and entry.Name:find("Portrait_Aphrodite") then
			local portraitPath = entry.Name:find("Annoyed")
				and (_PLUGIN.guid .. "Portraits\\Portraits_Aphrodite_Annoyed_01")
				or (_PLUGIN.guid .. "Portraits\\Portraits_Aphrodite_01")

			if entry.FilePath ~= nil then
				entry.FilePath = portraitPath
			end

			if entry.Slides then
				for _, slide in ipairs(entry.Slides) do
					if slide and slide.FilePath then
						slide.FilePath = portraitPath
					end
				end
			end
		end
	end
end

local guiPortraitsVFXFile = rom.path.combine(rom.paths.Content(), "Game\\Animations\\GUI_Portraits_VFX.sjson")
-- For Mel testing we use a blank asset when `config.hide_mel` is true.
local TEST_ASSET_PATH = _PLUGIN.guid .. "Portraits\\Portraits_Aphrodite_01" -- default test asset (visible)

-- store originals so we can inspect/restore in-session
mod._mel_original_portraits = mod._mel_original_portraits or {}

sjson.hook(guiPortraitsVFXFile, function(data)
	-- Only modify Mel if the config toggle is enabled
	if not (type(config) == 'table' and config.hide_mel) then
		return
	end

	local ok, err = pcall(function()
		for _, entry in ipairs(data.Animations or {}) do
			if type(entry.Name) == "string" and entry.Name:find("Portrait_Mel") then
				if not mod._mel_original_portraits[entry.Name] then
					mod._mel_original_portraits[entry.Name] = {
						FilePath = entry.FilePath,
						Slides = entry.Slides and deepcopy(entry.Slides) or entry.Slides
					}
				end

				-- use a guaranteed blank asset and remove overlays for testing
				local blankPath = "Dev\\blank_invisible"
				print("[TEST] Replacing", entry.Name, "->", blankPath)
				if entry.FilePath then entry.FilePath = blankPath end
				if entry.Slides then
					for _, slide in ipairs(entry.Slides) do
						if slide and slide.FilePath then slide.FilePath = blankPath end
					end
				end

				entry.CreateAnimations = {}
				entry.VisualFx = nil
			end
		end
	end)
	if not ok then print("[ERROR] Mel portrait hook failed:", err) end
end)

-- rom.path.combine is provided by Hell2Modding to build file paths correctly across different operating systems
-- rom.paths.Content() will return the path to the Content folder of the current Hades II installation
-- hook the file to apply Aphrodite overrides using the `guiPortraitsVFXFile` declared above
sjson.hook(guiPortraitsVFXFile, function(data)
	local ok, err = pcall(function() overrideAphroditePortraitEntries(data) end)
	if not ok then print("[ERROR] Aphrodite portrait hook failed:", err) end
end)
