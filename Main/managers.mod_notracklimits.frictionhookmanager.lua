local global = _G
local api = global.api
local pairs = global.pairs
local iparis = global.ipairs
local require = global.require
local module = global.module
local tostring = global.tostring
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")
local TrackedRideDataStoreComponent = require("Components.UI.DataStore.TrackedRideDataStoreComponent")

local FrictionHookManager = module(..., Mutators.Manager())

FrictionHookManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("FrictionHookManager:Init()")

end

FrictionHookManager.Advance = function(self, _nDeltaTime, _tData)
end

FrictionHookManager.Activate = function(self)
    api.debug.Trace("FrictionHookManager:Activate()")
    local _tConfigLocal = GameDatabase.NTLGetGlobalConfig()
    if _tConfigLocal.tConfig.tFriction ~= nil then
        api.debug.Trace("[NoTrackLimits] Setting Friction multiplier")
        if _tConfigLocal.tConfig.tFriction.max ~= nil then
            api.debug.Trace("[NoTrackLimits] Setting Friction Max: " .. _tConfigLocal.tConfig.tFriction.max)
            TrackedRideDataStoreComponent.s_nMaxCoasterFriction = _tConfigLocal.tConfig.tFriction.max
        end
        if _tConfigLocal.tConfig.tFriction.min ~= nil then
            
            api.debug.Trace("[NoTrackLimits] Setting Friction Min: " .. _tConfigLocal.tConfig.tFriction.min)
            TrackedRideDataStoreComponent.s_nMaxCoasterFriction = _tConfigLocal.tConfig.tFriction.max
            TrackedRideDataStoreComponent.s_nMinCoasterFriction = _tConfigLocal.tConfig.tFriction.min
        end
    end


end



FrictionHookManager.Deactivate = function(self)
end

FrictionHookManager.Shutdown = function(self)


end

Mutators.VerifyManagerModule(FrictionHookManager)
