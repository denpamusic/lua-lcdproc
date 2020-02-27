# lua-lcdproc - LCDproc client for Lua
## About
lua-lcdproc is a client for [LCDproc](https://github.com/lcdproc/lcdproc) server
written in Lua language using LuaSocket.

## Installation
This project is available on [luarocks](https://luarocks.org/modules/denpamusic/lua-lcdproc).
```
$ luarocks install lua-lcdproc
```

## Usage
```lua
local LCDproc = require "lcdproc"

-- firstly create client instance
local lcd = LCDproc.new("localhost", 13666)

-- then create some screens...
local screen = lcd:add_screen("my_screen")

-- ...and add some widgets to it
screen:add_title("one", "Title Text")
screen:add_string("two", 1, 2, "First Line Text")
screen:add_string("three", 1, 3, "Second Line Text")
screen:add_string("four", 1, 4, "Third Line Text")

lcd:on_listen(function (screen)
  -- text will be updated once screen is visible
  screen.widgets.two:set_text("First Line Now Has New Text")
  screen.widgets.three:set_text("Second Line Also Does")
end)

lcd:on_ignore(function (screen)
  -- do something on screen hide
end)

while true do
  local line = lcd:poll()
end

lcd:close()
```

## Documentation
Full documentation is available at [here](https://lua-lcdproc.denpa.pro).
