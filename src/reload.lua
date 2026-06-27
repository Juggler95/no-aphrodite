---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.


-- Load the portrait package containing the blank Aphrodite assets.
function mod.LoadAphroditePackage()
	local packageName = _PLUGIN.guid .. "Portraits"
	print("SGG_Modding-ModdingTemplate - Loading packages: " .. packageName)
	LoadPackages({ Name = packageName })
end