------------
-- A LCDproc client module.
-- @module lcdproc
-- @author denpamusic
-- @license MIT
-- @copyright denpamusic 2020

local socket = require "socket"
local Screen = require "lcdproc.screen"

--- trim string
-- @tparam string s a string to trim
-- @treturn string trimmed string
local function trim(s)
  return s:match "^%s*(.-)%s*$"
end

--- A LCDproc client class.
-- @type LCDproc
local LCDproc = {
  sock = nil,     -- LuaSocket instance
  name = nil,     -- client name
  menu = nil,     -- client main menu
  screens = {},   -- client screens table
  keys = {},      -- client keys table
  debug = false   -- debug mode
}

--- LCDproc server info
LCDproc.server = {
  version = nil,  -- LCDproc version
  protocol = nil  -- protocol version
}

--- LCDproc display info
-- @table display
LCDproc.display = {
  width = 0,       -- display width
  height = 0,      -- display height
  cell_width = 0,  -- display cell width
  cell_height = 0  -- display cell height
}

--- event patterns table
-- @table events
-- @local
LCDproc.events = {
  listen = "listen ([%a%d%p]+)",                    -- screen listen pattern
  ignore = "ignore ([%a%d%p]+)",                    -- screen ignore pattern
  keypress = "key ([%a%d%p]+)",                     -- key event pattern
  menu = "menuevent (%a+) ([%a%d%p]+) ([%a%d%p]+)"  -- menu event pattern
}

--- event handlers table
-- @table handlers
LCDproc.handlers = {
  listen   = {},   -- screen listen event handlers
  ignore   = {},   -- screen ignore event handlers
  keypress = {},   -- key press event handlers
  menu     = {}    -- menu event handers
}
LCDproc.__index = LCDproc

setmetatable(LCDproc, { __call = function (cls, ...) return cls.new(...) end })

--- create client instance
-- @tparam[opt] string host LCDproc server host (localhost)
-- @tparam[opt] int port LCDproc server port (13666)
-- @tparam[opt] table opts additional options ({ timeout = 3, debug = false })
-- @treturn LCDproc the new LCDproc client
function LCDproc.new(host, port, opts)
  local self = setmetatable({}, LCDproc)
  opts = opts or {}
  self.debug = opts.debug or false
  self.screens = {}
  self.keys = {}
  self.handlers = { listen = {}, ignore = {}, keypress = {}, menu = {} }
  self.sock = assert(socket.tcp())
  self.sock:settimeout(opts.timeout or 3)
  local ret, err = self.sock:connect((host or "localhost"), (port or 13666))
  if ret then
    self:hello()
    return self
  end
  return nil, err
end

--- Helper function to run the callback every interval
-- @tparam string interval inteval string (i. e. "5m")
-- Supports "h" for hours, "m" for minutes and "s" for seconds
-- @tparam func fn callback function
function LCDproc.every(interval, fn)
  if not fn then return end
  local val, unit = interval:match "(%d+)%s?([h|m|s]?)"
  if val == nil then error(("invalid interval [%s]"):format(interval), 2) end
  local t = os.date("*t")
  if (unit == "h" and t.hour % val == 0 and t.min == 0 and t.sec == 0) or
     (unit == "m" and t.min % val == 0 and t.sec == 0) or
     ((unit == "s" or unit == nil) and t.sec % val == 0) then
        return fn()
  end
end

--- make request to LCDproc server
-- @tparam string line
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:request(line)
  if self.debug then print(">>> " .. line) end
  self.sock:send(trim(line) .. "\n")

  local line, err
  repeat
    line, err = self.sock:receive("*l")
    if self.debug then print("<<< " .. line) end
    if not line then
      return nil, err
    elseif line:match "^listen" or line:match "^ignore" then
      self:do_events(line)
    else
      err = line:match "huh%? (.*)"
      if err then
        return nil, err
      end
    end
  until line:match "^success" or line:match "^connect"

  return trim(line)
end

--- initiate the LCDproc session
-- @warning shouldn't be called directly, as it's handled by constructor
-- @see new
function LCDproc:hello()
  local line = self:request("hello")
  if line then
    self.server = {
      version = line:match "LCDproc ([0-9%.]+)",
      protocol = line:match "protocol ([0-9%.]+)"
    }
    self.display = {
      width = line:match " wid ([0-9]+)",
      height = line:match " hgt ([0-9]+)",
      cell_width = line:match " cellwid ([0-9]+)",
      cell_height = line:match " cellhgt ([0-9]+)"
    }
  end
end

--- set client name
-- @tparam string name
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:set_name(name)
  self.name = name
  return self:request(string.format("client_set name {%s}", self.name))
end

--- add new screen
-- @tparam string id screen id
-- @treturn Screen the new screen
function LCDproc:add_screen(id)
  self.screens[id] = Screen.new(self, id)
  return self.screens[id]
end

--- remove screen
-- @tparam string id screen id
function LCDproc:del_screen(id)
  if self.screens[id] and self:request("screen_del " .. id) then
    self.screens[id] = nil
  end
end

--- add new key
-- @tparam string id key id
-- @tparam string mode (exclusively, shared)
function LCDproc:add_key(id, mode)
  mode = mode or "shared"
  if not self.keys[id] then
    if self:request(string.format("client_add_key -%s %s", id, mode)) then
      self.keys[id] = id
    end
  end
end

--- remove key
-- @tparam string id key id
function LCDproc:del_key(id)
  if self.keys[id] then
    if self:request("client_del_key " .. id) then
      self.keys[id] = nil
    end
  end
end

--- add main menu to the client
-- @treturn Menu the main menu
function LCDproc:add_menu()
  if not self.menu then
    self.menu = (require "lcdproc/menu").new(self)
  end
  return self.menu
end

--- set display backlight state
-- @tparam string state backlight state (on | off | toggle | blink | flash)
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:backlight(state)
  return self:request("backlight " .. state)
end

--- set display gpio state
-- @tparam string state (on | off | number)
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:output(state)
  return self:request("output " .. state)
end

--- get display driver info
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:info()
  return self:request("info")
end

--- do nothing
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:noop()
  return self:request("noop")
end

--- sleep for a given amount of seconds
-- @tparam int seconds number of seconds to sleep
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:sleep(seconds)
  return self:request("sleep " .. seconds)
end

--- poll connection
-- @treturn string LCDproc server response
-- @treturn string error description
function LCDproc:poll()
  local canread = socket.select({ self.sock }, nil, 1)
  for _, _ in ipairs(canread) do
    local line, err = self.sock:receive("*l")

    if line then
      if self.debug then print("<<< [poll] " .. line) end
      self:do_events(line)
    end

    return line, err
  end
end

--- handle server events
-- @tparam string line response line
-- @treturn string event type
function LCDproc:do_events(line)
  for k, v in pairs(self.events) do
    local m = { line:match(v) }
    if #m > 0 then
      for _, fn in ipairs(self.handlers[k]) do
        if k == "listen" or k == "ignore" and self.screens[m[1]] then
          fn(self.screens[m[1]])
        else
          fn(unpack(m))
        end
      end
      return k
    end
  end
end

--- register screen listen event handler
-- @tparam func fn handler function
function LCDproc:on_listen(fn)
  table.insert(self.handlers.listen, fn)
end

--- register screen ignore event handler
-- @tparam func fn handler function
function LCDproc:on_ignore(fn)
  table.insert(self.handlers.ignore, fn)
end

--- register key press event handler
-- @tparam func fn handler function
function LCDproc:on_keypress(fn)
  table.insert(self.handlers.keypress, fn)
end

--- register menu event handler
-- @tparam func fn handler function
function LCDproc:on_menu(fn)
  table.insert(self.handlers.menu, fn)
end

--- close connection
function LCDproc:close()
  self:request("bye")
  self.sock:close()
end

return LCDproc
