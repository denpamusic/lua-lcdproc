------------
-- A LCDproc screen widgets module.
-- @module lcdproc.widgets
-- @author denpamusic
-- @license MIT
-- @copyright denpamusic 2020

--- A widget abstract class.
-- @type Widget
local Widget = {
  screen = nil,   -- Screen instance
  id = nil,       -- widget id
  type = nil      -- widget type
}
Widget.__index = Widget

--- create new widget
-- @tparam Screen screen Screen instance
-- @tparam string id widget id
-- @tparam string type widget type
-- @return the new widget
function Widget:new(screen, id, type)
  setmetatable(self, { __index = Widget })
  local newinst = setmetatable({}, self)
  newinst.id = id
  newinst.screen = screen
  newinst.type = type
  return newinst
end

--- initialize widget on the server
-- @return string initialized widget
-- @treturn string error description
function Widget:init(vars)
  for k, v in pairs(vars) do self[k] = v end
  local ret, err = self:create()
  if not ret then return nil, err end
  ret, err = self:update()
  if not ret then return nil, err end
  return self, nil
end

--- create widget on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Widget:create()
  return self.screen.server:request(
    ("widget_add %s %s %s"):format(self.screen.id, self.id, self.type))
end

--- delete widget on the server
function Widget:delete()
  return self.screen.server:request(("widget_del %s"):format(self.id))
end

--- A string widget class.
-- @type String
local String = {
  x = 0,          -- horizontal position
  y = 0,          -- vertical position
  text = nil      -- text to display
}
String.__index = String

--- create string widget
-- @tparam Screen screen screen instance
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam string text text to display
-- @treturn String then new string widget
function String.new(screen, id, x, y, text)
  local self = Widget.new(String, screen, id, "string")
  return self:init{x = x, y = y, text = text}
end

--- update string on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function String:update()
  return self.screen.server:request(
    ("widget_set %s %s %i %i {%s}"):format(
      self.screen.id,
      self.id,
      self.x,
      self.y,
      self.text))
end

--- set string position
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @treturn string LCDproc server response
-- @treturn string error description
function String:set_position(x, y)
  self.x = x
  self.y = y
  return self:update()
end

--- set text to display
-- @tparam string text a text to display
-- @treturn string LCDproc server response
-- @treturn string error description
function String:set_text(text)
  self.text = text
  return self:update()
end

--- A title widget class.
-- @type Title
local Title = {
  screen = nil,  -- Screen instance
  id = nil,      -- widget id
  text = nil     -- text to display
}
Title.__index = Title

--- create title widget
-- @tparam Screen screen screen instance
-- @tparam string id widget id
-- @tparam string text text to display
-- @treturn Title the new title widget
function Title.new(screen, id, text)
  local self = Widget.new(Title, screen, id, "title")
  return self:init{ text = text }
end

--- update title on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Title:update()
  return self.screen.server:request(
    string.format("widget_set %s %s {%s}",
      self.screen.id,
      self.id,
      self.text))
end

--- set text to display
-- @tparam string text a text to display
-- @treturn string LCDproc server response
-- @treturn string error description
function Title:set_text(text)
  self.text = text
  return self:update()
end

--- Parent class of HBar and VBar.
-- This SHOULD NOT be used directly.
-- @type Bar
local Bar = {
  x = 0,         -- horizontal position
  y = 0,         -- vertical position
  length = 0,    -- progress bar length
  type = nil     -- progress bar type
}
Bar.__index = Bar

--- create progress bar
-- @tparam Screen screen Screen instance
-- @tparam string id progress bar id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam int length progress bar length
-- @tparam string type progress bar type (hbar, vbar)
-- @return the new bar
function Bar:new(screen, id, x, y, length, type)
  local newinst = Widget.new(Bar, screen, id, type)
  return newinst:init{ x = x, y = y, length = length }
end

--- update progress bar on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Bar:update()
  return self.screen.server:request(
   ("widget_set %s %s %i %i %i"):format(
      self.screen.id,
      self.id,
      self.x,
      self.y,
      self.length))
end

--- set progress bar position
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @treturn string LCDproc server response
-- @treturn string error description
function Bar:set_position(x, y)
  self.x = x
  self.y = y
  return self:update()
end

--- set progress bar length
-- @tparam int length progress bar length
-- @treturn string LCDproc server response
-- @treturn string error description
function Bar:set_length(length)
  self.length = length
  return self:update()
end

--- Horizontal progress bar widget class.
-- Inherits Bar class. See class Bar for other methods.
-- @type HBar
local HBar = {}
HBar.__index = HBar

--- create horizontal progress bar widget
-- @tparam Screen screen instance
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam int length progress bar length
-- @treturn HBar a new horizontal progress bar widget
function HBar.new(screen, id, x, y, length)
  return Bar.new(HBar, screen, id, x, y, length, "hbar")
end

--- Vertical progress bar widget class.
-- Inherits Bar class. See class Bar for other methods.
-- @type VBar
local VBar = {}
VBar.__index = VBar

--- create vertical progress bar widget
-- @tparam Screen screen instance
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam int length progress bar length
-- @treturn string LCDproc server response
-- @treturn string error description
function VBar.new(screen, id, x, y, length)
  return Bar.new(VBar, screen, id, x, y, length, "vbar")
end

--- Icon widget class.
-- @type Icon
local Icon = {
  x = 0,         -- horizontal position
  y = 0,         -- vertical position
  icon = nil,    -- icon name
}

--- list of available icons
-- @table icons
Icon.icons = {
  ["BLOCK_FILLED"]      = 1,
  ["HEART_OPEN"]        = 2,
  ["HEART_FILLED"]      = 3,
  ["ARROW_UP"]          = 4,
  ["ARROW_DOWN"]        = 5,
  ["ARROW_LEFT"]        = 6,
  ["ARROW_RIGHT"]       = 7,
  ["CHECKBOX_OFF"]      = 8,
  ["CHECKBOX_ON"]       = 9,
  ["CHECKBOX_GRAY"]     = 10,
  ["SELECTOR_AT_LEFT"]  = 11,
  ["SELECTOR_AT_RIGHT"] = 12,
  ["ELLIPSIS"]          = 13,
  ["STOP"]              = 14,
  ["PAUSE"]             = 15,
  ["PLAY"]              = 16,
  ["PLAYR"]             = 17,
  ["FF"]                = 18,
  ["FR"]                = 19,
  ["NEXT"]              = 20,
  ["PREV"]              = 21,
  ["REC"]               = 22
}
Icon.__index = Icon

--- create new icon widget
-- @tparam Screen screen instance
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @tparam string icon icon name from list of available icons
-- @see icons
-- @treturn Icon the new icon widget
function Icon.new(screen, id, x, y, icon)
  if not self.icons[icon] then
    error(("invalid icon [%s]"):format(self.icons[icon]), 2)
  end

  local self = Widget.new(Icon, screen, id, "icon")
  return self:init{ x = x, y = y, icon = icon }
end

--- update icon on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Icon:update()
  return self.screen.server:request(
    ("widget_set %s %s %i %i %s"):format(
      self.screen.id,
      self.id,
      self.x,
      self.y,
      self.icon))
end

--- set icon position
-- @tparam int x horizontal position
-- @tparam int y vertical position
-- @treturn string LCDproc server response
-- @treturn string error description
function Icon:set_position(x, y)
  self.x = x
  self.y = y
  return self:update()
end

--- set icon name
-- @tparam string icon icon name from list of available icons
-- @see icons
function Icon:set_icon(icon)
  self.icon = icon
  return self:update()
end

--- A scroller widget class.
-- @type Scroller
local Scroller = {
  left = 0,         -- left side position
  top = 0,          -- top side position
  right = 0,        -- right side position
  bottom = 0,       -- bottom side position
  direction = nil,  -- scroll direction (h, v, m)
  speed = 0,        -- scroll speed
  text = nil        -- text to scroll
}
Scroller.__index = Scroller

--- create scroller widget
-- @tparam Screen screen screen instance
-- @tparam string id widget id
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @tparam string direction scroll direction (h, v, m)
-- @tparam int speed scroll speed
-- @tparam string text text to scroll
-- @treturn Scroller the new scroller widget
function Scroller.new(
  screen, id, left, top, right, bottom, direction, speed, text)
  local self = Widget.new(Scroller, screen, id, "scroller")
  return self:init{
    left = left,
    top = top,
    right = right,
    bottom = bottom,
    direction = direction,
    speed = speed,
    text = text
  }
end

--- update scroller
-- @treturn string LCDproc server response
-- @treturn string error description
function Scroller:update()
  return self.screen.server:request(
    ("widget_set %s %s %i %i %i %i %s %i {%s}"):format(
      self.screen.id,
      self.id,
      self.left,
      self.top,
      self.right,
      self.bottom,
      self.direction,
      self.speed,
      self.text))
end

--- set scroller position
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @treturn string LCDproc server response
-- @treturn string error description
function Scroller:set_position(left, top, right, bottom)
  self.left = left
  self.top = top
  self.right = right
  self.bottom = bottom
  return self:update()
end

--- set scroll direction
-- @tparam string direction scroll direction (h, v, m)
-- @treturn string LCDproc server response
-- @treturn string error description
function Scroller:set_direction(direction)
  self.direction = direction
  return self:update()
end

--- set scroll speed
-- @tparam int speed scroll speed
-- @treturn string LCDproc server response
-- @treturn string error description
function Scroller:set_speed(speed)
  self.speed = speed
  return self:update()
end

--- set text to scroll
-- @tparam string text a text to scroll
-- @treturn string LCDproc server response
-- @treturn string error description
function Scroller:set_text(text)
  self.text = text
  return self:update()
end

--- Frame widget class.
-- @type Frame
local Frame = {
  left = 0,         -- left side position
  top = 0,          -- top side position
  right = 0,        -- right side position
  bottom = 0,       -- bottom side position
  width = 0,        -- frame width
  height = 0,       -- frame height
  direction = nil,  -- scroll direction (h, v)
  speed = 0         -- scroll speed
}
Frame.__index = Frame

--- create frame widget
-- @tparam Screen screen instance
-- @tparam string id widget id
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @tparam int width frame width
-- @tparam int height frame heigth
-- @tparam string direction scroll direction (h | v)
-- @tparam int speed scroll speed
-- @treturn Frame then new frame widget
function Frame.new(
  screen, id, left, top, right, bottom, width, height, direction, speed)
  local self = Widget.new(Frame, screen, id, "frame")
  return self:init{
    left = left,
    top = top,
    right = right,
    bottom = bottom,
    width = width,
    height = height,
    direction = direction,
    speed = speed,
  }
end

--- update frame on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Frame:update()
  return self.screen.server:request(
    ("widget_set %s %s %i %i %i %i %s %i %s"):format(
      self.screen.id,
      self.id,
      self.left,
      self.top,
      self.right,
      self.bottom,
      self.width,
      self.height,
      self.direction,
      self.speed))
end

--- set frame position
-- @tparam int left left side position
-- @tparam int top top side position
-- @tparam int right right side position
-- @tparam int bottom bottom side position
-- @treturn string LCDproc server response
-- @treturn string error description
function Frame:set_position(left, top, right, bottom)
  self.left = left
  self.top = top
  self.right = right
  self.bottom = bottom
  return self:update()
end

--- set frame size
-- @tparam int width frame width
-- @tparam int height frame height
-- @treturn string LCDproc server response
-- @treturn string error description
function Frame:set_size(width, height)
  self.width = width
  self.height = height
  return self:update()
end

--- set scroll direction
-- @tparam string direction scroll direction (h | v)
-- @treturn string LCDproc server response
-- @treturn string error description
function Frame:set_direction(direction)
  self.direction = direction
  return self:update()
end

--- set scroll speed
-- @tparam int speed scroll speed
-- @treturn string LCDproc server response
-- @treturn string error description
function Frame:set_speed(speed)
  self.speed = speed
  return self:update()
end

--- Big number widget class.
-- @type Number
local Number = {
  screen = nil,  -- Screen instance
  id = nil,      -- widget id
  x = 0,         -- horizontal position
  number = 0     -- displayed number (0-9, 10 is semicolon)
}
Number.__index = Number

--- create big number widget
-- @tparam Screen screen screen instance
-- @tparam string id widget id
-- @tparam int x horizontal position
-- @tparam int number displayed number (0-9, 10 is semicolon)
-- @treturn Number the new number widget
function Number.new(screen, id, x, number)
  local self = Widget.new(Number, screen, id, "num")
  return self:init{ x = x, number = number }
end

--- update big number on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Number:update()
  return self.screen.server:request(
    ("widget_set %s %s %i %i"):format(
      self.screen.id,
      self.id,
      self.x,
      self.number))
end

--- set big number position
-- @tparam int x horizontal position
-- @treturn string LCDproc server response
-- @treturn string error description
function Number:set_position(x)
  self.x = x
  return self:update()
end

--- set displayed number
-- @tparam int number displayed number (0-9, 10 is semicolon)
-- @treturn string LCDproc server response
-- @treturn string error description
function Number:set_number(number)
  self.number = number
  return self:update()
end

--- widgets table
-- @table widgets
local widgets = {
  string   = String,    -- string widget
  title    = Title,     -- title widget
  hbar     = HBar,      -- horizontal progress bar widget
  vbar     = VBar,      -- vertical progress bar widget
  icon     = Icon,      -- icon widget
  scroller = Scroller,  -- scroller widget
  frame    = Frame,     -- frame widget
  number   = Number     -- big number widget
}

return widgets