local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local gfs = require("gears.filesystem")
local spawn = require("awful.spawn")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/noobie'
local ICONS_DIR = WIDGET_DIR .. '/feather_icons/'
local CACHE_DIR = os.getenv("HOME") .. '/.cache/noobie/icons'

local row_builder = {}

local function build_header_row(item)
    return wibox.widget {
        {
            {
                markup = "<span foreground='#888888'>" .. item.title .. "</span>",
                widget = wibox.widget.textbox,
            },
            left = 8,
            layout = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }
end

local function build_icon_and_text_row(item, widget, noobie_popup)
    local item_image = wibox.widget{
        resize = true,
        forced_height = item.icon_size or 20,
        forced_width = item.icon_size or 20 ,
        widget = wibox.widget.imagebox
    }

    -- new_icon is an absolute path to a file
    if item.icon:sub(1, 1) == '/' then
        item_image:set_image(item.icon)

    -- new_icon is a relative path to the file
    elseif item.icon:sub(1, 1) == '~' then
        print(HOME_DIR .. '/' .. item.icon:sub(3))
        item_image:set_image(HOME_DIR .. '/' .. item.icon:sub(3))

    -- new_icon is a url of the icon
    elseif item.icon:sub(1, 4) == 'http' then
        local icon_path = CACHE_DIR .. '/' .. item.icon:sub(-16)
        if gfs.file_readable(icon_path) then
            item_image:set_image(icon_path)
        else
            local download_cmd = string.format([[sh -c "curl -L -f --create-dirs -o  %s %s"]], icon_path, item.icon)
            spawn.easy_async(download_cmd, function(stdout, stderr, reason, exit_code)
                if (exit_code == 0) then
                    item_image:set_image(icon_path)
                else
                    item_image:set_image(item.icon_fallback)
                end
            end)
        end

    -- new_icon is a feather icon
    else
        item_image:set_image(ICONS_DIR .. item.icon .. '.svg')
    end

    local right_part
    if item.subtitle ~=nil and #item.subtitle > 0 then
        right_part = wibox.widget {
            {
                markup = item.title,
                font = font,
                widget = wibox.widget.textbox
            },
            {
                markup = item.subtitle,
                font = font,
                widget = wibox.widget.textbox
            },
            spacing = 4,
            layout = wibox.layout.fixed.vertical
        }
    else
        right_part = wibox.widget {
            markup = item.title,
            font = font,
            widget = wibox.widget.textbox
        }
    end


    local row = wibox.widget {
        {
            {
                {
                    item_image,
                    valign = 'center',
                    layout = wibox.container.place,
                },
                right_part,
                spacing = 12,
                layout = wibox.layout.fixed.horizontal
            },
            margins = 8,
            layout = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }

    local old_cursor, old_wibox
    row:connect_signal("mouse::enter", function(c)
        c:set_bg(beautiful.bg_focus)
        local wb = mouse.current_wibox
        old_cursor, old_wibox = wb.cursor, wb
        wb.cursor = "hand1"
    end)
    row:connect_signal("mouse::leave", function(c)
        c:set_bg(beautiful.bg_normal)
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    row:buttons(gears.table.join(awful.button({}, 1, function()
        awful.spawn.with_shell(item.onclick)
        widget:set_bg(background)
        noobie_popup.visible = not noobie_popup.visible
    end)))

    return row
end


function row_builder:build_row(item, widget, noobie_popup)
    if item.type == 'header' then
        return build_header_row(item)
    elseif item.title ~= nil and #item.title > 0 and item.icon ~= nil and #item.icon > 0 then
        return build_icon_and_text_row(item, widget, noobie_popup)
    elseif item.type == 'separator' then
        return wibox.widget {
            {
                orientation = 'horizontal',
                forced_height = 1,
                span_ratio = 0.95,
                forced_width = 100,
                color = beautiful.bg_focus,
                widget = wibox.widget.separator
            },
            strategy = 'exact',
            widget = wibox.container.background

        }
    elseif item.title ~= nil and #item.title > 0 and item.icon == nil then
        local row = wibox.widget {
            {
                {
                    markup = item.title,
                    font = font,
                    widget = wibox.widget.textbox
                },
                margins = 8,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        if item.onclick ~= nil then
            local old_cursor, old_wibox
            row:connect_signal("mouse::enter", function(c)
                c:set_bg(beautiful.bg_focus)
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:connect_signal("mouse::leave", function(c)
                c:set_bg(beautiful.bg_normal)
                if old_wibox then
                    old_wibox.cursor = old_cursor
                    old_wibox = nil
                end
            end)

            row:buttons(gears.table.join(awful.button({}, 1, function()
                awful.spawn.with_shell(item.onclick)
                widget:set_bg(background)
                noobie_popup.visible = not noobie_popup.visible
            end)))
        end

        return row
    end
end


return row_builder