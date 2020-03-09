local http = require "socket.http"
local json = require "json"
local LCDproc = require "lcdproc"

-- obtain at http://openweathermap.org/find
local cityid = "<CITYID>"

-- obtain at https://home.openweathermap.org/api_keys
local appid = "<APPID>"

--- fetches and decodes json from openweathermap.org
function api_get(p)
    local url  = ("http://api.openweathermap.org/data/2.5/" ..
    p .. "?id=%i&units=metric&APPID=%s"):format(cityid, appid)
    local data = http.request(url)
    return json.decode(data)
end

--- formats screen lines
function format_lines(w)
  return {
    ("Weather: %s"):format(os.date("%H:%M", w.dt)),
    w.weather[1].description,
    ("%.2f C (%.2f C)"):format(w.main.temp, w.main.feels_like),
    ("%.2f m/s, %i%% RH"):format(w.wind.speed, w.main.humidity)
  }
end

--- gets table of strings
function get_strings(w, f)
  local t = { ["w1"] = format_lines(w) }
  local n = 1
  for _, v in ipairs(f.list) do
    n = n + 1
    if n > 3 then break end
    if v.dt > w.dt then
      t["w" .. n] = format_lines(v)
    end
  end
  return t
end

--- setup weather screens
function setup_screens(c, t, ids)
  for _, id in ipairs(ids) do
    if t[id] then
      local s = c:add_screen(id)
      s:add_title("title", t[id][1])
      s:add_string("one", 1, 2, t[id][2])
      s:add_string("two", 1, 3, t[id][3])
      s:add_string("three", 1, 4, t[id][4])
    end
  end
end

--- update weather screen
local function update_screen(s, t)
  if t[s.id] then
    s.widgets.title:set_text(t[s.id][1])
    s.widgets.one:set_text(t[s.id][2])
    s.widgets.two:set_text(t[s.id][3])
    s.widgets.three:set_text(t[s.id][4])
  end
end

-- get current weather
local weather = api_get("weather")
-- get 5 day weather forecast
local forecast = api_get("forecast")

local lcd = LCDproc("localhost", 13666)
lcd:set_name("Weather")
setup_screens(lcd, get_strings(weather, forecast), { "w1", "w2", "w3" })

-- store current active screen
local listen = nil
lcd:on_listen(function (s) listen = s end)
lcd:on_ignore(function () listen = nil end)

while true do
  -- poll LCDproc server once per second
  lcd:poll()
  -- update current weather data every five minutes
  LCDproc.every("5m", function () weather = api_get("weather") end)
  -- update weather forecast data every two hours
  LCDproc.every("2h", function () forecast = api_get("forecast") end)
  -- update currently active screen
  if listen then update_screen(listen, get_strings(weather, forecast)) end
end

-- close connection to LCDproc server
lcd:close()
