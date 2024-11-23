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
  
  -- Process all tracks
  for track_index = 1, #pattern.tracks do
    local track = song.tracks[track_index]
    local pattern_track = pattern.tracks[track_index]

    -- Only process note tracks
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then 
      local line = pattern_track:line(pos.line)
      
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
              -- Generate random note in selected scale
              local scale = self.scales[scale_name]  -- Use scale from volume
              local note_min, note_max = self.note_range[1], self.note_range[2]
              
              -- Get random scale degree and octave
              local scale_note = scale[math.random(#scale)]
              local octave = math.random(math.floor(note_min/12), math.floor(note_max/12)) * 12
              local new_note = scale_note + octave + root_note  -- Add root note offset
              
              -- Keep within range
              new_note = math.min(math.max(new_note, note_min), note_max)
              
              -- Update the note
              next_column.note_value = new_note
            end
          end
        end
      end
    end
  end
end

-- Create a single instance of the tool
if not _tool_instance then
  _tool_instance = GenQ()
end
