shader_type sky;

// HOW IS THIS POSSIBLE WOAHHH
const float INFINITY = 1.0 / 0.0;

// the planet
const float planet_radius = 6371000.0;
const vec3 planet_center = vec3(0.0, -planet_radius, 0.0);
const float atmosphere_height = 100000.0;
//const float rayleigh_height

uniform vec3 zenith_color: source_color;
uniform vec3 horizon_color: source_color;
uniform vec3 ground_color: source_color;
uniform float horizon_size;
uniform float horizon_fog_size;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	vec3 c;
	vec3 view_dir = normalize(EYEDIR);
	vec3 sun_dir = vec3(0.0, 1.0, 0.0);
	if (LIGHT0_ENABLED) {
		sun_dir = normalize(LIGHT0_DIRECTION);
	}
	// view_dir.y usually goes from -1..1, we are shifting it to 0..1
	float height = view_dir.y;
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0);
	c = ground_color;
	// must be 0 or 1
	float zenith = clamp(height * INFINITY, 0.0, 1.0);
	c = mix(c, zenith_color, zenith);
	// exp(x) is e^x
	// used cuz e^0 = 1, and height near horizon is near 0!!!
	// negative becauze e^1 is 2.676767 but e^-1 is smol number
	// float horizon = exp(-abs(height) / horizon_size);
	// second choice below
	// point slope form!!
	// super simplified and then clamp to 0..1
	float horizon = (-abs(height)+horizon_fog_size)/(horizon_fog_size-horizon_size);
	horizon = clamp(horizon, 0.0, 1.0);
	c = mix(c, horizon_color, horizon);
	
	COLOR = c;
}
