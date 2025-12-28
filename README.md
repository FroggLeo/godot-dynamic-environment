# Godot Dynamic Environment
Real time physics based sky and atmosphere for Godot!
![super cool space atmosphere with sun and moon](https://hc-cdn.hel1.your-objectstorage.com/s/v3/5b5e86f4784a28e7_screenshot_2025-12-28_020452.png)

## Super simple high level controls
* Time
* Humidity (%)
* AQI
* Temperature (°C)
* Visibility (km)
* Ozone (DU)
* Altitude (m)

## A TON of low level controls
* Rayleigh & Mie scattering and strength
* Ozone density and strength
* Sun and moon customization
* Stars size, distribution, density (procedural stars)
* Importance sampling (weighing sampling steps where the air is dense)
* Truncate sampling steps (break the physics for better colors & performance!)
* .. and more!

## Installation Instructions
You have three options in terms of playing the game:

1. **Play on Itch.io**
    * Go to my itch.io page for this game: https://froggleo.itch.io/godot-dynamic-environment
    * Click the Run Game to play 

2. **Download the executable**
    * Find the latest release [here](https://github.com/FroggLeo/godot-dynamic-environment/releases) or on [itch.io](https://froggleo.itch.io/godot-dynamic-environment)
    * Download the zip file and extract
    * Make sure the .exe and .pck stay in the same folder
    * Run the .exe executable

3. **Play from the Godot engine:**
    * Clone the repository OR download zip file of the source code
    * Extract the file if needed
    * Open Godot Engine (v4.5.1 or greater), import the project
    * Click the play button at the top right corner

## Game Demo Controls:
* Right click & drag - look around
* Sliders for atmosphere controls
* Space & Esc to pause/unpause time
* Scroll to go up to space or down into the earth

## More Screenshots
![stars, the moon, and a faint twilight](https://hc-cdn.hel1.your-objectstorage.com/s/v3/b544eff634434fa7_screenshot_2025-12-28_020634.png)
![just the classic sunriseon a cold morning](https://hc-cdn.hel1.your-objectstorage.com/s/v3/8f7d07d52b31cbb2_screenshot_2025-12-28_020741.png)
![nice midday picture with the moon out](https://hc-cdn.hel1.your-objectstorage.com/s/v3/97c0125f5c43a8a6_image.png)

## Future Improvements:
There are some things I would like to add to a future version of this shader system, especially the addition of weather events and particles! Here are all of them listed
* Rain (overcast, rain particles)
* Snow (overcast as well, fog, snow particles)
* Volumetric fog or distance fog, in addition to the current environment fog
* Proper Sun and Moon orbits, and a year system
* Easy weather and condition presets
* Better stars without UV projection, but also complex distribution and maybe star clusters
* and maybe more!

## Honorable Mentions
I saw this project as my excuse to finally learn gdshader, and honestly, it was a success! My initial inspriation was:
* [Sky++ by Ansol](https://godotshaders.com/shader/sky-sorta/)
Some code snippets I have used in my shader include information from:
* [Shader Hashes by Dave Hoskins](https://www.shadertoy.com/view/4djSRW)
* [Octahedron Vector Encoding by Krzysztof Narkowicz](https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/)
* [Hue Shift Shader by Agate Dragon](https://agatedragon.blog/2024/04/02/hue-shift-shader/)
* [HSV Adjustment by al1-ce](https://godotshaders.com/shader/hsv-adjustment/)
* [Wikipedia](https://www.wikipedia.org/)
* [Godot Docs](https://docs.godotengine.org/en/stable/)
* ...and the many more guides and forum posts from the community that taught me specific things and ideas

This project was also made for [Hack Club](https://hackclub.com/) as a part of [Midnight](https://midnight.hackclub.com/)!
