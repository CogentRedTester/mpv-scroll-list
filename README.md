# mpv-scroll-list

This is an API to allow scripts to create interactive scrollable lists in mpv player.

## For Users
Installing the script as a user is very simple, just place the `scroll-list.lua` file inside the `~~/script-modules` folder (you may need to make it).

For more advanced users you can also place the file into one of the lua package directories specified by the `LUA_PATH` environment variable.

## For Developers

### Importing the Module
Importing the module in such a way as to respect the above settings can be done with the following code:

```
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))
```

The list variable then contains a table that represents a single scroll-list object.

### Conceptual Overview
Each list object maintains a separate osd ass overlay, and has a suite of variables and methods to modify and control the overlay.
When the `open` method is run the list creates a header and then iterates through the list of items and creates a formatted ass string using the item objects.
Forced keybindings are then set to allow the user to control the selection, and hence scroll up or down.
When the `close` method is run the keybinds are removed, and the osd hidden.
Basic scripts can create a full scrollable list by simply constructing an array of valid item objects and running the `open`, `close`, and `toggle` methods, but generally one will want to change the settings and modify the keybindings to actually provide the list with functionality beyond scrolling.

### Variables

The following variables are provided to modify the behaviour of the list.

| Variable       | Description                                           | Default                                                     |
|----------------|-------------------------------------------------------|-------------------------------------------------------------|
| global_style   | An ass string prepended to the start of the overlay   | empty
| header         | The string to print as the header                     | `header \\N ----------------------------------------------` |
| header_style   | The ass tag used to format the header                 | `{\q2\fs35\c&00ccff&}`                                      |
| list           | Array of item objects                                 | empty                                                       |
| list_style     | Generic ass tag to apply to all list items            | `{\q2\fs25\c&Hffffff&}`                                     |
| wrapper_style  | Ass tag for the 'x item(s) remaining' text            | `{\c&00ccff&\fs16}`                                         |
| cursor         | String to print before the selected item              | `➤\h`                                                       |
| indent         | String to print before non-selected items             | `\h\h\h\h`                                                  |
| cursor_style   | Ass tag for the cursor                                | `{\c&00ccff&}`                                              |
| selected_style | Ass tag to use after the cursor                       | `{\c&Hfce788&}`                                             |
| num_entries    | Number of items to display on screen before scrolling | 16                                                          |
| selected       | Currently selected item                               |                                                             |
| wrap           | Whether scrolling should wrap around the list         | false                                                       |
| empty_text     | Text to print when list is empty                      | `no entries`                                                |
| keybinds       | Array of keybind objects to use when the list is open | See [Keybinds entry](#The-Keybinds-Array)                   |

There are also a small number of variables that are intended for internal use by the list, however they may be useful if one want to write custom functions.

| Variable    | Description                                                        |
|-------------|--------------------------------------------------------------------|
| ass         | Contains the object returned by `mp.create_osd_overlay`            |
| hidden      | Used to track if the list is closed in order to defer redraws      |
| flag_update | Used to track if an update was requested while the list was closed |


### Methods
These methods must all be run using `object:function()` syntax so that they act on the correct list object.

#### Methods meant to control the list overlay:

| Method          | Description                                 |
|---------------  |---------------------------------------------|
| open()          | opens the list                              |
| close()         | closes the list                             |
| toggle()        | toggles the list                            |
| update()        | re-scan the list and update the osd overlay |
| scroll_down()   | move cursor down                            |
| scroll_up()     | move cursor up                              |
| move_pagedown() | move cursor to next page                    |
| move_pagedup()  | move cursor to previous page                |
| move_begin()    | move cursor to begin                        |
| move_end()      | move cursor to end                          |

#### Methods designed to be replaceable for custom behaviour:
Changing these can break the script if certain function calls are missing. Make sure to check the defaults.

| Method                   | Description                                                  |
| ------------------------ | ------------------------------------------------------------ |
| format_header_string()   | format and return the header string - allows one to modify or substitute the header string on each redraw |
| format_header()          | formats and prints the header to the overlay                 |
| format_line(index, item) | formats the ass string for the given `item` at list position `index` - this handles the cursor, indents, styles and newlines. |
| open()                   | is called by `toggle` - runs the functions required when opening the list |
| close()                  | is called by `toggle` - runs the functions required when closing the list |

#### Methods to support custom functions:

Generally these shouldn't be changed.

| Method            | Description                                                                        |
|-------------------|------------------------------------------------------------------------------------|
| append(str)       | appends the string `str` to the ass overlay - if text is nil then it safely exits  |
| newline()         | alias for `append("\\N")`                                                          |
| add_keybinds()    | adds the keybinds defined in the `keybinds` variable - used by `open`              |
| remove_keybinds() | removes the defined keybinds - used by `close`                                     |
| open_list()       | sends the ass update command and manages the hidden flag - used by `open`          |
| close_list()      | sends the ass remove command and manages the hidden flag - used by `close`         |

#### Internally used methods (for reference):

| Method       | Description                                                                    |
|--------------|--------------------------------------------------------------------------------|
| update_ass() | Main function that runs the format functions and calculates the scroll offsets |

### The List Array

Each item in the list array is a table with the following values:
| key   | Description                                                                                                      |
|-------|------------------------------------------------------------------------------------------------------------------|
| ass   | the ass string to print to the screen                                                                            |
| style | Optional - an ass string to prepend before `ass` - this is to provide an easier way to add/remove a custom style |

Any other key is ignored, so can be used by a script if it needs to store more information.
Note that it is possible that future versions of the script may add functionality for other keys.

### The Keybinds Array

The `keybinds` variable is an array of keybinds that the script applies when the script is open.
Each keybind is itself an array consisting of:

    key     a string describing the key to bind to - same as input.conf
    name    a unique name for this binding
    fn      a function to run when the key is pressed
    flags   a table of flags (can be an empty table)

These are passed almost directly to the `mp.add_forced_key_binding` function.
For details on flags see [mp.add_key_binding](https://mpv.io/manual/master/#lua-scripting-[,flags]])


### Utility Functions
