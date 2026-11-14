---@class WeatherState
---@field current WeatherType
---@field next? WeatherType
---@field transition number seconds
---@field changesAt? integer unix time of the next change
---@field frozen boolean

---@class ClockState
---@field minutes number
---@field at integer
---@field msPerMinute integer
---@field frozen boolean

local state <const> = {
    weather = 'cobalt_weather:weather',
    clock = 'cobalt_weather:clock',
    blackout = 'cobalt_weather:blackout',
}

---@param clock ClockState
---@param now integer
---@return number
function state.minutesAt(clock, now)
    if clock.frozen then return clock.minutes end

    return (clock.minutes + (now - clock.at) / clock.msPerMinute) % 1440
end

return state
