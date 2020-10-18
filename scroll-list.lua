local mp = require 'mp'
local ass = mp.create_osd_overlay('ass-events')
ass.hidden = true

local overlay = {
    ass = ass,
    header = "header \\N ----------------------------------------------",
    header_style = [[{\q2\fs35\c&00ccff&}]],
    list_style = [[{\q2\fs25\c&Hffffff&}]],
    wrapper_style = [[{\c&00ccff&\fs16}]],
    num_entries = 10,
    selected = 1,
    list = {},
    keybinds = {
        {'DOWN', 'scroll_down', function() scroll_down() end, {repeatable = true}},
        {'UP', 'scroll_up', function() scroll_up() end, {repeatable = true}}
    },

    --appends the entered text to the overlay
    append = function(this, text)
        if text == nil then return end
        this.ass.data = this.ass.data .. text
    end,

    --appends a newline character to the osd
    newline = function(this)
        this.ass.data = this.ass.data .. '\\N'
    end,

    --force osd update - wrapper for ass:update
    update = function(this)
        this.ass:update()
    end,

    --refreshes the ass text using the contents of the list
    update_ass = function(this)
        this:append(this.header_style)
        this:append(this.header)
        this:newline()

        for i = 1, #this.list do
            local item = this.list[i]
            this:append(this.list_style)
            this:append(item.style)
            this:append(item.text)
            this:newline()
        end

        this:update()
    end,

    --moves the selector down the list
    scroll_down = function (this)
        if this.selected < #this.list then
            this.selected = this.selected + 1
            this:update_ass()
        end
    end,

    --moves the selector up the list
    scroll_up = function (this)
        if this.selected > 1 then
            this.selected = this.selected - 1
            this:update_ass()
        end
    end,

    --opens the list
    open = function(this)
        for _,v in ipairs(this.keybinds) do
            mp.add_forced_key_binding(v[1], 'dynamic/'..v[2], v[3], v[4])
        end

        this.ass.hidden = false
        this:update_ass()
    end,

    --closes the list
    close = function(this)
        for _,v in ipairs(this.keybinds) do
            mp.remove_key_binding('dynamic/'..v[2])
        end

        this.ass.hidden = true
        this.ass:remove()
    end
}

return overlay