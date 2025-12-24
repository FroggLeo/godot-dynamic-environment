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

// general line-sphere intesection formula
// https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
// why is it vec2??
// are we mapping the sphere onto polar coordinates?
vec2 sphere_intersection() {
	return vec2(-1.0); // return -1 for no intersect
}

// the part of the ray that is actually inside the atmosphere
// just calls sphere intersection with pre filled parameters
vec2 atmosphere_intersection() {
	return vec2(0.0);
}

// the height above/below sea level
// distance from center - planet radius
float altitude() {
	return 0.0;
}

// what is density??
// how dense the air is or how dense/powerful the scattering is?
// is h altitude?
// is there a formula someone made for this?
float rayleigh_density(float h) {
	return 0.0;
}

float mie_density(float h) {
	return 0.0;
}

// phase is how the light is scattering, right?
float rayleigh_phase(float mu) {
	// rayleigh phase = 3/4 * (1 + cos^2(scattering angle))
	// normalize by multiplying 1/4pi
	// mu = cos(scattering angle) which is actually just dot(view_dir, sun_dir)
	return (1.0 + mu * mu) * 3.0 / (16.0 * PI);
}

float mie_phase() {
	return 0.0;
}

// why vec2?
// vec2 to store TWO values!!! rayleigh and mie are the two vectors/values
// vec3 is only needed if we are also doing ozone
// calculates the optical depth value over the entire path of the ray?
// so optical depth considers blocking of light
// ohh so we do it in n steps to take many different samples
// and then gets the average?
vec2 optical_depth() {
	return vec2(0.0);
}

// absorb light based on the optical depth of the air
// what should it output?
vec2 ray_absorb() {

}

// the final function?
vec2 ray_scatter() {

}

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

	vec3 transmittance = exp(-optical_depth); // beer lambert law, transmittance = e^(-optical depth)
	vec3 scattered = (vec3(1.0) - transmittance); // where did this come from??
	c = scattered * vec3(1.0);
	COLOR = c;
}
