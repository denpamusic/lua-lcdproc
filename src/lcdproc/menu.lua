------------
-- A LCDproc menu module.
-- @module lcdproc.menu
-- @author denpamusic
-- @license MIT
-- @copyright denpamusic 2020

--- convert bool to string
-- @tparam boolean b boolean to convert
-- @treturn string conversion result
local function btos(b)
  if b then return "true" else return "false" end
end

--- search table for value
-- @param s value to search for
-- @tparam table t table in which search will be performed
-- @treturn bool if value is present in table
local function in_table(s, t)
  for _, v in ipairs(t) do
    if (s == v) then return true end
  end
  return false
end

--- Menu item parent class.
-- SHOULD NOT be used directly.
-- @type Item
local Item = {
  menu = nil,      -- Menu instance
  id = nil,        -- item id
  text = nil,      -- item text
  hidden = false,  -- is item hidden
  prev = nil,      -- item to show after pressing ESCAPE key
  next = nil       -- item to show after pressing ENTER key
}
Item.__index = Item

--- create new item
-- @tparam Menu menu menu that contains item
-- @tparam string id item id
-- @tparam string text item text
-- @tparam bool hidden is item hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @return the new item
function Item:new(menu, id, text, hidden, prev, next)
  setmetatable(self, { __index = Item })
  local newinst = setmetatable({}, self)
  newinst.menu = menu
  newinst.id = id or ""
  newinst.text = text
  newinst.hidden = hidden or false
  newinst.prev = prev
  newinst.next = next
  return newinst
end

--- set item text
-- @tparam string text item text
-- @treturn string LCDproc server response
-- @treturn string error description
function Item:set_text(text)
  self.text = text
  return self:update()
end

--- set item as hidden
-- @tparam bool hidden is item hidden
-- @treturn string LCDproc server response
-- @treturn string error description
function Item:set_hidden(hidden)
  self.hidden = hidden
  return self:update()
end

--- set previous item
-- @param prev item to show after pressing ESCAPE key
-- (Item, or special string: _close_, _quit_ or _none_)
-- @treturn string LCDproc server response
-- @treturn string error description
function Item:set_prev(prev)
  self.prev = prev
  return self:update()
end

--- set next item
-- @param next item to show after pressing ENTER key
--(Item, or special string: _close_, _quit_ or _none_)
-- @treturn string LCDproc server response
-- @treturn string error description
function Item:set_next(next)
  self.next = next
  return self:update()
end

--- add optional arguments to request line
-- @treturn string request line with added optional args
function Item:with_args(pattern, ...)
  local line = string.format(pattern, unpack(arg))
  if self.text then line = line .. " -text {" .. self.text .. "}" end
  if self.hidden then line = line .. " -is_hidden true " end
  if self.prev then line = line .. " -prev " .. (self.prev.id or self.prev) end
  if self.next then line = line .. " -next " .. (self.next.id or self.next) end
  return line
end

--- Action class.
-- @type Action
local Action = {
  result = nil  -- what to do when this item is selected
}
Action.__index = Item

--- add action to the menu
-- @tparam Menu menu Menu instance
-- @tparam string id action id
-- @tparam string text action text
-- @tparam string result result of action (none, close, quit)
-- @tparam bool hidden if action is hidden
-- @tparam Item prev previous item
-- @treturn Action the new action
function Action.new(menu, id, text, result, hidden, prev)
  local self = Item.new(Action, menu, id, text, hidden, prev)
  self.result = result or "none"
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s action -menu_result %s',
      self.menu.id,
      self.id,
      self.result
    )
  ) then return self end
end

--- update action on the server
-- @treturn string LCDproc server response
-- @treturn error description
function Action:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s menu_result %s',
      self.menu.id,
      self.id,
      self.result
    )
  )
end

--- set action result
-- @tparam string result result of action (none, close, quit)
-- @treturn string LCDproc server response
-- @treturn error description
function Action:set_result(result)
  self.result = result
  return self:update()
end

--- Checkbox class.
-- @type Checkbox
local Checkbox = {
  value = nil,        -- current checkbox value (off, on, gray)
  allow_gray = false  -- whether to allow checkbox to be grayed out
}
Checkbox.__index = Checkbox

--- create checkbox
-- @tparam Menu menu Menu instance
-- @tparam string id checkbox id
-- @tparam string text checkbox text
-- @tparam string value checkbox value (off, on, gray)
-- @tparam bool allow_gray whether to allow checkbox to be grayed out
-- @tparam bool hidden is checkbox hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @treturn Checkbox the new checkbox
function Checkbox.new(menu, id, text, value, allow_gray, hidden, prev)
  local self = Item.new(Checkbox, menu, id, text, hidden, prev)
  self.value = value
  self.allow_gray = allow_gray or false

  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s checkbox -value %s -allow_gray %s',
      self.menu.id,
      self.id,
      self.value,
      btos(self.allow_gray)
    )
  ) then return self end
end

--- update checkbox on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Checkbox:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s -value %s -allow_gray %s',
      self.menu.id,
      self.id,
      self.value,
      btos(self.allow_gray)
    )
  )
end

--- set checkbox value
-- @tparam int value checkbox value (off, on, gray)
-- @treturn string LCDproc server response
-- @treturn string error description
function Checkbox:set_value(value)
  self.value = value
  return self:update()
end

--- allow checkbox to be grayed out
-- @tparam bool allow_gray whether to allow checkbox to be grayed out
-- @treturn string LCDproc server response
-- @treturn string error description
function Checkbox:allow_gray(allow_gray)
  self.allow_gray = allow_gray
  return self:update()
end

--- Ring class.
-- @type Ring
local Ring = {
  value = nil,   -- currently selected index
  strings = {},  -- table of strings
}
Ring.__index = Ring

--- create ring
-- @tparam Menu menu Menu instance
-- @tparam string id ring id
-- @tparam string text ring text
-- @tparam string value index of currently selected string
-- @tparam table strings table of strings
-- @tparam bool hidden is ring hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @treturn Ring the new ring
function Ring.new(menu, id, text, value, strings, hidden, prev)
  local self = Item.new(Ring, menu, id, text, hidden, prev)
  self.value = value or 0
  self.strings = strings or {}
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s ring -value %s -strings {%s}',
      self.menu.id,
      self.id,
      self.value,
      table.concat(self.strings, "\t")
    )
  ) then return self end
end

--- update ring on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Ring:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s -value %s -strings %s',
      self.menu.id,
      self.id,
      self.value,
      table.concat(self.strings, "\t")
    )
  )
end

--- set ring value
-- @tparam int value index of current selection
-- @treturn string LCDproc server response
-- @treturn string error description
function Ring:set_value(value)
  self.value = value
  return self:update()
end

--- set ring strings
-- @tparam table strings table of strings
-- @treturn string LCDproc server response
-- @treturn string error description
function Ring:set_strings(strings)
  self.strings = strings
  return self:update()
end

--- Slider class.
-- @type Slider
local Slider = {
  value = nil,
  range = {},
  step = 1
}
Slider.__index = Slider

--- create slider
-- @tparam Menu menu Menu instance
-- @tparam string id slider id
-- @tparam string text slider text
-- @tparam int value slider value
-- @tparam table range slider range, i. e. {0, 100}
-- @tparam table labels slider labels, i. e. {"empty", "full"}
-- @tparam int step slider step
-- @tparam bool hidden if slider is hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Slider the new slider
function Slider.new(
    menu, id, text, value, range, labels, step, hidden, prev, next)
  local self = Item.new(Slider, menu, id, text, hidden, prev, next)
  self.value = value or 0
  self.range = range or { 0, 100 }
  self.labels = labels or { "", "" }
  self.step = step or 1
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s slider -value %i ' ..
      '-mintext {%s} -maxtext {%s} -minvalue %i -maxvalue %i',
      self.menu.id,
      self.id,
      self.value,
      self.labels[1],
      self.labels[2],
      self.range[1],
      self.range[2]
    )
  ) then return self end
end

--- update slider on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Slider:update()
  return self.menu.server:request(
    with_args(
      'menu_set_item "%s" %s -value %i' ..
      '-mintext "%s" -maxtext "%s" -minvalue %i -maxvalue %i',
      self.menu.id,
      self.id,
      self.value,
      self.labels[1],
      self.labels[2],
      self.range[1],
      self.range[2]
    )
  )
end

--- set slider value
-- @tparam int value slider value
-- @treturn string LCDproc server response
-- @treturn string error description
function Slider:set_value(value)
  self.value = value
  return self:update()
end

--- set slider range
-- @tparam table range set slider range
-- @treturn string LCDproc server response
-- @treturn string error description
function Slider:set_range(range)
  self.range = range
  return self:update()
end

--- Numeric class.
-- @type Numeric
local Numeric = {
  value = 0,  -- current value
  range = {}  -- numeric range table
}
Numeric.__index = Numeric

--- create numeric
-- @tparam Menu menu Menu instance
-- @tparam string id numeric id
-- @tparam string text numeric text
-- @tparam int value numeric value
-- @tparam table range numeric range, i. e. {0, 100}
-- @tparam bool hidden is numeric field hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Numeric the new numeric
function Numeric.new(menu, id, text, value, range, hidden, prev, next)
  local self = Item.new(Numeric, menu, id, text, hidden, prev, next)
  self.value = value or 0
  self.range = range or { 0, 100 }
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s numeric -value %i -minvalue %i -maxvalue %i',
      self.menu.id,
      self.id,
      self.value,
      self.range[1],
      self.range[2]
    )
  ) then return self end
end

--- update numeric on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Numeric:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s -value %i -minvalue %i -maxvalue %i',
      self.menu.id,
      self.id,
      self.value,
      self.range[1],
      self.range[2]
    )
  )
end

--- set numeric value
-- @tparam int value numeric value
-- @treturn string LCDproc server response
-- @treturn string error description
function Numeric:set_value(value)
  self.value = value
  return self:update()
end

--- set numeric range
-- @tparam table range numeric range, i. e. {0, 100}
-- @treturn string LCDproc server response
-- @treturn string error description
function Numeric:set_range(range)
  self.range = range
  return self:update()
end

--- Alpha class.
-- @type Alpha
local Alpha = {
  value = nil,
  mask = nil,
  range = {},
  allowed = {}
}
Alpha.__index = Alpha

--- create alpha
-- @tparam Menu menu Menu instance
-- @tparam string id alpha id
-- @tparam string text alpha text
-- @tparam string value alpha value
-- @tparam string mask character to mask input with
-- @tparam table range input length range, i. e. {0, 10} - min: 0 chars, max: 10
-- @tparam table allowed allowed characters { ":upper:", ":lower:", ":digit:" }
-- @tparam string extra additional allowed characters
-- @tparam bool hidden is alpha hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Alpha the new alpha
function Alpha.new(
    menu, id, text, value, mask, range, allowed, extra, hidden, prev, next)
  local self = Item.new(Alpha, menu, id, text, hidden, prev, next)
  self.value = value or ""
  self.mask = mask or ""
  self.range = range or { 0, 10 }
  self.allowed = allowed or { ":upper:" }
  self.extra = extra or ""
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s alpha -value {%s} -password_char "%s" -minlength %i ' ..
      '-maxlength %i -allow_caps %s -allow_noncaps %s -allow_numbers %s ' ..
      '-allowed_extra "%s"',
      self.menu.id,
      self.id,
      self.value,
      self.mask,
      self.range[1],
      self.range[2],
      btos(in_table(":upper:", self.allowed)),
      btos(in_table(":lower:", self.allowed)),
      btos(in_table(":digit:", self.allowed)),
      self.extra
    )
  ) then return self end
end

--- update alpha
-- @treturn string LCDproc server response
-- @treturn string error description
function Alpha:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s -value {%s} -password_char "%s" -minlength %i ' ..
      '-maxlength %i -allow_caps %s -allow_noncaps %s -allow_numbers %s ' ..
      '-allowed_extra "%s"',
      self.menu.id,
      self.id,
      self.value,
      self.mask,
      self.range[1],
      self.range[2],
      btos(in_table(":upper:", self.allowed)),
      btos(in_table(":lower:", self.allowed)),
      btos(in_table(":digit:", self.allowed)),
      self.extra
    )
  )
end

--- set alpha value
-- @tparam string value alpha value
-- @treturn string LCDproc server response
-- @treturn string error description
function Alpha:set_value(value)
  self.value = value
  return self.update()
end

--- set alpha length range
-- @tparam table range table range, i. e. {0, 10}
-- @treturn string LCDproc server response
-- @treturn string error description
function Alpha:set_range(range)
  self.range = range
  return self.update()
end

--- set allowed characters
-- @tparam table allowed characters, i. e. {":lower:", ":upper:", ":digit:"}
-- @treturn string LCDproc server response
-- @treturn string error description
function Alpha:set_allowed(allowed)
  self.allowed = allowed
  return self.update()
end

--- set extra allowed characters
-- @tparam string extra allowed characters
-- @treturn string LCDproc server response
-- @treturn string error description
function Alpha:set_extra(extra)
  self.extra = extra
  return self.update()
end

--- Ip class.
-- @type Ip
local Ip = {
  value = nil,  -- ip address value
  v6 = false    -- is ip address an IPv6 address
}
Ip.__index = Ip

--- create ip
-- @tparam Menu menu Menu instance
-- @tparam string id ip address field id
-- @tparam string text ip address field text
-- @tparam string value ip address value
-- @tparam bool v6 is ip address an IPv6
-- @tparam bool hidden is ip address hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Ip the new ip address field
function Ip.new(menu, id, text, value, v6, hidden, prev, next)
  local self = Item.new(Ip, menu, id, text, hidden, prev, next)
  self.value = value
  self.v6 = v6 or false
  if self.menu.server:request(
    self:with_args(
      'menu_add_item "%s" %s ip -value "%s" -v6 %s',
      self.menu.id,
      self.id,
      self.value,
      btos(self.v6)
    )
  ) then return self end
end

--- update ip address
-- @treturn string LCDproc server response
-- @treturn string error description
function Ip:update()
  return self.menu.server:request(
    self:with_args(
      'menu_set_item "%s" %s -value "%s" -v6 %s',
      self.menu.id,
      self.id,
      self.value,
      btos(self.v6)
    )
  )
end

--- set ip address value
-- @tparam string value ip address value
-- @treturn string LCDproc server response
-- @treturn string error description
function Ip:set_value(value)
  self.value = value
  return self.update()
end

--- set whether ip address is IPv6
-- @tparam bool v6 is ip address an IPv6
-- @treturn string LCDproc server response
-- @treturn string error description
function Ip:set_v6(v6)
  self.v6 = v6
  return self.update()
end

--- LCDproc Menu class.
-- @type Menu
local Menu = {
  server = nil,  -- LCDproc server
  items = {},    -- menu items
}
Menu.__index = Menu

--- create menu
-- @tparam LCDproc server LCDproc server
-- @tparam Menu menu menu parent
-- @tparam string id menu id
-- @tparam string text menu text
-- @tparam bool hidden is menu hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @treturn Menu the new menu
function Menu.new(server, menu, id, text, hidden, prev)
  local self = Item.new(Menu, menu, id, text, hidden, prev)
  self.server = server

  -- main menu is already defined on server
  -- so there's no need to create a request
  if self.id == "" then
    return self
  end

  if self.server:request(
    self:with_args(
      'menu_add_item "%s" %s menu',
      self.menu.id,
      self.id
    )
  ) then return self end
end

--- update menu on the server
-- @treturn string LCDproc server response
-- @treturn string error description
function Menu:update()
  if self.id ~= "" then
    return self.server:request(
      self:with_args(
        'menu_set_item "%s" %s',
        self.menu.id,
        self.id
      )
    )
  end
end

--- add action to the menu
-- @tparam string id action id
-- @tparam string text action text
-- @tparam string result result of action (none, close, quit)
-- @tparam bool hidden if action is hidden
-- @tparam Item prev previous item
-- @treturn Action the new action
function Menu:add_action(id, text, result, hidden, prev)
  self.items[id] = Action.new(self, id, text, result, hidden, prev)
  return self.items[id]
end

--- add checkbox to the menu
-- @tparam string id checkbox id
-- @tparam string text checkbox text
-- @tparam string value checkbox value (off, on, gray)
-- @tparam bool allow_gray whether to allow checkbox to be grayed out
-- @tparam bool hidden is checkbox hidden
-- @tparam Item prev previous item
-- @treturn Checkbox the new checkbox
function Menu:add_checkbox(id, text, value, allow_gray, hidden, prev)
  self.items[id] = Checkbox.new(self, id, text, value, allow_gray, hidden, prev)
  return self.items[id]
end

--- add ring to the menu
-- @tparam string id ring id
-- @tparam string text ring text
-- @tparam string value index of currently selected string
-- @tparam table strings table of strings
-- @tparam bool hidden is ring hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @treturn Ring the new ring
function Menu:add_ring(id, text, value, strings, hidden, prev)
  self.items[id] = Ring.new(self, id, text, value, strings, hidden, prev)
  return self.items[id]
end

--- add slider to the menu
-- @tparam string id slider id
-- @tparam string text slider text
-- @tparam int value slider value
-- @tparam table range slider range, i. e. {0, 100}
-- @tparam table labels slider labels, i. e. {"empty", "full"}
-- @tparam int step slider step
-- @tparam bool hidden if slider is hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Slider the new slider
function Menu:add_slider(
    id, text, value, range, labels, step, hidden, prev, next)
  self.items[id] = Slider.new(
    self, id, text, value, range, labels, step, hidden, prev, next)
  return self.items[id]
end

--- add numeric to the menu
-- @tparam string id numeric id
-- @tparam string text numeric text
-- @tparam int value numeric value
-- @tparam table range numeric range, i. e. {0, 100}
-- @tparam bool hidden is numeric field hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Numeric the new numeric
function Menu:add_numeric(id, text, value, range, hidden, prev, next)
  self.items[id] = Numeric.new(self, id, text, value, range, hidden, prev, next)
  return self.items[id]
end

--- add alpha to the menu
-- @tparam string id alpha id
-- @tparam string text alpha text
-- @tparam string value alpha value
-- @tparam string mask character to mask input with
-- @tparam table range input length range, i. e. {0, 10} - min: 0 chars, max: 10
-- @tparam table allowed allowed characters { ":upper:", ":lower:", ":digit:" }
-- @tparam string extra additional allowed characters
-- @tparam bool hidden is alpha hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Alpha the new alpha
function Menu:add_alpha(
    id, text, value, mask, range, allowed, extra, hidden, prev, next)
  self.items[id] = Alpha.new(
    self, id, text, value, mask, range, allowed, extra, hidden, prev, next)
  return self.items[id]
end

--- add ip to the menu
-- @tparam string id ip address field id
-- @tparam string text ip address field text
-- @tparam string value ip address value
-- @tparam bool v6 is ip address an IPv6
-- @tparam bool hidden is ip address hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @tparam Item next item to show after pressing ENTER key
-- @treturn Ip the new ip address field
function Menu:add_ip(id, text, value, v6, hidden, prev, next)
  self.items[id] = Ip.new(self, id, text, value, v6, hidden, prev, next)
  return self.items[id]
end

--- add submenu
-- @tparam string id submenu id
-- @tparam string text submenu text
-- @tparam bool hidden is submenu hidden
-- @tparam Item prev item to show after pressing ESCAPE key
-- @treturn Menu the new submenu
function Menu:add_menu(id, text, hidden, prev)
  self.items[id] = Menu.new(self.server, self, id, text, hidden, prev)
  return self.items[id]
end

return Menu
