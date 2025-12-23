shader_type sky;

// the planet
const float planet_radius = 6371000.0;
const vec3 planet_center = vec3(0.0, -planet_radius, 0.0);
const float atmosphere_height = 100000.0;
//const float rayleigh_height

uniform vec3 zenith_color: source_color;
uniform vec3 horizon_color: source_color;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	vec3 c;
	vec3 view_dir = normalize(EYEDIR);
	vec3 sun_dir = vec3(0.0, 1.0, 0.0);
	if (LIGHT0_ENABLED) {
		sun_dir = normalize(LIGHT0_DIRECTION);
	}
	float up = dot(view_dir, vec3(0.0, 1.0, 0.0));
	float down = dot(vec3(0.0, -1.0, 0.0),view_dir);
	
	float t = clamp(up, 0.0, 1.0);
	c = mix(horizon_color, zenith_color, t);
	float t2 = smoothstep(0.0, 1.0, down);
	c = mix(c, vec3(0.0,0.0,0.0), t2);
	
	COLOR = c;
}
