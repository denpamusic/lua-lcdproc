------------
-- A LCDproc screen module.
-- @module lcdproc.screen
-- @author denpamusic
-- @license MIT
-- @copyright denpamusic 2020

local W = require "lcdproc.widgets"

--- LCDproc Screen class.
-- @type Screen
local Screen = {
  server = nil,     -- LCDproc server
  id = nil,         -- screen id
  name = nil,       -- screen name
  width = 0,        -- width
  height = 0,       -- height
  priority = nil,   -- priority (hidden, background, info, foreground, alert, input)
  heartbeat = nil,  -- heartbeat state (on, off, open)
  backlight = nil,  -- backlight state (on, off, toggle, open, blink, flash)
  duration = 0,     -- display duration in rotation
  timeout = 0,      -- display timeout
  cursor = nil,     -- visibility of cursor (on, off, under, block)
  cursor_x = 0,     -- horizontal position of cursor
  cursor_y = 0,     -- vertical position of cursor
  widgets = {}      -- table of screen widgets
}
Screen.__index = Screen

--- create LCDproc screen
-- @tparam LCDproc server LCDproc server instance
-- @tparam string id screen id
-- @treturn Screen the new screen
-- @treturn string error description
function Screen.new(server, id)
  local self = setmetatable({}, Screen)
  self.server = server
  self.id = id
  self.widgets = Screen.widgets
  local ret, err = self.server:request("screen_add " .. self.id)
  if not ret then self = nil end
  return self, err
end

--- set screen name
-- @tparam string name screen name to set
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_name(name)
  self.name = name
  return self.server:request(("screen_set %s -name {%s}"):format(self.id, self.name))
end

--- set screen size
-- @tparam int width screen width
-- @tparam int height screen height
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_size(width, height)
  self.width = width
  self.height = height
  return self.server:request(("screen_set %s -wid %i -hgt %i"):format(
    self.id,
    self.width,
    self.height))
end

--- set screen priority
-- @tparam string priority screen priority
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_priority(priority)
  self.priority = priority
  return self.server:request(("screen_set %s -priority %s"):format(
    self.id,
    self.priority))
end

--- set screen heartbeat state
-- @tparam string heartbeat screen heartbeat state
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_heartbeat(heartbeat)
  self.heartbeat = heartbeat
  return self.server:request(("screen_set %s -heartbeat %s"):format(
    self.id,
    self.heartbeat))
end

--- set screen backlight state
-- @tparam string backlight screen backlight state
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_backlight(backlight)
  self.backlight = backlight
  return self.server:request(("screen_set %s -backlight %s"):format(
    self.id,
    self.backlight))
end

--- set display duration
-- @tparam int duration display screen for this amount of seconds in rotation
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_duration(duration)
  self.duration = duration
  return self.server:request(("screen_set %s -duration %i"):format(
    self.id,
    self.duration))
end

--- set display timeout
-- @tparam int timeout display screen for this amount of seconds
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_timeout(timeout)
  self.timeout = timeout
  return self.server:request(("screen_set %s -timeout %i"):format(
    self.id,
    self.timeout))
end

--- set cursor state
-- @tparam string cursor new cursor state
-- @tparam int x cursor horizontal position
-- @tparam int y cursor vertical position
-- @treturn string response from LCDproc server
-- @treturn string error description
function Screen:set_cursor(cursor, x, y)
  if self.server:request(
    ("screen_set %s -cursor %s -cursor_x %i -cursor_y %i"):format(
      self.id,
      self.cursor,
      self.cursor_x,
      self.cursor_y)) then
    self.cursor = cursor
    self.cursor_x = x
    self.cursor_y = y
  end
end

--- add string widget to the screen
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam string text widget text
-- @treturn widgets.String the new string widget
function Screen:add_string(id, x, y, text)
  self.widgets[id] = W.string.new(self, id, x, y, text)
  return self.widgets[id]
end

--- add title widget to the screen
-- @tparam string id widget id
-- @tparam string text widget text
-- @treturn widgets.Title the new title widget
function Screen:add_title(id, text)
  self.widgets[id] = W.title.new(self, id, text)
  return self.widgets[id]
end

--- add horizontal progress bar to the screen
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam int length progress bar length
-- @treturn widgets.HBar the new horizontal progress bar widget
function Screen:add_hbar(id, x, y, length)
  self.widgets[id] = W.hbar.new(self, id, x, y, length)
  return self.widgets[id]
end

--- add vertical progress bar to the screen
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam int length progress bar length
-- @treturn widgets.VBar the new vertical progress bar widget
function Screen:add_vbar(id, x, y, length)
  self.widgets[id] = W.vbar.new(self, id, x, y, length)
  return self.widgets[id]
end

--- add icon to the screen
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam string icon icon name
-- @treturn widgets.Icon the new icon widget
function Screen:add_icon(id, x, y, icon)
  self.widgets[id] = W.icon.new(self, id, x, y, icon)
  return self.widgets[id]
end

--- add scroller to the screen
-- @tparam string id widget id
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @tparam string direction scroll direction (h, v, m)
-- @tparam int speed scroll speed
-- @tparam string text scroller text
-- @treturn widgets.Scroller the new scroller widget
function Screen:add_scroller(
  id, left, top, right, bottom, direction, speed, text)
  self.widgets[id] = W.scroller.new(
    self, id, left, top, right, bottom, direction, speed, text)

  return self.widgets[id]
end

--- add frame widget to the screen
-- @tparam string id widget id
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @tparam int width frame width
-- @tparam int height frame height
-- @tparam string direction scroll direction (h, v)
-- @tparam int speed scroll speed
-- @treturn widgets.Frame the new frame widget
function Screen:add_frame(
  id, left, top, right, bottom, width, height, direction, speed)
  self.widgets[id] = W.frame.new(
    self, id, left, top, right, bottom, width, height, direction, speed)

  return self.widgets[id]
end

--- add number widget to the screen
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int number (0-9, 10 is semicolon)
-- @treturn widgets.Number the new number widget
function Screen:add_number(id, x, number)
  self.widgets[id] = W.number.new(self, id, x, number)
  return self.widgets[id]
end

--- remove widget from the screen
-- @param id widget id
function Screen:del_widget(id)
  if self.widgets[id] and self.widgets[id]:delete() then
    self.widgets[id] = nil
  end
end

return Screen
