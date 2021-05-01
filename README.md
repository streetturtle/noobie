# noobie

Still under development!

Create a wibar widget for Awesome WM with no lua code!

This is a widget-maker tool - it creates a widget based on a definition described in JSON format and returned by a script. 

For example, if your script returns a following JSON:

```json
{
  "widget": {
    "icon": "smile",
    "text": "noobie",
    "mouse_actions": {
      "on_scroll_up": "echo 'scroll up'",
      "on_scroll_down": "echo 'scroll down'",
      "on_right_click": "echo 'right click'"
    }
  }
}
```

noobie will convert it to following widget:

![screenshot](./screenshots/screenshot.png).

You can also create widgets with a menu:

```json
{
  "widget": {
    "icon": "smile",
    "text": "noobie",
    "mouse_actions": {
      "on_scroll_up": "echo 'scroll up'",
      "on_scroll_down": "echo 'scroll down'",
      "on_right_click": "echo 'right click'"
    }
  },
  "menu": {
    "items": [
      {
        "icon": "bell",
        "title": "Say hi!",
        "onclick": "notify-send 'hi!'"
      },
      {
        "icon": "terminal",
        "title": "Execute some script",
        "onclick": "/tmp/somescript.sh"
      },
      {
        "icon": "slack",
        "title": "OpenSlack",
        "onclick": "xdg-open https://slack.com"
      }
    ]
  }
}
```

gives:

![screenshot2](./screenshots/screenshot2.png)

## Features:

 - icon (either of a widget or of a menu item) can be one of:
    - a name of an icon from [feather icons](https://feathericons.com/): `arrow-down-circle`;
    - a path to a file: `/tmp/someicon.png;
    - a URL pointing to the icon: `http://some-icon.online/image.png` (with a fallback icon);
 - a notification with details in case your script failed:
 
  ![error notification](./screenshots/screenshot-errors.png)
 
## Plugins

Check out existing plugins in this repo: https://github.com/streetturtle/noobie-plugins.

## Installation

1. Clone the repo under ~/.config/awesome/ folder
1. At the top of rc.lua add an import:
 
    ```lua
    local noobie_exmaple_1 = require("noobie")
    local noobie_exmaple_2 = require("noobie")
    ```
1. Add a widget to wibox and provide a path to your script:
 
    ```lua
    noobie_exmaple_1{ path = os.getenv("HOME") .. '/.config/awesome/noobie/test.sh' },
    noobie_exmaple_2{ path = os.getenv("HOME") .. '/.config/awesome/noobie/othertest.py' },
    ```
