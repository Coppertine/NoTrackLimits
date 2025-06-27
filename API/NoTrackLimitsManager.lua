---@meta NoTrackLimitsManager


---@class (partial) GameDatabase
local GameDatabase = {}

---Returns the global config table of NoTrackLimits.
---@see NoTrackLimitsManager.Global
---@return table tGlobal Global table.
GameDatabase.NTLGetGlobalConfig = function() end

do -- Get Rides --
    ---Gets all tracked ride IDs found in the `RideData` table.
    ---@return table tTrackedRides List of tracked ride IDs.
    GameDatabase.NTLGetAllTrackedRides = function() end

    ---Gets a list of all non-transport and non-kart ride IDs.
    ---@see GameDatabase.NTLGetAllTrackedRides
    ---@return table tNonTransportRides List of non-transport and non-kart ride IDs.
    GameDatabase.NTLGetAllNonTransportRides = function() end

    ---Gets a list of non-transport, non-kart and non-water slide tracked ride IDs.
    ---@return table tNonSlideRides List of ride IDs
    GameDatabase.NTLGetAllNonSlideRides = function() end

    ---Gets a list of all non-kart train names found in the `Trains` table.
    ---@return table tTrains List of all non-kart train IDs.
    GameDatabase.NTLGetAllTrains = function() end

    ---Gets all interchangable train names for a tracked ride.
    ---@param _sRide string Ride ID
    GameDatabase.NTLGetAllRideTrains_ExtraOfRide = function(_sRide) end
end

do -- Append Elements --
    ---Appends a track element ID to all tracked rides
    ---@see GameDatabase.NTLUpdateElementToRide
    ---@param _sElementName string Track Element ID
    GameDatabase.NTLUpdateElementToRides = function(_sElementName) end

    ---Appends a track element ID to a tracked ride. If it already exists, it is skipped.
    ---@param _sRide any
    ---@param _sElementName any
    GameDatabase.NTLUpdateElementToRide = function(_sRide, _sElementName) end
end

do -- Track Length --
    ---Sets all track element and ride's `LengthRangeMeters` value
    ---@param _fMin number Minimum Length in Meters
    ---@param _fMax number Maximum Length in Meters
    ---@param _fStep number Step value in Meters
    GameDatabase.NTLUpdateTrackLength = function(_fMin, _fMax, _fStep) end

    ---Sets all track element's `LengthRangeMetres` minimum length.
    ---@param _fMin number Minimum Length in Meters
    GameDatabase.NTLUpdateMinTrackLength = function(_fMin) end
    ---Sets all track element's `LengthRangeMeters` maximum length.
    ---@param _fMax number Maximum Length in Meters
    GameDatabase.NTLUpdateMaxTrackLength = function(_fMax) end
    ---Sets all track element's `LengthRangeMeters` step value.
    ---@param _fStep number Step value in Meters
    GameDatabase.NTLUpdateStepTrackLength = function(_fStep) end
    do -- Rides --
        ---Sets the tracked ride's Minimum Track Length.
        ---@param _sRide string Tracked Ride ID
        ---@param _fMin number Minimum length in meters.
        GameDatabase.NTLUpdateRideMinTrackLength = function(_sRide, _fMin) end
        ---Sets the tracked ride's Maximum Track Length.
        ---@param _sRide string Tracked Ride ID
        ---@param _fMax number Maximum length in meters.
        GameDatabase.NTLUpdateRideMaxTrackLength = function(_sRide, _fMax) end
        ---Sets the tracked ride's Track Length step value.
        ---@param _sRide string Tracked Ride ID
        ---@param _fMax number Step value in meters.
        GameDatabase.NTLUpdateRideStepTrackLength = function(_sRide, _fMax) end
    end
    do -- Elements --
        ---Sets the track element's Minimum Track Length.
        ---@param _sElement string Track Element ID
        ---@param _fMin number Minimum length in meters.
        GameDatabase.NTLUpdateElementMinTrackLength = function(_sElement, _fMin) end
        ---Sets the track element's Maximum Track Length.
        ---@param _sElement string Track Element ID
        ---@param _fMax number Maximum length in meters.
        GameDatabase.NTLUpdateElementMaxTrackLength = function(_sElement, _fMax) end

        ---Sets the track element's length step value.
        ---@param _sElement string Track Element ID
        ---@param _fStep number Step value in meters.
        GameDatabase.NTLUpdateElementStepTrackLength = function(_sElement, _fStep) end
    end
end

---Sets all tracked ride's maximum track height from sea level.
---@param _iHeight number Max height in feet.
GameDatabase.NTLSetMaxTrackHeight = function(_iHeight) end

do     -- Slope Range --
    do -- Rides --
        ---Sets all tracked rides' `SlopeRangeDegrees` values.
        ---This controls how steep a ride can be set.
        ---@param _fMin number Minimum value in degrees, `-50000` is uncapped
        ---@param _fMax number Maximum value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateRidesSlopeRangeDegrees = function(_fMin, _fMax) end

        ---Sets all tracked ride's Minimum `SlopeRangeDegrees` value.
        ---@param _fMin number Minimum slope value in degrees, `-50000` is uncapped
        GameDatabase.NTLUpdateRidesMinSlopeRangeDegrees = function(_fMin) end

        ---Sets all tracked ride's Maximum `SlopeRangeDegrees` value.
        ---@param _fMax number Maximum slope value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateRidesMaxSlopeRangeDegrees = function(_fMax) end

        ---Sets a tracked ride's Minimum `SlopeRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMin number Minimum slope value in degrees, `-50000` is uncapped
        GameDatabase.NTLUpdateRideMinSlopeRangeDegrees = function(_sRide, _fMin) end

        ---Sets a tracked ride's Maximum `SlopeRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMax number Maximum slope value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateRideMaxSlopeRangeDegrees = function(_sRide, _fMax) end
    end
    do -- Elements --
        ---Sets all track elements' `SlopeRangeDegrees` values.
        ---This controls how steep a track element can be set.
        ---@param _fMin number Minimum slope value in degrees, `-50000` is uncapped
        ---@param _fMax number Maximum slope value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateElementsSlopeRangeDegrees = function(_fMin, _fMax) end

        ---Sets all track element's Minimum `SlopeRangeDegrees` value.
        ---@param _fMin number Minimum slope value in degrees, `-50000` is uncapped
        GameDatabase.NTLUpdateElementsMinSlopeRangeDegrees = function(_fMin) end

        ---Sets all track element's Maximum `SlopeRangeDegrees` value.
        ---@param _fMax number Maximum slope value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateElementsMaxSlopeRangeDegrees = function(_fMax) end

        ---Sets the track element's Minimum `SlopeRangeDegrees` value.
        ---@param _sElement string Track element ID
        ---@param _fMin number Minimum slope value in degrees, `-50000` is uncapped
        GameDatabase.NTLUpdateElementMinSlopeRangeDegrees = function(_sElement, _fMin) end

        ---Sets the track element's Maximum `SlopeRangeDegrees` value.
        ---@param _sElement string Track element ID
        ---@param _fMax number Maximum slope value in degrees, `50000` is uncapped
        GameDatabase.NTLUpdateElementMaxSlopeRangeDegrees = function(_sElement, _fMax) end
    end
end

do -- Slope Delta --
    ---Updates all tracked ride's Maximum slope delta. <br/> This changes how steep a singular track piece can go.
    ---@param _fMax number Maximum delta in degrees.
    GameDatabase.NTLUpdateRidesMaxSlopeDeltaDegrees = function(_fMax) end

    ---Updates a tracked ride's Maximum slope delta. <br/> This changes how steep a singular track piece can go.
    ---@param _sRide string Ride ID
    ---@param _fMax number Maximum delta in degrees.
    GameDatabase.NTLUpdateRideMaxSlopeDeltaDegrees = function(_sRide, _fMax) end
end

do -- Banking Range --
    ---Sets all track rides and element's `BankingRangeDegrees` value.
    ---@param _fMin number Minimum bank in degrees.
    ---@param _fMax number Maximum bank in degrees.
    GameDatabase.NTLUpdateBankingRangeDegrees = function(_fMin, _fMax) end

    do -- Elements --
        ---Sets all elements' Minimum `BankingRangeDegrees` value.
        ---@param _fMin number Minimum bank in degrees.
        GameDatabase.NTLUpdateElementsMinBankingRangeDegrees = function(_fMin) end
        ---Sets all elements' Maximum `BankingRangeDegrees` value.
        ---@param _fMax number Maximum bank in degrees.
        GameDatabase.NTLUpdateElementsMaxBankingRangeDegrees = function(_fMax) end

        ---Sets a track element's Minimum `BankingRangeDegrees` value.
        ---@param _sElement string Track element ID
        ---@param _fMin number Minimum bank in degrees.
        GameDatabase.NTLUpdateElementMinBankingRangeDegrees = function(_sElement, _fMin) end
        ---Sets a track element's Maximum `BankingRangeDegrees` value.
        ---@param _sElement string Track element ID
        ---@param _fMax number Maximum bank in degrees.
        GameDatabase.NTLUpdateElementMaxBankingRangeDegrees = function(_sElement, _fMax) end
    end

    do -- Rides --
        ---Sets all tracked rides' Minimum `BankingRangeDegrees` value.
        ---@param _fMin number Minimum bank in degrees.
        GameDatabase.NTLUpdateRidesMinBankingRangeDegrees = function(_fMin) end
        ---Sets all tracked rides' Maximum `BankingRangeDegrees` value.
        ---@param _fMax number Maximum bank in degrees.
        GameDatabase.NTLUpdateRidesMaxBankingRangeDegrees = function(_fMax) end

        ---Sets a tracked ride's Minimum `BankingRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMin number Minimum bank in degrees.
        GameDatabase.NTLUpdateRideMinBankingRangeDegrees = function(_sRide, _fMin) end
        ---Sets a tracked ride's Maximum `BankingRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMax number Maximum bank in degrees.
        GameDatabase.NTLUpdateRideMaxBankingRangeDegrees = function(_sRide, _fMax) end
    end
end

do -- Banking Offset Range --
    ---Sets all track rides and track element's Banking Offset range.<br/>
    ---This changes how far the track rotates around. Also known as a Heartline value.
    ---@param _fMin number Minimum offset in meters.
    ---@param _fMax number Maximum offset in meters.
    GameDatabase.NTLUpdateBankPivotRange = function(_fMin, _fMax) end

    do -- Elements --
        ---Sets all track element's Minimum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _fMin number Minimum offset in meters.
        GameDatabase.NTLUpdateElementsMinBankPivotRange = function(_fMin) end
        ---Sets all track element's Maximum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _fMax number Maximum offset in meters.
        GameDatabase.NTLUpdateElementsMaxBankPivotRange = function(_fMax) end
        ---Sets a track element's Minimum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _sElement string Track element ID
        ---@param _fMin number Minimum offset in meters.
        GameDatabase.NTLUpdateElementMinBankPivotRange = function(_sElement, _fMin) end
        ---Sets a track element's Maximum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _sElement string Track Element ID
        ---@param _fMax number Maximum offset in meters.
        GameDatabase.NTLUpdateElementMaxBankPivotRange = function(_sElement, _fMax) end
    end

    do -- Rides --
        ---Sets all tracked ride's Minimum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _fMin number Minimum offset in meters.
        GameDatabase.NTLUpdateRidesMinBankPivotRange = function(_fMin) end
        ---Sets all tracked ride's Maximum Banking Offset value.
        ---@see GameDatabase.NTLUpdateBankPivotRange
        ---@param _fMax number Maximum offset in meters.
        GameDatabase.NTLUpdateRidesMaxBankPivotRange = function(_fMax) end
        ---Sets a tracked ride's Minimum Banking Offset value.
        ---@param _sRide string Ride ID
        ---@param _fMin number Minimum offset in meters.
        GameDatabase.NTLUpdateRidesMinBankPivotRange = function(_sRide, _fMin) end
        ---Sets a tracked ride's Maximum Banking Offset value.
        ---@param _sRide string Ride ID
        ---@param _fMax number Maximum offset in meters.
        GameDatabase.NTLUpdateRideMaxBankPivotRange = function(_sRide, _fMax) end
    end
end

do -- Curve Range --
    ---Sets all tracked rides and track elements' `CurveRangeDegrees` values.
    ---@param _fMin number Minimum value in degrees.
    ---@param _fMax number Maximum value in degrees.
    GameDatabase.NTLUpdateCurveRangeDegrees = function(_fMin, _fMax) end

    do -- Elements --
        ---Sets all track elements' Minimum `CurveRangeDegrees` value.
        ---@param _fMin number Minimum value in degrees.
        GameDatabase.NTLUpdateElementsMinCurveRangeDegrees = function(_fMin) end
        ---Sets all track elements' Maximum `CurveRangeDegrees` value.
        ---@param _fMax number Maximum value in degrees.
        GameDatabase.NTLUpdateElementsMaxCurveRangeDegrees = function(_fMax) end
        ---Sets a track element's Minimum `CurveRangeDegrees` value.
        ---@param _sElement string Track Element ID
        ---@param _fMin number Minimum value in degrees.
        GameDatabase.NTLUpdateElementMinCurveRangeDegrees = function(_sElement, _fMin) end
        ---Sets a track element's Maximum `CurveRangeDegrees` value.
        ---@param _sElement string Track Element ID
        ---@param _fMax number Maximum value in degrees.
        GameDatabase.NTLUpdateElementMaxCurveRangeDegrees = function(_sElement, _fMax) end
    end
    do -- Rides --
        ---Sets all tracked rides' Minimum `CurveRangeDegrees` value.
        ---@param _fMin number Minimum value in degrees.
        GameDatabase.NTLUpdateRideMinCurveRangeDegrees = function(_fMin) end
        ---Sets all tracked rides' Maximum `CurveRangeDegrees` value.
        ---@param _fMax number Maximum value in degrees.
        GameDatabase.NTLUpdateRideMaxCurveRangeDegrees = function(_fMax) end
        ---Sets a tracked ride's Minimum `CurveRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMin number Minimum value in degrees.
        GameDatabase.NTLUpdateRideMinCurveRangeDegrees = function(_sRide, _fMin) end
        ---Sets a tracked ride's Maximum `CurveRangeDegrees` value.
        ---@param _sRide string Ride ID
        ---@param _fMax number Maximum value in degrees.
        GameDatabase.NTLUpdateRideMaxCurveRangeDegrees = function(_sRide, _fMax) end
    end
end

do -- Scale Range --
    ---comment
    ---@param _fMin any
    ---@param _fMax any
    GameDatabase.NTLUpdateScaleRange = function(_fMin, _fMax)end
    ---comment
    ---@param _fMin any
    GameDatabase.NTLUpdateElementsMinScaleRange = function(_fMin) end
    ---comment
    ---@param _fMax any
    GameDatabase.NTLUpdateElementsMaxScaleRange = function(_fMax) end
    ---comment
    ---@param _sElement any
    ---@param _fMin any
    GameDatabase.NTLUpdateElementMinScaleRange = function(_sElement, _fMin) end
    ---comment
    ---@param _sElement any
    ---@param _fMax any
    GameDatabase.NTLUpdateElementMaxScaleRange = function(_sElement, _fMax) end
end

do         -- Booster --
    do     -- Acceleration --
        do -- Regular --
            --- Sets all track elements' booster acceleration speed value.
            ---@param _fMin number Minimum acceleration in meters per second.
            ---@param _fMax number Maximum acceleration in meters per second.
            GameDatabase.NTLSetBoosterAcceleration = function(_fMin, _fMax) end
            
            --- Sets all track element's minimum booster acceleration speed. 
            ---@param _fMin number Minimum acceleration in meters per second.    
            GameDatabase.NTLUpdateElementsMinBoosterAcceleration= function(_fMin) end
            --- Sets all track element's maximum booster acceleration speed.
            ---@param _fMax any
            GameDatabase.NTLUpdateElementsMaxBoosterAcceleration= function(_fMax) end

            ---comment
            ---@param _sElement any
            ---@param _fMin any
            GameDatabase.NTLUpdateElementMinBoosterAcceleration = function(_sElement, _fMin) end
            ---comment
            ---@param _sElement any
            ---@param _fMax any
            GameDatabase.NTLUpdateElementMaxBoosterAcceleration = function(_sElement, _fMax) end
        end

        do -- Alternate (F25) --
            ---comment
            ---@param _fMin any
            ---@param _fMax any
            GameDatabase.NTLSetAltBoosterAcceleration = function(_fMin, _fMax) end

            ---
            ---@param _fMin any
           GameDatabase.NTLUpdateElementsMinAltBoosterAcceleration = function (_fMin) end
           ---comment
           ---@param _fMax any
           GameDatabase.NTLUpdateElementsMaxAltBoosterAcceleration = function(_fMax)end
            ---comment
            ---@param _sElement any
            ---@param _fMin any
           GameDatabase.NTLUpdateElementMinAltBoosterAcceleration = function(_sElement, _fMin)end
           ---comment
           ---@param _sElement any
           ---@param _fMax any
           GameDatabase.NTLUpdateElementMaxAltBoosterAcceleration = function (_sElement, _fMax)end            
           end            
        end
    end
    do     -- Max Speed --
        do -- Regular --
        end
        do -- Alternate (F25) --
        end
    end
end

do -- Hydraulic --
end

do -- Holding Section --
end

do -- Brakes --
end

do     -- Chain Lift --
    do -- Boomerang Drop Location
    end
end

do -- Element Allowed on Water --
end

do -- Chain Lift Swap on Slope Down --
end

GameDatabase.NTLUpdateAllTrainsToRide_Extras = function(_sRide) end

do -- Car Count

end

do -- Powered Cars
end

do -- Passes Through Station --
end
