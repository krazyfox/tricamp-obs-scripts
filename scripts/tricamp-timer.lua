-- TODOs
-- ausblenden am ende aller elemente
-- leeren text ausblenden
--
-- validierung
-- pause button
-- stream dec

obs           = obslua


total_seconds = 0
cur_event_nr = 1
cur_seconds   = 0
last_cur_seconds = ""
events_text     = ""
activated     = false
event_list={}

hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

CURRENT_EXERCISE_TEXTFIELD_NAME = "currentExerciseTextfield"
NEXT_EXERCISE_TEXTFIELD_NAME = "nextExerciseTextfield"
CURRENT_EXERCISE_IMAGE_NAME = "currentExerciseImage"
NEXT_EXERCISE_IMAGE_NAME = "nextExerciseImage"

CURRENT_SECONDS_TEXTFIELD_NAME = "currentSecondsTextfield"
CURRENT_SECONDS_IMAGE_NAME = "currentSecondsImage"

EVENT_ITEM_SEPARATOR = ";"
EVENT_SEPARATOR = "\r\n"

-- Function to update element
function update_element(source_name,text)
	if text == nil then
		return
	end
	if source_name == nil then
		return
	end

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
		update_element(CURRENT_SECONDS_TEXTFIELD_NAME,cur_seconds)
		update_element(CURRENT_EXERCISE_TEXTFIELD_NAME,split(event_list[cur_event_nr],EVENT_ITEM_SEPARATOR)[2])
		update_element(NEXT_EXERCISE_TEXTFIELD_NAME,split(event_list[cur_event_nr+1],EVENT_ITEM_SEPARATOR)[2])
	end

	last_cur_seconds = cur_seconds
end

function timer_callback()
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		cur_event_nr =cur_event_nr+1
		cur_seconds = tonumber(split(event_list[cur_event_nr],EVENT_ITEM_SEPARATOR)[1])
	end
	if array_length(event_list) ==  cur_event_nr+1 then
		--print ("finish")
		obs.remove_current_callback()
		return
	end


	set_time_text()

end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		cur_seconds = total_seconds
		set_time_text()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate(false)
	local source = obs.obs_get_source_by_name(CURRENT_SECONDS_TEXTFIELD_NAME)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

--[[
	local p = obs.obs_properties_add_list(props, "timeSource", "Time Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)


	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				print(name)

				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	]]
	obs.obs_properties_add_text(props, "events_text", "Events", obs.OBS_TEXT_MULTILINE)
	obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_button_clicked)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Prepare 3 textfields with following names\n\n"..
			"* " .. CURRENT_SECONDS_TEXTFIELD_NAME .. "\n" ..
			"* " .. CURRENT_EXERCISE_TEXTFIELD_NAME .. "\n" ..
			"* " .. NEXT_EXERCISE_TEXTFIELD_NAME .. "\n" ..
			"\n" .. "Prepare 3 images with following names\n\n"..
			"* " .. CURRENT_SECONDS_IMAGE_NAME .. "\n" ..
			"* " .. CURRENT_EXERCISE_IMAGE_NAME .. "\n" ..
			"* " .. NEXT_EXERCISE_IMAGE_NAME
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	activate(false)
	events_text = obs.obs_data_get_string(settings, "events_text")
	event_list = split(events_text, EVENT_SEPARATOR)
	total_seconds = tonumber(split(event_list[cur_event_nr],EVENT_ITEM_SEPARATOR)[1])
	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "events_text", "5;10 Burbees\r\n3;erste pause\r\n5;30 Burbees\r\n3;zweite pause\r\n5;10 Burbees\r\n1;Ende\r\n0; ")
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
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
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

function split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end


function array_length(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end