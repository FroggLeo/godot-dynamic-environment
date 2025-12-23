shader_type sky;

group_uniforms sun;
	// main sun stuff
	uniform float sun_size;
	uniform sampler2D sun_color;
	uniform sampler2D sun_dropoff; // curve/gradient for adjusting the dropoff/blend
	// sun glow stuff, the extra glow that's not the main disc and different color
	uniform float sun_glow_size;
	uniform sampler2D sun_glow_color;
	uniform sampler2D sun_glow_dropoff;

group_uniforms world;
	// drawn in this order
	// base color -> ground -> zenith -> horizon
	uniform sampler2D base_color;
	// ground, on the bottom hemisphere
	uniform sampler2D ground_color;
	// zenith, or the top of the sky
	uniform float zenith_size;
	uniform sampler2D zenith_color;
	uniform sampler2D zenith_dropoff; 
	// horizon, where ground meets sky
	uniform float horizon_size;
	uniform sampler2D horizon_east_color;
	uniform sampler2D horizon_west_color;
	uniform sampler2D horizon_dropoff;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	vec3 c;
	vec3 view_dir = normalize(EYEDIR);
	vec3 sun_dir = vec3(0.0, 1.0, 0.0);
	if (LIGHT0_ENABLED) {
		sun_dir = normalize(LIGHT0_DIRECTION);
	}
	
	
	
	//COLOR = c;
}
