--[[
    This script implements an interractive chapter list

    This script was written as an example for the mpv-scroll-list api
    https://github.com/CogentRedTester/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")

local settings = {
    header = "Chapter List \\N ------------------------------------",
    wrap = true,
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_open_chapter = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
  }

opts.read_options(settings, "chapter_list")

--adding the source directory to the package path and loading the module
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))

--modifying the list settings
list.header = settings.header
list.wrap = settings.wrap

--jump to the selected chapter
local function open_chapter()
    if list.list[list.selected] then
        mp.set_property_number('chapter', list.selected - 1)
    end
end

--dynamic keybinds to bind when the list is open

--update the list when the current chapter changes
mp.observe_property('chapter', 'number', function(_, curr_chapter)
    list.list = {}
    local chapter_list = mp.get_property_native('chapter-list', {})
    for i = 1, #chapter_list do
        local item = {}
        if (i-1 == curr_chapter) then
            item.style = [[{\c&H33ff66&}]]
        end

        local time = chapter_list[i].time
        if time < 0 then time = 0
        else time = math.floor(time) end
        item.ass = string.format("[%02d:%02d:%02d]", math.floor(time/60/60), math.floor(time/60)%60, time%60)
        item.ass = item.ass..'\\h\\h\\h'..list.ass_escape(chapter_list[i].title)
        list.list[i] = item
    end
    list:update()
end)

list.keybinds = {}

local function add_keys(keys, name, fn, flags)
    local i = 1
    for key in keys:gmatch("%S+") do
      table.insert(list.keybinds, {key, name..i, fn, flags})
      i = i + 1
    end
end

add_keys(settings.key_scroll_down, 'scroll_down', function() list:scroll_down() end, {repeatable = true})
add_keys(settings.key_scroll_up, 'scroll_up', function() list:scroll_up() end, {repeatable = true})
add_keys(settings.key_open_chapter, 'open_chapter', open_chapter, {})
add_keys(settings.key_close_browser, 'close_browser', function() list:close() end, {})

mp.register_script_message("toggle-chapter-browser", function() list:toggle() end)
