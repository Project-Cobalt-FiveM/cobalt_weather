---@meta

---@alias WeatherType 'EXTRASUNNY'|'CLEAR'|'NEUTRAL'|'SMOG'|'FOGGY'|'OVERCAST'|'CLOUDS'|'CLEARING'|'RAIN'|'THUNDER'|'SNOW'|'BLIZZARD'|'SNOWLIGHT'|'XMAS'|'HALLOWEEN'

---@class WeatherReport : WeatherState
---@field blackout boolean

---@class WeatherTime
---@field hour integer 0 to 23
---@field minute integer 0 to 59
---@field frozen boolean

---@class CobaltWeatherExports
local CobaltWeatherExports = {}

---**Client.** Stops applying the synced weather and clock locally, or resumes it.
---@param enabled boolean
function CobaltWeatherExports:SetSync(enabled) end

---**Server.** Changes the weather; false when the type is unknown.
---@param name WeatherType|string case-insensitive
---@param transitionSeconds? number
---@return boolean
function CobaltWeatherExports:SetWeather(name, transitionSeconds) end

---**Server.** Sets the game clock; false when out of range.
---@param hour integer 0 to 23
---@param minute integer 0 to 59
---@return boolean
function CobaltWeatherExports:SetTime(hour, minute) end

---**Server.** Freezes or unfreezes the clock.
---@param frozen boolean
function CobaltWeatherExports:FreezeTime(frozen) end

---**Server.** Freezes or unfreezes the weather cycle.
---@param frozen boolean
function CobaltWeatherExports:FreezeWeather(frozen) end

---**Server.** Turns the blackout on or off.
---@param enabled boolean
function CobaltWeatherExports:SetBlackout(enabled) end

---**Server.** Returns the current weather state.
---@return WeatherReport
function CobaltWeatherExports:GetWeather() end

---**Server.** Returns the current game time.
---@return WeatherTime
function CobaltWeatherExports:GetTime() end

---**Server.** Returns the configured weather types.
---@return WeatherType[]
function CobaltWeatherExports:GetWeatherTypes() end

exports.cobalt_weather = CobaltWeatherExports
