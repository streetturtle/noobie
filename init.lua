local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local json = require("json")


local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/noobie'
local ICONS_DIR = WIDGET_DIR .. '/feather_icons/'


local noobie_widget = {}

local noobie_popup = awful.popup{
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local function worker(user_args)
    local args = user_args or {}
    local path = args.path

    noobie_widget = wibox.widget {
        {
            {
                id = 'icn',
                forced_height = 20,
                forced_width = 20,
                resize = true,
                widget = wibox.widget.imagebox
            },
            valign = 'center',
            layout = wibox.container.place
        },
        {
            id = 'txt',
            widget = wibox.widget.textbox
        },
        spacing = 4,
        layout = wibox.layout.fixed.horizontal,
        set_text = function(self, new_text)
            self:get_children_by_id('txt')[1]:set_text(new_text)
        end,
        set_icon = function(self, new_icon)
            self:get_children_by_id('icn')[1]:set_image(ICONS_DIR .. new_icon .. '.svg')
        end
    }

    local update_widget = function(widget, stdout, stderr)

        local result = json.decode(stdout)
        widget:set_text(result.widget.text)
        widget:set_icon(result.widget.icon_path)

        local rows = {
            { widget = wibox.widget.textbox },
            layout = wibox.layout.fixed.vertical,
        }

        for i = 0, #rows do rows[i]=nil end
        for _, item in ipairs(result.menu.items) do
            local row = wibox.widget {
                {
                    {
                        {
                            image = ICONS_DIR .. item.icon .. '.svg',
                            resize = true,
                            forced_height = 20,
                            forced_width = 20,
                            widget = wibox.widget.imagebox
                        },
                        {
                            text = item.title,
                            font = font,
                            widget = wibox.widget.textbox
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }
            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            table.insert(rows, row)
        end

        noobie_popup:setup(rows)


    end


    noobie_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if noobie_popup.visible then
                            noobie_popup.visible = not noobie_popup.visible
                        else
                            noobie_popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    watch(string.format([[sh -c "%s"]], args.path), 10, update_widget, noobie_widget)

    return noobie_widget
end

return setmetatable(noobie_widget, { __call = function(_, ...)
    return worker(...)
end })
