shader_type sky;

// HOW IS THIS POSSIBLE WOAHHH
const float INFINITY = 1.0 / 0.0;

// the planet
const float PLANET_RADIUS = 6371000.0; // radius of the planet, duh
const vec3 PLANET_CENTER = vec3(0.0, -PLANET_RADIUS, 0.0); // assumes y=0 is planet surface/sea level
const float ATMOSPHERE_HEIGHT = 100000.0; // how high the atmosphere is, this one uses the karman line
// correct ratios, values not true
const vec3 RAYLEIGH_BETA = vec3(
	5.8e-3, // red
	13.5e-3, // green
	33.1e-3 // blue
);

// Called for every visible pixel in the sky background, as well as all pixels
// in the radiance cubemap.
void sky() {
	// environment stuff
	vec3 c; // final color that will be applied
	vec3 top = vec3(0.0,1.0,0.0); // the top of the world/zenith
	vec3 view_dir = normalize(EYEDIR); // the direction where this pixel is
	float height = view_dir.y; // how high this pixel is, -1..1
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0); // shifting height -1..1 to 0..1
	// sun and moon
	vec3 sun_dir = top; // default to top
	if (LIGHT0_ENABLED) { sun_dir = normalize(LIGHT0_DIRECTION); }
	vec3 moon_dir = top; // default to top
	if (LIGHT1_ENABLED) { moon_dir = normalize(LIGHT1_DIRECTION); }
	// scattering
	// super simple air mass approximation, although not very accurate near horizon/for twilight
	float air_mass = 1.0/max(0.05, abs(dot(view_dir, top)));
	vec3 optical_depth = RAYLEIGH_BETA * air_mass;
	vec3 transmittance = exp(-optical_depth); // beer lambert law, transmittance = e^(-optical depth)
	vec3 scattered = (vec3(1.0) - transmittance);
	c = scattered * vec3(1.0);
	COLOR = c;
}
