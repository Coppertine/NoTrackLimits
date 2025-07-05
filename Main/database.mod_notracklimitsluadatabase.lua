local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local table = require("Common.tableplus")
local tryrequire = global.tryrequire
--local export = require("Export")
local GameDatabase = require("Database.GameDatabase")

local Mod_NoTrackLimitsLuaDatabase = module(...)

local FORGE_UTILS_VERSION = 1.0
local MOD_NAME = "NoTrackLimits"

Mod_NoTrackLimitsLuaDatabase.AddContentToCall = function(_tContentToCall)
    if not global.api.acse or global.api.acse.versionNumber < 0.7 then
        return
    end

    table.insert(_tContentToCall, Mod_NoTrackLimitsLuaDatabase)
    table.insert(_tContentToCall, require("Database.Mod_NoTrackLimits.NoTrackLimitsManager"))
    -- table.insert(_tContentToCall, require("Managers.Mod_NoTrackLimits.CameraHookManager"))
end

Mod_NoTrackLimitsLuaDatabase.Init = function()
    api.debug.Trace("Mod_NoTrackLimitsLuaDatabase.Init()")

    local forgeutils_module = tryrequire("forgeutils.ModDB")
    if forgeutils_module ~= nil then
        forgeutils_module.RegisterMod(MOD_NAME, FORGE_UTILS_VERSION)
    end
end

Mod_NoTrackLimitsLuaDatabase.Setup = function()
    --   export.Export()
end

Mod_NoTrackLimitsLuaDatabase.Activate = function()
    api.debug.Trace("Mod_NoTrackLimitsLuaDatabase.Activate()")
end

Mod_NoTrackLimitsLuaDatabase.tManagers = {
    ["Environments.CPTEnvironment"] = {
        ["Managers.Mod_NoTrackLimits.CameraHookManager"] = {},
        ["Managers.Mod_NoTrackLimits.FrictionHookManager"] = {},
    },
}

Mod_NoTrackLimitsLuaDatabase.AddLuaManagers = function(_fnAdd)
    for sManagerName, tParams in pairs(Mod_NoTrackLimitsLuaDatabase.tManagers) do
        _fnAdd(sManagerName, tParams)
    end
end
