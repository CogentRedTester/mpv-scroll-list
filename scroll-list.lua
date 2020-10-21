local mp = require 'mp'

local overlay = {
    ass = mp.create_osd_overlay('ass-events'),
    hidden = true,
    flag_update = true,

    header = "header \\N ----------------------------------------------",
    header_style = [[{\q2\fs35\c&00ccff&}]],

    list = {},
    list_style = [[{\q2\fs25\c&Hffffff&}]],
    wrapper_style = [[{\c&00ccff&\fs16}]],

    cursor = [[➤  ]],
    indent = [[   ]],
    cursor_style = [[{\c&00ccff&}]],
    selected_style = [[{\c&Hfce788&}]],

    num_entries = 16,
    selected = 1,
    wrap = false,
    empty_text = "no entries",

    keybinds = {},

    --appends the entered text to the overlay
    append = function(this, text)
        if text == nil then return end
        this.ass.data = this.ass.data .. text
    end,

    --appends a newline character to the osd
    newline = function(this)
        this.ass.data = this.ass.data .. '\\N'
    end,

    --re-parses the list into an ass string
    --if the list is closed then it flags an update on the next open
    update = function(this)
        if this.hidden then this.flag_update = true
        else this:update_ass() end
    end,

    --refreshes the ass text using the contents of the list
    update_ass = function(this)
        this.ass.data = ""
        this:append(this.header_style)
        this:append(this.header)
        this:newline()

        if #this.list < 1 then
            this:append(this.empty_text)
            this:update()
            return
        end

        this:append(this.list_style)
        local start = 1
        local finish = start+this.num_entries-1

        --handling cursor positioning
        local mid = math.ceil(this.num_entries/2)+1
        if this.selected+mid > finish then
            local offset = this.selected - finish + mid

            --if we've overshot the end of the list then undo some of the offset
            if finish + offset > #this.list then
                offset = offset - ((finish+offset) - #this.list)
            end

            start = start + offset
            finish = finish + offset
        end

        --making sure that we don't overstep the boundaries
        if start < 1 then start = 1 end
        local overflow = finish < #this.list
        --this is necessary when the number of items in the dir is less than the max
        if not overflow then finish = #this.list end

        --adding a header to show there are items above in the list
        if start > 1 then this:append(this.wrapper_style..(start-1)..' item(s) above\\N\\N') end

        for i=start, finish do
            local v = this.list[i]
            this:append(this.list_style)

            if i == this.selected then this:append(this.cursor_style..this.cursor..this.selected_style)
            else this:append(this.indent) end

            this:append(v.text)
            this:newline()
        end

        if overflow then this:append('\\N'..this.wrapper_style..#this.list-finish..' item(s) remaining') end
        this.ass:update()
    end,

    --moves the selector down the list
    scroll_down = function (this)
        if this.selected < #this.list then
            this.selected = this.selected + 1
            this:update_ass()
        elseif this.wrap then
            this.selected = 1
            this:update_ass()
        end
    end,

    --moves the selector up the list
    scroll_up = function (this)
        if this.selected > 1 then
            this.selected = this.selected - 1
            this:update_ass()
        elseif this.wrap then
            this.selected = #this.list
            this:update_ass()
        end
    end,

    --opens the list
    open = function(this)
        for _,v in ipairs(this.keybinds) do
            mp.add_forced_key_binding(v[1], 'dynamic/'..v[2], v[3], v[4])
        end

        this.hidden = false
        if not this.flag_update then this.ass:update()
        else this.flag_update = false ; this:update_ass() end
    end,

    --closes the list
    close = function(this)
        for _,v in ipairs(this.keybinds) do
            mp.remove_key_binding('dynamic/'..v[2])
        end

        this.hidden = true
        this.ass:remove()
    end
}

overlay.keybinds = {
    {'DOWN', 'scroll_down', function() overlay:scroll_down() end, {repeatable = true}},
    {'UP', 'scroll_up', function() overlay:scroll_up() end, {repeatable = true}}
}

return overlay