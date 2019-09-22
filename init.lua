-- Weather mod by shivajiva for minetest


weather = {}
weather.registered_weather = {}
weather.registered_biomes = {}
weather.status = {}
--weather.types = {}
weather.wind = {}

-- Constants
local MP = minetest.get_modpath(minetest.get_current_modname())
local YMIN = 1 -- effects floor (set to sealevel)
local YMAX = 120 -- effects ceiling (set to cloud height)
local GCYCLE = 60 -- Generator timer interval (seconds)
local PCYCLE = 0.5 -- Player loop interval (seconds)
local RAINGAIN = 0.2 -- Rain sound volume
local CSMAX = 5 -- Cloud speed max nodes/s
local NISVAL = 0 -- plain skybox RGB night value
local DASVAL = 175 -- plain skybox RGB day value
local C_WHITE = {r=240,g=240,b=255,a=229} -- normal colour
local SKY_BLUE = {r=139, g=185, b=249, a=255}
local SKY_GREY = {r=175, g=175, b=191, a=255}
local SKY_BLACK = {r=0, g=0, b=16, a=255}
local SKY_WHITE = {r=255, g=255, b=255, a=255}
local STEPS = 13 -- steps for rgb_lerp transitions
local CDEF = {
  color = C_WHITE,
  density = 0,
  height = 120,
  thickness = 0
} -- cloud reset

-- variables
local audio_id = {} -- audio handles table
local biome_idx = {} -- biomes current weather index
local c = {} -- cloud transition state
local d = {} -- density transition state
local force = 0 -- trigger
local h = {} -- cloud height transition state
local hud_id = {} -- hud overlay table
local lightning = false -- trigger flag
local l_temp = {} -- temp cache for player skybox state during lightening
local s = {} -- temp transition state for skybox (flag)
local sky = {} -- temp cache for player skybox state
local t = {} -- cloud thickness transition state

-- ### INIT ###
weather.wind.x = 0
weather.wind.z = -2
weather.wind.i = 5

-- ### DEVELOPMENT ###
local dev = {} -- hud debugging
local mod_debug = true

-- REGISTRATION API

-- weather type
weather.register_weather = function(name, def)
  weather.registered_weather[name] = def
end

-- biome weather sequence
weather.register_biome = function(name, def)
  weather.registered_biomes[name] = def
	biome_idx[name] = 1 -- init current index
end

-- register default types
dofile(MP .. "/register.lua")

weather.get_player = function(name)
  if type(name) == "string" and weather.status[name] then
    return {
      biome = weather.status[name].working_biome,
      weather = weather.status[name].w,
      outside = weather.status[name].outside
    }
  end
end

-- HELPER FUNCTIONS --

local function round(num)
  if num == nil then return end
  local mult = 1000
  return math.floor(num * mult + 0.5) / mult
end

local function rgba_lerp(st, f, p)
  -- linear rgba interpolation
  -- st = table; start point
  -- f = table; end point
  -- p = float; point along the interpolated line
  if not st or not f or not p then return end
  local r = {}
  r.r = math.floor(st.r + (f.r - st.r) * p)
  r.g = math.floor(st.g + (f.g - st.g) * p)
  r.b = math.floor(st.b + (f.b - st.b) * p)
  r.a = math.floor(st.a + (f.a - st.a) * p)
  return r
end

local function rgba_diff(a, b)
  if a.r ~= b.r or a.g ~= b.g or a.b ~= b.b or a.a ~= b.a then
    return true
  end

  return false
end

local function lerp(st, f, p)
  -- linear interpolation
  return (st + (f - st) * p)
end

local function particle_pos(pos, velocity)
  -- Predict particle position as behind the cycle interval.
  local ppos = vector.add(pos, vector.multiply(velocity, 0.85))
  local pposx = math.floor(ppos.x)
  -- add 2 nodes for precipitation when swimming
  local pposy = math.floor(ppos.y) + 2
  local pposz = math.floor(ppos.z)
  -- particle position
  return {x = pposx, y = pposy, z = pposz}
end

-- GENERATORS (timers) --

math.randomseed(os.time())

minetest.register_globalstep(function(dtime)
  force = force + math.random(-1,1)
  -- assert min/max
  if force > 100 then
    force = 100
  elseif force < 0 then
    force = 0
  end
end)

local function wind_generator()
  local direction = {
    [1] = {x = 0, z = 1, hrf = "N"},
    [2] = {x = 1, z = 1, hrf = "NE"},
    [3] = {x = 1, z = 0, hrf = "E"},
    [4] = {x = 1, z = -1, hrf = "SE"},
    [5] = {x = 0, z = -1, hrf = "S"},
    [6] = {x = -1, z = -1, hrf = "SW"},
    [7] = {x = -1, z = 0, hrf = "W"},
    [8] = {x = -1, z = 1, hrf = "NW"}
  }
  local x, z
  local sts = math.random(-1,1)
  local i = weather.wind.i

  if sts > 0 then
    -- increase speed
    local current = direction[i]
    if (weather.wind.x < CSMAX and weather.wind.x > -CSMAX) and
      (weather.wind.z < CSMAX and weather.wind.z > -CSMAX) then
      x = weather.wind.x + current.x
      z = weather.wind.z + current.z
      dev.sts = "plus"
    end
  elseif sts < 0 then
    -- decrease speed
    local current = direction[i]
    if weather.wind.x > -CSMAX and weather.wind.z > -CSMAX then
      x = weather.wind.x - current.x
      z = weather.wind.z - current.z
      dev.sts = "minus"
    end
  else
    -- change direction
    local r = math.random(0,1)
    local mx, mz = 1,1
    local index
    if weather.wind.x < -1 then
      mx = weather.wind.x * -1
    elseif weather.wind.x > 1 then
      mx = weather.wind.x
    end
    if weather.wind.z < -1 then
      mz = weather.wind.z * -1
    elseif weather.wind.z > 1 then
      mz = weather.wind.z
    end
    if r > 0 then
      -- increment current index
      index = weather.wind.i + 1
      if index > #direction then index = 1 end -- loop
      weather.wind.i = index
      x = direction[index].x * mx
      z = direction[index].z * mz
      dev.dts = direction[index].hrf
      dev.sts = ""
    else
      -- decrement current index
      index = weather.wind.i - 1
      if index < 1 then index = #direction end -- loop
      weather.wind.i = index
      x = direction[index].x * mx
      z = direction[index].z * mz
      dev.dts = direction[index].hrf
      dev.sts = ""
    end
  end
  if x and z then
    weather.wind.x = x
    weather.wind.z = z
  end
  -- random trigger 1-2 mins
  minetest.after(math.random(30,60), wind_generator)
end
minetest.after(30, wind_generator)

local function weather_generator()
  local time = minetest.get_timeofday()
  if time >= 0.5 then time = 1 - time	end
  if time <= 0.1875 or time >= 0.2396 then
    if force > 60 then
      for k,v in pairs(weather.registered_biomes) do
        local n = math.random(1,10)
        if n > 5 then
          -- increment or reset if max index reached
          if biome_idx[k] < #v then
            biome_idx[k] = biome_idx[k] + 1
          elseif biome_idx[k] >= #v then -- reset
            biome_idx[k] = 1
          end
        end
      end
      force = 0 -- reset
    end
  end
  minetest.after(GCYCLE, weather_generator)
end
minetest.after(10, weather_generator)

local function lightning_generator()
  -- test code
  lightning = math.random(1, 10) > 5
  minetest.after(5, lightning_generator)
end
minetest.after(5, lightning_generator)

-- AUDIO --

local function fade_audio(name, sound_clip)
  local entry, gain, sound
  -- handle specific sound clip?
  if sound_clip then
    entry = audio_id[name][sound_clip]
    if entry then
      -- stop current audio
      minetest.sound_stop(entry.id)
      -- fade at the correct gain
      gain = entry.gain
      sound = sound_clip .. "_fadeout"
      audio_id[name] = nil
      minetest.sound_play(sound,
        {
          to_player = name,
          gain = gain,
          loop = false
        }
      )
    end
  else -- all looping audio!
    entry = audio_id[name]
    for k,v in pairs(entry) do
      -- stop current audio
      minetest.sound_stop(v.id)
      -- fade at the correct gain
      gain = v.gain
      sound = k .. "_fadeout"
      audio_id[name][k] = nil
      minetest.sound_play(sound,
        {
          to_player = name,
          gain = gain,
          loop = false
        }
      )
    end
  end
end

local function play_audio(name, sound_clip, player_gain)
  local id,clip
  -- is sound playing?
  if audio_id[name][sound_clip] then
    clip = audio_id[name][sound_clip]
    if clip.gain == player_gain then -- no change?
      return
    else -- gain change
      minetest.sound_stop(clip.id)
      audio_id[name][sound_clip] = nil
    end
    id = minetest.sound_play(sound_clip,
      {
        to_player = name,
        gain = player_gain,
        loop = true,
      }
    )
  else
    -- add sound clip, fading in
    id = minetest.sound_play(sound_clip,
      {
        to_player = name,
        gain = player_gain,
        fade = 0.01,
        loop = true,
      }
    )
  end
  -- stash meta for subsequent control
  if id then
    audio_id[name][sound_clip] = {id = id, gain = player_gain}
  end
end

function weather.audio(name, pos, def, outside)
  local pass
  local status = weather.status[name]
  if pos.y > YMAX or pos.y < YMIN then
    fade_audio(name)
    return
  end
  -- does the weather def have sound?
  if def.sound then
    -- allow rain -> rain transition
    if status.p:match("rain") and status.w:match("rain") then
      pass = true
    else
      if s[name] or status.lock then
        return
      end
      pass = true
    end
  else
    fade_audio(name)
    return
  end

  if pass then
    local gain
    if outside then
      gain = RAINGAIN * def.gain
    else
      gain = RAINGAIN * (def.gain * 0.75)
    end
    play_audio(name, def.sound, gain)
  end
end

-- SKYBOX --

function weather.sky(name, player, def)

  -- handle skybox transitions based on time of day

  local sval, sky_bg
  local psky = {}
  local clouds = def.clouds or false
  local p_def = weather.registered_weather[weather.status[name].p]

  if def.skybox then
    -- skybox and no ticket requires a fade in
    if not sky[name] then
      sky[name] = {fin = true} -- init fade in
    end
  elseif sky[name] then
    -- ticket and no skybox requires fade out
    if not sky[name].fout then
      sky[name].fout = true -- init fade out
    end
  end

  -- ticket?
  if not sky[name] then return end

  -- get current player sky
  psky.bgcolor, psky.type, psky.textures = player:get_sky()

  local time = minetest.get_timeofday()
  if time >= 0.5 then time = 1 - time	end
  if time <= 0.1875 then -- ### NIGHTIME ###

    if sky[name].fin then -- fading in?
      sky[name].fin = false -- no fade in!
      s[name] = nil
  elseif sky[name].fout then
    -- no fade out, it's dark so return to regular skybox
    player:set_sky({}, "regular", {}, clouds)
    sky[name] = nil -- remove ticket
    s[name] = nil
    return
  end

  sval = NISVAL -- skybox colour

  elseif time >= 0.2396 then -- ### DAYTIME ###

    -- use players current skybox type to determine
    -- the starting point of the rgb_lerp
    if psky.type == "regular" and p_def.cloud_def.height == 1 then
      sky_bg = SKY_WHITE
  elseif psky.type == "regular" then
    sky_bg = SKY_BLUE
  elseif psky.type == "plain" then
    sky_bg = psky.bgcolor
  end

  -- fade in?
  if sky[name].fin then
    -- if fade hasn't been initialised then calcuate the increment
    -- and initialise t to one increment
    if not sky[name].t then
      sky[name].inc = 1 / STEPS -- calc increment
      sky[name].t = sky[name].inc
      sky[name].bg = sky_bg
      s[name] = true
    end
    sval = rgba_lerp(sky[name].bg, SKY_GREY, sky[name].t)
    sky[name].t = sky[name].t + sky[name].inc
    if sky[name].t > 1 then
      sval = SKY_GREY
      sky[name].fin = nil
      sky[name].t = nil
      sky[name].inc = nil
      s[name] = nil
    end
    player:set_sky(sval, "plain", {}, clouds)
    return
  elseif sky[name].fout then
    -- if fade hasn't been initialised then calcuate the increment
    -- and initialise t to one increment
    if not sky[name].t then
      sky[name].inc = 1 / STEPS
      sky[name].t = 0
      sky[name].bg = sky_bg
      s[name] = true
    end
    sval = rgba_lerp(sky[name].bg, SKY_BLUE, sky[name].t)
    sky[name].t = sky[name].t + sky[name].inc
    -- overflow?
    if sky[name].t < 1 then
      player:set_sky(sval, "plain", {}, clouds) -- set
      s[name] = nil
    else
      player:set_sky({}, "regular", {}, clouds)
      sky[name] = nil -- remove ticket
      s[name] = nil
    end
    return
  end

  sval = DASVAL -- set skybox colour

  else -- ### SUNRISE ###
    -- First transition (24000 -) 4500, (1 -) 0.1875
    -- Last transition (24000 -) 5750, (1 -) 0.2396
    sval = math.floor(NISVAL +	((time - 0.1875) / 0.0521) * (DASVAL - NISVAL))
    --sval = rgb_lerp()
  end
  -- Set sky; slight blue shift
  local rgba = {r = sval, g = sval, b = sval + 16, a = 255}
  player:set_sky(rgba, "plain", {}, clouds)
end

local function revertsky()
  -- decrement t for skybox lightning tickets
  for key, entry in pairs(l_temp) do
    entry.t = entry.t - 1
    if entry.t > 1 then
      break
    end
    -- revert skybox
    local tmp = entry.s
    entry.p:set_sky(tmp.bgcolor, tmp.type, tmp.textures, tmp.clouds)
    l_temp[key] = nil -- remove ticket
  end
end

minetest.register_globalstep(revertsky)

function weather.lightning(name, player, def)
  -- only process players in a weather type that uses lightning
  if not def.lightning then
    return
  elseif lightning and
    not weather.status[name].lock and
    not s[name] then -- lightning event

    local delay = math.random(0, 5)
    local clouds = def.clouds or false -- default to off

    if delay ~= 5 then -- ~ 83% chance of thunder
      minetest.after(delay, function()
        -- untracked audio sample
        minetest.sound_play({
          to_player = name,
          name = "weather_thunder",
          gain = 8
        })
      end)
    end

    local psky = {}

    psky.bgcolor, psky.type, psky.textures, psky.clouds = player:get_sky()

    if not l_temp[name] then
      l_temp[name] = {p = player, s = psky, t = 5}
      player:set_sky(SKY_WHITE, "plain", {}, clouds)
    end
  end
end

-- CLOUDS --

function weather.cloud_color(name, player, def)

  local current = player:get_clouds()
  local cloud_def = def.cloud_def or CDEF -- init if reqd!
  local nval

  -- weather type has clouds?
  if def.clouds then
    -- no ticket and skybox colour diff?
    if not c[name] and rgba_diff(current.color, cloud_def.color) then
      -- sharp transition? [fog > cloud]
      if current.height == 1 and cloud_def.height > current.height or
        current.height > 1 and cloud_def.height == 1 then
        c[name] = {
          inc = 1,
          t = 1,
          s = current.color,
          f = cloud_def.color
        }
      else -- smooth transition
        c[name] = {
          inc = 1/STEPS,
          t = 1/STEPS,
          s = current.color,
          f = cloud_def.color
        }
      end
    end
  end
  -- ticket?
  if c[name] then
    weather.status[name].lock = true -- assert blocking status
    nval = rgba_lerp(c[name].s, c[name].f, c[name].t)
    c[name].t = c[name].t + c[name].inc
    if c[name].t > 1 then
      nval = c[name].f
      c[name] = nil
    end
    return nval
  end
end

function weather.cloud_density(name, player, def)

  local nval
  local current = player:get_clouds()

  if def.clouds then

    -- no ticket and a shift to ground level?
    if not d[name] and current.height > 1 and
      def.height == 1 then

      -- initiate the fade out first and extend the ticket
      d[name] = {
        inc = 1 / (STEPS*2),
        t = 1 / (STEPS*2),
        s = current.density,
        f = 0
      }

      -- no ticket and density diff?
    elseif not d[name] and
      def.cloud_def.density ~= round(current.density) then

      d[name] = {
        inc = 1 / (STEPS*2),
        t = 1 / (STEPS*2),
        s = current.density,
        f = def.cloud_def.density
      }

    end
  else
    -- initialise evaporate transition for no clouds
    if not d[name] and current.density and current.density > 0 then

      d[name] = {
        inc = 1 / (STEPS*2),
        t = 1 / (STEPS*2),
        s = current.density,
        f = 0
      }

    end
  end

  if d[name] then -- ticket
    weather.status[name].lock = true -- assert blocking status
    nval = round(lerp(d[name].s, d[name].f, d[name].t))
    d[name].t = d[name].t + d[name].inc
    if d[name].t > 1 then -- overflow
      nval = d[name].f
      d[name] = nil -- remove ticket
    end

    return nval

  end
end

function weather.cloud_thickness(name, player, def)

  local nval
  local current = player:get_clouds()

  if def.clouds then
    -- ticket?
    if not t[name] and def.cloud_def.thickness ~= current.thickness then
      t[name] = {
        inc = 1 / (STEPS*2),
        t = 1 / (STEPS*2),
        s = current.thickness,
        f = def.cloud_def.thickness
      }
    end
  else
    -- no clouds
    if not t[name] and current.thickness and current.thickness > 0 then
      -- initialise
      t[name] = {
        inc = 1 / (STEPS*2),
        t = 1 / (STEPS*2),
        s = current.thickness,
        f = 0
      }
    end
  end

  if t[name] then
    weather.status[name].lock = true -- assert blocking status
    nval = round(lerp(t[name].s, t[name].f, t[name].t))
    t[name].t = t[name].t + t[name].inc
    -- overflow?
    if t[name].t > 1 then
      nval = t[name].f
      t[name] = nil
    end
    return nval
  end
end

function weather.cloud_height(name, player, def)

  local nval
  local current = player:get_clouds()

  if def.clouds then
    -- ticket?
    if not h[name] and def.cloud_def.height ~= current.height then
      -- sharp transition? [fog <-> cloud]
      if current.height == 1 and
        def.cloud_def.height > current.height or
        current.height > 1 and
        def.cloud_def.height == 1 then
        h[name] = {
          inc = 1,
          t = 1,
          s = current.height,
          f = def.cloud_def.height
        }
      else -- smooth transition
        h[name] = {
          inc = 1 / STEPS,
          t = 1 / STEPS,
          s = current.height,
          f = def.cloud_def.height
        }
      end
    end
  else
    -- no clouds
    if not h[name] and current.height and current.height > 0 then
      -- initialise
      h[name] = {
        inc = 1,
        t = 1,
        s = 120,
        f = 120
      }
    end
  end

  if h[name] then
    weather.status[name].lock = true -- assert blocking status
    nval = round(lerp(h[name].s, h[name].f, h[name].t))
    h[name].t = h[name].t + h[name].inc
    -- overflow?
    if h[name].t > 1 then
      nval = h[name].f
      h[name] = nil
    end
    return nval
  end
end

local function wind_changed(current)
  if current and
    current.speed.x ~= weather.wind.x or
    current.speed.z ~= weather.wind.z then
    return true
  end
end

function weather.clouds(name, player, def)

  --[[
	This function attempts to encapsulate the transition sequences
	for different types of cloud. It uses the current and previous
	type definitions to decide the sequence order.
	]]

  -- block cloud transitions during skybox transitions
  if s[name] then return end

  -- localise def for previous weather type
  local p_def = weather.registered_weather[weather.status[name].p]

  local current = player:get_clouds()
  local final = def.cloud_def
  local c_def = {}
  local m, color, density, thickness, height

  if p_def.name:match("fog") or p_def.name:match("sand") or
    p_def.name:match("dust") then
    -- previous type ground based
    if def.name == "clear" then
      -- ground based to clear using transition sequence: TDHC
      if t[name] or current.thickness ~= final.thickness then
        thickness = weather.cloud_thickness(name, player, def)
        if thickness then
          c_def.thickness = thickness
          m = true
        end
      elseif d[name] or round(current.density) ~= final.density then
        density = weather.cloud_density(name, player, def)
        if density then
          c_def.density = density
          m = true
        end
      elseif h[name] or current.height ~= final.height then
        height = weather.cloud_height(name, player, def)
        if height then
          c_def.height = height
          m = true
        end
      elseif c[name] or rgba_diff(current.color, final.color) then
        color = weather.cloud_color(name, player, def)
        if color then
          c_def.color = color
          m = true
        end
      end
    elseif def.name:match("fog") or def.name:match("sand") or
      def.name:match("dust") then
      -- ground changes using transition sequence: CT
      if c[name] or rgba_diff(current.color, final.color) then
        color = weather.cloud_color(name, player, def)
        if color then
          c_def.color = color
          m = true
        end
      elseif t[name] or current.thickness ~= final.thickness then
        thickness = weather.cloud_thickness(name, player, def)
        if thickness then
          c_def.thickness = thickness
          m = true
        end
      end
    elseif def.clouds then
      -- ground to sky using transition sequence: TDHCDT
      if h[name] or current.height ~= final.height then
        -- use suitable def for thickness and density
        local ndef = weather.registered_weather["clear"]
        if t[name] or
          round(current.thickness) ~= ndef.cloud_def.thickness then
          thickness = weather.cloud_thickness(name, player, ndef)
          if thickness then
            c_def.thickness = thickness
            m = true
          end
        elseif d[name] or
          round(current.density) ~= ndef.cloud_def.density then
          density = weather.cloud_density(name, player, ndef)
          if density then
            c_def.density = density
            m = true
          end
        else
          height = weather.cloud_height(name, player, def)
          if height then
            c_def.height = height
            m = true
          end
        end
      elseif c[name] or rgba_diff(current.color, final.color) then
        color = weather.cloud_color(name, player, def)
        if color then
          c_def.color = color
          m = true
        end
      elseif d[name] or round(current.density) ~= final.density then
        density = weather.cloud_density(name, player, def)
        if density then
          c_def.density = density
          m = true
        end
      elseif t[name] or current.thickness ~= final.thickness then
        thickness = weather.cloud_thickness(name, player, def)
        if thickness then
          c_def.thickness = thickness
          m = true
        end
      end
    end
  elseif def.name:match("fog") or def.name:match("sand") or
    def.name:match("dust") then
    -- previous type not ground based
    if p_def.name == "clear" then
      --  clear to ground transition sequence: HCDT
      if h[name] or current.height ~= final.height then
        height = weather.cloud_height(name, player, def)
        if height then
          c_def.height = height
          m = true
        end
      elseif c[name] or rgba_diff(current.color, final.color) then
        color = weather.cloud_color(name, player, def)
        if color then
          c_def.color = color
          m = true
        end
      elseif d[name] or round(current.density) ~= final.density then
        density = weather.cloud_density(name, player, def)
        if density then
          c_def.density = density
          m = true
        end
      elseif t[name] or current.thickness ~= final.thickness then
        thickness = weather.cloud_thickness(name, player, def)
        if thickness then
          c_def.thickness = thickness
          m = true
        end
      end
    elseif p_def.clouds then
      -- sky to ground transition sequence: TDHCDT
      if h[name] or current.height ~= final.height then
        -- use suitable def for thickness and density
        local ndef = weather.registered_weather["clear"]
        if t[name] or
          round(current.thickness) ~= ndef.cloud_def.thickness then
          thickness = weather.cloud_thickness(name, player, ndef)
          if thickness then
            c_def.thickness = thickness
            m = true
          end
        elseif d[name] or
          round(current.density) ~= ndef.cloud_def.density then
          density = weather.cloud_density(name, player, ndef)
          if density then
            c_def.density = density
            m = true
          end
        else
          height = weather.cloud_height(name, player, def)
          if height then
            c_def.height = height
            m = true
          end
        end
      elseif c[name] or rgba_diff(current.color, final.color) then
        color = weather.cloud_color(name, player, def)
        if color then
          c_def.color = color
          m = true
        end
      elseif d[name] or round(current.density) ~= final.density then
        density = weather.cloud_density(name, player, def)
        if density then
          c_def.density = density
          m = true
        end
      elseif t[name] or current.thickness ~= final.thickness then
        thickness = weather.cloud_thickness(name, player, def)
        if thickness then
          c_def.thickness = thickness
          m = true
        end
      end
    end
  elseif p_def.clouds then
    -- handle previous cloud with transition sequence: TDCH
    if t[name] or current.thickness ~= final.thickness then
      thickness = weather.cloud_thickness(name, player, def)
      if thickness then
        c_def.thickness = thickness
        m = true
      end
    elseif d[name] or round(current.density) ~= final.density then
      density = weather.cloud_density(name, player, def)
      if density then
        c_def.density = density
        m = true
      end
    elseif c[name] or rgba_diff(current.color, final.color) then
      color = weather.cloud_color(name, player, def)
      if color then
        c_def.color = color
        m = true
      end
    elseif h[name] or current.height ~= final.height then
      height = weather.cloud_height(name, player, def)
      if height then
        c_def.height = height
        m = true
      end
    end
  elseif def.clouds then
    -- handle cloud with no previous using transition sequence: HCDT
    if h[name] or current.height ~= final.height then
      height = weather.cloud_height(name, player, def)
      if height then
        c_def.height = height
        m = true
      end
    elseif c[name] or rgba_diff(current.color, final.color) then
      color = weather.cloud_color(name, player, def)
      if color then
        c_def.color = color
        m = true
      end
    elseif d[name] or round(current.density) ~= final.density then
      density = weather.cloud_density(name, player, def)
      if density then
        c_def.density = density
        m = true
      end
    elseif t[name] or current.thickness ~= final.thickness then
      thickness = weather.cloud_thickness(name, player, def)
      if thickness then
        c_def.thickness = thickness
        m = true
      end
    end
  end
  -- wind change?
  if wind_changed(current) then
    c_def.speed = weather.wind
    m = true
  end
  -- modify?
  if m then
    player:set_clouds(c_def)
  end
  -- unlock when all transitions complete
  if not color and not thickness and
    not density and not height then
    weather.status[name].lock = false
  end
end

-- PRECIPITATION --

function weather.precipitation(tbl)
  local status = weather.status[tbl.name]
  local lock
  -- allow rain -> rain
  if status.p:match("rain") and status.w:match("rain") then
    lock = false
  elseif s[tbl.name] then -- skybox lock
    return
  else -- use status lock
    lock = status.lock
  end
  if lock then return end
  -- particle def?
  if tbl.def.particle then
    -- precipitation is limited by players height
    if tbl.player_pos.y > YMAX or tbl.player_pos.y < YMIN then
      return
    end
    local p_obj = tbl.def.particle
    local inside = {}
    local outside = {}
    -- set player in particle def copy
    p_obj.playername = tbl.name
    -- set velocity
    p_obj.velocity.x = weather.wind.x
    p_obj.velocity.z = weather.wind.z
    -- Rain or snow?
    if tbl.weather_name:match("rain") or
      tbl.weather_name:match("tropical") then
      -- generate positions
      for droplet = 1, p_obj.qty do
        local pos = {
          x = tbl.ppos.x - 8 + math.random(0, 16),
          y = tbl.ppos.y + 8 + math.random(0, 5),
          z = tbl.ppos.z - 8 + math.random(0, 16)
        }
        -- create unique key
        local key = tostring(pos.x) .. tostring(pos.z)
        -- handle signed chars
        key = key:gsub("%-", "n")
        if not inside[key] then
          if not outside[key] then
            if minetest.get_node_light(pos, 0.5) == 15 then
              outside[key] = true
            else
              inside[key] = true
            end
          end
        end
        if outside[key] then
          -- outside, add particle
          p_obj.pos = pos
          minetest.add_particle(p_obj)
        end
      end
    elseif tbl.weather_name:match("snow") or
      tbl.weather_name:match("blizzard") then
      -- generate positions
      for flake = 1, p_obj.qty do
        local pos = {
          x = tbl.ppos.x - 24 + math.random(0, 47),
          y = tbl.ppos.y + 8 + math.random(0, 1),
          z = tbl.ppos.z - 20 + math.random(0, 47)
        }
        -- create a unique key
        local key = tostring(pos.x) .. tostring(pos.z)
        -- handle signed chars
        key = key:gsub("%-", "n")
        if not inside[key] then
          if not outside[key] then
            if minetest.get_node_light(pos, 0.5) == 15 then
              outside[key] = true
            else
              inside[key] = true
            end
          end
        end
        if outside[key] then
          -- outside, add particle
          p_obj.pos = pos
          minetest.add_particle(p_obj)
        end
      end
    end
  end
end

-- PLAYER LOOP --

local function player_weather()

  local players = minetest.get_connected_players()
  for _, player in ipairs(players) do

    local name = player:get_player_name()
    local player_pos = player:get_pos()

    if not player or not player_pos then break end -- sanity check

    local ppos = particle_pos(player_pos, player:get_player_velocity())

    -- biome detection
    local biome_name = minetest.get_biome_name(
      minetest.get_biome_data(player_pos).biome)

    local status = weather.status[name]

    if not status.initialised then
      status.working_biome = biome_name
      status.initialised = true
    end

    local pattern = weather.registered_biomes[status.working_biome]
    local new_pattern = weather.registered_biomes[biome_name]

    -- missing pattern handler
    if not pattern or not new_pattern then
      player:set_sky({}, "regular", {}, true) -- reset skybox
      break -- next!
    end

		local weather_name = pattern[biome_idx[status.working_biome]]
    local def = weather.registered_weather[weather_name]
    local outside = minetest.get_node_light(ppos, 0.5) == 15

    -- biome transition delay
		-- stop transitions toggling at the biome blend regions by using a delay
    if status.ttl and status.ttl < 1 then
      status.working_biome = biome_name -- update
      status.ttl = nil --remove
    elseif status.ttl then
      if status.working_biome ~= biome_name then
        status.ttl = status.ttl - 1 -- decrement
      else
        status.ttl = nil -- remove
      end
    elseif status.working_biome ~= biome_name and not status.ttl then
      status.ttl = 5 -- reset
    end

    status.outside = outside

    -- update current & previous weather status
    if status.w then
      if status.w ~= weather_name then
        status.p = status.w
        status.w = weather_name
      end
    else
      status.p = 'cloudy'
      status.w = weather_name
    end

    weather.status[name] = status -- update global

    weather.sky(name, player, def)
    weather.clouds(name, player, def)
    weather.precipitation({
      name = name,
      player = player,
      def = def,
      player_pos = player_pos,
      ppos = ppos,
      weather_name = weather_name})
    weather.lightning(name, player, def)
    weather.audio(name, player_pos, def, outside)

    -- ### DEVELOPMENT USE ONLY! ###
    -- depends on conf setting and dev table
    if mod_debug then
      local current = player:get_clouds()
      local msg = ([[
			biome:
			  current: %s
			  working: %s
			weather:
			  prev: %s
			  now: %s
			skybox:
			  plain: %s
			  lock: %s
			cloud:
			  lock: %s
			  density: %s
			  colour: %s, %s, %s, %s
			  height: %s
			  thickness: %s
			wind:
			  speed: %s, %s
			  adj: %s
			  dir: %s
			]]):format(biome_name:gsub("_", " "),
        status.working_biome:gsub("_", " "),
        weather.status[name].p,
        weather.status[name].w,
        tostring(def.skybox),
        tostring(s[name]),
        tostring(weather.status[name].lock),
        round(current.density),
        tostring(current.color.r),
        tostring(current.color.g),
        tostring(current.color.b), tostring(current.color.a),
        tostring(current.height),
        round(current.thickness),
        tostring(weather.wind.x), tostring(weather.wind.z),
        tostring(dev.sts),
        tostring(dev.dts)
			)
      if dev.id then -- update
        player:hud_change(dev.id, "text", msg)
      else -- add
        dev.id = player:hud_add({
          hud_elem_type = "text",
          name = "dev_hud",
          scale = {x=100, y=100},
          text = msg,
          number = 0x00FF00,
          position = {x=0.8, y=0.5},
          alignment = {x=0, y=0},
          offset = {x=0, y=0}
        })
      end
    end

  end -- player loop

  lightning = false -- players processed, reset
  minetest.after(PCYCLE, player_weather) -- loop
end
minetest.after(5, player_weather)

-- CALLBACKS --

minetest.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  weather.status[name] = {}
  audio_id[name] = {}
end)

minetest.register_on_leaveplayer(function(player)
  -- cleanup player data
  local name = player:get_player_name()
  weather.status[name] = nil
  if hud_id[name] then hud_id[name] = nil end
  local def = audio_id[name]
  if def then
    -- cleanup player audio entries
    for k,v in pairs(def) do
      minetest.sound_stop(v.id)
    end
    audio_id[name] = nil
  end
end)

-- DEV COMMANDS --
if mod_debug then
  minetest.register_chatcommand("nxt", {
    description = "Set next weather in the current biome",
    privs = {server = true},
    func = function(name)
      local player = minetest.get_player_by_name(name)
      local pos = player:get_pos()
      local biome_name = minetest.get_biome_name(
        minetest.get_biome_data(pos).biome)
      local pattern = weather.registered_biomes[biome_name]
      if pattern then
        if biome_idx[biome_name] < #pattern then
          biome_idx[biome_name] = biome_idx[biome_name] + 1
        else
          biome_idx[biome_name] = 1
        end
        force = 0 -- reset
      else
        minetest.chat_send_player(name, "No weather pattern for this biome!")
      end
    end,
  })

  minetest.register_chatcommand("prev", {
    description = "Set previous weather in the current biome",
    privs = {server = true},
    func = function(name)
      local player = minetest.get_player_by_name(name)
      local pos = player:get_pos()
      local biome_name = minetest.get_biome_name(
        minetest.get_biome_data(pos).biome)
      local pattern = weather.registered_biomes[biome_name]
      if pattern then
        if biome_idx[biome_name] == 1 then
          biome_idx[biome_name] = #pattern
        else
          biome_idx[biome_name] = biome_idx[biome_name] - 1
        end
        force = 0 -- reset
      else
        minetest.chat_send_player(name, "No weather pattern for this biome!")
      end
    end,
  })
end
