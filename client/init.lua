local state <const> = require 'shared.state'

---@type table<WeatherType, true>
local snowy <const> = { SNOW = true, BLIZZARD = true, SNOWLIGHT = true, XMAS = true }

local synced = true
local offset = 0

---@type WeatherType?
local applied

---@param name WeatherType
---@param transition number
local function applyWeather(name, transition)
    if applied and transition > 0 then
        SetWeatherTypeOvertimePersist(name, transition + 0.0)
    else
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeNowPersist(name)
    end

    applied = name

    local snow <const> = snowy[name] == true
    SetForceVehicleTrails(snow)
    SetForcePedFootstepsTracks(snow)
end

---@param clock ClockState
local function applyClockRate(clock)
    NetworkOverrideClockMillisecondsPerGameMinute(clock.msPerMinute)
    PauseClock(clock.frozen)
end

local function applyClock()
    local clock <const> = GlobalState[state.clock] --[[@as ClockState?]]

    if not synced or not clock then return end

    local minutes <const> = state.minutesAt(clock, GetGameTimer() + offset)
    NetworkOverrideClockTime(math.floor(minutes / 60), math.floor(minutes % 60), math.floor(minutes * 60 % 60))
end

local function applyAll()
    local weather <const> = GlobalState[state.weather] --[[@as WeatherState?]]
    local clock <const> = GlobalState[state.clock] --[[@as ClockState?]]

    applied = nil

    if weather then
        applyWeather(weather.current, 0)
    end

    if clock then
        applyClockRate(clock)
    end

    SetArtificialLightsState(GlobalState[state.blackout] == true)
    applyClock()
end

AddStateBagChangeHandler(state.weather, 'global', function(_, _, value)
    if not synced or not value or value.current == applied then return end

    applyWeather(value.current, value.transition)
end)

AddStateBagChangeHandler(state.clock, 'global', function(_, _, value)
    if not synced or not value then return end

    applyClockRate(value)
end)

AddStateBagChangeHandler(state.blackout, 'global', function(_, _, value)
    if not synced then return end

    SetArtificialLightsState(value == true)
end)

CreateThread(function()
    local sentAt <const> = GetGameTimer()
    local serverTime <const> = lib.callback.await('cobalt_weather:serverTime', false)
    offset = serverTime - (sentAt + GetGameTimer()) // 2

    SetArtificialLightsStateAffectsVehicles(false)

    if synced then applyAll() end

    SetInterval(applyClock, 1000)
end)

exports('SetSync', function(enabled)
    synced = enabled == true

    if synced then applyAll() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    ClearOverrideWeather()
    ClearWeatherTypePersist()
    NetworkClearClockTimeOverride()
    PauseClock(false)
    NetworkOverrideClockMillisecondsPerGameMinute(2000)
    SetArtificialLightsState(false)
    SetArtificialLightsStateAffectsVehicles(true)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
end)
