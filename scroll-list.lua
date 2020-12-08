local mp = require 'mp'
local methods = {}

--formats strings for ass handling
--this function is taken from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
function methods.ass_escape(str)
    str = str:gsub('\\', '\\\239\187\191')
    str = str:gsub('{', '\\{')
    str = str:gsub('}', '\\}')
    -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
    -- consecutive newlines
    str = str:gsub('\n', '\239\187\191\\N')
    -- Turn leading spaces into hard spaces to prevent ASS from stripping them
    str = str:gsub('\\N ', '\\N\\h')
    str = str:gsub('^ ', '\\h')
    return str
end
--appends the entered text to the overlay
function methods:append(text)
        if text == nil then return end
        self.ass.data = self.ass.data .. text
    end

--appends a newline character to the osd
function methods:newline()
    self.ass.data = self.ass.data .. '\\N'
end

--re-parses the list into an ass string
--if the list is closed then it flags an update on the next open
function methods:update()
    if self.hidden then self.flag_update = true
    else self:update_ass() end
end

--prints the header to the overlay
function methods:format_header()
    self:append(self.header_style)
    self:append(self.header)
    self:newline()
end

--formats each line of the list and prints it to the overlay
function methods:format_line(index, item)
    self:append(self.list_style)

    if index == self.selected then self:append(self.cursor_style..self.cursor..self.selected_style)
    else self:append(self.indent) end

    self:append(item.style)
    self:append(item.ass)
    self:newline()
end

--refreshes the ass text using the contents of the list
function methods:update_ass()
    self.ass.data = self.global_style
    self:format_header()

    if #self.list < 1 then
        self:append(self.empty_text)
        self.ass:update()
        return
    end

    local start = 1
    local finish = start+self.num_entries-1

    --handling cursor positioning
    local mid = math.ceil(self.num_entries/2)+1
    if self.selected+mid > finish then
        local offset = self.selected - finish + mid

        --if we've overshot the end of the list then undo some of the offset
        if finish + offset > #self.list then
            offset = offset - ((finish+offset) - #self.list)
        end

        start = start + offset
        finish = finish + offset
    end

    --making sure that we don't overstep the boundaries
    if start < 1 then start = 1 end
    local overflow = finish < #self.list
    --this is necessary when the number of items in the dir is less than the max
    if not overflow then finish = #self.list end

    --adding a header to show there are items above in the list
    if start > 1 then self:append(self.wrapper_style..(start-1)..' item(s) above\\N\\N') end

    for i=start, finish do
        self:format_line(i, self.list[i])
    end

    if overflow then self:append('\\N'..self.wrapper_style..#self.list-finish..' item(s) remaining') end
    self.ass:update()
end

--moves the selector down the list
function methods:scroll_down()
    if self.selected < #self.list then
        self.selected = self.selected + 1
        self:update_ass()
    elseif self.wrap then
        self.selected = 1
        self:update_ass()
    end
end

--moves the selector up the list
function methods:scroll_up()
    if self.selected > 1 then
        self.selected = self.selected - 1
        self:update_ass()
    elseif self.wrap then
        self.selected = #self.list
        self:update_ass()
    end
end

--adds the forced keybinds
function methods:add_keybinds()
    for _,v in ipairs(self.keybinds) do
        mp.add_forced_key_binding(v[1], 'dynamic/'..self.ass.id..'/'..v[2], v[3], v[4])
    end
end

--removes the forced keybinds
function methods:remove_keybinds()
    for _,v in ipairs(self.keybinds) do
        mp.remove_key_binding('dynamic/'..self.ass.id..'/'..v[2])
    end
end

--opens the list and sets the hidden flag
function methods:open_list()
    self.hidden = false
    if not self.flag_update then self.ass:update()
    else self.flag_update = false ; self:update_ass() end
end

--closes the list and sets the hidden flag
function methods:close_list()
    self.hidden = true
    self.ass:remove()
end

--modifiable function that opens the list
function methods:open()
    self:open_list()
    self:add_keybinds()
end

--modifiable function that closes the list
function methods:close ()
    self:remove_keybinds()
    self:close_list()
end

--toggles the list
function methods:toggle()
    if self.hidden then self:open()
    else self:close() end
end

local metatable = {
    __index = methods,
    __len = function(t) return #t.list end,
}

--creates a new list object
function methods:new()
    local vars
    vars = {
        ass = mp.create_osd_overlay('ass-events'),
        hidden = true,
        flag_update = true,

        global_style = [[]],

        header = "header \\N ----------------------------------------------",
        header_style = [[{\q2\fs35\c&00ccff&}]],

        list = {},
        list_style = [[{\q2\fs25\c&Hffffff&}]],
        wrapper_style = [[{\c&00ccff&\fs16}]],

        cursor = [[➤\h]],
        indent = [[\h\h\h\h]],
        cursor_style = [[{\c&00ccff&}]],
        selected_style = [[{\c&Hfce788&}]],

        num_entries = 16,
        selected = 1,
        wrap = false,
        empty_text = "no entries",

        keybinds = {
            {'DOWN', 'scroll_down', function() vars:scroll_down() end, {repeatable = true}},
            {'UP', 'scroll_up', function() vars:scroll_up() end, {repeatable = true}},
            {'ESC', 'close_browser', function() vars:close() end, {}}
        }
    }
    return setmetatable(vars, metatable)
end

return methods:new()