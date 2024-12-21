-- Add at the very top of the file, after _AUTO_RELOAD_DEBUG = true
_AUTO_RELOAD_DEBUG = true

-- Declare global variables
_tool_instance = nil
local options = renoise.Document.create("GenQSettings") {
  selected_scale = "major",
  note_range_min = 24,
  note_range_max = 84,
  current_pattern = "random"
}

-- Save preferences when they change
renoise.tool().preferences = options

class 'GenQ'

function GenQ:__init()
  -- Unified scale definitions with metadata
  self.scales = {
    major = {id = 1, name = "major", intervals = {0, 2, 4, 5, 7, 9, 11}},
    minor = {id = 2, name = "minor", intervals = {0, 2, 3, 5, 7, 8, 10}},
    harmonic_minor = {id = 3, name = "harmonic_minor", intervals = {0, 2, 3, 5, 7, 8, 11}},
    melodic_minor = {id = 4, name = "melodic_minor", intervals = {0, 2, 3, 5, 7, 9, 11}},
    pentatonic = {id = 5, name = "pentatonic", intervals = {0, 2, 4, 7, 9}},
    minor_pentatonic = {id = 6, name = "minor_pentatonic", intervals = {0, 3, 5, 7, 10}},
    dorian = {id = 7, name = "dorian", intervals = {0, 2, 3, 5, 7, 9, 10}},
    phrygian = {id = 8, name = "phrygian", intervals = {0, 1, 3, 5, 7, 8, 10}},
    lydian = {id = 9, name = "lydian", intervals = {0, 2, 4, 6, 7, 9, 11}},
    mixolydian = {id = 10, name = "mixolydian", intervals = {0, 2, 4, 5, 7, 9, 10}},
    locrian = {id = 11, name = "locrian", intervals = {0, 1, 3, 5, 6, 8, 10}},
    blues = {id = 12, name = "blues", intervals = {0, 3, 5, 6, 7, 10}},
    whole_tone = {id = 13, name = "whole_tone", intervals = {0, 2, 4, 6, 8, 10}},
    diminished = {id = 14, name = "diminished", intervals = {0, 2, 3, 5, 6, 8, 9, 11}},
    augmented = {id = 15, name = "augmented", intervals = {0, 3, 4, 7, 8, 11}},
    chromatic = {id = 16, name = "chromatic", intervals = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}},
    hungarian_minor = {id = 17, name = "hungarian_minor", intervals = {0, 2, 3, 6, 7, 8, 11}},
    persian = {id = 18, name = "persian", intervals = {0, 1, 4, 5, 6, 8, 11}},
    japanese = {id = 19, name = "japanese", intervals = {0, 2, 3, 7, 8}},
    arabic = {id = 20, name = "arabic", intervals = {0, 2, 4, 5, 6, 8, 10}},
    bebop = {id = 21, name = "bebop", intervals = {0, 2, 4, 5, 7, 9, 10, 11}},
    prometheus = {id = 22, name = "prometheus", intervals = {0, 2, 4, 6, 9, 10}},
    algerian = {id = 23, name = "algerian", intervals = {0, 2, 3, 6, 7, 8, 11}},
    byzantine = {id = 24, name = "byzantine", intervals = {0, 1, 4, 5, 7, 8, 11}},
    egyptian = {id = 25, name = "egyptian", intervals = {0, 2, 5, 7, 10}},
    eight_tone = {id = 26, name = "eight_tone", intervals = {0, 2, 3, 4, 6, 7, 9, 10}},
    enigmatic = {id = 27, name = "enigmatic", intervals = {0, 1, 4, 6, 8, 10, 11}},
    neapolitan = {id = 28, name = "neapolitan", intervals = {0, 1, 3, 5, 7, 9, 11}},
    neapolitan_minor = {id = 29, name = "neapolitan_minor", intervals = {0, 1, 3, 5, 7, 8, 11}},
    romanian_minor = {id = 30, name = "romanian_minor", intervals = {0, 2, 3, 6, 7, 9, 10}},
    ukrainian_dorian = {id = 31, name = "ukrainian_dorian", intervals = {0, 2, 3, 6, 7, 9, 10}},
    yo = {id = 32, name = "yo", intervals = {0, 2, 5, 7, 9}},
    in_sen = {id = 33, name = "in_sen", intervals = {0, 1, 5, 7, 10}},
    bhairav = {id = 34, name = "bhairav", intervals = {0, 1, 4, 5, 7, 8, 11}},
    marva = {id = 35, name = "marva", intervals = {0, 1, 4, 6, 7, 9, 11}},
    purvi = {id = 36, name = "purvi", intervals = {0, 1, 4, 6, 7, 8, 11}},
    todi = {id = 37, name = "todi", intervals = {0, 1, 3, 6, 7, 8, 11}},
    super_locrian = {id = 38, name = "super_locrian", intervals = {0, 1, 3, 4, 6, 8, 10}},
    double_harmonic = {id = 39, name = "double_harmonic", intervals = {0, 1, 4, 5, 7, 8, 11}},
    hindu = {id = 40, name = "hindu", intervals = {0, 2, 4, 5, 7, 8, 10}},
    kumoi = {id = 41, name = "kumoi", intervals = {0, 2, 3, 7, 9}},
    iwato = {id = 42, name = "iwato", intervals = {0, 1, 5, 6, 10}},
    messiaen1 = {id = 43, name = "messiaen1", intervals = {0, 2, 4, 6, 8, 10}},
    messiaen2 = {id = 44, name = "messiaen2", intervals = {0, 1, 3, 4, 6, 7, 9, 10}},
    messiaen3 = {id = 45, name = "messiaen3", intervals = {0, 2, 3, 4, 6, 7, 8, 10, 11}},
    leading_whole_tone = {id = 46, name = "leading_whole_tone", intervals = {0, 2, 4, 6, 8, 10, 11}}
  }

  -- Generate scale_map and id_to_scale_name lookup
  self.scale_map = {}
  self.id_to_scale_name = {}  -- New lookup table
  for name, scale in pairs(self.scales) do
    self.scale_map[scale.id] = string.format("%02X %s", scale.id, scale.name)
    self.id_to_scale_name[scale.id] = name  -- Store reverse lookup
  end

  -- Helper function to get scale from volume
  function GenQ:get_scale_from_volume(volume)
    -- Ensure volume is a valid number
    if type(volume) ~= "number" then
      renoise.app():show_status("Warning: Invalid volume value for scale selection")
      return "major"
    end
    
    local scale_name = self.id_to_scale_name[volume]
    if not scale_name or not self.scales[scale_name] then
      return "major"  -- Direct lookup with fallback
    end
    
    return scale_name
  end

  -- Unified pattern types with metadata
  self.patterns = {
    random = {id = 1, name = "random"},
    up = {id = 2, name = "up"},
    down = {id = 3, name = "down"},
    random_walk = {id = 4, name = "random_walk"},
    jazz_walk = {id = 5, name = "jazz_walk"},
    modal_drift = {id = 6, name = "modal_drift"},
    tension_release = {id = 7, name = "tension_release"},
    melodic_contour = {id = 8, name = "melodic_contour"},
    phrase_based = {id = 9, name = "phrase_based"},
    markov = {id = 10, name = "markov"},
    euclidean = {id = 11, name = "euclidean"},
    melodic_sequence = {id = 12, name = "melodic_sequence"},
    melodic_development = {id = 13, name = "melodic_development"},
    melodic_phrase = {id = 14, name = "melodic_phrase"},
    rhythmic_phrase = {id = 15, name = "rhythmic_phrase"}
  }

  -- Generate pattern_types from patterns
  self.pattern_types = {}
  for _, pattern in pairs(self.patterns) do
    self.pattern_types[pattern.id] = string.format("%02X %s", pattern.id, pattern.name)
  end

  -- Initialize properties
  self.selected_scale = "major"
  self.selected_pattern = 1
  self.note_range = {40, 80}
  self.trigger_instrument = 0

  -- Add menu entry directly to Tools menu
  renoise.tool():add_menu_entry{name="Main Menu:Tools:GenQ",invoke=function() self:show_gui() end}

  -- Real-time processing
  renoise.tool().app_idle_observable:add_notifier(function()
    self:check_for_trigger()
  end)

  -- Add properties for musical context
  self.prev_note = nil
  self.pattern_index = 1
  self.current_pattern = options.current_pattern.value
  self.current_pattern_type = 1

  -- Initialize state management
  self.column_state = {}
  self.last_pattern_key = nil
end

function GenQ:show_gui()
  if self.dialog and self.dialog.visible then
    self.dialog:show()
    return
  end

  local vb = renoise.ViewBuilder()
  self.vb = vb

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  
  local dialog = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:horizontal_aligner {
      mode = "center",
      width = "100%",
      
      vb:column {
        vb:row {
          spacing = CONTENT_SPACING,
          
          vb:text {
            text = "Select Scale",
            width = 100
          },
          
          vb:popup {
            id = "scale_popup",
            items = self.scale_map,
            value = table.find(self.scale_map, self.selected_scale) or 1,
            width = 150,
            notifier = function(index)
              self.selected_scale = self.scale_map[index]
              renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
            end
          }
        },
        
        vb:row {
          spacing = CONTENT_SPACING,
          margin = CONTENT_MARGIN,
          
          vb:text {
            text = "Note Range (Low-High)",
            width = 100
          },
          
          vb:valuebox {
            id = "note_range_min",
            min = 0,
            max = 119,
            value = self.note_range[1],
            width = 50,
            notifier = function(value)
              self.note_range[1] = value
            end
          },
          
          vb:valuebox {
            id = "note_range_max",
            min = 0,
            max = 119,
            value = self.note_range[2],
            width = 50,
            notifier = function(value)
              self.note_range[2] = value
            end
          }
        },
        
        vb:row {
          spacing = CONTENT_SPACING,
          
          vb:text {
            text = "Pattern Type",
            width = 100
          },
          
          vb:popup {
            id = "pattern_popup",
            items = self.pattern_types,
            value = self.current_pattern_type,
            width = 150,
            notifier = function(index)
              self.current_pattern_type = index
              -- When pattern type changes in UI, update the panning value in the trigger column
              local song = renoise.song()
              if song.selected_note_column then
                -- Set panning to match pattern number (01 for pattern 1, etc.)
                local panning = index  -- No need to subtract 1 anymore
                renoise.app():show_status(string.format("Setting panning: %02X for pattern %d", 
                  panning, index))
                song.selected_note_column.panning_value = panning
              end
              renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
            end
          }
        }
      }
    }
  }
  
  self.dialog = renoise.app():show_custom_dialog(
    "Random Note Generator Settings",
    dialog
  )
end

function genq_keyhandler_func(dialog, key)
  local closer = "esc"
  if key.modifiers == "" and key.name == closer then
    dialog:close()
    dialog = nil
    return
  else 
    return key
  end
end

-- Helper function to get scale intervals
function GenQ:get_scale_intervals(scale_name)
  -- Handle nil or invalid scale name
  if not scale_name or type(scale_name) ~= "string" then
    renoise.app():show_status("Warning: Invalid scale name, using major scale")
    return self.scales.major.intervals
  end
  
  -- Get scale and validate intervals
  local scale = self.scales[scale_name]
  if not scale or not scale.intervals or #scale.intervals == 0 then
    renoise.app():show_status("Warning: Invalid scale definition for " .. scale_name .. ", using major scale")
    return self.scales.major.intervals
  end
  
  return scale.intervals
end

-- Helper function to get pattern from panning
function GenQ:get_pattern_from_panning(panning)
  -- Ensure panning is a number and in valid range
  if type(panning) ~= "number" then return 1 end
  panning = math.floor(panning)
  
  -- Check if panning value maps to a valid pattern
  local valid_pattern = false
  for _, pattern in pairs(self.patterns) do
    if pattern.id == panning then
      valid_pattern = true
      break
    end
  end
  
  if not valid_pattern then
    renoise.app():show_status(string.format("Warning: Invalid pattern type %d, using default", panning))
    return 1  -- Default to random pattern
  end
  
  return panning
end

function GenQ:get_instrument_config(instrument_index)
  local song = renoise.song()
  local instrument = song.instruments[instrument_index]
  if not instrument then return nil end
  
  local name = instrument.name
  if not name or not name:find("GENQ:") then return nil end
  
  local min, max = name:match("GENQ:(%d+):(%d+)")
  local display_name = name:match("GENQ:%d+:%d+|(.+)") or ""
    
  if min and max then
    min = tonumber(min)
    max = tonumber(max)
    if min and max then
      -- Ensure valid range
      min = math.max(0, math.min(min, 119))
      max = math.max(0, math.min(max, 119))
      if min > max then min, max = max, min end
      
      return {
        note_range = {min, max},
        display_name = display_name
      }
    end
  end
  
  return nil
end

function GenQ:check_for_trigger()
  if not renoise.song() then return end
  if not renoise.song().transport.playing then return end

  local song = renoise.song()
  local pos = song.transport.playback_pos
  if not pos then return end  -- Extra safety check
  local pattern_index = song.sequencer:pattern(pos.sequence)
  local current_pattern = song.patterns[pattern_index]
  
  -- Check current line and next line, handling pattern boundaries
  local patterns_to_check = {{pattern = current_pattern, line = pos.line}}
  
  if pos.line < current_pattern.number_of_lines then
    -- Add next line in current pattern
    table.insert(patterns_to_check, {pattern = current_pattern, line = pos.line + 1})
  elseif pos.sequence < #song.sequencer.pattern_sequence then
    -- Add first line of next pattern
    local next_pattern_index = song.sequencer:pattern(pos.sequence + 1)
    local next_pattern = song.patterns[next_pattern_index]
    if next_pattern then
      table.insert(patterns_to_check, {pattern = next_pattern, line = 1})
    end
  else
    -- At end of last pattern, check first line of first pattern (sequence loop)
    local first_pattern_index = song.sequencer:pattern(1)
    local first_pattern = song.patterns[first_pattern_index]
    if first_pattern and #song.sequencer.pattern_sequence > 0 then
      table.insert(patterns_to_check, {pattern = first_pattern, line = 1})
    end
  end
  
  for _, check_info in ipairs(patterns_to_check) do
    local pattern_to_check = check_info.pattern
    local line_to_check = check_info.line
    
    for track_index = 1, #song.tracks do
      local track = song.tracks[track_index]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then 
        local pattern_track = pattern_to_check:track(track_index)
        local line = pattern_track:line(line_to_check)

        for column_index = 1, track.visible_note_columns do
          local note_column = line.note_columns[column_index]
          
          if note_column and 
             note_column.note_value >= 0 and 
             note_column.note_value <= 11 and
             note_column.instrument_value == self.trigger_instrument then
            
            local root_note = note_column.note_value
            local scale_name = self:get_scale_from_volume(note_column.volume_value)
            local pattern_type = self:get_pattern_from_panning(note_column.panning_value)
            
            -- Store the current pattern type
            self.current_pattern_type = pattern_type
            
            -- Update GUI if visible
            if self.vb and self.dialog and self.dialog.visible then
              -- Update scale popup safely
              if self.vb.views.scale_popup then
                local scale_index = note_column.volume_value
                if scale_index and scale_index >= 1 and scale_index <= #self.scale_map then
                  self.vb.views.scale_popup.value = scale_index
                else
                  renoise.app():show_status("Warning: Invalid scale index " .. tostring(scale_index))
                end
              end
              
              -- Update pattern popup safely
              if self.vb.views.pattern_popup then
                if pattern_type and pattern_type >= 1 and pattern_type <= #self.pattern_types then
                  self.vb.views.pattern_popup.value = pattern_type
                else
                  renoise.app():show_status("Warning: Invalid pattern type " .. tostring(pattern_type))
                end
              end
            end
            
            -- Process based on line position and pattern
            if pattern_to_check == current_pattern then
              self:process_next_column(track_index, pattern_to_check, column_index, root_note, scale_name, pattern_type)
            else
              -- For next pattern, process immediately to prepare the notes
              self:process_pattern_immediately(track_index, pattern_to_check, column_index, root_note, scale_name, pattern_type)
            end
          end
        end
      end
    end
  end
end

function GenQ:process_next_column(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
  local song = renoise.song()
  
  -- Initialize column-specific state if needed
  if not self.column_state then
    self.column_state = {}
  end
  
  -- Get current pattern index and sequence position
  local current_pattern_index = song.selected_pattern_index
  local current_sequence_pos = song.transport.playback_pos.sequence
  local current_line = song.transport.playback_pos.line
  local current_time = os.clock() * 1000  -- Add millisecond precision
  
  -- Create a unique key for this pattern iteration that includes line position
  local pattern_key = string.format("%d_%d_%d_%.0f", current_pattern_index, current_sequence_pos, current_line, current_time)
  
  -- Reset column state only when we're in a completely new pattern context
  if self.last_pattern_key and self.last_pattern_key:match("^(%d+_%d+)") ~= string.format("%d_%d", current_pattern_index, current_sequence_pos) then
    self.column_state = {}
  end
  self.last_pattern_key = pattern_key
  
  -- Process all tracks in the pattern
  for track_idx = track_index, #pattern.tracks do
    local track = song.tracks[track_idx]
    local pattern_track = pattern:track(track_idx)
    
    -- Determine which columns to process based on track
    local start_column = 1
    if track_idx == track_index then
      start_column = trigger_column_index + 1
    end
    
    -- Process note columns in this track
    for column_idx = start_column, track.visible_note_columns do
      -- Create unique key for this column
      local column_key = string.format("%d_%d", track_idx, column_idx)
      
      -- Initialize random state with more entropy
      local time_component = os.clock() * 1000
      local pattern_component = pattern.number_of_lines * 100
      local track_component = track_idx * 1000
      local column_component = column_idx * 10000
      local random_state = (time_component + pattern_component + track_component + column_component) % 1000000
      
      -- Initialize column state if needed
      if not self.column_state[column_key] then
        self.column_state[column_key] = {
          last_note = nil,
          phrase_position = 1,
          direction = nil,  -- Will be initialized with col_random
          tension = 0,
          sequence = nil,
          markov_state = nil,
          variation_seed = nil,  -- Will be initialized with col_random
          random_state = random_state
        }
      end
      
      local col_state = self.column_state[column_key]
      
      -- Update col_random to use column state
      local function col_random(max)
        col_state.random_state = (1664525 * col_state.random_state + 1013904223) % 4294967296
        if max then
          return 1 + math.floor((col_state.random_state / 4294967296) * max)
        end
        return col_state.random_state / 4294967296
      end
      
      -- Initialize direction and variation_seed if needed
      if not col_state.direction then
        col_state.direction = col_random(2) == 1 and 1 or -1
      end
      if not col_state.variation_seed then
        col_state.variation_seed = col_random()
      end
      
      for line_index = 1, pattern.number_of_lines do
        local line = pattern_track:line(line_index)
        local note_column = line.note_columns[column_idx]
        
        if note_column and note_column.note_value > 0 and note_column.note_value < 120 then
          local config = self:get_instrument_config(note_column.instrument_value + 1)
          if config then
            local scale = self:get_scale_intervals(scale_name)
            if not scale then
              renoise.app():show_status("Warning: Scale not found: " .. scale_name)
              return
            end

            local new_note = nil
            local base_octave = self:get_octave(config.note_range[1], config.note_range[2], col_random)
            
            -- Add column-specific octave variation
            local octave_offset = (column_idx - 1) % 2 == 0 and 12 or 0
            base_octave = base_octave + octave_offset
            
            -- Handle different pattern types
            if pattern_type == 2 then  -- "2 up" pattern
              if col_state.last_note == nil then
                col_state.last_note = 1
              else
                col_state.last_note = (col_state.last_note % #scale) + 1
              end
              
              local octave_shift = math.floor((line_index - 1) / #scale) * 12
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave + octave_shift, config)

            elseif pattern_type == 3 then  -- "3 down" pattern
              if col_state.last_note == nil then
                col_state.last_note = #scale
              else
                col_state.last_note = col_state.last_note - 1
                if col_state.last_note < 1 then 
                  col_state.last_note = #scale
                end
              end
              
              local octave_shift = -math.floor((line_index - 1) / #scale) * 12
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave + octave_shift, config)

            elseif pattern_type == 4 then  -- "4 random_walk"
              if col_state.last_note == nil then
                col_state.last_note = col_random(#scale)
              else
                local direction = col_random(2) == 1 and 1 or -1
                col_state.last_note = col_state.last_note + direction
                if col_state.last_note < 1 then col_state.last_note = #scale
                elseif col_state.last_note > #scale then col_state.last_note = 1 end
              end
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)

            elseif pattern_type == 5 then  -- "5 jazz_walk"
              if col_state.last_note == nil then
                col_state.last_note = col_random(#scale)
              else
                -- More controlled intervals for smoother jazz lines
                local base_intervals = column_idx % 2 == 0 
                  and {1, 2, 2, 3}  -- Even columns: smaller intervals
                  or {2, 2, 3, 3}   -- Odd columns: medium intervals
                
                local interval = base_intervals[col_random(#base_intervals)]
                -- Occasionally allow larger intervals at phrase boundaries
                if line_index % 4 == 0 and col_random() < 0.3 then
                  interval = interval * 2
                end
                
                local direction = col_random(2) == 1 and 1 or -1
                -- Bias direction to stay in middle of scale
                if col_state.last_note > #scale * 0.7 then
                  direction = -1
                elseif col_state.last_note < #scale * 0.3 then
                  direction = 1
                end
                
                col_state.last_note = col_state.last_note + (direction * interval)
                while col_state.last_note < 1 do col_state.last_note = col_state.last_note + #scale end
                while col_state.last_note > #scale do col_state.last_note = col_state.last_note - #scale end
              end
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)

            elseif pattern_type == 6 then  -- "6 modal_drift"
              local shift = math.floor(line_index / 4) % #scale
              local pos = ((line_index - 1) % #scale) + 1
              local shifted_pos = ((pos + shift - 1) % #scale) + 1
              -- Add column variation
              if column_idx % 2 == 1 then
                shifted_pos = ((shifted_pos + 2) % #scale) + 1
              end
              new_note = self:quantize_to_scale(shifted_pos, scale_name, root_note, base_octave, config)

            elseif pattern_type == 7 then  -- "7 tension_release"
              if col_state.last_note == nil then
                -- Start at different scale positions for each column
                col_state.last_note = 1 + ((column_idx - 1) * 2) % #scale
                col_state.tension = 0
                col_state.base_octave = base_octave
              else
                -- Different tension patterns per column
                local tension_length = column_idx % 2 == 0 and 6 or 4
                if line_index % 8 < tension_length then
                  -- Use tension value to influence note selection
                  local tension_step = math.ceil(col_state.tension / 4)  -- More dramatic steps as tension builds
                  
                  -- Add column-specific variation to the step
                  if column_idx % 2 == 0 then
                    -- Even columns: move up the scale with larger steps
                    col_state.last_note = col_state.last_note + tension_step * 2
                  else
                    -- Odd columns: move down the scale with smaller steps
                    col_state.last_note = col_state.last_note - tension_step
                  end
                  
                  col_state.tension = math.min(col_state.tension + 1, 12)
                  
                  -- Handle scale wrapping differently for each column
                  if column_idx % 2 == 0 then
                    -- Even columns wrap up with octave change
                    if col_state.last_note > #scale then 
                      col_state.last_note = 1
                      local new_octave = col_state.base_octave + 12
                      if new_octave <= config.note_range[2] - 12 then
                        col_state.base_octave = new_octave
                      end
                    end
                  else
                    -- Odd columns wrap down with octave change
                    if col_state.last_note < 1 then 
                      col_state.last_note = #scale
                      local new_octave = col_state.base_octave - 12
                      if new_octave >= config.note_range[1] + 12 then
                        col_state.base_octave = new_octave
                      end
                    end
                  end
                else
                  -- Release phase
                  -- Different release behavior per column
                  if column_idx % 2 == 0 then
                    -- Even columns: quick descent to root
                    col_state.last_note = math.max(1, col_state.last_note - 2)
                  else
                    -- Odd columns: slower descent with more variation
                    local release_step = math.ceil(col_state.tension / 3)
                    if col_random() < 0.4 then  -- 40% chance for variation
                      release_step = release_step + col_random(3)
                    end
                    col_state.last_note = math.max(1, col_state.last_note - release_step)
                  end
                  
                  col_state.tension = math.max(0, col_state.tension - 2)
                  col_state.base_octave = base_octave
                end
              end
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, col_state.base_octave, config)

            elseif pattern_type == 8 then  -- "8 melodic_contour"
              -- Initialize wave state if needed
              if col_state.last_note == nil then
                col_state.last_note = col_random(#scale)
                col_state.phase = col_random() * math.pi * 2  -- Random starting phase
              end
              
              -- Different wave shapes and frequencies for each column
              local wave
              if column_idx % 2 == 0 then
                -- Even columns: sine wave with faster frequency
                wave = math.sin(line_index * 0.3 + col_state.phase)
              else
                -- Odd columns: cosine wave with slower frequency
                wave = math.cos(line_index * 0.2 + col_state.phase)
              end
              
              -- Scale the wave to our scale range
              local base_pos = math.floor((wave + 1) * (#scale / 2))
              base_pos = math.max(1, math.min(base_pos, #scale))
              
              -- Add column-specific offset
              local offset = ((column_idx - 1) * 2) % #scale
              local pos = ((base_pos + offset - 1) % #scale) + 1
              
              -- Center the base octave within the instrument's range
              local mid_note = (config.note_range[1] + config.note_range[2]) / 2
              local mid_octave = math.floor(mid_note / 12) * 12
              
              new_note = self:quantize_to_scale(pos, scale_name, root_note, mid_octave, config)

            elseif pattern_type == 9 then  -- "9 phrase_based"
              -- Different phrase lengths per column
              local phrase_length = column_idx % 2 == 0 and 16 or 12
              local phrase_pos = line_index % phrase_length
              
              if phrase_pos == 0 or col_state.last_note == nil then
                col_state.last_note = col_random(#scale)
                -- Initialize phrase direction
                col_state.phrase_direction = column_idx % 2 == 0 and 1 or -1
              elseif phrase_pos % (column_idx % 2 == 0 and 4 or 6) == 0 then  -- Changed 3 to 6 to avoid small divisions
                -- Different interval patterns per column
                if column_idx % 2 == 0 then
                  -- Even columns: larger steps up
                  col_state.last_note = col_state.last_note + (col_random(3) + 1)
                else
                  -- Odd columns: smaller steps with direction changes
                  col_state.phrase_direction = col_random() < 0.3 and -col_state.phrase_direction or col_state.phrase_direction
                  col_state.last_note = col_state.last_note + (col_state.phrase_direction * col_random(2))
                end
              end
              
              -- Ensure we stay in scale
              while col_state.last_note < 1 do col_state.last_note = col_state.last_note + #scale end
              while col_state.last_note > #scale do col_state.last_note = col_state.last_note - #scale end
              
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)

            elseif pattern_type == 10 then  -- "0A markov"
              if line_index == 1 or col_state.last_pattern_type ~= pattern_type then
                col_state.markov_transitions = nil
                col_state.last_pattern_type = pattern_type
              end
              
              if not col_state.markov_transitions then
                col_state.markov_transitions = {}
                for i = 1, #scale do
                  col_state.markov_transitions[i] = {}
                  for j = 1, #scale do
                    local interval = math.abs(i - j)
                    col_state.markov_transitions[i][j] = math.exp(-interval * (0.5 + column_idx * 0.1))
                  end
                end
              end
              
              if col_state.last_note == nil then
                col_state.last_note = col_random(#scale)  -- Use col_random
              else
                local probs = col_state.markov_transitions[col_state.last_note]
                local total = 0
                for _, p in ipairs(probs) do total = total + p end
                local r = col_random() * total  -- Use col_random
                for i, p in ipairs(probs) do
                  r = r - p
                  if r <= 0 then
                    col_state.last_note = i
                    break
                  end
                end
              end
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)

            elseif pattern_type == 11 then  -- "11 euclidean"
              local steps = #scale
              local pulses = math.ceil(steps * (0.4 + (column_idx % 2) * 0.1))
              local position = line_index % steps
              if (position * pulses) % steps < pulses then
                new_note = self:quantize_to_scale(col_random(#scale), scale_name, root_note, base_octave, config)  -- Use col_random
              else
                new_note = self:quantize_to_scale(col_state.last_note or 1, scale_name, root_note, base_octave, config)
              end

            elseif pattern_type == 12 then  -- "12 melodic_sequence"
              if not col_state.sequence then
                local max_motif_length = math.min(4, math.floor(#scale / 2))
                local motif_length = col_random(2, max_motif_length)
                col_state.sequence = {
                  pattern = {},
                  direction = col_random(2) == 1 and 1 or -1,
                  interval = col_random(2),
                  type = col_random(3)
                }
                
                local max_start = #scale - motif_length + 1
                local start_degree = col_random(max_start)
                for i = 1, motif_length do
                  table.insert(col_state.sequence.pattern, start_degree + i - 1)
                end
              end
              
              -- Calculate position in sequence
              local seq = col_state.sequence
              local motif_pos = (line_index - 1) % #seq.pattern
              local repetition = math.floor((line_index - 1) / #seq.pattern)
              
              -- Get base scale degree from pattern
              local base_degree = seq.pattern[motif_pos + 1]
              
              -- Apply transposition based on sequence type
              if seq.type == 1 then  -- Real sequence
                -- Limit transposition to prevent range issues
                local max_transpose = math.floor((config.note_range[2] - base_octave - root_note) / 12)
                local min_transpose = math.floor((config.note_range[1] - base_octave - root_note) / 12)
                local transpose = math.min(math.max(
                  repetition * seq.interval * seq.direction,
                  min_transpose
                ), max_transpose)
                
                -- Use quantize_to_scale with bounded scale position
                local scale_pos = base_degree + (transpose * #scale)
                scale_pos = ((scale_pos - 1) % #scale) + 1  -- Ensure scale_pos stays within bounds
                new_note = self:quantize_to_scale(scale_pos, scale_name, root_note, base_octave + (transpose * 12), config)
                
              elseif seq.type == 2 then  -- Tonal sequence
                -- Move pattern up/down the scale
                local scale_pos = base_degree + (repetition * seq.interval * seq.direction)
                -- Wrap around scale
                while scale_pos > #scale do scale_pos = scale_pos - #scale end
                while scale_pos < 1 do scale_pos = scale_pos + #scale end
                new_note = self:quantize_to_scale(scale_pos, scale_name, root_note, base_octave, config)
                
              else  -- Modified sequence
                -- Preserve contour but adapt to scale
                local scale_pos = base_degree + (repetition * seq.interval * seq.direction)
                -- Ensure we stay within reasonable range
                scale_pos = ((scale_pos - 1) % #scale) + 1
                -- Add column-specific variation while preserving contour
                if motif_pos > 0 then
                  local prev_degree = seq.pattern[motif_pos]
                  local interval = base_degree - prev_degree
                  scale_pos = scale_pos + (interval % math.min(3, #scale))
                end
                new_note = self:quantize_to_scale(scale_pos, scale_name, root_note, base_octave, config)
              end
              
              -- Reset sequence after 4 repetitions or if we're running out of range
              if line_index > #seq.pattern * 4 or 
                 (seq.type == 1 and (new_note <= config.note_range[1] or new_note >= config.note_range[2])) then
                col_state.sequence = nil
              end

            elseif pattern_type == 13 then  -- "13 melodic_development"
              if line_index % 8 == 0 or col_state.last_note == nil then
                col_state.last_note = col_random(#scale)  -- Use col_random
              else
                local variation = math.floor(line_index / 8)
                local step = col_random(-variation, variation)  -- Use col_random
                if column_idx % 2 == 1 then
                  step = step * 2
                end
                col_state.last_note = math.max(1, math.min(col_state.last_note + step, #scale))
              end
              new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)

            elseif pattern_type == 14 then  -- "14 melodic_phrase"
              -- Generate scale-appropriate phrases
              local function get_safe_phrases(scale_length, is_even_column)
                local max_degree = math.min(5, scale_length)
                if is_even_column then
                  return {
                    {1, math.min(3, max_degree), 2, math.min(5, max_degree)},
                    {math.min(5, max_degree), math.min(4, max_degree), math.min(3, max_degree), 1},
                    {1, 2, math.min(3, max_degree), math.min(4, max_degree)}
                  }
                else
                  return {
                    {math.min(3, max_degree), 2, 1, 2},
                    {math.min(4, max_degree), 2, math.min(3, max_degree), 1},
                    {2, math.min(4, max_degree), math.min(3, max_degree), 1}
                  }
                end
              end
              
              local phrases = get_safe_phrases(#scale, column_idx % 2 == 0)
              local phrase_length = 4  -- Simplified to consistent length
              local phrase = phrases[math.floor(line_index / phrase_length) % #phrases + 1]
              local pos = phrase[line_index % #phrase + 1]
              new_note = self:quantize_to_scale(pos, scale_name, root_note, base_octave, config)

            elseif pattern_type == 15 then  -- "15 rhythmic_phrase"
              -- Different rhythms per column
              local rhythm = column_idx % 2 == 0
                and {1, 0, 1, 0, 1, 1, 0, 1}  -- Even columns
                or {1, 1, 0, 1, 0, 1, 0, 0}   -- Odd columns
              
              if rhythm[line_index % #rhythm + 1] == 1 then
                if col_state.last_note == nil then
                  col_state.last_note = col_random(#scale)  -- Use col_random
                else
                  local step = col_random(3) - 2  -- Use col_random for step size
                  col_state.last_note = col_state.last_note + step
                  while col_state.last_note < 1 do col_state.last_note = col_state.last_note + #scale end
                  while col_state.last_note > #scale do col_state.last_note = col_state.last_note - #scale end
                end
                new_note = self:quantize_to_scale(col_state.last_note, scale_name, root_note, base_octave, config)
              else
                new_note = self:quantize_to_scale(col_state.last_note or 1, scale_name, root_note, base_octave, config)
              end

            else  -- "1 random" (default)
              -- Add some column-specific variation to random
              local scale_pos = col_random(#scale)
              if column_idx % 2 == 1 then
                scale_pos = ((scale_pos + 2) % #scale) + 1
              end
              new_note = self:quantize_to_scale(scale_pos, scale_name, root_note, base_octave, config)
            end
            
            -- Keep within configured range
            new_note = math.min(math.max(new_note, config.note_range[1]), config.note_range[2])
            note_column.note_value = new_note
          end
        end
      end
    end
  end
end

-- Reset column state when starting new pattern
function GenQ:reset_column_state()
  self.column_state = {}
end

-- Call reset when processing new pattern
function GenQ:process_pattern_immediately(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
  self:reset_column_state()
  self:process_next_column(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
end

-- Weighted octave selection
function GenQ:get_octave(note_min, note_max, col_random_func)
  local min_oct = math.floor(note_min/12)
  local max_oct = math.floor(note_max/12)
  local mid_oct = math.floor((min_oct + max_oct) / 2)
  
  -- Even stronger weighting towards middle octaves
  local weights = {}
  for oct = min_oct, max_oct do
    -- Steeper exponential falloff
    local distance = math.abs(oct - mid_oct)
    weights[oct] = math.exp(-distance * 1.2)  -- Increased from 0.8 to 1.2
  end
  
  -- Even more weight to middle octave
  weights[mid_oct] = weights[mid_oct] * 3  -- Increased from 2 to 3
  
  -- Add weight to adjacent octaves
  if weights[mid_oct - 1] then weights[mid_oct - 1] = weights[mid_oct - 1] * 1.5 end
  if weights[mid_oct + 1] then weights[mid_oct + 1] = weights[mid_oct + 1] * 1.5 end
  
  -- Weighted random selection
  local total = 0
  for _, w in pairs(weights) do total = total + w end
  local r = (col_random_func and col_random_func() or math.random()) * total
  
  for oct, w in pairs(weights) do
    r = r - w
    if r <= 0 then return oct * 12 end
  end
  return mid_oct * 12
end

-- Add this helper function
function GenQ:quantize_to_scale(note_index, scale_name, root_note, octave, config)
  local scale = self:get_scale_intervals(scale_name)
  if not scale then
    renoise.app():show_status("Warning: Invalid scale " .. tostring(scale_name))
    scale = self.scales.major.intervals  -- Fallback to major scale
  end
  
  -- Ensure note_index is within scale bounds and not nil
  note_index = note_index or 1
  while note_index < 1 do note_index = note_index + #scale end
  while note_index > #scale do note_index = note_index - #scale end
  
  -- Get the scale degree and add octave and root
  local scale_note = scale[note_index]
  if not scale_note then
    renoise.app():show_status("Warning: Invalid scale index " .. tostring(note_index))
    scale_note = scale[1]  -- Fallback to root note
  end
  
  local new_note = scale_note + octave + root_note
  
  -- Ensure note stays within configured range if config is provided
  if config then
    -- First quantize to scale, then adjust octave
    local note_in_first_octave = (new_note - root_note) % 12
    local closest_scale_note = scale[1]  -- Default to root
    local min_distance = 12
    
    -- Find closest scale note
    for _, scale_interval in ipairs(scale) do
      local distance = math.abs(note_in_first_octave - scale_interval)
      if distance < min_distance then
        min_distance = distance
        closest_scale_note = scale_interval
      end
    end
    
    -- Reconstruct note with correct scale degree and original octave
    new_note = closest_scale_note + octave + root_note
    
    -- Then enforce range
    new_note = self:enforce_note_range(new_note, config)
  end
  
  return new_note
end

-- Add this helper function to enforce note range
function GenQ:enforce_note_range(note, config)
  if not note or not config then return note end
  
  -- First ensure we have valid range values
  local min_note = math.max(0, math.min(config.note_range[1], 119))
  local max_note = math.max(0, math.min(config.note_range[2], 119))
  
  -- Swap if min is greater than max
  if min_note > max_note then
    min_note, max_note = max_note, min_note
  end
  
  -- Try to keep note in range by octave shifts first
  while note < min_note and note + 12 <= max_note do note = note + 12 end
  while note > max_note and note - 12 >= min_note do note = note - 12 end
  
  -- Final clamp to ensure we're in range
  note = math.max(min_note, math.min(note, max_note))
  
  return note
end

-- Create a single instance of the tool
if not _tool_instance then
  _tool_instance = GenQ()
end
