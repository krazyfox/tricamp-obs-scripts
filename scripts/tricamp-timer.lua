-- TODOs

-- validierung
-- hotkeys
-- stream deck

obs = obslua
logEnabled = true
logDebugEnabled = false
logInfoEnabled = true


cur_event_nr = 1
cur_seconds = 0
last_cur_seconds = ""
events_text = ""
activated = false
event_list = {}

hotkey_id = obs.OBS_INVALID_HOTKEY_ID

TRICAMP_ITEMS_PREFIX = "tricamp"

CURRENT_EXERCISE_TEXTFIELD_NAME = TRICAMP_ITEMS_PREFIX .. "CurrentExerciseTextfield"
NEXT_EXERCISE_TEXTFIELD_NAME = TRICAMP_ITEMS_PREFIX .. "NextExerciseTextfield"
CURRENT_EXERCISE_IMAGE_NAME = TRICAMP_ITEMS_PREFIX .. "CurrentExerciseImage"
NEXT_EXERCISE_IMAGE_NAME = TRICAMP_ITEMS_PREFIX .. "NextExerciseImage"

CURRENT_SECONDS_TEXTFIELD_NAME = TRICAMP_ITEMS_PREFIX .. "CurrentSecondsTextfield"
CURRENT_SECONDS_IMAGE_NAME = TRICAMP_ITEMS_PREFIX .. "CurrentSecondsImage"

EVENT_ITEM_SEPARATOR = ";"
EVENT_SEPARATOR = "\r\n"
EVENT_ITEM_POSITION__SECONDS = 1
EVENT_ITEM_POSITION__VISIBILITY = 2
EVENT_ITEM_POSITION__CURRENT_TEXT = 3
EVENT_ITEM_POSITION__NEXT_TEXT = 4


-- Function to update element
function update_element(source_name, text)

    do_log_debug("update_element")

    if text == nil then
        text = " "
    end

    if source_name == nil then
        return
    end
    do_log_debug("update_element(\"" .. source_name .. "\", \"" .. text .. "\")")
    local currentSource = obs.obs_get_source_by_name(source_name)
    if currentSource ~= nil then
        local cSsettings = obs.obs_data_create()
        obs.obs_data_set_string(cSsettings, "text", text)
        obs.obs_source_update(currentSource, cSsettings)
        obs.obs_data_release(cSsettings)
        obs.obs_source_release(currentSource)
    end

end

-- Function to set the time text
function set_time_text()

    if cur_seconds ~= last_cur_seconds then
        update_element(CURRENT_SECONDS_TEXTFIELD_NAME, cur_seconds)
        do_log_debug("update " .. CURRENT_EXERCISE_TEXTFIELD_NAME)
        update_element(CURRENT_EXERCISE_TEXTFIELD_NAME, split(event_list[cur_event_nr], EVENT_ITEM_SEPARATOR)[EVENT_ITEM_POSITION__CURRENT_TEXT])
        do_log_debug("update " .. NEXT_EXERCISE_TEXTFIELD_NAME)
        update_element(NEXT_EXERCISE_TEXTFIELD_NAME, split(event_list[cur_event_nr], EVENT_ITEM_SEPARATOR)[EVENT_ITEM_POSITION__NEXT_TEXT])
    end
    do_log_debug("set_time_text() done ")
    last_cur_seconds = cur_seconds
end

function timer_callback()
    do_log_debug("timer_callback () start")
    cur_seconds = cur_seconds - 1

    do_log_debug("info","event nr " .. cur_event_nr .. "/" .. array_length(event_list))

    do_log_debug("event nr " .. cur_event_nr .. "/" .. array_length(event_list))

    if cur_seconds < 0 then
        cur_event_nr = cur_event_nr + 1
        if array_length(event_list) == cur_event_nr - 1 then

            obs.remove_current_callback()
            obs.timer_remove(timer_callback)
            do_log_info("finish")
            return
        end
        do_log_info("new event {" .. event_list[cur_event_nr].."}" )
        do_log_debug("split event nr " .. cur_event_nr .. " -- " .. event_list[cur_event_nr])

        cur_seconds = getSecondsOfCurrentEvent()
        set_tricampItems_visible(getVisibilityOfCurrentEvent())
    end
    do_log_debug("call setTimeText")
    set_time_text()

end

function getVisibilityOfCurrentEvent()

    local currentEvent = event_list[cur_event_nr]
    local currentEventArr = split(currentEvent, EVENT_ITEM_SEPARATOR)
    return tovisibiltytext(currentEventArr[EVENT_ITEM_POSITION__VISIBILITY])

end

function tovisibiltytext(str)

    if (str == "show") then
        return true
    end
    if (str == "hide") then
        return false
    end

    print(str .. "is not valid. Must be show or hide")

end

function activate(activating)
    do_log_debug("activate(" .. tostring(activating) .. ") activated=" .. tostring(activated))
    if activated == activating then
        return
    end

    activated = activating

    if activating then
        obs.timer_add(timer_callback, 1000)
        set_tricampItems_visible(getVisibilityOfCurrentEvent())
        set_time_text()
    else
        obs.timer_remove(timer_callback)
    end
end

function restart()
    cur_event_nr = 1
    cur_seconds = getSecondsOfCurrentEvent()
    activate(false)
    activate(true)
    do_log_info("Re-(Start)")
    do_log_info("new event {" .. event_list[cur_event_nr].."}" )

end

function pause(pressed)
    do_log_debug("pause ( " .. tostring(pressed) .. ")")
    activate(pressed)
    activate(not pressed)

end

function restart_button_clicked(props, p)
    restart()
    return p
end

function pause_button_clicked(props, p)
    pause(true)
    return false
end

function play_button_clicked(props, p)
    pause(false)
    return false
end

function hide_button_clicked(props, p)
    set_tricampItems_visible(false)
    return false
end

function show_button_clicked(props, p)
    set_tricampItems_visible(true)
    return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
    do_log_debug("script_properties ()")

    local props = obs.obs_properties_create()

    obs.obs_properties_add_button(props, "restart_button", "(Re-)Start", restart_button_clicked)
    obs.obs_properties_add_button(props, "play_button", "Play", play_button_clicked)
    obs.obs_properties_add_button(props, "pause_button", "Pause", pause_button_clicked)
    obs.obs_properties_add_button(props, "hide_button", "Hide Tricamp Items", hide_button_clicked)
    obs.obs_properties_add_button(props, "show_button", "Show Tricamp Items", show_button_clicked)
    obs.obs_properties_add_text(props, "events_text", "Events", obs.OBS_TEXT_MULTILINE)
    return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
    return "Prepare 3 textfields with following names\n\n" ..
            "* " .. CURRENT_SECONDS_TEXTFIELD_NAME .. "\n" ..
            "* " .. CURRENT_EXERCISE_TEXTFIELD_NAME .. "\n" ..
            "* " .. NEXT_EXERCISE_TEXTFIELD_NAME .. "\n" ..
            "\n" .. "Prepare 3 images with following names\n\n" ..
            "* " .. CURRENT_SECONDS_IMAGE_NAME .. "\n" ..
            "* " .. CURRENT_EXERCISE_IMAGE_NAME .. "\n" ..
            "* " .. NEXT_EXERCISE_IMAGE_NAME .. "\n\n" ..
            "<seconds>;<show|hide>;<currentExercise>;<nextExercise>" .. "\n\n" ..
            "e.g.   5;show;1 Burbee;2 Burpees" .. "\n" ..
            "       1;hide;;"

end

-- A function named script_update will be called when settings are changed
function script_update(settings)
    do_log_debug("script_update (" .. tostring(settings) .. ")")
    activate(false)
    events_text = obs.obs_data_get_string(settings, "events_text")
    event_list = split(events_text, EVENT_SEPARATOR)

    local event = {name="x", bla="y"}
    do_log_debug(event.name)
    cur_seconds = getSecondsOfCurrentEvent()
end

function getSecondsOfCurrentEvent ()
    return tonumber(split(event_list[cur_event_nr], EVENT_ITEM_SEPARATOR)[EVENT_ITEM_POSITION__SECONDS])
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
    do_log_debug("script_defaults (" .. tostring(settings) .. ")")
    obs.obs_data_set_default_string(settings,
            "events_text",
            "5;show;1 Burbee;2 Burpees\r\n" ..
                    "3;show;Pause;\r\n" ..
                    "5;show;2 Burbees;3 Burpees\r\n" ..
                    "3;show;Pause;3 Burpees\r\n" ..
                    "5;show;3 Burpees;Ende\r\n" ..
                    "1;hide;;"
    )
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
    do_log_debug("script_save (" .. tostring(settings) .. ")")
    --  local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    -- obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
    -- obs.obs_data_array_release(hotkey_save_array)
end

-- a function named script_load will be called on startup
function script_load(settings)
    -- Connect hotkey and activation/deactivation signal callbacks
    --
    -- NOTE: These particular script callbacks do not necessarily have to
    -- be disconnected, as callbacks will automatically destroy themselves
    -- if the script is unloaded.  So there's no real need to manually
    -- disconnect callbacks that are intended to last until the script is
    -- unloaded.

    do_log_debug("script_load (" .. tostring(settings) .. ")")
    -- local sh = obs.obs_get_signal_handler()
    -- obs.signal_handler_connect(sh, "source_activate", source_activated)
    --obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

    --hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
    --local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
    --obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    --obs.obs_data_array_release(hotkey_save_array)
end

function set_tricampItems_visible(visible)

    do_log_debug("set_tricampItems_visible (" .. tostring(visible) .. ")")
    local sceneSource = obs.obs_frontend_get_current_scene()
    local scene = obs.obs_scene_from_source(sceneSource)
    -- do_log_debug( "scene ".. scene)
    local sceneitems = obs.obs_scene_enum_items(scene)
    for i, sceneitem in ipairs(sceneitems) do
        local itemsource = obs.obs_sceneitem_get_source(sceneitem)
        local isn = obs.obs_source_get_name(itemsource)
        do_log_debug("isn " .. isn)
        do_log_debug("TRICAMP_ITEMS_PREFIX " .. TRICAMP_ITEMS_PREFIX)
        if starts_with(isn, TRICAMP_ITEMS_PREFIX) then
            do_log_debug("set " .. isn .. "visible: " .. tostring(visible))
            obs.obs_sceneitem_set_visible(sceneitem, visible)
        end
    end
    obs.sceneitem_list_release(sceneitems)
end

function split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function array_length(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function starts_with(str, start)
    return str:sub(1, #start) == start
end

function do_log_debug ( str)
    if logDebugEnabled then
        do_log(str)
    end
end

function do_log_info ( str)
    if logInfoEnabled then
        do_log(str)
    end
end

function do_log (str)
    if logEnabled then
        print(str)
    end
end