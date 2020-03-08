local LCDproc = require "lcdproc"

local lcd = LCDproc.new("localhost", 13666)
lcd:set_name("Simple Clock")

-- create clock screen
local screen = lcd:add_screen("clock_screen")
screen:add_title("one", "Simple Clock")
screen:add_string("time", 1, 2, os.date("%H:%M:%S"))

local active = false

-- toggle active variable if screen is currenly being shown or ignored
lcd:on_listen(function () active = true end)
lcd:on_ignore(function () active = false end)

while true do
  -- poll LCDproc server once per second
  lcd:poll()

  if active then
    -- update time only when screen is active
    screen.widgets.time:set_text(os.date("%H:%M:%S"))
  end
end

-- close connection to LCDproc server
lcd:close()
