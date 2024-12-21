-- Add at the very top of the file, after _AUTO_RELOAD_DEBUG = true
_AUTO_RELOAD_DEBUG = true

-- Declare global variables
_tool_instance = nil
local options = renoise.Document.create("GenQSettings") {
  selected_scale = "major",
  note_range_min = 24,
  note_range_max = 84,
  trigger_instrument = 1,
  current_pattern = "random"
}

-- Save preferences when they change
renoise.tool().preferences = options

class 'GenQ'

function GenQ:__init()
  -- Initialize scale_map first with ALL scales in hex format (1-based)
  self.scale_map = {
    "01 major", "02 minor", "03 harmonic_minor", "04 melodic_minor",
    "05 pentatonic", "06 minor_pentatonic", "07 dorian", "08 phrygian",
    "09 lydian", "0A mixolydian", "0B locrian", "0C blues",
    "0D whole_tone", "0E diminished", "0F augmented", "10 chromatic",
    "11 hungarian_minor", "12 persian", "13 japanese", "14 arabic",
    "15 bebop", "16 prometheus", "17 algerian", "18 byzantine",
    "19 egyptian", "1A eight_tone", "1B enigmatic", "1C neapolitan",
    "1D neapolitan_minor", "1E romanian_minor", "1F ukrainian_dorian", "20 yo",
    "21 in_sen", "22 bhairav", "23 marva", "24 purvi",
    "25 todi", "26 super_locrian", "27 double_harmonic", "28 hindu",
    "29 kumoi", "2A iwato", "2B messiaen1", "2C messiaen2",
    "2D messiaen3", "2E leading_whole_tone"
  }

  -- Update pattern types with hex numbers
  self.pattern_types = {
    "01 random",
    "02 up",
    "03 down", 
    "04 random_walk",
    "05 jazz_walk",
    "06 modal_drift",
    "07 tension_release",
    "08 melodic_contour",
    "09 phrase_based",
    "0A markov",
    "0B euclidean",
    "0C melodic_sequence",
    "0D melodic_development",
    "0E melodic_phrase",
    "0F rhythmic_phrase"
  }

  -- Then initialize scales
  self.scales = {
    major = {0, 2, 4, 5, 7, 9, 11},
    minor = {0, 2, 3, 5, 7, 8, 10},
    harmonic_minor = {0, 2, 3, 5, 7, 8, 11},
    melodic_minor = {0, 2, 3, 5, 7, 9, 11},
    pentatonic = {0, 2, 4, 7, 9},
    minor_pentatonic = {0, 3, 5, 7, 10},
    dorian = {0, 2, 3, 5, 7, 9, 10},
    phrygian = {0, 1, 3, 5, 7, 8, 10},
    lydian = {0, 2, 4, 6, 7, 9, 11},
    mixolydian = {0, 2, 4, 5, 7, 9, 10},
    locrian = {0, 1, 3, 5, 6, 8, 10},
    blues = {0, 3, 5, 6, 7, 10},
    whole_tone = {0, 2, 4, 6, 8, 10},
    diminished = {0, 2, 3, 5, 6, 8, 9, 11},
    augmented = {0, 3, 4, 7, 8, 11},
    chromatic = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
    hungarian_minor = {0, 2, 3, 6, 7, 8, 11},
    persian = {0, 1, 4, 5, 6, 8, 11},
    japanese = {0, 2, 3, 7, 8},
    arabic = {0, 2, 4, 5, 6, 8, 10},
    bebop = {0, 2, 4, 5, 7, 9, 10, 11},
    prometheus = {0, 2, 4, 6, 9, 10},
    algerian = {0, 2, 3, 6, 7, 8, 11},
    byzantine = {0, 1, 4, 5, 7, 8, 11},
    egyptian = {0, 2, 5, 7, 10},
    eight_tone = {0, 2, 3, 4, 6, 7, 9, 10},
    enigmatic = {0, 1, 4, 6, 8, 10, 11},
    neapolitan = {0, 1, 3, 5, 7, 9, 11},
    neapolitan_minor = {0, 1, 3, 5, 7, 8, 11},
    romanian_minor = {0, 2, 3, 6, 7, 9, 10},
    ukrainian_dorian = {0, 2, 3, 6, 7, 9, 10},
    yo = {0, 2, 5, 7, 9},
    in_sen = {0, 1, 5, 7, 10},
    bhairav = {0, 1, 4, 5, 7, 8, 11},
    marva = {0, 1, 4, 6, 7, 9, 11},
    purvi = {0, 1, 4, 6, 7, 8, 11},
    todi = {0, 1, 3, 6, 7, 8, 11},
    super_locrian = {0, 1, 3, 4, 6, 8, 10},
    double_harmonic = {0, 1, 4, 5, 7, 8, 11},
    hindu = {0, 2, 4, 5, 7, 8, 10},
    kumoi = {0, 2, 3, 7, 9},
    iwato = {0, 1, 5, 6, 10},
    messiaen1 = {0, 2, 4, 6, 8, 10},
    messiaen2 = {0, 1, 3, 4, 6, 7, 9, 10},
    messiaen3 = {0, 2, 3, 4, 6, 7, 8, 10, 11},
    leading_whole_tone = {0, 2, 4, 6, 8, 10, 11}
  }

  -- Initialize properties
  self.selected_scale = "major"
  self.selected_pattern = 1
  self.note_range = {40, 80}
  self.trigger_instrument = 1

  -- Add menu entries
  renoise.tool():add_menu_entry{name="Main Menu:Tools:Random Note Generator:Process Pattern",invoke=function() self:process_pattern() end}
  renoise.tool():add_menu_entry{name="Main Menu:Tools:Random Note Generator:Configure Settings",invoke=function() self:show_gui() end}

  -- Remove the previous notifier code and replace with:
  renoise.tool().app_idle_observable:add_notifier(function()
    self:check_for_trigger()
  end)

  -- Add properties for musical context
  self.prev_note = nil
  self.pattern_index = 1
  self.current_pattern = options.current_pattern.value

  -- Add pattern memory
  self.pattern_memory = {
    last_patterns = {},    -- Store last N patterns
    common_motifs = {},    -- Store recurring motifs
    max_memory = 16       -- How many patterns to remember
  }

  -- Initialize current pattern type
  self.current_pattern_type = 1
end

function GenQ:process_pattern()
  local song = renoise.song()
  local pattern = song.selected_pattern
  local track = song.selected_track
 
  -- Only process note tracks
  if track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER then 
    return
  end

  -- First, check if we have a C-0 in any note column
  for column_index = 1, track.visible_note_columns do
    -- Process each line in the pattern
    for line_index = 1, pattern.number_of_lines do
      local line = pattern:track(song.selected_track_index):line(line_index)
      local note_column = line.note_columns[column_index]
      
      -- If we find C-0, randomize all notes in the next column
      if note_column and note_column.note_value == 0 then
        if track.visible_note_columns < 2 then track.visible_note_columns = 2 end
        -- Process all lines in the next column
        for process_line = 1, pattern.number_of_lines do
          local process_note = pattern:track(song.selected_track_index):line(process_line).note_columns[column_index + 1]
          
          -- Only process actual notes (not empty or OFF)
          if process_note and process_note.note_value > 0 and process_note.note_value < 120 then
            -- Generate random note in selected scale
            local scale = self.scales[self.selected_scale]
            local note_min, note_max = self.note_range[1], self.note_range[2]
            
            -- Get random scale degree and octave
            local scale_note = scale[math.random(#scale)]
            local octave = math.random(math.floor(note_min/12), math.floor(note_max/12)) * 12
            local new_note = scale_note + octave
            
            -- Keep within range
            new_note = math.min(math.max(new_note, note_min), note_max)
            
            -- Update the note
            process_note.note_value = new_note
          end
        end
        -- Break after finding C-0 as we've processed the next column
        break
      end
    end
  end
  
  renoise.app():show_status("Processed pattern with " .. self.selected_scale .. " scale")
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
            text = "Trigger Instrument",
            width = 100
          },
          
          vb:valuebox {
            id = "trigger_instrument",
            min = 1,
            max = 255,
            value = self.trigger_instrument,
            width = 50,
            notifier = function(value)
              self.trigger_instrument = value
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
        },
        
        vb:row {
          spacing = CONTENT_SPACING,
          margin = CONTENT_MARGIN,
          
          vb:button {
            text = "Process Pattern",
            width = 100,
            notifier = function()
              local song = renoise.song()
              local pattern = song.patterns[song.selected_pattern_index]
              local track = song.selected_track_index
              local column = song.selected_note_column_index or 1
              
              self:process_pattern_immediately(
                track,
                pattern,
                column,
                0,  -- root note
                self.selected_scale,
                self.selected_pattern
              )
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


function GenQ:get_scale_from_volume(volume)
  -- Volume values should be 1-based (01 = major, 02 = minor, etc.)
  -- No need to add 1 since we want volume 01 to map to index 1
  local scale_entry = self.scale_map[volume]  -- Remove the +1
  if not scale_entry then return "major" end  -- default fallback
  
  -- Extract just the scale name (everything after the space)
  local scale_name = scale_entry:match("%x%x%s+(.+)")
  
  -- Add debug output
  renoise.app():show_status(string.format("Volume %02X -> scale: %s (index %d)", 
    volume, scale_name, volume))
  
  return scale_name
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
    return {
      note_range = {tonumber(min), tonumber(max)},
      display_name = display_name
    }
  end
  
  return nil
end

function GenQ:get_pattern_from_panning(panning_value)
  if not panning_value then 
    print("No panning value provided")
    return 1 
  end
  
  -- Map panning value to pattern type number
  -- Panning 01 -> "01 random"
  -- Panning 0C -> "0C melodic_sequence" etc.
  local pattern_index = panning_value
  
  -- Ensure we never return 0 and stay within valid pattern indices
  if pattern_index < 1 then pattern_index = 1 end
  pattern_index = math.min(pattern_index, #self.pattern_types)
  
  -- Add debug output to Renoise console
  renoise.app():show_status(string.format("Panning %02X -> pattern: %s", 
    panning_value, self.pattern_types[pattern_index]))
  
  return pattern_index
end

function GenQ:check_for_trigger()
  if not renoise.song() then return end
  if not renoise.song().transport.playing then return end

  local song = renoise.song()
  local pos = song.transport.playback_pos
  local pattern_index = song.sequencer:pattern(pos.sequence)
  local current_pattern = song.patterns[pattern_index]
  
  local process_line = pos.line
  if pos.line > 1 then
    process_line = pos.line + 1
  end
  
  for track_index = 1, #song.tracks do
    local track = song.tracks[track_index]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then 
      local pattern_track = current_pattern:track(track_index)
      local line = pattern_track:line(process_line)

      for column_index = 1, track.visible_note_columns do
        local note_column = line.note_columns[column_index]
        
        if note_column and 
           note_column.note_value >= 0 and 
           note_column.note_value <= 11 and
           note_column.instrument_value == self.trigger_instrument - 1 then
          
          local root_note = note_column.note_value
          local scale_name = self:get_scale_from_volume(note_column.volume_value)
          local pattern_type = self:get_pattern_from_panning(note_column.panning_value)
          
          -- Store the current pattern type
          self.current_pattern_type = pattern_type
          
          -- Update GUI if visible
          if self.vb and self.dialog and self.dialog.visible then
            if self.vb.views.scale_popup then
              -- Find the scale index by matching the volume value directly
              local scale_index = note_column.volume_value  -- Remove the +1
              self.vb.views.scale_popup.value = scale_index
            end
            if self.vb.views.pattern_popup then
              -- Add debug output
              print(string.format("Updating pattern popup to index: %d", pattern_type))
              self.vb.views.pattern_popup.value = pattern_type
            end
          end
          
          if pos.line == 1 then
            self:process_pattern_immediately(track_index, current_pattern, column_index, root_note, scale_name, pattern_type)
          else
            self:process_next_column(track_index, current_pattern, column_index, root_note, scale_name, pattern_type)
          end
        end
      end
    end
  end
end

function GenQ:process_next_column(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
  local song = renoise.song()
  
  -- Process all tracks in the pattern
  for track_idx = 1, #pattern.tracks do
    local track = song.tracks[track_idx]
    local pattern_track = pattern:track(track_idx)
    
    -- Process all note columns in this track
    for column_idx = 1, track.visible_note_columns do
      -- Keep track of the last note for patterns that need it
      local last_note = nil
      
      for line_index = 1, pattern.number_of_lines do
        local line = pattern_track:line(line_index)
        local note_column = line.note_columns[column_idx]
        
        if note_column and note_column.note_value > 0 and note_column.note_value < 120 then
          -- Check if this note's instrument has GENQ config
          local config = self:get_instrument_config(note_column.instrument_value + 1)
          if config then
            local scale = self.scales[scale_name]
            local new_note = nil
            
            -- Handle different pattern types
            if pattern_type == 2 then  -- "2 up" pattern
              if last_note == nil then
                last_note = 1
              else
                last_note = (last_note % #scale) + 1
              end
              
              local base_octave = self:get_octave(config.note_range[1], config.note_range[2])
              local octave_shift = math.floor((line_index - 1) / #scale) * 12
              new_note = scale[last_note] + base_octave + octave_shift + root_note

            elseif pattern_type == 3 then  -- "3 down" pattern
              if last_note == nil then
                last_note = #scale
              else
                last_note = last_note - 1
                if last_note < 1 then 
                  last_note = #scale
                end
              end
              
              local base_octave = self:get_octave(config.note_range[1], config.note_range[2])
              local octave_shift = -math.floor((line_index - 1) / #scale) * 12
              new_note = scale[last_note] + base_octave + octave_shift + root_note

            elseif pattern_type == 4 then  -- "4 random_walk"
              if last_note == nil then
                last_note = math.random(1, #scale)
              else
                local direction = math.random(2) == 1 and 1 or -1
                last_note = last_note + direction
                if last_note < 1 then last_note = #scale
                elseif last_note > #scale then last_note = 1 end
              end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 5 then  -- "5 jazz_walk"
              if last_note == nil then
                last_note = math.random(1, #scale)
              else
                local intervals = {2, 2, 2, 3, 3, 4, 4, 5}  -- weighted towards common jazz intervals
                local interval = intervals[math.random(#intervals)]
                last_note = last_note + (math.random(2) == 1 and interval or -interval)
                while last_note < 1 do last_note = last_note + #scale end
                while last_note > #scale do last_note = last_note - #scale end
              end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 6 then  -- "6 modal_drift"
              local shift = math.floor(line_index / 4) % #scale
              local pos = ((line_index - 1) % #scale) + 1
              local shifted_pos = ((pos + shift - 1) % #scale) + 1
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[shifted_pos] + octave + root_note

            elseif pattern_type == 7 then  -- "7 tension_release"
              if last_note == nil then
                last_note = math.random(1, #scale)
              else
                if line_index % 8 < 6 then  -- tension phase
                  last_note = last_note + 1
                  if last_note > #scale then last_note = 1 end
                else  -- release phase
                  last_note = math.max(1, last_note - math.random(3, 5))
                end
              end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 8 then  -- "8 melodic_contour"
              local wave = math.sin(line_index * 0.5)
              local pos = math.floor((wave + 1) * (#scale / 2))
              pos = math.max(1, math.min(pos, #scale))
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[pos] + octave + root_note

            elseif pattern_type == 9 then  -- "9 phrase_based"
              local phrase_pos = line_index % 16
              if phrase_pos == 0 or last_note == nil then
                last_note = math.random(1, #scale)  -- phrase start
              elseif phrase_pos % 4 == 0 then
                last_note = last_note + (math.random(2) == 1 and 2 or -2)  -- phrase variation
              end
              while last_note < 1 do last_note = last_note + #scale end
              while last_note > #scale do last_note = last_note - #scale end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 10 then  -- "10 markov"
              if not self.markov_transitions then
                self.markov_transitions = {}
                for i = 1, #scale do
                  self.markov_transitions[i] = {}
                  for j = 1, #scale do
                    local interval = math.abs(i - j)
                    self.markov_transitions[i][j] = math.exp(-interval * 0.5)
                  end
                end
              end
              
              if last_note == nil then
                last_note = math.random(1, #scale)
              else
                local probs = self.markov_transitions[last_note]
                local total = 0
                for _, p in ipairs(probs) do total = total + p end
                local r = math.random() * total
                for i, p in ipairs(probs) do
                  r = r - p
                  if r <= 0 then
                    last_note = i
                    break
                  end
                end
              end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 11 then  -- "11 euclidean"
              local steps = #scale
              local pulses = math.ceil(steps * 0.4)  -- 40% density
              local position = line_index % steps
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              if (position * pulses) % steps < pulses then
                new_note = scale[math.random(#scale)] + octave + root_note
              else
                new_note = scale[last_note or 1] + octave + root_note
              end

            elseif pattern_type == 12 then  -- "12 melodic_sequence"
              local sequence = {2, 4, 1, 3}  -- example sequence
              local pos = sequence[(line_index % #sequence) + 1]
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[pos] + octave + root_note

            elseif pattern_type == 13 then  -- "13 melodic_development"
              if line_index % 8 == 0 or last_note == nil then
                last_note = math.random(1, #scale)  -- new phrase
              else
                local variation = math.floor(line_index / 8)  -- increase variation over time
                local step = math.random(-variation, variation)
                last_note = math.max(1, math.min(last_note + step, #scale))
              end
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[last_note] + octave + root_note

            elseif pattern_type == 14 then  -- "14 melodic_phrase"
              local phrases = {
                {1, 3, 2, 5}, {5, 4, 3, 1}, {1, 2, 3, 5, 4}, {3, 2, 1, 2}
              }
              local phrase = phrases[math.floor(line_index / 4) % #phrases + 1]
              local pos = phrase[line_index % #phrase + 1]
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale[pos] + octave + root_note

            elseif pattern_type == 15 then  -- "15 rhythmic_phrase"
              local rhythm = {1, 0, 1, 0, 1, 1, 0, 1}  -- example rhythm
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              if rhythm[line_index % #rhythm + 1] == 1 then
                if last_note == nil then
                  last_note = math.random(1, #scale)
                else
                  last_note = last_note + (math.random(3) - 2)  -- small steps
                  while last_note < 1 do last_note = last_note + #scale end
                  while last_note > #scale do last_note = last_note - #scale end
                end
                new_note = scale[last_note] + octave + root_note
              else
                new_note = scale[last_note or 1] + octave + root_note
              end

            else  -- "1 random" (default)
              local scale_note = scale[math.random(#scale)]
              local octave = self:get_octave(config.note_range[1], config.note_range[2])
              new_note = scale_note + octave + root_note
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

-- Update process_pattern_immediately similarly
function GenQ:process_pattern_immediately(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
  -- Same code as process_next_column
  self:process_next_column(track_index, pattern, trigger_column_index, root_note, scale_name, pattern_type)
end

-- Weighted octave selection
function GenQ:get_octave(note_min, note_max)
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
  local r = math.random() * total
  
  for oct, w in pairs(weights) do
    r = r - w
    if r <= 0 then return oct * 12 end
  end
  return mid_oct * 12
end

function GenQ:analyze_pattern(pattern)
  local analysis = {
    intervals = {},      -- Common intervals used
    rhythmic_density = 0, -- Notes per line
    range = {min = 127, max = 0},
    common_sequences = {}
  }
  -- Analyze existing pattern to inform generation
  return analysis
end

function GenQ:get_phrase_position(line_index)
  -- Track where we are in musical phrases
  local phrase_length = 8
  local position = line_index % phrase_length
  local is_phrase_start = position == 0
  local is_phrase_end = position == phrase_length - 1
  
  return {
    position = position,
    strength = is_phrase_start and 3 or (position % 2 == 0 and 2 or 1),
    is_start = is_phrase_start,
    is_end = is_phrase_end
  }
end

function GenQ:save_instrument_config(instrument_index, min, max, display_name)
  local song = renoise.song()
  local instrument = song.instruments[instrument_index]
  if not instrument then return end
  
  -- Format: GENQ:min:max|Display Name
  local config = string.format(
    "GENQ:%d:%d|%s",
    min,
    max,
    display_name or ""
  )
  
  instrument.name = config
end

-- Create a single instance of the tool
if not _tool_instance then
  _tool_instance = GenQ()
end
