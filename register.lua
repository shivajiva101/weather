
local COLLIDE = true -- Particles: remove on collision with nodes

-- REGISTRATION --

weather.register_weather("clear", {
	name = "clear",
	skybox = false,
	clouds = false,
	cloud_def = {
		color = {r=240,g=240,b=255,a=229},
		density = 0,
		height = 120,
		thickness = 0
	}
})

weather.register_weather("cloudy", {
	name = "cloudy",
	skybox = false,
	clouds = true,
	cloud_def = {
		color = {r=240,g=240,b=255,a=229},
		density = 0.4,
		height = 120,
		thickness = 16
	}
})

weather.register_weather("duststorm", {
	name = "duststorm",
	skybox = false,
	clouds = true,
	cloud_def = {
		color = {r=103,g=100,b=105,a=229},
		density = 1.0,
		height = 1,
		thickness = 128
	},
	sound = "weather_wind",
	gain = 1,
})

weather.register_weather("light_rain", {
	name = "light_rain",
	particle = {
		velocity = {
			x = 0.0,
			y = -10.0,
			z = 0.0
		},
		acceleration = {x = 0, y = 0, z = 0},
		expirationtime = 2.1,
		size = 1.2,
		collisiondetection = COLLIDE,
		collision_removal = true,
		vertical = true,
		texture = "weather_raindrop.png",
		qty = 32
	},
	skybox = false,
	skybox_def = {color = {r=195,g=195,b=210,a=255}},
	clouds = true,
	cloud_def = {
		color = {r=200,g=200,b=215,a=229},
		density = 0.45,
		height = 120,
		thickness = 16
	},
	sound = "weather_raindrop",
	gain = 0.5
})

weather.register_weather("medium_rain", {
	name = "medium_rain",
	particle = {
		velocity = {
			x = 0.0,
			y = -10.0,
			z = 0.0
		},
		acceleration = {x = 0, y = 0, z = 0},
		expirationtime = 2.1,
		size = 2,
		collisiondetection = COLLIDE,
		collision_removal = true,
		vertical = true,
		texture = "weather_raindrop.png",
		qty = 48
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=175,g=175,b=191,a=229},
		density = 0.5,
		height = 120,
		thickness = 24
	},
	sound = "weather_raindrop",
	gain = 1
})

weather.register_weather("heavy_rain", {
	name = "heavy_rain",
	particle = {
		velocity = {
			x = 0.0,
			y = -10.0,
			z = 0.0
		},
		acceleration = {x = 0, y = 1, z = 0},
		expirationtime = 2.1,
		size = 3,
		collisiondetection = COLLIDE,
		collision_removal = true,
		vertical = true,
		texture = "weather_raindrop.png",
		qty = 64
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=143,g=143,b=158,a=229},
		density = 0.55,
		height = 120,
		thickness = 32
	},
	sound = "weather_raindrop",
	gain = 1.5
})

weather.register_weather("fog", {
	name = "fog",
	skybox = false,
	clouds = true,
	cloud_def = {
		color = {r=240,g=240,b=255,a=150},
		density = 1.0,
		height = 1,
		thickness = 64
	}
})

weather.register_weather("heavy_fog", {
	name = "heavy_fog",
	skybox = false,
	clouds = true,
	cloud_def = {
		color = {r=240,g=240,b=255,a=229},
		density = 1.0,
		height = 1,
		thickness = 128
	}
})

weather.register_weather("light_snow", {
	name = "light_snow",
	particle = {
			velocity = {
				x = 0.0,
				y = -2.0,
				z = -1.0
			},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = 8.5,
			size = 2.8,
			collisiondetection = COLLIDE,
			collision_removal = true,
			vertical = false,
			texture = "weather_snowflake" .. math.random(1, 4) .. ".png",
			qty = 8
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=175,g=175,b=190,a=229},
		density = 0.45,
		height = 120,
		thickness = 16
	}
})

weather.register_weather("medium_smow", {
	name = "medium_snow",
	particle = {
			velocity = {
				x = 0.0,
				y = -2.0,
				z = -1.0
			},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = 8.5,
			size = 2.8,
			collisiondetection = COLLIDE,
			collision_removal = true,
			vertical = false,
			texture = "weather_snowflake" .. math.random(1, 5) .. ".png",
			qty = 12
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=175,g=175,b=190,a=229},
		density = 0.45,
		height = 120,
		thickness = 24
	}
})

weather.register_weather("heavy_snow", {
	name = "heavy_snow",
	particle = {
			velocity = {
				x = 0.0,
				y = -2.0,
				z = -1.0
			},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = 8.5,
			size = 2.8,
			collisiondetection = COLLIDE,
			collision_removal = true,
			vertical = false,
			texture = "weather_snowflake" .. math.random(1, 8) .. ".png",
			qty = 16
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=175,g=175,b=190,a=229},
		density = 0.45,
		height = 120,
		thickness = 32
	}
})

weather.register_weather("blizzard", {
	name = "blizzard",
	particle = {
			velocity = {
				x = 0.0,
				y = -2.0,
				z = -1.0
			},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = 8.5,
			size = 2.8,
			collisiondetection = COLLIDE,
			collision_removal = true,
			vertical = false,
			texture = "weather_snowflake" .. math.random(1, 4) .. ".png",
			qty = 20
	},
	skybox = true,
	clouds = false,
	cloud_def = {
		color = {r=240,g=240,b=255,a=229},
		density = 0,
		height = 120,
		thickness = 0
	},
	sound = "weather_wind",
	gain = 1.5
})

weather.register_weather("tropical_storm", {
	name = "tropical_storm",
	particle = {
		velocity = {
			x = 0.0,
			y = -10.0,
			z = 0.0
		},
		acceleration = {x = 0, y = 0, z = 0},
		expirationtime = 2.1,
		size = 3,
		collisiondetection = COLLIDE,
		collision_removal = true,
		vertical = true,
		texture = "weather_raindrop.png",
		qty = 64
	},
	skybox = true,
	clouds = true,
	cloud_def = {
		color = {r=175,g=175,b=190,a=229},
		density = 0.45,
		height = 120,
		thickness = 48
	},
	sound = "weather_raindrop",
	gain = 1.5,
	lightning = true
})

weather.register_weather("thunderstorm", {
	name = "thunderstorm",
	clouds = true,
	cloud_def = {
		color = {r=102,g=102,b=118,a=229},
		density = 0.65,
		height = 120,
		thickness = 48
	},
	skybox = true,
	lightning = true
})

weather.register_weather("overcast", {
	name = "overcast",
	clouds = true,
	cloud_def = {
		color = {r=240,g=240,b=255,a=229},
		density = 0.4,
		height = 120,
		thickness = 16
	},
	skybox = true
})

weather.register_weather("sandstorm", {
	name = "sandstorm",
	skybox = false,
	clouds = true,
	cloud_def = {
		color = {r=142,g=112,b=72,a=229},
		density = 1.0,
		height = 1,
		thickness = 128
	},
	sound = "weather_wind",
	gain = 1,
})

local W_SYSTEMS = {
  rainforest_ocean = {
		'clear','light_rain','medium_rain','fog','heavy_fog','fog'
	},
  rainforest_swamp = {
		'clear','light_rain','medium_rain','fog','heavy_fog','fog'
	},
  rainforest = {
		'clear','light_rain','medium_rain','fog','heavy_fog','fog'
	},
  savanna_ocean = {
		'clear','cloudy','light_rain','cloudy'
	},
  savanna_shore = {
		'clear','cloudy','light_rain','cloudy'
	},
  savanna = {
		'clear','cloudy','light_rain','cloudy'
	},
  cold_desert_ocean = {
		'clear','cloudy','clear'
	},
  cold_desert = {
		'clear','cloudy','clear'
	},
  sandstone_desert_ocean = {
		'clear','cloudy','clear'
	},
  sandstone_desert = {
		'clear','sandstorm','clear'
	},
  desert_ocean = {
		'clear','cloudy','clear'
	},
  desert_sand = {
		'clear','cloudy','duststorm','clear'
	},
  deciduous_forest_ocean = {
		'clear','cloudy','light_rain','medium_rain','fog','clear'
	},
  deciduous_forest_shore = {
		'clear','cloudy','light_rain','medium_rain','fog','clear'
	},
  deciduous_forest = {
		'clear','cloudy','light_rain','medium_rain','fog','clear'
	},
  coniferous_forest_ocean = {
		'cloudy','light_rain','medium_rain','fog','light_snow'
	},
  coniferous_forest_dunes = {
		'cloudy','light_rain','medium_rain','fog','light_snow'
	},
  coniferous_forest = {
		'cloudy','light_rain','medium_rain','fog','light_snow'
	},
  grassland_ocean = {
		'clear','cloudy','light_rain','medium_rain','overcast','clear'
	},
  grassland_dunes = {
		'clear','cloudy','light_rain','medium_rain','overcast','clear'
	},
  grassland = {
		'clear','cloudy','light_rain','medium_rain','overcast','clear'
	},
  snowy_grassland_ocean = {
		'cloudy','light_snow','medium_snow','heavy_snow'
	},
  snowy_grassland = {
		'cloudy','light_snow','medium_snow','heavy_snow'
	},
  taiga_ocean = {
		'cloudy','light_snow','medium_snow','heavy_snow'
	},
  taiga = {
		'cloudy','light_snow','medium_snow','heavy_snow'
	},
  tundra_ocean = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  tundra_beach = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  tundra = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  tundra_highland = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  icesheet_ocean = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  icesheet = {
		'cloudy','medium_snow','heavy_snow','overcast'
	},
  default = {
		'clear','light_rain','medium_rain','overcast','fog',
		'heavy_fog','thunderstorm'
	}
}

-- register biome weather systems
for key,val in pairs(W_SYSTEMS) do
  weather.register_biome(key, val)
end
