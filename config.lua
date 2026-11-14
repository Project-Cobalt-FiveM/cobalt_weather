---@class WeatherSeason
---@field months integer[]
---@field weights table<WeatherType, number>

---@class WeatherConfig
---@field weather WeatherType
---@field hour integer
---@field minute integer
---@field msPerGameMinute integer
---@field freezeTime boolean
---@field freezeWeather boolean
---@field blackout boolean
---@field transitionSeconds number
---@field cycleMinutes { min: integer, max: integer }
---@field types WeatherType[]
---@field transitions table<WeatherType, table<WeatherType, number>>
---@field seasons WeatherSeason[]

---@type WeatherConfig
return {
    -- Start-up state (a resource restart keeps the current weather and clock instead)
    weather = 'EXTRASUNNY', -- weather on first start; one of types below
    hour = 8, -- in-game hour on first start, 0 to 23
    minute = 0, -- in-game minute on first start, 0 to 59

    -- Clock and cycle
    msPerGameMinute = 2000, -- real milliseconds per in-game minute; 2000 makes a full day last 48 real minutes
    freezeTime = false, -- true stops the clock at hour:minute
    freezeWeather = false, -- true keeps weather fixed and turns off the random cycle
    blackout = false, -- true turns off city lights on start
    transitionSeconds = 45, -- real seconds one weather type takes to blend into the next
    cycleMinutes = { min = 20, max = 40 }, -- real minutes between random weather changes, picked between min and max

    -- Weather types that may be set; a type with no transitions entry returns to weather on its next change
    types = {
        'EXTRASUNNY',
        'CLEAR',
        'NEUTRAL',
        'SMOG',
        'FOGGY',
        'OVERCAST',
        'CLOUDS',
        'CLEARING',
        'RAIN',
        'THUNDER',
        'SNOW',
        'BLIZZARD',
        'SNOWLIGHT',
        'XMAS',
        'HALLOWEEN',
    },

    -- Weather chain: for each current type, the types it can change to and their relative weights
    transitions = {
        EXTRASUNNY = { EXTRASUNNY = 4, CLEAR = 4, CLOUDS = 2, SMOG = 1 },
        CLEAR = { EXTRASUNNY = 3, CLEAR = 3, CLOUDS = 3, SMOG = 1, FOGGY = 1 },
        CLOUDS = { CLEAR = 3, CLOUDS = 2, OVERCAST = 3, FOGGY = 1 },
        SMOG = { CLEAR = 3, CLOUDS = 2, FOGGY = 1 },
        FOGGY = { CLEAR = 2, CLOUDS = 3, OVERCAST = 1 },
        OVERCAST = { CLOUDS = 3, CLEARING = 2, RAIN = 3, SNOWLIGHT = 1 },
        RAIN = { CLEARING = 4, RAIN = 1, THUNDER = 2 },
        THUNDER = { CLEARING = 3, RAIN = 2 },
        CLEARING = { CLEAR = 3, CLOUDS = 3, FOGGY = 1 },
        SNOWLIGHT = { OVERCAST = 2, SNOWLIGHT = 2, SNOW = 1, CLEARING = 2 },
        SNOW = { SNOWLIGHT = 3, BLIZZARD = 1, OVERCAST = 1 },
        BLIZZARD = { SNOW = 3, SNOWLIGHT = 1 },
    },

    -- Seasons by real-world server month: multiply the transition weights above; 0 rules a type out
    seasons = {
        { months = { 12, 1, 2 }, weights = { RAIN = 1.5, SNOWLIGHT = 2, SNOW = 2, EXTRASUNNY = 0.5 } },
        { months = { 3, 4, 5 }, weights = { RAIN = 1.5, FOGGY = 1.5, SNOWLIGHT = 0, SNOW = 0 } },
        { months = { 6, 7, 8 }, weights = { EXTRASUNNY = 2, SMOG = 1.5, RAIN = 0.5, THUNDER = 1.5, SNOWLIGHT = 0, SNOW = 0 } },
        { months = { 9, 10, 11 }, weights = { OVERCAST = 1.5, FOGGY = 1.5, RAIN = 1.5, SNOWLIGHT = 0, SNOW = 0 } },
    },
}
