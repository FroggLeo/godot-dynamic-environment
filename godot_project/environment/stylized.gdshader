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
uniform vec3 sun_color: source_color;
uniform float horizon_size;
uniform float horizon_fog_size;
uniform float sun_size;
uniform float sun_glow_size;

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
	vec3 top = vec3(0.0,1.0,0.0);
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0);
	c = ground_color;
	// must be 0 or 1
	float zenith = clamp(height * INFINITY, 0.0, 1.0);
	c = mix(c, zenith_color, zenith);
	// abs(dot(view_dir, top)) gives the top/bottom as 1, and horizon as 0
	// to essentially flip it, we can just do 1 - x, now it goes from 0 to -1
	// then simple absolute value will do
	float horizon_factor = abs(1.0-abs(dot(view_dir, top)));
	// take the power can give sharper/more natural dropoff
	// also gives us nice arbitary controls
	horizon_factor = pow(horizon_factor + horizon_size, horizon_fog_size);
	// second choice below
	// point slope form!!
	// super simplified and then clamp to 0..1
	//horizon_factor = (-abs(height)+horizon_fog_size)/(horizon_fog_size-horizon_size);
	horizon_factor = clamp(horizon_factor, 0.0, 1.0);
	c = mix(c, horizon_color, horizon_factor);
	float sun_alt = dot(vec3(0.0,1.0,0.0), sun_dir);
	// extra clamp to be sure
	float sun_near_area = clamp(dot(view_dir, sun_dir), -1.0, 1.0);
	float sun_factor = pow(max(0.0,sun_near_area)+sun_size, sun_glow_size);
	sun_factor = clamp(sun_factor, 0.0, 1.0);
	c = mix(c, sun_color, sun_factor);
	COLOR = c;
}
