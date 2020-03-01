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
    p .. "?id=%i&appid=%s"):format(cityid, appid)
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
  local t = { ["weather_1"] = format_lines(w) }
  local n = 1
  for _, v in ipairs(f.list) do
    n = n + 1
    if n > 3 then break end
    if v.dt > w.dt then
      t["weather_" .. n] = format_lines(v)
    end
  end
  return t
end

--- centers string by padding it with spaces on both sides
function center_str(s, l)
  l = (l or 20) - #s
  s = string.rep(' ', math.floor(l/2)) .. s
  return s .. string.rep(' ', math.ceil(l/2))
end

--- setup weather screens
function setup_screens(c, t, ids)
  for _, v in ipairs(ids) do
    local s = c:add_screen(v)
    s:add_title("title", center_str(t[v][1], c.lcd.width))
    s:add_string("one", 1, 2, center_str(t[v][2], c.lcd.width))
    s:add_string("two", 1, 3, center_str(t[v][3], c.lcd.width))
    s:add_string("three", 1, 4, center_str(t[v][4], c.lcd.width))
  end
end

local weather = api_get("weather")
local forecast = api_get("forecast")
local strings = get_strings(weather, forecast)

local lcd = LCDproc.new("localhost", 13666)
lcd:set_name("weather")
setup_screens(lcd, strings, { "weather_1", "weather_2", "weather_3" })

-- update strings when screen is shown
lcd:on_listen(function (s, c)
  strings = get_strings(weather, forecast)
  s.widgets.title:set_text(center_str(strings[s.id][1], c.lcd.width))
  s.widgets.one:set_text(center_str(strings[s.id][2], c.lcd.width))
  s.widgets.two:set_text(center_str(strings[s.id][3], c.lcd.width))
  s.widgets.three:set_text(center_str(strings[s.id][4], c.lcd.width))
end)

while true do
  local dt = os.date("*t")
  if dt.min % 5 == 0 and dt.sec == 0 then
    -- update current weather data every 5 minutes
    weather = api_get("weather")
  elseif dt.min == 0 and dt.sec == 0 then
    -- update forecast weather data every hour
    forecast = api_get("forecast")
  end

  lcd:poll()
end

lcd:close()
