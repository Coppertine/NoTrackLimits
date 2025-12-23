local global = _G
local api = global.api ---@type Api
local table = global.table
local tostring = global.tostring
local loadfile = global.loadfile
local pairs = global.pairs
local ipairs = global.ipairs
local math = global.math
local tryrequire = global.tryrequire
local Vector3 = require("Vector3")
local camoffset_mod = tryrequire("database.mod_camoffsetsluadatabase")
---@class (partial) GameDatabase
local GameDatabase = require("Database.GameDatabase")
local database = api.database

---@class NoTrackLimitsManager
---@field Global table Currently stored config of NoTrackLimits
local NoTrackLimitsManager = module(...)

local _tTrace = function(_line)
    local _trace = api.debug.TraceNoFlush or api.debug.Trace
    return _trace("[NoTrackLimits]: " .. _line)
end

local dbgTrace = function(_line)
    --    if NoTrackLimitsManager.Global.bPrintDebugLog == true then
    _tTrace(_line)
    --  end
end

local dbgTraceErr = function(_line)
    local _trace = api.debug.TraceNoFlush or api.debug.Trace
    return _trace("[NoTrackLimits ERROR]: " .. _line)
end

--- Default Config values.
NoTrackLimitsManager._tConfigDefaults = {
    eConfigMode = "realistic",
    bEnableCameraEffects = false,
    bAllowAllInterchangableCoasterTrains = true,
    bPatchTrainCameras = true,
    bPrintDebugLog = true,
    tConfig = {}
}

--- Config values for "Realistic" mode. <br/>
--- Used as fallback or when `eConfigMode` is set as `"realistic"`
NoTrackLimitsManager._tRealisticDefaults = {
    tAppendedElements = { "default_LSM", "default_LSM_HoldingSection", "default_chainlift" },
    tAppendedElementsToRide = {
        CC_Vector = { 'TK_040_ShuttleLaunch_station_leftleft', 'TK_040_ShuttleLaunch_station_leftright',
            'TK_040_ShuttleLaunch_station_rightleft', 'TK_040_ShuttleLaunch_station_rightright',
            'TK_040_Shuttle_booster' }
    },
    tTrackLength = {
        min = 1,
        max = 50,
        step = 1
    },
    tSlopeRange = {
        min = -50000.0,
        max = 50000.0
    },
    tRideSlopeRange = {
        min = -360.0,
        max = 360.0
    },
    tBankingRange = {
        min = -50000.0,
        max = 50000.0
    },
    tBankPivotRange = {
        min = -2.0,
        max = 2.0,
        step = 0.1
    },
    tCurveRange = {
        min = -360.0,
        max = 360.0
    },
    -- meters per second
    tBooster = {
        -- NTLSetBoosterAcceleration (min - float, max - float)
        tAcceleration = {
            min = 1.0,
            max = 35.0
        },
        -- NTLSetBoosterSpeed (min - float, max - float)
        tSpeed = {
            min = 0.0,
            max = 80.4672
        }
    },
    -- meters per second
    tHydraulicLaunch = {
        -- NTLSetHydraulicAcceleration (min - float, max - float)
        tAcceleration = {
            min = 1.0,
            max = 35.0
        },
        -- NTLSetHydraulicSpeed (min - float, max - float)
        tSpeed = {
            min = 0.0,
            max = 89.408
        },
        -- NTLSetHydraulicReturnSpeed (min - float, max - float)
        --- keep a hold on this one, this is intended to only replace Interceptor / Jixxer
        tReturnSpeed = {
            min = 1.0,
            max = 13.4112
        }
    },
    tHoldingSection = {
        -- NTLSetHoldingStopLocation (min-float max-float)
        tStopLocation = {
            min = 0,
            max = 2.0
        },
        -- NTLSetHoldingReleaseSpeed (min-float max-float)
        tReleaseSpeed = {
            min = 0.0,
            max = nil -- default value
        },
        tReleaseAcceleration = {
            min = 1.0,
            max = 35.0
        }
    },
    tBrakes = {
        -- NTLSetBrakeMinSpeed (min-float max-float)
        tMinSpeed = {
            min = 0.27777777,
            max = nil -- default value
        },
        tDeceleration = {
            min = nil,
            max = 20.0
        }
    },
    tChainLift = {
        tSpeed = {
            min = 0.0,
            max = 10.0
        }
    },
    tAnimatedTrack = {
        tPostDepatureDelay = {
            min = 0.1,
            max = 0.1
        }
    },
    -- Feet
    -- NTLSetMaxTrackHeight (int)
    tMaxTrackHeight = 10000,
    tCarCount = {
        min = 1,
        max = 200
    },
    tTrainCount = {
        max = 200
    },
    -- NTLSetPoweredCarMaxSpeed (float)
    tPoweredCars = {
        tSpeed = {
            min = 0.2777,
            max = 35.7632
        }
    },
    tPassesThroughStation = {
        min = 1,
        max = 20
    }
}

-- List of all the trains that decided that cameras are a crazy fad and should be wonky in the process.
-- Edit: On further inspection, these seem to be PC1 trains that weren't properly translated over..
-- Thx Hiyshhiysh for finding all these and Distantz for finding the problem with these trains.
local invertedCameraTrainPrefabs = {
    "CC_ZenithBogC_Art",         -- Outermax Hydraulic Launch
    "CC_RivalCarF_Art",          -- V&N Invert 4 seater
    "CC_Sprint500CarF_Art",      -- Outermax Hydraulic Launch (Formula Rossa)
    "CC_Sprint500StockCarF_Art", -- Outermax Hydraulic Launch (Formula Rossa, Standard)
    "CC_TorqueCarF_Art",         -- Murphy & Son Star Loop
    "CC_AethonCarF_Art",         -- V&N Drop
    "CC_DragonCarF_Art",         -- Zephyr Junior Coaster
    "CC_DragonStockCarF_Art",    -- Zephyr Junior Coaster (Standard)
    "CC_BakasuraCarF_Art",       -- Vector Giant Inverted Return
    "CC_BoaCarF_Art",            -- Giovanni Inverted 2 seater
    "CC_LoonyTurnsCarF_Art",     -- F&F International Crazy Mouse
    "CC_WerewolfCarF_Art",       -- V&N Floorless
    "CC_NextGenStandUpCarF_Art", -- V&N Surf
    "CC_SuperSplashCarF_Art",    -- Big M's Rides Water Coaster
    "CC_ThrustAir2000CarF",      -- F&F International Pneumatic
    "CC_InvincibleCarF_Art"      -- Outermax Giga
}

NoTrackLimitsManager.Init = function()
    local forgeUtils = tryrequire("forgeutils.Logger")

    if forgeUtils ~= nil then
        forgeUtilsLogger = forgeUtils:Get("NoTrackLimits")
    end

    NoTrackLimitsManager.Global = {}
    NoTrackLimitsManager.tRides = {}
    NoTrackLimitsManager.tNonSlideRides = {}
    NoTrackLimitsManager.tNonKartTrains = {}
end

-- Shamelessly taken partly from Kai's FreeBuild
---Loads a lua file (disguised as a .ini file) with no environment attached and is parsed to a table as output.
---@return boolean bOK Success of config loading.
---@return table env Config output from file.
---@return table error Error message if populated
local LoadConfig = function()
    local bOK, sMsg = false, ""
    local env = {}
    local chunk, err = loadfile("Win64\\ovldata\\Mod_NoTrackLimits\\Config.NoTrackLimits.ini", "t", env)
    if not err then
        dbgTrace("Loading " .. "Config.NoTrackLimits")
        dbgTrace(tostring(chunk))
        bOK, sMsg = global.pcall(chunk, nil)
        if bOK == false then
            dbgTraceErr("Config.NoTrackLimits - error")
            dbgTraceErr(sMsg)
        end
    else
        dbgTraceErr(tostring(err))
    end
    return bOK, env, { err, sMsg }
end

---Merges each value from both _input and the global table together. <br/>
---This is intended as a workaround to tables from a loadfile not behaving the same as regular tables.
---<br/> Original from FreeBuild
---@param _input table Config to override with.
local MergeConfig = function(_input)
    local _global = NoTrackLimitsManager.Global
    for i, v in pairs(_input) do
        _global[i] = (_input[i] ~= nil and _input[i] == true)
        _global[i] = v
        dbgTrace("Merging: " .. i)
    end
end

local TableContains = function(_table, _value)
    for _, value in pairs(_table) do
        if value == _value then
            return true
        end
    end
    return false
end

NoTrackLimitsManager.Setup = function()
    api.debug.Trace("Mod_NoTrackLimits.NoTrackLimitsManager:Setup()")
    NoTrackLimitsManager.Global = NoTrackLimitsManager._tConfigDefaults

    -- Config read here
    local bOK_Main, tNTL, tErrorMain = LoadConfig()
    dbgTrace("config grabbed")
    -- Now, PZPlus basically "merges" the tables together.. ok
    dbgTrace(tostring(bOK_Main))
    MergeConfig(tNTL)
    dbgTrace(tostring(NoTrackLimitsManager.Global.eConfigMode))
    if NoTrackLimitsManager.Global.eConfigMode == "custom" then
        dbgTrace("Loading 'custom' config")
    else
        dbgTrace("Loading 'realistic config")
        NoTrackLimitsManager.Global.tConfig = NoTrackLimitsManager._tRealisticDefaults
    end

    NoTrackLimitsManager._BindPreparedStatements()
end

---Executes a Prepared Statement to a selected database with provided arguments.
---@param _sDatabase string Database name.
---@param _sPSCollection string Prepared Statement Collection name.
---@param _sInstance string Prepared Statement name.
---@param ...? any Prepared Statement paramaters.
---@return table|nil
NoTrackLimitsManager._ExecuteQuery = function(_sDatabase, _sPSCollection, _sInstance, ...)
    local result = nil
    database.SetReadOnly(_sDatabase, false)
    local tArgs = table.pack(...)

    local cPSInstance = database.GetPreparedStatementInstance(_sDatabase, _sInstance)
    if cPSInstance ~= nil then
        dbgTrace("binding to: " .. _sInstance)
        if #tArgs > 0 then
            for i, j in ipairs(tArgs) do
                dbgTrace("binding parameter: " .. j)
                database.BindParameter(cPSInstance, i, j)
            end
        end
        database.BindComplete(cPSInstance)
        database.Step(cPSInstance)

        local tRows = database.GetAllResults(cPSInstance, false)
        result = tRows or nil
    else
        dbgTrace("WARNING: COULD NOT GET INSTANCE: " .. _sInstance .. " IN: " .. _sPSCollection)
    end
    database.SetReadOnly(_sDatabase, true)
    return result
end

local tPreparedStatements = {
    TrackedRides = "Mod_NoTrackLimits_TrackedRides"
}

NoTrackLimitsManager._BindPreparedStatements = function()
    _tTrace("NoTrackLimitsManager._BindPreparedStatements()")

    local bSuccess = 0
    for k, ps in pairs(tPreparedStatements) do
        _tTrace(k)
        dbgTrace(ps)
        database.SetReadOnly(k, false)

        bSuccess = database.BindPreparedStatementCollection(k, ps)
        if bSuccess == 0 then
            _tTrace("Warning: Prepared Statement " .. ps .. " can not be bound to table " .. k)
            return nil
        end
        _tTrace("bsuccess" .. tostring(bSuccess))
        database.SetReadOnly(k, true)
    end
end

--- List of all appended GameDatabase methods that NoTrackLimits interacts with.
---@see GameDatabase
NoTrackLimitsManager.tDatabaseFunctions = {
    -- All Rides (Non-Transport)
    NTLGetAllTrackedRides = function()
        dbgTrace("NoTrackLimitsManager.GetAllRides()")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetAllTrackedRides")
    end,
    NTLGetAllNonTransportRides = function()
        dbgTrace("NoTrackLimitsManager.GetAllRides()")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetNonTransportRides")
    end,
    NTLGetAllNonSlideRides = function()
        dbgTrace("NoTrackLimitsManager.NTLGetAllNonSlideRides()")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetNonTransportNonFlumeRides")
    end,
    NTLGetAllTrains = function()
        dbgTrace("NoTrackLimitsManager.GetAllTrains()")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetAllTrains")
    end,
    NTLGetAllRideTrains_ExtraOfRide = function(_sRide)
        dbgTrace("NoTrackLimitsManager.GetAllTrains()")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetAllRideTrains_ExtraOfRide", _sRide)
    end,
    -- Elements
    NTLUpdateElementToRides = function(_sElementName)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementToRides()")

        for _, _sRide in ipairs(NoTrackLimitsManager.tRides) do
            dbgTrace(_sRide)
            NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
                "NTLUpdateElementToElementLists", _sRide, _sElementName)
        end
    end,
    NTLUpdateElementToRide = function(_sRide, _sElementName)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementToRide()")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementToElementLists", _sRide, _sElementName)
    end,
    -- Track Length
    NTLUpdateTrackLength = function(_fMin, _fMax, _fStep)
        dbgTrace("NoTrackLimitsManager.NTLUpdateTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "LengthRangeMetres", _fMin, _fMax, _fStep)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideTrackLength", _fMin, _fMax, _fStep)
    end,
    NTLUpdateMinTrackLength = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateMinTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "LengthRangeMetres", _fMin, nil, nil)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinTrackLength", _fMin)
    end,
    NTLUpdateMaxTrackLength = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateMaxTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "LengthRangeMetres", nil, _fMax, nil)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxTrackLength", _fMax)
    end,
    NTLUpdateStepTrackLength = function(_fStep)
        dbgTrace("NoTrackLimitsManager.NTLUpdateStepTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "LengthRangeMetres", nil, nil, _fStep)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesStepTrackLength", _fStep)
    end,
    -- -- Ride
    NTLUpdateRideMinTrackLength = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinTrackLength", _sRide, _fMin)
    end,
    NTLUpdateRideMaxTrackLength = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxTrackLength", _sRide, _fMax)
    end,
    NTLUpdateRideStepTrackLength = function(_sRide, _fStep)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideStepTrackLength", _sRide, _fStep)
    end,
    -- -- Element
    NTLUpdateElementMinTrackLength = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementParameterValues", "LengthRangeMetres", _sElement, _fMin, nil, nil)
    end,
    NTLUpdateElementMaxTrackLength = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementParameterValues", "LengthRangeMetres", _sElement, nil, _fMax, nil)
    end,
    NTLUpdateElementStepTrackLength = function(_sElement, _fStep)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideTrackLength")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementParameterValues", "LengthRangeMetres", _sElement, _fStep, nil, nil)
    end,

    -- Ride Height
    NTLSetMaxTrackHeight = function(_iHeight)
        dbgTrace("NoTrackLimitsManager.NTLSetMaxTrackHeight")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetMaxTrackHeight", _iHeight)
    end,
    -- SlopeRangeDegrees
    NTLUpdateElementsSlopeRangeDegrees = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "SlopeRangeDegrees", _fMin, _fMax, nil)
    end,
    NTLUpdateRidesSlopeRangeDegrees = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesSlopeRangeDegrees", _fMin, _fMax)
    end,
    -- -- Ride
    NTLUpdateRideMinSlopeRangeDegrees = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinSlopeRangeDegrees", _sRide, _fMin)
    end,
    NTLUpdateRidesMinSlopeRangeDegrees = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinSlopeRangeDegrees", _fMin)
    end,
    NTLUpdateRideMaxSlopeRangeDegrees = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxSlopeRangeDegrees", _sRide, _fMax)
    end,
    NTLUpdateRidesMaxSlopeRangeDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxSlopeRangeDegrees", _fMax)
    end,
    -- -- Element
    NTLUpdateElementMinSlopeRangeDegrees = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementParameterValues", "SlopeRangeDegrees", _sElement, _fMin, nil, nil)
    end,
    NTLUpdateElementMaxSlopeRangeDegrees = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideSlopeRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementParameterValues", _sElement, nil, _fMax, nil)
    end,
    -- Delta
    NTLUpdateRidesMaxSlopeDeltaDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMaxSlopeDeltaDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxSlopeDeltaDegrees", _fMax)
    end,
    NTLUpdateRideMaxSlopeDeltaDegrees = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxSlopeDeltaDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxSlopeDeltaDegrees", _sRide, _fMax)
    end,
    -- BankingRangeDegrees
    NTLUpdateBankingRangeDegrees = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "BankingRangeDegrees", _fMin, _fMax, nil)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesBankingRangeDegrees", _fMin, _fMax)
    end,
    -- Element
    NTLUpdateElementsMinBankingRangeDegrees = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinBankingRangeDegrees", _fMin)
    end,
    NTLUpdateElementMinBankingRangeDegrees = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBankingRangeDegrees", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBankingRangeDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBankingRangeDegrees", _fMax)
    end,
    NTLUpdateElementMaxBankingRangeDegrees = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBankingRangeDegrees", _sElement, _fMax)
    end,
    -- Rides
    NTLUpdateRideMinBankingRangeDegrees = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinBankingRangeDegrees", _sRide, _fMin)
    end,
    NTLUpdateRidesMinBankingRangeDegrees = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinBankingRangeDegrees", _fMin)
    end,
    NTLUpdateRideMaxBankingRangeDegrees = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxBankingRangeDegrees", _sRide, _fMax)
    end,
    NTLUpdateRidesMaxBankingRangeDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxBankingRangeDegrees", _fMax)
    end,
    NTLUpdateRidesMaxBankDeltaDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMaxBankingRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxBankDeltaDegrees", _fMax)
    end,


    -- Bank Pivot Range

    NTLUpdateBankPivotRange = function(_fMin, _fMax, _fStep)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "BankPivotRange", _fMin, _fMax, _fStep)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesBankPivotRange", _fMin, _fMax, _fStep)
    end,
    -- -- Elements
    NTLUpdateElementsMinBankPivotRange = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "BankPivotRange", _fMin, nil, nil)
    end,
    NTLUpdateElementMinBankPivotRange = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBankPivotRange", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBankPivotRange = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBankPivotRange", _fMax)
    end,
    NTLUpdateElementMaxBankPivotRange = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBankPivotRange", _sElement, _fMax)
    end,


    -- -- Rides
    NTLUpdateRideMinBankPivotRange = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinBankPivotRange", _sRide, _fMin)
    end,
    NTLUpdateRidesMinBankPivotRange = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinBankPivotRange", _fMin)
    end,
    NTLUpdateRideMaxBankPivotRange = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxBankPivotRange", _sRide, _fMax)
    end,
    NTLUpdateRidesMaxBankPivotRange = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxBankPivotRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxBankPivotRange", _fMax)
    end,


    -- Curve Range
    NTLUpdateCurveRangeDegrees = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsCurveRangeDegrees", _fMin, _fMax)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesCurveRangeDegrees", _fMin, _fMax)
    end,
    -- -- Elements
    NTLUpdateElementsMinCurveRangeDegrees = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinCurveRangeDegrees", _fMin)
    end,
    NTLUpdateElementMinCurveRangeDegrees = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinCurveRangeDegrees", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxCurveRangeDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxCurveRangeDegrees", _fMax)
    end,
    NTLUpdateElementMaxCurveRangeDegrees = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxCurveRangeDegrees", _sElement, _fMax)
    end,
    -- -- Rides
    NTLUpdateRideMinCurveRangeDegrees = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinCurveRangeDegrees", _sRide, _fMin)
    end,
    NTLUpdateRidesMinCurveRangeDegrees = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinCurveRangeDegrees", _fMin)
    end,
    NTLUpdateRideMaxCurveRangeDegrees = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxCurveRangeDegrees", _sRide, _fMax)
    end,
    NTLUpdateRidesMaxCurveRangeDegrees = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxCurveRangeDegrees")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxCurveRangeDegrees", _fMax)
    end,

    -- Scale Range
    NTLUpdateScaleRange = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsScaleRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsScaleRange", _fMin, _fMax)
    end,
    NTLUpdateElementsMinScaleRange = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinScaleRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinScaleRange", _fMin)
    end,
    NTLUpdateElementMinScaleRange = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinScaleRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinScaleRange", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxScaleRange = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxScaleRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxScaleRange", _fMax)
    end,
    NTLUpdateElementMaxScaleRange = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxScaleRange")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxScaleRange", _sElement, _fMax)
    end,
    -- Booster Acceleration
    NTLSetBoosterAcceleration = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetBoosterAcceleration", _fMin, _fMax)
    end,
    NTLUpdateElementsMinBoosterAcceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinBoosterAcceleration", _fMin)
    end,
    NTLUpdateElementMinBoosterAcceleration = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBoosterAcceleration", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBoosterAcceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBoosterAcceleration", _fMax)
    end,
    NTLUpdateElementMaxBoosterAcceleration = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBoosterAcceleration", _sElement, _fMax)
    end,
    -- Alt Booster Acceleration (for F25)
    NTLSetAltBoosterAcceleration = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinAltBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetAltBoosterAcceleration", _fMin, _fMax)
    end,
    NTLUpdateElementsMinAltBoosterAcceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinAltBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinAltBoosterAcceleration", _fMin)
    end,
    NTLUpdateElementMinAltBoosterAcceleration = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinAltBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinAltBoosterAcceleration", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxAltBoosterAcceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxAltBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxAltBoosterAcceleration", _fMax)
    end,
    NTLUpdateElementMaxAltBoosterAcceleration = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxAltBoosterAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxAltBoosterAcceleration", _sElement, _fMax)
    end,
    -- BoosterMaxSpeed
    NTLSetBoosterMaxSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetBoosterMaxSpeed", _fMin, _fMax)
    end,
    NTLUpdateElementsMinBoosterMaxSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinBoosterMaxSpeed", _fMin)
    end,
    NTLUpdateElementMinBoosterMaxSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBoosterMaxSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBoosterMaxSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBoosterMaxSpeed", _fMax)
    end,
    NTLUpdateElementMaxBoosterMaxSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBoosterMaxSpeed", _sElement, _fMax)
    end,
    -- AltBoosterMaxSpeed (F25)
    NTLSetAltBoosterMaxSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinAltBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetAltBoosterMaxSpeed", _fMin, _fMax)
    end,
    NTLUpdateElementsMinAltBoosterMaxSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinAltBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinAltBoosterMaxSpeed", _fMin)
    end,
    NTLUpdateElementMinAltBoosterMaxSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinAltBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinAltBoosterMaxSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxAltBoosterMaxSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxAltBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxAltBoosterMaxSpeed", _fMax)
    end,
    NTLUpdateElementMaxAltBoosterMaxSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxAltBoosterMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxAltBoosterMaxSpeed", _sElement, _fMax)
    end,
    -- Hydraulic Acceleration
    NTLSetHydraulicAcceleration = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsHydraulicAcceleration", _fMin, _fMax)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetRidesHydraulicAcceleration", _fMin, _fMax)
    end,
    -- Elements
    NTLUpdateElementsMinHydraulicAcceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHydraulicAcceleration", _fMin)
    end,
    NTLUpdateElementMinHydraulicAcceleration = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHydraulicAcceleration", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHydraulicAcceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHydraulicAcceleration", _fMax)
    end,
    NTLUpdateElementMaxHydraulicAcceleration = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHydraulicAcceleration", _sElement, _fMax)
    end,
    -- Rides
    NTLUpdateRidesMinHydraulicAcceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMinHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinHydraulicAcceleration", _fMin)
    end,
    NTLUpdateRideMinHydraulicAcceleration = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinHydraulicAcceleration", _sRide, _fMin)
    end,
    NTLUpdateRidesMaxHydraulicAcceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMaxHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxHydraulicAcceleration", _fMax)
    end,
    NTLUpdateRideMaxHydraulicAcceleration = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxHydraulicAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxHydraulicAcceleration", _sRide, _fMax)
    end,
    -- Hydraulic Speed
    NTLSetHydraulicSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsHydraulicSpeed", _fMin, _fMax)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetRidesHydraulicSpeed", _fMin, _fMax)
    end,
    -- Elements
    NTLUpdateElementsMinHydraulicSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHydraulicSpeed", _fMin)
    end,
    NTLUpdateElementMinHydraulicSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHydraulicSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHydraulicSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHydraulicSpeed", _fMax)
    end,
    NTLUpdateElementMaxHydraulicSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHydraulicSpeed", _sElement, _fMax)
    end,
    -- Rides
    NTLUpdateRidesMinHydraulicSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMinHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinHydraulicSpeed", _fMin)
    end,
    NTLUpdateRideMinHydraulicSpeed = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinHydraulicSpeed", _sRide, _fMin)
    end,
    NTLUpdateRidesMaxHydraulicSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMaxHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxHydraulicSpeed", _fMax)
    end,
    NTLUpdateRideMaxHydraulicSpeed = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxHydraulicSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxHydraulicSpeed", _sRide, _fMax)
    end,
    -- Hydraulic Return Speed
    NTLSetHydraulicReturnSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsHydraulicReturnSpeed", _fMin, _fMax)
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetRidesHydraulicReturnSpeed", _fMin, _fMax)
    end,
    -- Elements
    NTLUpdateElementsMinHydraulicReturnSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHydraulicReturnSpeed", _fMin)
    end,
    NTLUpdateElementMinHydraulicReturnSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHydraulicReturnSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHydraulicReturnSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHydraulicReturnSpeed", _fMax)
    end,
    NTLUpdateElementMaxHydraulicReturnSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHydraulicReturnSpeed", _sElement, _fMax)
    end,
    -- Rides
    NTLUpdateRidesMinHydraulicReturnSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMinHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMinHydraulicReturnSpeed", _fMin)
    end,
    NTLUpdateRideMinHydraulicReturnSpeed = function(_sRide, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMinHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMinHydraulicReturnSpeed", _sRide, _fMin)
    end,
    NTLUpdateRidesMaxHydraulicReturnSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRidesMaxHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRidesMaxHydraulicReturnSpeed", _fMax)
    end,
    NTLUpdateRideMaxHydraulicReturnSpeed = function(_sRide, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateRideMaxHydraulicReturnSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateRideMaxHydraulicReturnSpeed", _sRide, _fMax)
    end,
    -- Holding Stop Location
    NTLSetHoldingStopLocation = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHoldingStopLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsHoldingStopLocation", _fMin, _fMax)
    end,
    NTLUpdateElementsMinHoldingStopLocation = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHoldingStopLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHoldingStopLocation", _fMin)
    end,
    NTLUpdateElementMinHoldingStopLocation = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHoldingStopLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHoldingStopLocation", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHoldingStopLocation = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHoldingStopLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHoldingStopLocation", _fMax)
    end,
    NTLUpdateElementMaxHoldingStopLocation = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHoldingStopLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHoldingStopLocation", _sElement, _fMax)
    end,
    -- Holding Release Speed
    NTLSetHoldingReleaseSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHoldingReleaseSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetHoldingReleaseSpeed", _fMin, _fMax)
    end,
    NTLUpdateElementsMinHoldingReleaseSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHoldingReleaseSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHoldingReleaseSpeed", _fMin)
    end,
    NTLUpdateElementMinHoldingReleaseSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHoldingReleaseSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHoldingReleaseSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHoldingReleaseSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHoldingReleaseSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHoldingReleaseSpeed", _fMax)
    end,
    NTLUpdateElementMaxHoldingReleaseSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHoldingReleaseSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHoldingReleaseSpeed", _sElement, _fMax)
    end,
    -- Holding Release Acceleration
    NTLSetHoldingReleaseAcceleration = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetHoldingReleaseAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetHoldingReleaseAcceleration", _fMin, _fMax)
    end,
    NTLUpdateElementsMinHoldingReleaseAcceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinHoldingReleaseAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinHoldingReleaseAcceleration", _fMin)
    end,
    NTLUpdateElementMinHoldingReleaseAcceleration = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinHoldingReleaseAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinHoldingReleaseAcceleration", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxHoldingReleaseAcceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxHoldingReleaseAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxHoldingReleaseAcceleration", _fMax)
    end,
    NTLUpdateElementMaxHoldingReleaseAcceleration = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxHoldingReleaseAcceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxHoldingReleaseAcceleration", _sElement, _fMax)
    end,
    NTLSetAnimatedTrackPostDepartureDelay = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetAnimatedTrackPostDepartureDelay")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetAnimatedTrackPostDepartureDelay", _fMin, _fMax)
    end,
    -- Brake Min Speed
    NTLSetBrakeMinSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetBrakeMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsBrakeMinSpeed", _fMin, _fMax)
    end,
    NTLUpdateElementsMinBrakeMinSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBrakeMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinBrakeMinSpeed", _fMin)
    end,
    NTLUpdateElementMinBrakeMinSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBrakeMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBrakeMinSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBrakeMinSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBrakeMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBrakeMinSpeed", _fMax)
    end,
    NTLUpdateElementMaxBrakeMinSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBrakeMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBrakeMinSpeed", _sElement, _fMax)
    end,
    -- Brake Deceleration
    NTLSetBrakeDeceleration = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetBrakeDeceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsBrakeDeceleration", _fMin, _fMax)
    end,
    NTLUpdateElementsMinBrakeDeceleration = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinBrakeDeceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinBrakeDeceleration", _fMin)
    end,
    NTLUpdateElementMinBrakeDeceleration = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinBrakeDeceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinBrakeDeceleration", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxBrakeDeceleration = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxBrakeDeceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxBrakeDeceleration", _fMax)
    end,
    NTLUpdateElementMaxBrakeDeceleration = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxBrakeDeceleration")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxBrakeDeceleration", _sElement, _fMax)
    end,
    -- Chain Lift Speed
    NTLSetChainLiftSpeed = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetChainLiftSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetChainLiftSpeed", _fMin, _fMax)
    end,
    NTLUpdateElementsMinChainLiftSpeed = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinChainLiftSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinChainLiftSpeed", _fMin)
    end,
    NTLUpdateElementMinChainLiftSpeed = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinChainLiftSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinChainLiftSpeed", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxChainLiftSpeed = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxChainLiftSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxChainLiftSpeed", _fMax)
    end,
    NTLUpdateElementMaxChainLiftSpeed = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxChainLiftSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxChainLiftSpeed", _sElement, _fMax)
    end,
    -- Boomerang Drop Location
    NTLSetChainLiftDropLocation = function(_fMin, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLSetChainLiftDropLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetChainLiftDropLocation", _fMin, _fMax)
    end,
    NTLUpdateElementsMinChainLiftDropLocation = function(_fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMinChainLiftDropLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMinChainLiftDropLocation", _fMin)
    end,
    NTLUpdateElementMinChainLiftDropLocation = function(_sElement, _fMin)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMinChainLiftDropLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMinChainLiftDropLocation", _sElement, _fMin)
    end,
    NTLUpdateElementsMaxChainLiftDropLocation = function(_fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementsMaxChainLiftDropLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementsMaxChainLiftDropLocation", _fMax)
    end,
    NTLUpdateElementMaxChainLiftDropLocation = function(_sElement, _fMax)
        dbgTrace("NoTrackLimitsManager.NTLUpdateElementMaxChainLiftDropLocation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLUpdateElementMaxChainLiftDropLocation", _sElement, _fMax)
    end,
    -- Element allowed on water
    NTLSetElementsAllowedOnWater = function(_value)
        dbgTrace("NoTrackLimitsManager.NTLSetElementsAllowedOnWater()")
        if _value ~= 0 and _value ~= 1 then
            dbgTrace("ERROR: value is not a 0 or 1.")
            return
        end
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsAllowedOnWater", _value)
    end,
    NTLSetElementAllowedOnWater = function(_element, _value)
        dbgTrace("NoTrackLimitsManager.NTLSetElementAllowedOnWater()")
        if _value ~= 0 and _value ~= 1 then
            dbgTrace("ERROR: value is not a 0 or 1.")
            return
        end
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementAllowedOnWater", _element, _value)
    end,
    -- if chain lift swaps to default track when being sloped downwards
    NTLSetChainLiftsSwapOnSlopeDown = function(_value)
        dbgTrace("NoTrackLimitsManager.NTLDisableChainLiftSwapOnSlopeDown()")
        if _value ~= 0 and _value ~= 1 then
            dbgTrace("ERROR: value is not a 0 or 1.")
            return
        end
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetChainLiftsSwapOnSlopeDown", _value)
    end,
    NTLSetChainLiftSwapOnSlopeDown = function(_element, _value)
        dbgTrace("NoTrackLimitsManager.NTLDisableChainLiftSwapOnSlopeDown()")
        if _value ~= 0 and _value ~= 1 then
            dbgTrace("ERROR: value is not a 0 or 1.")
            return
        end
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetChainLiftSwapOnSlopeDown", _element, _value)
    end,
    NTLUpdateAllTrainsToRide_Extras = function(_sRide)
        dbgTrace("NoTrackLimitsManager.NTLUpdateAllTrainsToRide_Extras()")
        dbgTrace(_sRide)
        local _iSort = 0

        local _trainDBList = NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetAllRideTrains_ExtraOfRide", _sRide)
        -- Some coasters / flat rides don't even have their own trains
        -- So we need to account for that
        if _trainDBList == nil or #_trainDBList == 0 then
            dbgTrace("Found empty list, adding in all trains.")
            _iSort = 10
            for _, _train in pairs(NoTrackLimitsManager.tNonKartTrains) do
                NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
                    "NTLUpdateTrainToRideExtra", _sRide, _train, _iSort)
                _iSort = _iSort + 10
            end
            return
        end
        local _trainList = {}
        local _sortList = {}
        for _, _j in pairs(_trainDBList) do
            --     dbgTrace(tableplus.tostring(_train, nil, nil, nil, true))
            table.insert(_trainList, _j[1])
            table.insert(_sortList, _j[2])
        end

        for _, _train in pairs(NoTrackLimitsManager.tNonKartTrains) do
            if TableContains(_trainList, _train) then -- Skipping all trains that were already added to the table
                goto continue
            end
            if _iSort == 0 then
                _iSort = math.max(table.unpack(_sortList)) + 10
                dbgTrace("Set sort number to " .. _iSort)
            end
            dbgTrace("Appending train: " .. _train .. " to ride: " .. _sRide .. " using sort id " .. _iSort)
            NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
                "NTLUpdateTrainToRideExtra", _sRide, _train, _iSort)
            table.insert(_trainList, _train)
            _iSort = _iSort + 10
            ::continue::
        end
    end,
    -- Car Count
    NTLSetCarsCount = function(_iMinCars, _iMaxCars)
        dbgTrace("NoTrackLimitsManager.NTLSetCarCount()")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides", "NTLSetNumCars",
            _iMinCars, _iMaxCars)
    end,
    NTLSetMinCarsCount = function(_iMinCars)
        dbgTrace("NoTrackLimitsManager.NTLSetCarCount()")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides", "NTLUpdateMinNumCars",
            _iMinCars)
    end,
    NTLSetMaxCarsCount = function(_iMaxCars)
        dbgTrace("NoTrackLimitsManager.NTLSetCarCount()")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides", "NTLUpdateMaxNumCars",
            _iMaxCars)
    end,
    NTLSetMaxTrainCount = function(_iMaxTrain)
        dbgTrace("NoTrackLimitsManager.NTLSetCarCount()")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides", "NTLUpdateMaxNumTrain",
            _iMaxTrain)
    end,
    -- Powered Cars
    NTLSetPoweredMinSpeed = function(_sTrain, _dPoweredMinSpeed)
        dbgTrace("NoTrackLimitsManager.NTLSetPoweredMinSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetPoweredCarMinSpeed", _sTrain, _dPoweredMinSpeed)
    end,
    NTLSetPoweredMaxSpeed = function(_sTrain, _dPoweredMaxSpeed)
        dbgTrace("NoTrackLimitsManager.NTLSetPoweredMaxSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetPoweredCarMaxSpeed", _sTrain, _dPoweredMaxSpeed)
    end,
    NTLSetPoweredCarSpeed = function(_dPoweredMinSpeed, _dPoweredMaxSpeed)
        dbgTrace("NoTrackLimitsManager.NTLSetPoweredCarSpeed")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetPoweredCarSpeed", _dPoweredMinSpeed, _dPoweredMaxSpeed)
    end,
    NTLSetPassesThroughStation = function(_dMinPasses, _dMaxPasses)
        dbgTrace("NoTrackLimitsManager.NTLSetPassesThroughStation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetPassesThroughStation", _dMinPasses, _dMaxPasses)
    end,
    NTLSetMinPassesThroughStation = function(_sRide, _dMinPasses)
        dbgTrace("NoTrackLimitsManager.NTLSetMinPassesThroughStation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetMinPassesThroughStation", _sRide, _dMinPasses)
    end,
    NTLSetMaxPassesThroughStation = function(_sRide, _dMaxPasses)
        dbgTrace("NoTrackLimitsManager.NTLSetMaxPassesThroughStation")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetMaxPassesThroughStation", _sRide, _dMaxPasses)
    end,

    NTLAppendElementParamaterToElement = function(_sElement, _sParam, _dMin, _dMax, _dInitial, _dStep, _labelOverride,
                                                  _valueLabelSetName)
        dbgTrace("NoTrackLimitsManager.NTLAppendElementParamaterToElement")
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLAppendElementParamaterToElement", _sElement, _sParam, _dMin, _dMax, _dInitial, _dStep, _labelOverride,
            _valueLabelSetName)
    end,

    NTLGetAllContentPacksOfElement = function(_sElement)
        dbgTrace("NoTrackLimitsManager.NTLGetAllContentPacksOfElement")
        return NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLGetAllContentPacksOfElement", _sElement)
    end,
    NTLGetGlobalConfig = function()
        return NoTrackLimitsManager.Global
    end
}

NoTrackLimitsManager.AddDatabaseFunctions = function(_tDatabaseFunctions)
    for sMethod, fnMethod in pairs(NoTrackLimitsManager.tDatabaseFunctions) do
        _tDatabaseFunctions[sMethod] = fnMethod
    end
end

NoTrackLimitsManager.ShutdownForReInit = function()

end

NoTrackLimitsManager.Shutdown = function()

end

-- PreBuildPrefabs is used here as a way to ensure the database functions are called before prefabs are actually built
-- Therefore, _fnAdd is never needed
NoTrackLimitsManager.PreBuildPrefabs = function(_fnAdd, _tLuaPrefabNames, _tLuaPrefabs)
    NoTrackLimitsManager.Global = NoTrackLimitsManager._tConfigDefaults

    dbgTrace("NoTrackLimitsManager.PreBuildPrefabs()")
    -- Config read here
    local bOK_Main, tNTL, tErrorMain = LoadConfig()
    dbgTrace("config grabbed")
    -- Now, PZPlus basically "merges" the tables together.. ok
    dbgTrace(tostring(bOK_Main))
    MergeConfig(tNTL)
    dbgTrace(tostring(NoTrackLimitsManager.Global.eConfigMode))
    if NoTrackLimitsManager.Global.eConfigMode == "custom" then
        dbgTrace("Loading 'custom' config")
    else
        dbgTrace("Loading 'realistic config")
        NoTrackLimitsManager.Global.tConfig = NoTrackLimitsManager._tRealisticDefaults
    end

    NoTrackLimitsManager._BindPreparedStatements()

    local _tRides = GameDatabase.NTLGetAllTrackedRides()
    NoTrackLimitsManager.tRides = {} -- to prevent duplicates
    for _, row in ipairs(_tRides) do
        table.insert(NoTrackLimitsManager.tRides, row[1])
    end

    local _tNonSlideRides = GameDatabase.NTLGetAllNonSlideRides()
    NoTrackLimitsManager.tNonSlideRides = {} -- to prevent duplicates
    for _, row in ipairs(_tNonSlideRides) do
        table.insert(NoTrackLimitsManager.tNonSlideRides, row[1])
    end

    if NoTrackLimitsManager.Global.bAllowAllInterchangableCoasterTrains then
        local _tTrains = GameDatabase.NTLGetAllTrains()
        -- dbgTrace("Grabbed trains, now to check if they exist")
        for _, row in ipairs(_tTrains) do
            table.insert(NoTrackLimitsManager.tNonKartTrains, row[1])
        end
        for _, _sRide in pairs(NoTrackLimitsManager.tNonSlideRides) do
            GameDatabase.NTLUpdateAllTrainsToRide_Extras(_sRide)
        end
    end
    NoTrackLimitsManager._ProcessConfig()

    -- remember how i said that _fnAdd is never needed? i lied
    -- this is for the strange case of Frontier accidentally doing -pi to some train cameras. need to iterate through all train prefabs tho.
    if NoTrackLimitsManager.Global.bEnableCameraEffects ~= true and NoTrackLimitsManager.Global.bPatchTrainCameras == true then
        dbgTrace("Patching all cameras on trains")
        -- CamOffset does the same thing, so i don't want to ruin their progress..
        if camoffset_mod == nil then
            for _, sPrefabName in ipairs(invertedCameraTrainPrefabs) do
                local tVisualsPrefab = NoTrackLimitsManager.EditBumperCameraPrefab(sPrefabName);
                if tVisualsPrefab ~= nil then
                    _fnAdd(sPrefabName, tVisualsPrefab)
                end
            end
        else
            dbgTrace("CamOffsets found, skipping prefab patching and letting the mod handle it instead.")
            NoTrackLimitsManager.Global.bPatchTrainCameras = false
        end
    end
end


NoTrackLimitsManager.EditBumperCameraPrefab = function(sPrefabName)
    dbgTrace("Editing visuals prefab of " .. sPrefabName)
    local tVisualsPrefab = api.entity.FindPrefab(sPrefabName)
    if tVisualsPrefab == nil then
        dbgTrace("Prefab not found, are you sure you got the right capitalisation?");
        return nil
    end

    -- for SOME reason, there's a train type that doesn't even have a front camera bumper??
    if tVisualsPrefab.Children.TrackCarFrontBumper == nil then
        table.insert(tVisualsPrefab.Children.TrackCarFrontBumper, {
            Prefab = 'TrackCarFrontBumperCameraAttachPoint',
            Properties = {
                FOV = {
                    Default = 1.0
                },
                Rotation = {
                    Default = Vector3:new(0.0, 0.0, 0.0)
                },
                Position = {
                    Default = Vector3:new(0, 0, 0)
                }
            }
        }
        )
        return tVisualsPrefab
    end

    -- Now to set the prefab rotation
    tVisualsPrefab.Children.TrackCarFrontBumper.Properties.Rotation.Default = Vector3:new(0, 0, 0)
    -- Apparently CamOffsets pointed out the problem also lies with FrontLook
    tVisualsPrefab.Children.TrackCarFrontLook.Properties.Rotation.Default = Vector3:new(0, 0, 0)
    return tVisualsPrefab
end


function NoTrackLimitsManager.CanUseElement(_sElement)
    local contentPacks = GameDatabase.NTLGetAllContentPacksOfElement(_sElement)
    for _, _sPack in ipairs(contentPacks) do
        if _sPack == "BaseGame" then
            return true
        end
        if api.content.IsDLCOwned(_sPack) == false then
            return false
        end
    end
    return true
end

NoTrackLimitsManager._ProcessConfig = function()
    --- Mostly for those who JUST want more trains or change the camera effects.
    if NoTrackLimitsManager.Global.tConfig == {} or NoTrackLimitsManager.Global.tConfig == nil then
        dbgTrace(
            "tConfig is empty, no changes are made to tracked rides or their elements excluding new trains or prefab edits to cameras")
        return
    end

    -- Elements to other rides
    if NoTrackLimitsManager.Global.tConfig.tAppendedElements then
        for _, element in ipairs(NoTrackLimitsManager.Global.tConfig.tAppendedElements) do
            local canAddElement = NoTrackLimitsManager.CanUseElement(element)
            if not canAddElement then
                dbgTraceErr("User does not have the DLC required for " .. element)
            end
            if canAddElement then
                dbgTrace("Appending element: " .. element)
                GameDatabase.NTLUpdateElementToRides(element)
            end
        end
    end

    -- Ride spesific elements to be added
    if NoTrackLimitsManager.Global.tConfig.tAppendedElementsToRide then
        for _sRide, _tRideElements in pairs(NoTrackLimitsManager.Global.tConfig.tAppendedElementsToRide) do
            for _, element in ipairs(_tRideElements) do
                dbgTrace("Appending element: " .. element .. "to ride: " .. _sRide)

                local canAddElement = NoTrackLimitsManager.CanUseElement(element)
                if canAddElement then
                    GameDatabase.NTLUpdateElementToRide(_sRide, element)
                end
                if not canAddElement then
                    dbgTraceErr("User does not have the DLC required for " .. element)
                end
            end
        end
    end

    -- Track Length
    if NoTrackLimitsManager.Global.tConfig.tTrackLength then
        dbgTrace("Setting Global Track Length")
        if NoTrackLimitsManager.Global.tConfig.tTrackLength.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tTrackLength.max ~= nil and
            NoTrackLimitsManager.Global.tConfig.tTrackLength.step ~= nil then
            dbgTrace("Using min, max and step")

            GameDatabase.NTLUpdateTrackLength(NoTrackLimitsManager.Global.tConfig.tTrackLength.min,
                NoTrackLimitsManager.Global.tConfig.tTrackLength.max,
                NoTrackLimitsManager.Global.tConfig.tTrackLength.step)
        else
            if NoTrackLimitsManager.Global.tConfig.tTrackLength.min ~= nil then
                GameDatabase.NTLUpdateMinTrackLength(NoTrackLimitsManager.Global.tConfig.tTrackLength.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tTrackLength.max ~= nil then
                GameDatabase.NTLUpdateMaxTrackLength(NoTrackLimitsManager.Global.tConfig.tTrackLength.max)
            end
            if NoTrackLimitsManager.Global.tConfig.tTrackLength.step ~= nil then
                GameDatabase.NTLUpdateStepTrackLength(NoTrackLimitsManager.Global.tConfig.tTrackLength.step)
            end
        end
    end

    -- Track Height
    if NoTrackLimitsManager.Global.tConfig.tMaxTrackHeight and NoTrackLimitsManager.Global.tConfig.tMaxTrackHeight ~= nil then
        dbgTrace("Setting Max Track Height")
        GameDatabase.NTLSetMaxTrackHeight(NoTrackLimitsManager.Global.tConfig.tMaxTrackHeight)
    end

    -- Element SlopeRangeDegrees
    if NoTrackLimitsManager.Global.tConfig.tSlopeRange then
        dbgTrace("Setting Global Slope Range")
        -- Appending Slope Range to a chosen element
        if NoTrackLimitsManager.Global.tConfig.tSlopeRange.tAppendToElements ~= nil then
            dbgTrace("Adding Global Slope Range to elements")
            -- bit of error correction
            local _nSlopeMin = 0
            local _nSlopeMax = 0
            local _nStep = 0
            local _nInitial = 0
            local _labelOverride = nil -- Only used to change the name of the visual on UI
            -- i.e. "Optional Catwalk" is replaced with "Optional Spine" on Copperhead Strike
            local _valueLabelSetName = nil

            -- dbgTrace(tableplus.tostring(NoTrackLimitsManager.Global.tConfig.tSlopeRange.tAppendToElements))

            if NoTrackLimitsManager.Global.tConfig.tSlopeRange.min ~= nil then
                _nSlopeMin = NoTrackLimitsManager.Global.tConfig.tSlopeRange.min
            end
            if NoTrackLimitsManager.Global.tConfig.tSlopeRange.max ~= nil then
                _nSlopeMax = NoTrackLimitsManager.Global.tConfig.tSlopeRange.max
            end
            -- dbgTrace("Check 3")

            for _, value in pairs(NoTrackLimitsManager.Global.tConfig.tSlopeRange.tAppendToElements) do
                dbgTrace("Adding SlopeRangeDegrees to element: " .. value)
                GameDatabase.NTLAppendElementParamaterToElement(value, "SlopeRangeDegrees", _nSlopeMin, _nSlopeMax,
                    _nInitial, _nStep, _labelOverride, _valueLabelSetName)
            end
        end

        if NoTrackLimitsManager.Global.tConfig.tSlopeRange.maxDelta ~= nil then
            dbgTrace("Setting Max Delta")
            GameDatabase.NTLUpdateRidesMaxSlopeDeltaDegrees(NoTrackLimitsManager.Global.tConfig.tSlopeRange.maxDelta)
        end

        if NoTrackLimitsManager.Global.tConfig.tSlopeRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tSlopeRange.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateElementsSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tSlopeRange.min,
                NoTrackLimitsManager.Global.tConfig.tSlopeRange.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tSlopeRange.min ~= nil then
                GameDatabase.NTLUpdateElementsMinSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tSlopeRange.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tSlopeRange.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tSlopeRange.max)
            end
        end
    end

    -- Ride Slope Range Degrees
    if NoTrackLimitsManager.Global.tConfig.tRideSlopeRange then
        dbgTrace("Setting Ride Slope Range")
        if NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateRidesSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.min,
                NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.min ~= nil then
                GameDatabase.NTLUpdateRidesMinSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tRideSlopeRange
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tRideSlopeRange.max ~= nil then
                GameDatabase.NTLUpdateRidesMaxSlopeRangeDegrees(NoTrackLimitsManager.Global.tConfig.tRideSlopeRange
                    .max)
            end
        end
    end

    -- Banking Range
    if NoTrackLimitsManager.Global.tConfig.tBankingRange then
        dbgTrace("Setting Banking Range")

        -- Appending Banking Range to a chosen element
        if NoTrackLimitsManager.Global.tConfig.tBankingRange.tAppendToElements ~= nil then
            dbgTrace("Adding Banking Range to elements")
            -- bit of error correction
            local _nRangeMin = 0
            local _nRangeMax = 0
            local _nStep = 0
            local _nInitial = 0
            local _labelOverride = nil -- Only used to change the name of the visual on UI
            -- i.e. "Optional Catwalk" is replaced with "Optional Spine" on Copperhead Strike
            local _valueLabelSetName = nil
            -- dbgTrace("Check 1")

            -- dbgTrace(tableplus.tostring(NoTrackLimitsManager.Global.tConfig.tBankingRange.tAppendToElements))
            -- dbgTrace("Check 2")

            if NoTrackLimitsManager.Global.tConfig.tBankingRange.min ~= nil then
                _nRangeMin = NoTrackLimitsManager.Global.tConfig.tBankingRange.min
            end
            if NoTrackLimitsManager.Global.tConfig.tBankingRange.max ~= nil then
                _nRangeMax = NoTrackLimitsManager.Global.tConfig.tBankingRange.max
            end
            -- dbgTrace("Check 3")

            for _, value in pairs(NoTrackLimitsManager.Global.tConfig.tBankingRange.tAppendToElements) do
                -- dbgTrace(key)
                -- dbgTrace(value)
                dbgTrace("Adding BankingRangeDegrees to element: " .. value)
                GameDatabase.NTLAppendElementParamaterToElement(value, "BankingRangeDegrees", _nRangeMin, _nRangeMax,
                    _nInitial, _nStep, _labelOverride, _valueLabelSetName)
            end
        end

        if NoTrackLimitsManager.Global.tConfig.tBankingRange.maxDelta ~= nil then
            dbgTrace("Setting Max Banking Delta")
            GameDatabase.NTLUpdateRidesMaxBankDeltaDegrees(NoTrackLimitsManager.Global.tConfig.tBankingRange.maxDelta)
        end

        if NoTrackLimitsManager.Global.tConfig.tBankingRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBankingRange.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateBankingRangeDegrees(NoTrackLimitsManager.Global.tConfig.tBankingRange.min,
                NoTrackLimitsManager.Global.tConfig.tBankingRange.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBankingRange.min ~= nil then
                GameDatabase.NTLUpdateRidesMinBankingRangeDegrees(NoTrackLimitsManager.Global.tConfig.tBankingRange
                    .min)
                GameDatabase.NTLUpdateElementsMinBankingRangeDegrees(NoTrackLimitsManager.Global.tConfig
                    .tBankingRange.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBankingRange.max ~= nil then
                GameDatabase.NTLUpdateRidesMaxBankingRangeDegrees(NoTrackLimitsManager.Global.tConfig.tBankingRange
                    .max)
                GameDatabase.NTLUpdateElementsMaxBankingRangeDegrees(NoTrackLimitsManager.Global.tConfig
                    .tBankingRange.max)
            end
        end
    end

    -- Bank Pivot Range
    if NoTrackLimitsManager.Global.tConfig.tBankPivotRange then
        dbgTrace("Setting Banking Pivot Range")

        -- Appending Banking Range to a chosen element
        if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.tAppendToElements ~= nil then
            dbgTrace("Adding Banking Pivot Range to elements")
            -- bit of error correction
            local _nRangeMin = 0
            local _nRangeMax = 0
            local _nStep = 0
            local _nInitial = 0
            local _labelOverride = nil -- Only used to change the name of the visual on UI
            -- i.e. "Optional Catwalk" is replaced with "Optional Spine" on Copperhead Strike
            local _valueLabelSetName = nil
            -- dbgTrace("Check 1")

            -- dbgTrace(tableplus.tostring(NoTrackLimitsManager.Global.tConfig.tBankPivotRange.tAppendToElements))
            -- dbgTrace("Check 2")

            if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min ~= nil then
                _nRangeMin = NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min
            end
            if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max ~= nil then
                _nRangeMax = NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max
            end

            if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.step ~= nil then
                _nStep = NoTrackLimitsManager.Global.tConfig.tBankPivotRange.step
            end
            -- dbgTrace("Check 3")

            for _, value in pairs(NoTrackLimitsManager.Global.tConfig.tBankPivotRange.tAppendToElements) do
                -- dbgTrace(key)
                -- dbgTrace(value)
                dbgTrace("Adding BankPivotRange to element: " .. value)
                GameDatabase.NTLAppendElementParamaterToElement(value, "BankPivotRange", _nRangeMin, _nRangeMax,
                    _nInitial, _nStep, _labelOverride, _valueLabelSetName)
            end
        end

        if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBankPivotRange.step ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateBankPivotRange(NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min,
                NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max,
                NoTrackLimitsManager.Global.tConfig.tBankPivotRange.step)
        else
            if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min ~= nil then
                GameDatabase.NTLUpdateRidesMinBankPivotRange(NoTrackLimitsManager.Global.tConfig.tBankPivotRange.min)
                GameDatabase.NTLUpdateElementsMinBankPivotRange(NoTrackLimitsManager.Global.tConfig.tBankPivotRange
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max ~= nil then
                GameDatabase.NTLUpdateRidesMaxBankPivotRange(NoTrackLimitsManager.Global.tConfig.tBankPivotRange.max)
                GameDatabase.NTLUpdateElementsMaxBankPivotRange(NoTrackLimitsManager.Global.tConfig.tBankPivotRange
                    .max)
            end
        end
    end

    -- Curve Range
    if NoTrackLimitsManager.Global.tConfig.tCurveRange then
        dbgTrace("Setting Curve Range")

        -- Appending Banking Range to a chosen element
        if NoTrackLimitsManager.Global.tConfig.tCurveRange.tAppendToElements ~= nil then
            dbgTrace("Adding Banking Pivot Range to elements")
            -- bit of error correction
            local _nRangeMin = 0
            local _nRangeMax = 0
            local _nStep = 0
            local _nInitial = 0
            local _labelOverride = nil -- Only used to change the name of the visual on UI
            -- i.e. "Optional Catwalk" is replaced with "Optional Spine" on Copperhead Strike
            local _valueLabelSetName = nil
            -- dbgTrace("Check 1")

            -- dbgTrace(tableplus.tostring(NoTrackLimitsManager.Global.tConfig.tCurveRange.tAppendToElements))
            -- dbgTrace("Check 2")

            if NoTrackLimitsManager.Global.tConfig.tCurveRange.min ~= nil then
                _nRangeMin = NoTrackLimitsManager.Global.tConfig.tCurveRange.min
            end
            if NoTrackLimitsManager.Global.tConfig.tCurveRange.max ~= nil then
                _nRangeMax = NoTrackLimitsManager.Global.tConfig.tCurveRange.max
            end
            -- dbgTrace("Check 3")

            for _, value in pairs(NoTrackLimitsManager.Global.tConfig.tCurveRange.tAppendToElements) do
                -- dbgTrace(key)
                -- dbgTrace(value)
                dbgTrace("Adding CurveRangeDegrees to element: " .. value)
                GameDatabase.NTLAppendElementParamaterToElement(value, "CurveRangeDegrees", _nRangeMin, _nRangeMax,
                    _nInitial, _nStep, _labelOverride, _valueLabelSetName)
            end
        end

        if NoTrackLimitsManager.Global.tConfig.tCurveRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tCurveRange.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateCurveRangeDegrees(NoTrackLimitsManager.Global.tConfig.tCurveRange.min,
                NoTrackLimitsManager.Global.tConfig.tCurveRange.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tCurveRange.min ~= nil then
                GameDatabase.NTLUpdateRidesMinCurveRangeDegrees(NoTrackLimitsManager.Global.tConfig.tCurveRange.min)
                GameDatabase.NTLUpdateElementsMinCurveRangeDegrees(NoTrackLimitsManager.Global.tConfig.tCurveRange
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tCurveRange.max ~= nil then
                GameDatabase.NTLUpdateRidesMaxCurveRangeDegrees(NoTrackLimitsManager.Global.tConfig.tCurveRange.max)
                GameDatabase.NTLUpdateElementsMaxCurveRangeDegrees(NoTrackLimitsManager.Global.tConfig.tCurveRange
                    .max)
            end
        end
    end

    -- Scale Range
    if NoTrackLimitsManager.Global.tConfig.tScaleRange then
        dbgTrace("Setting Scale Range")
        if NoTrackLimitsManager.Global.tConfig.tScaleRange.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tScaleRange.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLUpdateScaleRange(NoTrackLimitsManager.Global.tConfig.tScaleRange.min,
                NoTrackLimitsManager.Global.tConfig.tScaleRange.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tScaleRange.min ~= nil then
                GameDatabase.NTLUpdateElementsMinScaleRange(NoTrackLimitsManager.Global.tConfig.tScaleRange
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tScaleRange.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxScaleRange(NoTrackLimitsManager.Global.tConfig.tCurveRange
                    .max)
            end
        end
    end

    -- If checking for elements with "VNTR" (F25) in the name, use "AltBoosterAcceleration"
    -- Booster Acceleration
    if NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration then
        dbgTrace("Setting Booster Acceleration")
        if NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.min,
                NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.max)
            GameDatabase.NTLSetAltBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.min,
                NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.min ~= nil then
                GameDatabase.NTLUpdateElementsMinBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster
                    .tAcceleration.min)
                GameDatabase.NTLUpdateElementsMinAltBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster
                    .tAcceleration.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBooster.tAcceleration.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster
                    .tAcceleration.max)
                GameDatabase.NTLUpdateElementsMaxAltBoosterAcceleration(NoTrackLimitsManager.Global.tConfig.tBooster
                    .tAcceleration.max)
            end
        end
    end

    -- Booster MaxSpeed
    if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed then
        dbgTrace("Setting Booster Speed")
        if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max)
            end
        end
    end

    -- Alt Booster MaxSpeed (F25)
    if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed then
        dbgTrace("Setting F25 Booster Speed")
        if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetAltBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinAltBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxAltBoosterMaxSpeed(NoTrackLimitsManager.Global.tConfig.tBooster.tSpeed
                    .max)
            end
        end
    end

    -- Hydraulic Acceleration
    if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration then
        dbgTrace("Setting Hydraulic Launch Acceleration")
        if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetHydraulicAcceleration(
                NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.min,
                NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.min ~= nil then
                GameDatabase.NTLUpdateElementsMinHydraulicAcceleration(NoTrackLimitsManager.Global.tConfig
                    .tHydraulicLaunch.tAcceleration.min)
                GameDatabase.NTLUpdateRidesMinHydraulicAcceleration(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tAcceleration.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tAcceleration.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxHydraulicAcceleration(NoTrackLimitsManager.Global.tConfig
                    .tHydraulicLaunch.tAcceleration.max)
                GameDatabase.NTLUpdateRidesMaxHydraulicAcceleration(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tAcceleration.max)
            end
        end
    end

    -- Hydraulic Speed
    if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed then
        dbgTrace("Setting Hydraulic Launch Speed")
        if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetHydraulicSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinHydraulicSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tSpeed.min)
                GameDatabase.NTLUpdateRidesMinHydraulicSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxHydraulicSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tSpeed.max)
                GameDatabase.NTLUpdateRidesMaxHydraulicSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tSpeed
                    .max)
            end
        end
    end

    -- Hydraulic ReturnSpeed
    if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed then
        dbgTrace("Setting Hydraulic Launch ReturnSpeed")
        if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetHydraulicReturnSpeed(
                NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinHydraulicReturnSpeed(NoTrackLimitsManager.Global.tConfig
                    .tHydraulicLaunch.tReturnSpeed.min)
                GameDatabase.NTLUpdateRidesMinHydraulicReturnSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tReturnSpeed.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tReturnSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxHydraulicReturnSpeed(NoTrackLimitsManager.Global.tConfig
                    .tHydraulicLaunch.tReturnSpeed.max)
                GameDatabase.NTLUpdateRidesMaxHydraulicReturnSpeed(NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch
                    .tReturnSpeed.max)
            end
        end
    end

    -- Launch Delay
    if NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tLaunchDelay then
        dbgTrace("Setting Hydraulic Launch Delay")
        local _fMin = NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tLaunchDelay.min
        local _fMax = NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tLaunchDelay.max
        local _fStep = NoTrackLimitsManager.Global.tConfig.tHydraulicLaunch.tLaunchDelay.step
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "HoldingSectionMinTime", _fMin, _fMax, _fStep)
    end
    -- Stop Location
    -- Semi Disabled due to broken animated tracks. thx DotNet
    -- Users will have to re enter it into the config file.
    if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation then
        dbgTrace("Setting Holding Section Stop Location")

        if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetHoldingStopLocation(NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.min,
                NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.min ~= nil then
                GameDatabase.NTLUpdateElementsMinHoldingStopLocation(NoTrackLimitsManager.Global.tConfig.tHoldingSection
                    .tStopLocation.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tStopLocation.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxHoldingStopLocation(NoTrackLimitsManager.Global.tConfig.tHoldingSection
                    .tStopLocation.max)
            end
        end
    end

    --- Holding Section
    -- Release Speed
    if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed then
        dbgTrace("Setting Holding Section Release")

        if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetHoldingReleaseSpeed(NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinHoldingReleaseSpeed(NoTrackLimitsManager.Global.tConfig.tHoldingSection
                    .tReleaseSpeed.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxHoldingReleaseSpeed(NoTrackLimitsManager.Global.tConfig.tHoldingSection
                    .tReleaseSpeed.max)
            end
        end
    end

    -- Min Time
    if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMinTime then
        dbgTrace("Setting Holding Section min time")
        local _fMin = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMinTime.min
        local _fMax = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMinTime.max
        local _fStep = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMinTime.step
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "HoldingSectionMinTime", _fMin, _fMax, _fStep)
    end

    -- Max Time
    if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMaxTime then
        dbgTrace("Setting Holding Section max time")
        local _fMin = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMaxTime.min
        local _fMax = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMaxTime.max
        local _fStep = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tMaxTime.step
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "HoldingSectionMaxTime", _fMin, _fMax, _fStep)
    end

    -- Release Acceleartion
    if NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseAcceleration then
        dbgTrace("Setting Holding Section max time")
        local _fMin = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseAcceleration.min
        local _fMax = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseAcceleration.max
        local _fStep = NoTrackLimitsManager.Global.tConfig.tHoldingSection.tReleaseAcceleration.step
        NoTrackLimitsManager._ExecuteQuery("TrackedRides", "Mod_NoTrackLimits_TrackedRides",
            "NTLSetElementsParameterValues", "HoldingSectionReleaseAcceleration", _fMin, _fMax, _fStep)
    end

    --

    -- -- Animated Track



    -- Brake Min Speed
    if NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed then
        dbgTrace("Setting Brake Min Speed")
        if NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetBrakeMinSpeed(NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinBrakeMinSpeed(NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxBrakeMinSpeed(NoTrackLimitsManager.Global.tConfig.tBrakes.tMinSpeed.max)
            end
        end
    end

    -- Brake Deceleration
    if NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration then
        dbgTrace("Setting Brake Deceleration")
        if NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetBrakeDeceleration(NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.min,
                NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.min ~= nil then
                GameDatabase.NTLUpdateElementsMinBrakeDeceleration(NoTrackLimitsManager.Global.tConfig.tBrakes
                    .tDeceleration.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tBrakes.tDeceleration.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxBrakeDeceleration(NoTrackLimitsManager.Global.tConfig.tBrakes
                    .tDeceleration.max)
            end
        end
    end

    -- Chain Lift Speed
    if NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed then
        dbgTrace("Setting Chain Lift Speed")
        if NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetChainLiftSpeed(NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.min ~= nil then
                GameDatabase.NTLUpdateElementsMinChainLiftSpeed(NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed
                    .min)
            end
            if NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxChainLiftSpeed(NoTrackLimitsManager.Global.tConfig.tChainLift.tSpeed
                    .max)
            end
        end
    end

    -- Chain lift swap
    if NoTrackLimitsManager.Global.tConfig.tChainLift.bSwapToDefaultWhenSlopedDown == false then
        dbgTrace("Disabling Chain Lift's Swap to Default when Sloped Down")
        GameDatabase.NTLSetChainLiftsSwapOnSlopeDown(0)
    end

    -- Boomerang
    if NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation then
        dbgTrace("Setting Boomerang Drop location")
        if NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.max ~= nil then
            dbgTrace("Using min, max")
            GameDatabase.NTLSetChainLiftDropLocation(
                NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.min,
                NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.min ~= nil then
                GameDatabase.NTLUpdateElementsMinChainLiftDropLocation(NoTrackLimitsManager.Global.tConfig.tChainLift
                    .tBoomerangDropLocation.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tChainLift.tBoomerangDropLocation.max ~= nil then
                GameDatabase.NTLUpdateElementsMaxChainLiftDropLocation(NoTrackLimitsManager.Global.tConfig.tChainLift
                    .tBoomerangDropLocation.max)
            end
        end
    end

    -- Car Count
    if NoTrackLimitsManager.Global.tConfig.tCarCount then
        dbgTrace("Setting Car Count")

        if NoTrackLimitsManager.Global.tConfig.tCarCount.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tCarCount.max ~= nil then
            GameDatabase.NTLSetCarsCount(NoTrackLimitsManager.Global.tConfig.tCarCount.min,
                NoTrackLimitsManager.Global.tConfig.tCarCount.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tCarCount.min ~= nil then
                GameDatabase.NTLSetMinCarsCount(NoTrackLimitsManager.Global.tConfig.tCarCount.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tCarCount.max ~= nil then
                GameDatabase.NTLSetMaxCarsCount(NoTrackLimitsManager.Global.tConfig.tCarCount.max)
            end
        end
    end

    if NoTrackLimitsManager.Global.tConfig.tTrainCount then
        dbgTrace("Setting Train Count")

        if NoTrackLimitsManager.Global.tConfig.tTrainCount.max ~= nil then
            GameDatabase.NTLSetMaxTrainCount(NoTrackLimitsManager.Global.tConfig.tTrainCount.max)
        end
    end
    -- Powered Cars Speed
    if NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed then
        dbgTrace("Setting Powered Car Speed")

        if NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.max ~= nil then
            GameDatabase.NTLSetPoweredCarSpeed(NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.min,
                NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.min ~= nil then
                GameDatabase.NTLSetPoweredMinSpeed(NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.max ~= nil then
                GameDatabase.NTLSetPoweredMaxSpeed(NoTrackLimitsManager.Global.tConfig.tPoweredCars.tSpeed.max)
            end
        end
    end

    -- Passes Through Station (how many laps)
    if NoTrackLimitsManager.Global.tConfig.tPassesThroughStation then
        dbgTrace("Setting Passes Through Station")

        if NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.min ~= nil and
            NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.max ~= nil then
            GameDatabase.NTLSetPassesThroughStation(NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.min,
                NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.max)
        else
            if NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.min ~= nil then
                GameDatabase.NTLSetMinPassesThroughStation(NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.min)
            end
            if NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.max ~= nil then
                GameDatabase.NTLSetMaxPassesThroughStation(NoTrackLimitsManager.Global.tConfig.tPassesThroughStation.max)
            end
        end
    end
end
