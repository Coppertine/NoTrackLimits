local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local module = global.module
local table = require("Common.tableplus")
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")

local SandboxSettingsHookManager = module(..., Mutators.Manager())



SandboxSettingsHookManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("SandboxSettingsHookManager:Init()")

end

SandboxSettingsHookManager.Advance = function(self, _nDeltaTime, _tData)
end

SandboxSettingsHookManager.Activate = function(self)
    api.debug.Trace("SandboxSettingsHookManager:Activate()")

    self.tWorldAPIs = api.world.GetWorldAPIs()

end

SandboxSettingsHookManager.Deactivate = function(self)
end

SandboxSettingsHookManager.Shutdown = function(self)
end

Mutators.VerifyManagerModule(SandboxSettingsHookManager)