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
  -- Keep all the existing scales
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
  self.selected_scale = options.selected_scale.value
  self.note_range = {
    options.note_range_min.value,
    options.note_range_max.value
  }
  self.active = false -- Toggles real-time processing

  -- Add trigger instrument property
  self.trigger_instrument = options.trigger_instrument.value

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
  self.pattern_types = {
    "random",
    "jazz_walk", 
    "modal_drift",
    "tension_release",
    "melodic_contour",
    "phrase_based",
    "markov",
    "euclidean",
    "melodic_sequence",
    "melodic_development",
    "melodic_phrase",
    "rhythmic_phrase"
  }
  self.current_pattern = options.current_pattern.value

  -- Add pattern memory
  self.pattern_memory = {
    last_patterns = {},    -- Store last N patterns
    common_motifs = {},    -- Store recurring motifs
    max_memory = 16       -- How many patterns to remember
  }
end

function GenQ:process_pattern()
  local song = renoise.song()
  local pattern = song.selected_pattern
  local track = pattern.tracks[song.selected_track_index]
 
  -- Only process note tracks
  if song.tracks[song.selected_track_index].type ~= renoise.Track.TRACK_TYPE_SEQUENCER then 
    return 
  end

  -- First, check if we have a C-0 in any note column
  for column_index = 1, track.visible_note_columns do
    -- Process each line in the pattern
    for line_index = 1, pattern.number_of_lines do
      local line = track:line(line_index)
      local note_column = line.note_columns[column_index]
      
      -- If we find C-0, randomize all notes in the next column
      if note_column and note_column.note_value == 0 then
        if track.visible_note_columns < 2 then track.visible_note_columns = 2 end
        -- Process all lines in the next column
        for process_line = 1, pattern.number_of_lines do
          local process_note = track:line(process_line).note_columns[column_index + 1]
          
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
  local vb = renoise.ViewBuilder()
  
  -- Create arrays for popup items with hex numbers
  local scale_items = {
    "00 Major", "01 Minor", "02 Harmonic Minor", "03 Melodic Minor",
    "04 Pentatonic", "05 Minor Pentatonic", "06 Dorian", "07 Phrygian",
    "08 Lydian", "09 Mixolydian", "10 Locrian", "11 Blues",
    "12 Whole Tone", "13 Diminished", "14 Augmented", "15 Chromatic",
    "16 Hungarian Minor", "17 Persian", "18 Japanese", "19 Arabic", "20 Bebop",
    "21 Prometheus", "22 Algerian", "23 Byzantine", "24 Egyptian", "25 Eight Tone",
    "26 Enigmatic", "27 Neapolitan", "28 Neapolitan Minor", "29 Romanian Minor",
    "30 Ukrainian Dorian", "31 Yo", "32 In Sen", "33 Bhairav", "34 Marva", "35 Purvi",
    "36 Todi", "37 Super Locrian", "38 Double Harmonic", "39 Hindu", "40 Kumoi",
    "41 Iwato", "42 Messiaen Mode 1", "43 Messiaen Mode 2", "44 Messiaen Mode 3",
    "45 Leading Whole Tone"
  }
  
  local scale_map = {
    "major", "minor", "harmonic_minor", "melodic_minor",
    "pentatonic", "minor_pentatonic", "dorian", "phrygian",
    "lydian", "mixolydian", "locrian", "blues",
    "whole_tone", "diminished", "augmented", "chromatic",
    "hungarian_minor", "persian", "japanese", "arabic", "bebop",
    "prometheus", "algerian", "byzantine", "egyptian", "eight_tone",
    "enigmatic", "neapolitan", "neapolitan_minor", "romanian_minor",
    "ukrainian_dorian", "yo", "in_sen", "bhairav", "marva", "purvi",
    "todi", "super_locrian", "double_harmonic", "hindu", "kumoi",
    "iwato", "messiaen1", "messiaen2", "messiaen3",
    "leading_whole_tone"
  }

  local dialog_content = vb:column {
    vb:row {
      vb:text { text = "Select Scale", width=125},
      vb:popup {
        items = scale_items, width=150,
        value = table.find(scale_map, self.selected_scale) or 1,
        notifier = function(index)
          self.selected_scale = scale_map[index]
          options.selected_scale.value = self.selected_scale
          renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR  
        end
      }
    },
    vb:row {
      vb:text { text = "Note Range (Low-High)", width=125 },
      vb:valuebox {
        min = 0,
        max = 127,
        value = self.note_range[1],
        notifier = function(value)
          self.note_range[1] = value
          options.note_range_min.value = value
          renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
        end
      },
      vb:valuebox {
        min = 0,
        max = 127,
        value = self.note_range[2],
        notifier = function(value)
          self.note_range[2] = value
          options.note_range_max.value = value
          renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
        end
      }
    },
    vb:row {
      vb:text { text = "Trigger Instrument",width=125 },
      vb:valuebox {
        min = 0,
        max = 255,
        value = self.trigger_instrument,
        notifier = function(value)
          self.trigger_instrument = value
          options.trigger_instrument.value = value
          renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
        end
      }
    },
    vb:row {
      vb:text { text = "Pattern Type", width=125 },
      vb:popup {
        items = self.pattern_types, width=150,
        value = table.find(self.pattern_types, self.current_pattern) or 1,
        notifier = function(index)
          self.current_pattern = self.pattern_types[index]
          options.current_pattern.value = self.current_pattern
          self.prev_note = nil
          renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
        end
      },
     
    },
      vb:row{vb:button{text="Process Pattern",width=125, notifier=function() 
      self:process_pattern()
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
      end}},
    
  }

  renoise.app():show_custom_dialog("Random Note Generator Settings", dialog_content, genq_keyhandler_func)
  renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
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
  -- Create an array of scale names in a fixed order
  local scale_list = {
    "major", "minor", "harmonic_minor", "melodic_minor",
    "pentatonic", "minor_pentatonic", "dorian", "phrygian",
    "lydian", "mixolydian", "locrian", "blues",
    "whole_tone", "diminished", "augmented", "chromatic",
    "hungarian_minor", "persian", "japanese", "arabic", "bebop",
    "prometheus", "algerian", "byzantine", "egyptian", "eight_tone",
    "enigmatic", "neapolitan", "neapolitan_minor", "romanian_minor",
    "ukrainian_dorian", "yo", "in_sen", "bhairav", "marva", "purvi",
    "todi", "super_locrian", "double_harmonic", "hindu", "kumoi",
    "iwato", "messiaen1", "messiaen2", "messiaen3",
    "leading_whole_tone"
  }
  
  -- Map volume (0-127) to scale index
  local scale_count = #scale_list
  local index = math.floor((volume / 80) * scale_count) + 1
  index = math.min(index, scale_count)
  
  return scale_list[index]
end

function GenQ:check_for_trigger()
  if not renoise.song() then return end
  if not renoise.song().transport.playing then return end

  local song = renoise.song()
  local pos = song.transport.playback_pos
  local pattern_index = song.sequencer:pattern(pos.sequence)
  local pattern = song.patterns[pattern_index]
  
  -- Look ahead one line
  local next_line = pos.line + 1
  local next_sequence = pos.sequence
  
  -- Handle pattern boundary
  if next_line > pattern.number_of_lines then
    next_line = 1
    next_sequence = pos.sequence + 1
    -- Wrap around sequence
    if next_sequence > #song.sequencer.pattern_sequence then
      next_sequence = 1
    end
    pattern_index = song.sequencer:pattern(next_sequence)
    pattern = song.patterns[pattern_index]
  end
  
  -- Process all tracks for the next line
  for track_index = 1, #pattern.tracks do
    local track = song.tracks[track_index]
    local pattern_track = pattern.tracks[track_index]
     
    -- Only process note tracks
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then 
      local line = pattern_track:line(next_line)  -- Look at next line

      -- Check each note column for notes in octave 0
      for column_index = 1, track.visible_note_columns do
        local note_column = line.note_columns[column_index]
        
        -- If we find any note in octave 0 (0-11) with the correct instrument
        if note_column and 
           note_column.note_value >= 0 and 
           note_column.note_value <= 11 and
           note_column.instrument_value == self.trigger_instrument then
          
          local root_note = note_column.note_value  -- Use this as our root note
          local scale_name = self:get_scale_from_volume(note_column.volume_value)
          
          -- Process all lines in the pattern using track_index instead of selected_track_index
          for line_index = 1, pattern.number_of_lines do
            local process_line = pattern_track:line(line_index)
            local next_column = process_line.note_columns[column_index + 1]
            
            -- Only process actual notes (not empty or OFF)
            if next_column and next_column.note_value > 0 and next_column.note_value < 120 then
              local scale = self.scales[scale_name]
              if not scale then
                print("Warning: Scale not found:", scale_name)
                scale = self.scales["major"]  -- Fallback to major scale
              end
              
              local note_min, note_max = self.note_range[1], self.note_range[2]
              
              -- Use improved note generation with error checking
              local scale_note = self:generate_note(scale, root_note, line_index)
              if not scale_note then
                print("Warning: No note generated, using random")
                scale_note = scale[math.random(#scale)]
              end
              
              local octave = self:get_octave(note_min, note_max)
              local new_note = scale_note + octave + root_note
              
              -- Keep within range
              new_note = math.min(math.max(new_note, note_min), note_max)
              
              next_column.note_value = new_note
            end
          end
        end
      end
    end
  end
end

-- Improved note generation with musical context
function GenQ:generate_note(scale, root_note, line_index)
  local pattern_funcs = {
    jazz_walk = function()
      if not self.prev_note then
        self.prev_note = scale[math.random(#scale)]
        self.direction = math.random() > 0.5 and 1 or -1
        return self.prev_note
      end

      -- Sometimes use chromatic approach notes
      if math.random() < 0.3 then
        self.prev_note = self.prev_note + self.direction
        self.direction = -self.direction -- Change direction after approach
        return self.prev_note
      else
        -- Target next scale note
        local current_pos = 1  -- Default to root if not found
        for i, note in ipairs(scale) do
          if note == (self.prev_note % 12) then
            current_pos = i
            break
          end
        end
        
        local target_pos = current_pos + self.direction
        if target_pos > #scale then target_pos = 1
        elseif target_pos < 1 then target_pos = #scale end
        
        self.prev_note = scale[target_pos]
        return self.prev_note
      end
    end,

    modal_drift = function()
      if not self.modal_state then
        self.modal_state = {
          strong_degrees = {1, 3, 5}, -- Start with triad degrees
          current_degree = 1,
          drift_counter = 0
        }
      end
      
      -- Occasionally change the emphasized degrees
      self.modal_state.drift_counter = self.modal_state.drift_counter + 1
      if self.modal_state.drift_counter > 8 then
        self.modal_state.drift_counter = 0
        -- Change one of the strong degrees
        local idx = math.random(#self.modal_state.strong_degrees)
        self.modal_state.strong_degrees[idx] = math.random(#scale)
      end

      -- Higher chance to use strong degrees
      if math.random() < 0.7 then
        self.prev_note = scale[self.modal_state.strong_degrees[math.random(#self.modal_state.strong_degrees)]]
      else
        self.prev_note = scale[math.random(#scale)]
      end
      return self.prev_note
    end,

    tension_release = function()
      if not self.tension_state then
        self.tension_state = {
          tension = 0, -- 0 to 1
          phrase_pos = 0
        }
      end
      
      self.tension_state.phrase_pos = self.tension_state.phrase_pos + 1
      if self.tension_state.phrase_pos > 8 then
        self.tension_state.phrase_pos = 1
        self.tension_state.tension = 0
      end
      
      -- Build tension through the phrase
      self.tension_state.tension = self.tension_state.tension + 0.125
      
      -- Higher tension = wider intervals and more dissonant notes
      if self.tension_state.tension > 0.7 then
        -- Use more dissonant intervals
        local intervals = {1, 6, 8, 10}
        self.prev_note = scale[intervals[math.random(#intervals)]]
      elseif self.tension_state.tension > 0.4 then
        -- Use wider consonant intervals
        local intervals = {2, 5, 7}
        self.prev_note = scale[intervals[math.random(#intervals)]]
      else
        -- Resolution - use stable intervals
        local intervals = {1, 3, 5}
        self.prev_note = scale[intervals[math.random(#intervals)]]
      end
      return self.prev_note
    end,

    melodic_contour = function()
      if not self.contour_state then
        self.contour_state = {
          direction = 1,
          step_size = 1,
          phrase_length = math.random(4, 8),
          position = 0,
          target_note = nil
        }
      end
      
      self.contour_state.position = (self.contour_state.position + 1) % self.contour_state.phrase_length
      
      if self.contour_state.position == 0 then
        -- Start new phrase
        self.contour_state.direction = math.random() > 0.5 and 1 or -1
        self.contour_state.step_size = math.random(1, 3)
        self.contour_state.phrase_length = math.random(4, 8)
        -- Pick target note from scale
        self.contour_state.target_note = scale[math.random(#scale)]
      end
      
      if not self.prev_note then
        self.prev_note = scale[math.random(#scale)]
      else
        -- Move towards target note
        local current_pos = table.find(scale, self.prev_note % 12)
        local target_pos = table.find(scale, self.contour_state.target_note)
        local step = current_pos < target_pos and 1 or -1
        current_pos = current_pos + step * self.contour_state.step_size
        
        -- Wrap around scale
        while current_pos > #scale do current_pos = current_pos - #scale end
        while current_pos < 1 do current_pos = current_pos + #scale end
        
        self.prev_note = scale[current_pos]
      end
      
      return self.prev_note
    end,

    phrase_based = function()
      if not self.phrase_state then
        self.phrase_state = {
          phrase = {},
          position = 0,
          variation = 0
        }
        -- Generate initial phrase
        for i = 1, 4 do
          self.phrase_state.phrase[i] = scale[math.random(#scale)]
        end
      end
      
      self.phrase_state.position = (self.phrase_state.position + 1) % 4
      
      if self.phrase_state.position == 0 then
        -- Vary the phrase slightly
        self.phrase_state.variation = (self.phrase_state.variation + 1) % 3
        if self.phrase_state.variation == 0 then
          -- Modify one note in the phrase
          local idx = math.random(4)
          local current = table.find(scale, self.phrase_state.phrase[idx])
          local step = math.random(-2, 2)
          current = ((current + step - 1) % #scale) + 1
          self.phrase_state.phrase[idx] = scale[current]
        end
      end
      
      return self.phrase_state.phrase[self.phrase_state.position + 1]
    end,

    markov = function()
      if not self.markov_state then
        -- Initialize with default transitions
        self.markov_state = {
          transitions = {
            -- Default transitions for any position
            default = {
              [1] = {[1]=0.1, [3]=0.4, [5]=0.4, [7]=0.1},
              [2] = {[1]=0.2, [3]=0.4, [4]=0.2, [6]=0.2},
              [3] = {[2]=0.3, [4]=0.3, [5]=0.2, [6]=0.2},
              [4] = {[3]=0.3, [5]=0.3, [6]=0.2, [7]=0.2},
              [5] = {[1]=0.4, [3]=0.3, [7]=0.3},
              [6] = {[4]=0.2, [5]=0.6, [7]=0.2},
              [7] = {[1]=0.5, [3]=0.3, [5]=0.2}
            }
          },
          current_degree = 1,
          phrase_pos = 0,
          phrase_length = 8
        }
      end

      -- Update phrase position
      self.markov_state.phrase_pos = (self.markov_state.phrase_pos + 1) % self.markov_state.phrase_length
      
      -- Use default transitions
      local transitions = self.markov_state.transitions.default
      
      -- Select next note based on transitions
      local current_transitions = transitions[self.markov_state.current_degree]
      if not current_transitions then
        self.markov_state.current_degree = 1
        current_transitions = transitions[1]
      end

      -- Calculate next degree using transition probabilities
      local r = math.random()
      local sum = 0
      for next_degree, prob in pairs(current_transitions) do
        sum = sum + prob
        if r <= sum then
          self.markov_state.current_degree = next_degree
          break
        end
      end

      return scale[self.markov_state.current_degree]
    end,

    euclidean = function()
      if not self.euclidean_state then
        self.euclidean_state = {
          steps = 8,           -- Total steps in pattern
          pulses = 3,          -- Number of active pulses
          position = 0,        -- Current position
          pattern = {},        -- Will hold the euclidean pattern
          scale_positions = {} -- Will hold scale degrees for active pulses
        }
        
        -- Generate Euclidean pattern
        local pattern = {}
        local bucket = 0
        for i = 1, self.euclidean_state.steps do
          bucket = bucket + self.euclidean_state.pulses
          if bucket >= self.euclidean_state.steps then
            bucket = bucket - self.euclidean_state.steps
            pattern[i] = true
          else
            pattern[i] = false
          end
        end
        self.euclidean_state.pattern = pattern
        
        -- Assign scale degrees to active pulses
        local pulse_count = 0
        for i = 1, #pattern do
          if pattern[i] then
            pulse_count = pulse_count + 1
            -- Use different scale degrees for each pulse
            self.euclidean_state.scale_positions[i] = 
              math.floor(pulse_count * #scale / self.euclidean_state.pulses)
          end
        end
      end
      
      -- Advance position
      self.euclidean_state.position = 
        (self.euclidean_state.position + 1) % self.euclidean_state.steps
      
      -- Return note based on current position
      if self.euclidean_state.pattern[self.euclidean_state.position + 1] then
        local scale_pos = self.euclidean_state.scale_positions[self.euclidean_state.position + 1]
        return scale[scale_pos]
      else
        -- For non-active positions, return previous note or random note
        return self.prev_note or scale[math.random(#scale)]
      end
    end,

    melodic_phrase = function()
      if not self.phrase_state then
        self.phrase_state = {
          length = math.random(4, 8),
          position = 0,
          notes = {},
          direction = 1,
          pattern = {1, 2, 0, 1, 2, 1, 0, 2}  -- Add rhythm pattern
        }
        -- Generate initial phrase
        local current = math.random(#scale)
        for i = 1, self.phrase_state.length do
          self.phrase_state.notes[i] = scale[current]
          -- Move stepwise with occasional leaps
          if math.random() < 0.2 then
            current = math.random(#scale)  -- Leap
          else
            current = ((current + self.phrase_state.direction - 1) % #scale) + 1  -- Step
            if math.random() < 0.3 then
              self.phrase_state.direction = -self.phrase_state.direction  -- Change direction
            end
          end
        end
      end
      
      self.phrase_state.position = (self.phrase_state.position + 1) % 8
      local strength = self.phrase_state.pattern[self.phrase_state.position + 1]
      
      if strength == 1 then
        return scale[math.random(#scale)]  -- Strong beat - any note
      elseif strength == 2 then
        -- Medium beat - stay close to previous
        local current = table.find(scale, self.prev_note % 12)
        local step = math.random(-2, 2)
        return scale[((current + step - 1) % #scale) + 1]
      else
        -- Weak beat - use base note or nearby
        return self.phrase_state.base_note
      end
    end,

    rhythmic_phrase = function()
      if not self.rhythm_state then
        self.rhythm_state = {
          pattern = {1, 0, 2, 0, 1, 2, 0, 1},  -- 1 = accent, 2 = normal, 0 = quiet
          position = 0,
          base_note = scale[math.random(#scale)]
        }
      end
      
      self.rhythm_state.position = (self.rhythm_state.position + 1) % 8
      local strength = self.rhythm_state.pattern[self.rhythm_state.position + 1]
      
      if strength == 1 then
        return scale[math.random(#scale)]  -- Strong beat - any note
      elseif strength == 2 then
        -- Medium beat - stay close to previous
        local current = table.find(scale, self.prev_note % 12)
        local step = math.random(-2, 2)
        return scale[((current + step - 1) % #scale) + 1]
      else
        -- Weak beat - use base note or nearby
        return self.rhythm_state.base_note
      end
    end,

    melodic_development = function()
      if not self.development_state then
        self.development_state = {
          motif = {},
          variations = {},
          current_variation = 1,
          position = 0,
          -- Transformation types
          transforms = {
            'original',
            'retrograde',
            'inversion',
            'retrograde_inversion',
            'augmentation',
            'diminution'
          }
        }
        
        -- Generate initial motif
        for i = 1, 4 do
          self.development_state.motif[i] = scale[math.random(#scale)]
        end
        
        -- Generate variations
        for _, transform in ipairs(self.development_state.transforms) do
          local variation = {}
          if transform == 'retrograde' then
            for i = 1, 4 do
              variation[i] = self.development_state.motif[5-i]
            end
          elseif transform == 'inversion' then
            for i = 1, 4 do
              local interval = self.development_state.motif[i] - self.development_state.motif[1]
              variation[i] = self.development_state.motif[1] - interval
            end
          -- Add other transformations...
          end
          table.insert(self.development_state.variations, variation)
        end
      end
      
      -- Use variations in sequence
      local current_var = self.development_state.variations[self.development_state.current_variation]
      local note = current_var[self.development_state.position + 1]
      
      -- Update positions
      self.development_state.position = (self.development_state.position + 1) % 4
      if self.development_state.position == 0 then
        self.development_state.current_variation = 
          (self.development_state.current_variation % #self.development_state.variations) + 1
      end
      
      return note
    end,

    melodic_sequence = function()
      if not self.sequence_state then
        self.sequence_state = {
          sequence = {},
          position = 0,
          length = 4,
          transpositions = {0, 2, -1, 1}  -- Sequence variations
        }
        -- Generate initial sequence
        for i = 1, self.sequence_state.length do
          self.sequence_state.sequence[i] = scale[math.random(#scale)]
        end
      end
      
      local base_note = self.sequence_state.sequence[self.sequence_state.position + 1]
      local transpose = self.sequence_state.transpositions[math.floor(line_index / 4) % 4 + 1]
      self.sequence_state.position = (self.sequence_state.position + 1) % self.sequence_state.length
      
      return base_note + transpose
    end,

    adaptive = function()
      if not self.adaptive_state then
        self.adaptive_state = {
          motif_length = math.random(2, 4),
          variations = 0,
          last_motif = {},
          tension = 0
        }
        -- Learn from existing patterns
        self.adaptive_state.motif = self:analyze_pattern(current_pattern)
      end
      -- Generate variations based on analysis
    end
  }

  -- Use pattern function if it exists, otherwise use random selection
  if pattern_funcs[self.current_pattern] then
    return pattern_funcs[self.current_pattern](line_index)
  else
    -- Default random behavior
    if not self.prev_note then
      self.prev_note = scale[math.random(#scale)]
    else
      -- Prefer notes closer to previous note
      local nearby_notes = {}
      for _, note in ipairs(scale) do
        if math.abs(note - self.prev_note) <= 4 then  -- within a third
          table.insert(nearby_notes, note)
        end
      end
      self.prev_note = #nearby_notes > 0 
        and nearby_notes[math.random(#nearby_notes)] 
        or scale[math.random(#scale)]
    end
    return self.prev_note
  end
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

-- Create a single instance of the tool
if not _tool_instance then
  _tool_instance = GenQ()
end
