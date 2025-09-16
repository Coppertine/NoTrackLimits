local global = _G
local api = global.api
local pairs = global.pairs
local iparis = global.ipairs
local require = global.require
local module = global.module
local tostring = global.tostring
local table = require("Common.tableplus")
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")

local CameraHookManager = module(..., Mutators.Manager())
local tweakableLookAheadRollEnabled = ((api.debug).CreateDebugTweakable)(
    (api.debug).Tweakable_Bool,
    "Camera.Ride.EffectsToggles.LookAheadRollEnabled",
    true
)
local tweakableLookAheadYawEnabled = ((api.debug).CreateDebugTweakable)(
    (api.debug).Tweakable_Bool,
    "Camera.Ride.EffectsToggles.LookAheadEnabled",
    true
)
local tweakableLookAheadPitchEnabled = ((api.debug).CreateDebugTweakable)(
    (api.debug).Tweakable_Bool,
    "Camera.Ride.EffectsToggles.LookAheadPitchEnabled",
    true
)
local tweakableDisplaceEnabled = ((api.debug).CreateDebugTweakable)(
    (api.debug).Tweakable_Bool,
    "Camera.Ride.EffectsToggles.DisplaceEnabled",
    true
)
local tweakableFOVEnabled = ((api.debug).CreateDebugTweakable)(
    (api.debug).Tweakable_Bool,
    "Camera.Ride.EffectsToggles.FOVEnabled",
    true
)
CameraHookManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("CameraHookManager:Init()")
end

CameraHookManager.Advance = function(self, _nDeltaTime, _tData) end

CameraHookManager.Activate = function(self)
    api.debug.Trace("CameraHookManager:Activate()")
    local _tConfigLocal = GameDatabase.NTLGetGlobalConfig()
    if _tConfigLocal.bEnableCameraEffects ~= nil and not _tConfigLocal.bEnableCameraEffects then
        tweakableLookAheadPitchEnabled:SetValue(false)
        tweakableLookAheadYawEnabled:SetValue(false)
        tweakableLookAheadRollEnabled:SetValue(false)

        tweakableDisplaceEnabled:SetValue(false)
        tweakableFOVEnabled:SetValue(false)
    end

end

CameraHookManager.Deactivate = function(self) end

CameraHookManager.Shutdown = function(self) end

Mutators.VerifyManagerModule(CameraHookManager)
