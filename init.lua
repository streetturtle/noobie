local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local json = require("json")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/noobie'
local ICONS_DIR = WIDGET_DIR .. '/feather_icons/'

local cur_stdout
local noobie_widget = {}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Noobie',
        text = message}
end

local function worker(user_args)
    local args = user_args or {}
    local refresh_rate = args.refresh_rate or 600
    local path = args.path
    local background = args.background or '#00000000'

    if path == nil then
        show_warning("Cannot create a widget, required parameter 'path' is not provided")
        return
    end
    local noobie_popup = awful.popup{
        ontop = true,
        visible = false,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {}
    }
    local has_menu = false
    local has_mouse_actions = false
    local menu_buttons = {}
    local mouse_actions_buttons = {}

    noobie_widget = wibox.widget {
        {
            {
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
                id = 'spc',
                spacing = 4,
                layout = wibox.layout.fixed.horizontal
            },
            margins = 4,
            widget = wibox.container.margin
        },
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        bg = background,
        widget = wibox.container.background,
        set_text = function(self, new_text)
            if new_text == nil or new_text == '' then
                self:get_children_by_id('txt')[1]:set_text('')
                self:get_children_by_id('spc')[1]:set_spacing(0)
            else
                self:get_children_by_id('txt')[1]:set_text(new_text)
            end
        end,
        set_icon = function(self, new_icon)
            self:get_children_by_id('icn')[1]:set_image(ICONS_DIR .. new_icon .. '.svg')
        end,
    }

    local update_widget = function(widget, stdout, stderr)
        if stderr ~= '' then
            show_warning(stderr)
            return
        end

        --- do nothing if the output hasn't changed
        if (cur_stdout == stdout) then return
        else cur_stdout = stdout
        end

        local result = json.decode(stdout)
        widget:set_text(result.widget.text)
        widget:set_icon(result.widget.icon_path)

        has_menu = result.menu ~= nil and result.menu.items ~= nil and #result.menu.items > 0

        if has_menu then
            local rows = { layout = wibox.layout.fixed.vertical }

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

                table.insert(rows, row)
            end

            noobie_popup:setup(rows)

            menu_buttons =  gears.table.join(
                            awful.button({}, 1, function()
                                if noobie_popup.visible then
                                    widget:set_bg(background)
                                    noobie_popup.visible = not noobie_popup.visible
                                else
                                    widget:set_bg(beautiful.bg_focus)
                                    noobie_popup:move_next_to(mouse.current_widget_geometry)
                                end
                            end)
                    )
        end

        local actions = result.widget.mouse_actions
        has_mouse_actions = actions ~= nil

        if has_mouse_actions then

            mouse_actions_buttons = gears.table.join(
                    awful.button({}, 1, function() if actions.on_left_click ~= nil then awful.spawn.with_shell(actions.on_left_click) end end),
                    awful.button({}, 2, function() if actions.on_right_click ~= nil then awful.spawn.with_shell(actions.on_right_click) end end),
                    awful.button({}, 4, function() if actions.on_scroll_up ~= nil then awful.spawn.with_shell(actions.on_scroll_up) end end),
                    awful.button({}, 5, function() if actions.on_scroll_down ~= nil then awful.spawn.with_shell(actions.on_scroll_down) end end)
            )
        end

    widget:buttons(gears.table.join(mouse_actions_buttons, menu_buttons))
    end

    watch(string.format([[sh -c "%s"]], path), refresh_rate, update_widget, noobie_widget)

    return noobie_widget
end

return setmetatable(noobie_widget, { __call = function(_, ...)
    return worker(...)
end })
