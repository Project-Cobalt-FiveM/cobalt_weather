local config <const> = require 'config'
local state <const> = require 'shared.state'

---@type table<string, true>
local allowed <const> = {}

for _, name in ipairs(config.types) do
    allowed[name] = true
end

for from, targets in pairs(config.transitions) do
    for to in pairs(targets) do
        if not allowed[from] or not allowed[to] then
            error(('transition %s -> %s uses a weather type missing from config.types'):format(from, to))
        end
    end
end

if not allowed[config.weather] then
    error(('config.weather %s is missing from config.types'):format(config.weather))
end

---@return table<WeatherType, number>
local function seasonWeights()
    local month <const> = os.date('*t').month

    for _, season in ipairs(config.seasons) do
        for _, seasonMonth in ipairs(season.months) do
            if seasonMonth == month then return season.weights end
        end
    end

    return {}
end

---@param from WeatherType
---@return WeatherType
local function pickNext(from)
    local targets <const> = config.transitions[from]

    if not targets then return config.weather end

    local weights <const> = seasonWeights()
    local pool <const> = {}
    local total = 0

    for to, weight in pairs(targets) do
        local scaled <const> = weight * (weights[to] or 1)

        if scaled > 0 then
            total += scaled
            pool[#pool + 1] = { name = to, weight = scaled }
        end
    end

    if total == 0 then return from end

    local roll = math.random() * total

    for _, entry in ipairs(pool) do
        roll -= entry.weight
        if roll <= 0 then return entry.name end
    end

    return pool[#pool].name
end

local cycle = 0

---@param current WeatherType
---@param transition number
---@param frozen boolean
local function publishWeather(current, transition, frozen)
    cycle += 1

    local id <const> = cycle
    local nextWeather, changesAt

    if not frozen then
        local delay <const> = math.random(config.cycleMinutes.min, config.cycleMinutes.max) * 60
        nextWeather = pickNext(current)
        changesAt = os.time() + delay

        SetTimeout(delay * 1000, function()
            if id ~= cycle then return end

            publishWeather(nextWeather, config.transitionSeconds, false)
        end)
    end

    GlobalState[state.weather] = {
        current = current,
        next = nextWeather,
        transition = transition,
        changesAt = changesAt,
        frozen = frozen,
    } --[[@as WeatherState]]
end

---@return WeatherState
local function weather()
    return GlobalState[state.weather]
end

---@param minutes number
---@param frozen boolean
local function publishClock(minutes, frozen)
    GlobalState[state.clock] = {
        minutes = minutes,
        at = GetGameTimer(),
        msPerMinute = config.msPerGameMinute,
        frozen = frozen,
    } --[[@as ClockState]]
end

---@return ClockState
local function clock()
    return GlobalState[state.clock]
end

---@return number
local function currentMinutes()
    return state.minutesAt(clock(), GetGameTimer())
end

---@param name string
---@param transitionSeconds? number
---@return boolean
local function setWeather(name, transitionSeconds)
    if type(name) ~= 'string' or not allowed[name:upper()] then return false end

    if transitionSeconds ~= nil and (type(transitionSeconds) ~= 'number' or transitionSeconds < 0) then
        return false
    end

    publishWeather(name:upper(), transitionSeconds or config.transitionSeconds, weather().frozen)
    return true
end

---@param hour integer
---@param minute integer
---@return boolean
local function setTime(hour, minute)
    if math.type(hour) ~= 'integer' or hour < 0 or hour > 23 then return false end
    if math.type(minute) ~= 'integer' or minute < 0 or minute > 59 then return false end

    publishClock(hour * 60 + minute, clock().frozen)
    return true
end

---@param frozen boolean
local function freezeTime(frozen)
    publishClock(currentMinutes(), frozen == true)
end

---@param frozen boolean
local function freezeWeather(frozen)
    local current <const> = weather()
    publishWeather(current.current, current.transition, frozen == true)
end

---@param enabled boolean
local function setBlackout(enabled)
    GlobalState[state.blackout] = enabled == true
end

---@return WeatherReport
local function getWeather()
    local current <const> = weather()

    return {
        current = current.current,
        next = current.next,
        transition = current.transition,
        changesAt = current.changesAt,
        frozen = current.frozen,
        blackout = GlobalState[state.blackout],
    }
end

---@return WeatherTime
local function getTime()
    local minutes <const> = currentMinutes()

    return {
        hour = math.floor(minutes / 60),
        minute = math.floor(minutes % 60),
        frozen = clock().frozen,
    }
end

local previousWeather <const> = GlobalState[state.weather] --[[@as WeatherState?]]

if previousWeather and allowed[previousWeather.current] then
    publishWeather(previousWeather.current, 0, previousWeather.frozen)
else
    publishWeather(config.weather, 0, config.freezeWeather)
end

if GlobalState[state.clock] then
    publishClock(currentMinutes(), clock().frozen)
else
    publishClock(config.hour * 60 + config.minute, config.freezeTime)
end

if GlobalState[state.blackout] == nil then
    setBlackout(config.blackout)
end

lib.callback.register('cobalt_weather:serverTime', function()
    return GetGameTimer()
end)

exports('SetWeather', setWeather)
exports('SetTime', setTime)
exports('FreezeTime', freezeTime)
exports('FreezeWeather', freezeWeather)
exports('SetBlackout', setBlackout)
exports('GetWeather', getWeather)
exports('GetTime', getTime)
exports('GetWeatherTypes', function() return config.types end)
