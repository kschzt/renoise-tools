-- Random Note Generator and Quantizer for Renoise
_AUTO_RELOAD_DEBUG = true

-- Declare global tool instance
_tool_instance = nil

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
  self.selected_scale = "major"
  self.note_range = {24, 84}  -- Default range C2-B6
  self.active = false -- Toggles real-time processing

  -- Add trigger instrument property
  self.trigger_instrument = 1  -- Default to instrument 01

  -- Add menu entries
  renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:Random Note Generator:Process Pattern",
    invoke = function() self:process_pattern() end
  }
  renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:Random Note Generator:Configure Settings",
    invoke = function() self:show_gui() end
  }

  -- Remove the previous notifier code and replace with:
  renoise.tool().app_idle_observable:add_notifier(function()
    self:check_for_trigger()
  end)

  -- Add properties for musical context
  self.prev_note = nil
  self.pattern_index = 1
  self.pattern_types = {
    "random", -- keep the basic random as fallback
    "jazz_walk", -- chromatic approach notes, target notes from scale
    "modal_drift", -- emphasize certain scale degrees, drift between modes
    "tension_release", -- build tension with wider intervals then resolve
    "call_response", -- alternate between question/answer phrases
    "rhythmic_cycle", -- based on polyrhythmic cycles (3,4,5,7)
    "motivic", -- develop short motifs with variations
    "harmonic_series" -- use harmonic series relationships
  }
  self.current_pattern = "random"
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
    "00 Major", "08 Minor", "10 Harmonic Minor", "18 Melodic Minor",
    "20 Pentatonic", "28 Minor Pentatonic", "30 Dorian", "38 Phrygian",
    "40 Lydian", "48 Mixolydian", "50 Locrian", "58 Blues",
    "60 Whole Tone", "68 Diminished", "70 Augmented", "78 Chromatic",
    "80 Hungarian Minor", "88 Persian", "90 Japanese", "98 Arabic", "A0 Bebop",
    "A8 Prometheus", "B0 Algerian", "B8 Byzantine", "C0 Egyptian", "C8 Eight Tone",
    "D0 Enigmatic", "D8 Neapolitan", "E0 Neapolitan Minor", "E8 Romanian Minor",
    "F0 Ukrainian Dorian", "F8 Yo", "FF In Sen", "01 Bhairav", "09 Marva", "11 Purvi",
    "19 Todi", "21 Super Locrian", "29 Double Harmonic", "31 Hindu", "39 Kumoi",
    "41 Iwato", "49 Messiaen Mode 1", "51 Messiaen Mode 2", "59 Messiaen Mode 3",
    "61 Leading Whole Tone"
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
      vb:text { text = "Select Scale:" },
      vb:popup {
        items = scale_items,
        value = table.find(scale_map, self.selected_scale) or 1,
        notifier = function(index)
          self.selected_scale = scale_map[index]
        end
      }
    },
    vb:row {
      vb:text { text = "Note Range (Low-High):" },
      vb:valuebox {
        min = 0,
        max = 127,
        value = self.note_range[1],
        notifier = function(value)
          self.note_range[1] = value
        end
      },
      vb:valuebox {
        min = 0,
        max = 127,
        value = self.note_range[2],
        notifier = function(value)
          self.note_range[2] = value
        end
      }
    },
    vb:row {
      vb:text { text = "Trigger Instrument:" },
      vb:valuebox {
        min = 0,
        max = 255,
        value = self.trigger_instrument,
        notifier = function(value)
          self.trigger_instrument = value
        end
      }
    },
    vb:row {
      vb:text { text = "Pattern Type:" },
      vb:popup {
        items = self.pattern_types,
        value = table.find(self.pattern_types, self.current_pattern) or 1,
        notifier = function(index)
          self.current_pattern = self.pattern_types[index]
          self.prev_note = nil  -- Reset context when changing patterns
        end
      }
    }
  }

  renoise.app():show_custom_dialog("Random Note Generator Settings", dialog_content)
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
  local index = math.floor((volume / 127) * scale_count) + 1
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
              local note_min, note_max = self.note_range[1], self.note_range[2]
              
              -- Use improved note generation
              local scale_note = self:generate_note(scale, root_note, line_index)
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
      else
        -- Sometimes use chromatic approach notes
        if math.random() < 0.3 then
          self.prev_note = self.prev_note + self.direction
          self.direction = -self.direction -- Change direction after approach
        else
          -- Target next scale note
          local current_pos = table.find(scale, self.prev_note % 12)
          local target_pos = current_pos + self.direction
          if target_pos > #scale then target_pos = 1
          elseif target_pos < 1 then target_pos = #scale end
          self.prev_note = scale[target_pos]
        end
      end
      return self.prev_note
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
  
  -- Much stronger weighting towards middle octaves
  local weights = {}
  for oct = min_oct, max_oct do
    -- Exponential falloff from middle octave
    local distance = math.abs(oct - mid_oct)
    weights[oct] = math.exp(-distance * 0.8)  -- Steeper falloff
  end
  
  -- Add extra weight to middle octave
  weights[mid_oct] = weights[mid_oct] * 2
  
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

-- Create a single instance of the tool
if not _tool_instance then
  _tool_instance = GenQ()
end
