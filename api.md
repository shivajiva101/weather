Register weather types as follows:

	weather.register_weather = function(name, def)

	def is a table with these values:
	particle = {
			pos = {x=0, y=0, z=0},
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 1,
			size = 1,
			collisiondetection = false,
			collision_removal = false,
			vertical = false,
			texture = "image.png",
			playername = "singleplayer",
			animation = {Tile Animation definition},
			glow = 0,
			qty = 64 - required! (number of particles)
		},
	hud = "image_name.png",
	skybox = false used to trigger plain skybox event
	clouds = true shows clouds(default)
	cloud_def = set cloud parameters
		* `parameters` is a table with the following optional fields:
				* `density`: from `0` (no clouds) to `1` (full clouds) (default `0.4`)
				* `color`: basic cloud color with alpha channel, ColorSpec (default `#fff0f0e5`)
				* `ambient`: cloud color lower bound, use for a "glow at night" effect. ColorSpec (alpha ignored, default `#000000`)
				* `height`: cloud height, i.e. y of cloud base (default per conf, usually `120`)
				* `thickness`: cloud thickness in nodes (default `16`)
				* `speed`: 2D cloud speed + direction in nodes per second (default `{x=0, z=-2}`).
	sound = name(s) of the sound clip(s)
	* `parameter` string or a table:
		'weather_raindrop'
		OR
		{'weather_raindrop','weather_wind'}
	gain = float value,
	lightning = boolean

Register weather systems to a biome:

	weather.register_biome = function(name, def)

	def is a table of weather patterns, consisting of several types of weather and
	it must use the weather type names that were registered with weather.register_weather()

	example:

	savanna = {
		'clear','cloudy','light_rain','overcast','cloudy'
	},
The weather progresses along the entries at random intervals so the size of the array is entirely up to you!
