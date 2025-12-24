shader_type sky;

// HOW IS THIS POSSIBLE WOAHHH
const float INFINITY = 1.0 / 0.0;

// the planet
const float PLANET_RADIUS = 6371000.0; // radius of the planet, duh
const vec3 PLANET_CENTER = vec3(0.0, -PLANET_RADIUS, 0.0); // assumes y=0 is planet surface/sea level
const float ATMOSPHERE_HEIGHT = 100000.0; // how high the atmosphere is, this one uses the karman line
// atmosphere
// rayleigh
const vec3 RAYLEIGH_BETA = vec3(5.8e-3, 13.5e-3, 33.1e-3); // correct ratios, values not true
const float RAYLEIGH_SCALE_HEIGHT = 8300.0;
// mie
const vec3 MIE_BETA = vec3(0.0);
const float MIE_SCALE_HEIGHT = 1200.0;
uniform float mie_factor = 0.85;

// general line-sphere intesection formula
// https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
// vec2 because it is vec2(t0, t1)
// t0 and t1 just being the time you enter/exit the sphere
vec2 sphere_intersection(float sphere_radius, vec3 sphere_center, vec3 line_origin, vec3 line_direction) {
	// the sphere
	// c - center point
	// r - radius of sphere
	// the line
	// o - origin of line
	// u - direction of line (vector)
	// abcd
	// a = u * u = ||u||^2 = 1 (if normalized)
	// *double absolute value squared is dot product: ||v||^2 = dot(v,v)
	float a = dot(line_direction, line_direction);
	// b = 2(u * (o - c)) = 2u(o - c)
	// u(o - c) = dot(o - c, u)
	vec3 o_c = line_origin - sphere_center;
	float b = 2.0*dot(o_c, line_direction);
	// c = (o - c)(o - c) - r^2 = ||o - c||^2 - r^2 = dot(o - c, o - c) - r^2
	float c = dot(o_c, o_c) - sphere_radius*sphere_radius;
	// d - distance from origin of line
	// ad^2 + bd + c = 0
	// d is just quadratic formula! how math!
	// d = (-b +- sqrt(b^2-4ac)) / 2a
	// currently only have b^2-4ac to determine how many points of intersection
	float d = b*b - 4.0*a*c;
	if (d < 0.0) { // no intersect
		return vec2(-1.0); // return -1 for no intersect
	}
	// return the full calculated d, the +- and /2a for all values
	d = sqrt(d);
	return vec2(-b - d, -b + d) / (a * 2.0);
}

// the place of the ray that intersects the atmosphere
// just calls sphere intersection with prefilled parameters
vec2 atmosphere_intersection(vec3 ray_origin, vec3 ray_direction) {
	// since we are calculating light intersecting the atmosphere, we are using planet radius + atmosphere height
	return sphere_intersection(PLANET_RADIUS+ATMOSPHERE_HEIGHT, PLANET_CENTER, ray_origin, ray_direction);
}

// the place of the ray that intersects the ground
vec2 ground_intersection(vec3 ray_origin, vec3 ray_direction) {
	return sphere_intersection(PLANET_RADIUS, PLANET_CENTER, ray_origin, ray_direction);
}

// the height above/below sea level
// distance from center - planet radius
float altitude(vec3 point) {
	// determined by a vec3 point
	return length(point - PLANET_CENTER) - PLANET_RADIUS;
}

// density is how dense the air is or how dense/powerful the scattering is
// we are modeling the density using an equation and a scale height
// general model: density = e^(-altitude / scale height)
float rayleigh_density(float altitude) {
	return exp(-max(altitude, 0.0) / RAYLEIGH_SCALE_HEIGHT);
}

float mie_density(float altitude) {
	return exp(-max(altitude, 0.0) / MIE_SCALE_HEIGHT);
}

// phase is light scatter
float rayleigh_phase(float mu) {
	// rayleigh phase = 3/4 * (1 + cos^2(scattering angle))
	// normalize by multiplying 1/4pi
	// mu = cos(scattering angle) which is actually just dot(view_dir, sun_dir)
	return (1.0 + mu * mu) * 3.0 / (16.0 * PI);
}

float mie_phase(float mu, float g) {
	// mie scattering using the henyey greenstein (HG) model
	// probability of scattering = (1 / 4pi) * (1 - g^2)/(1 + g^2 - 2gcos(scattering angle))^3/2
	// g is the asymmetry factor, or mie_factor
	float g2 = g * g;
	return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * mu, 1.5));
}

// optical depth
// calculates the amount of rayleigh air and mie haze a ray is passing through
// taking n steps throughout its journey, interpolates the rest for a function
// lastly adds them up to a sum / (approximation of) the integral of the function / the area below the function
// does this calculation for both rayleigh and mie, so returns vec2
vec2 optical_depth(vec3 ray_origin, vec3 ray_direction, float t0, float t1, int steps) {
	// length of the ray that is inside the atmosphere
	float ray_length = t1 - t0;
	// if the ray is invalid, negative or no length
	if (ray_length <= 0.0) {
		return vec2(0.0);
	}
	// total length / how many steps
	float step_size = ray_length / float(steps);
	// total depth to be added up
	vec2 total_depth = vec2(0.0);
	// start looooooooping
	for (int i = 0; i < steps; i++) {
		// sample each value at the middle
		// find the x value, or time t to sample
		float time = t0 + (0.5 + float(i)) * step_size;
		// get the actual point location that we are sampling
		vec3 point = ray_origin + ray_direction * time;
		// get the altitude of the point to find density
		float altitude = altitude(point);
		// get the values of the rayleigh and mie
		float rayleigh_density = rayleigh_density(altitude);
		float mie_density = mie_density(altitude);
		// first one is rayleigh, second is mie, third (if it exists) is ozone
		// multiply by step size to approximate the integral
		total_depth += vec2(rayleigh_density, mie_density) * step_size;
	}
	return total_depth;
}

// absorb light based on the optical depth of the air
// what should it output?
vec3 ray_absorb() {
	return vec3(0.0);
}

// the final function?
vec2 ray_scatter() {
	return vec2(0.0);
}

// Called for every visible pixel in the sky background, as well as all pixels
// in the radiance cubemap.
void sky() {
	// environment stuff
	vec3 c = vec3(0.0); // final color that will be applied
	vec3 top = vec3(0.0,1.0,0.0); // the top of the world/zenith
	vec3 view_dir = normalize(EYEDIR); // the direction where this pixel is
	float height = view_dir.y; // how high this pixel is, -1..1
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0); // shifting height -1..1 to 0..1
	// sun and moon
	vec3 sun_dir = top; // default to top
	if (LIGHT0_ENABLED) { sun_dir = normalize(LIGHT0_DIRECTION); }
	vec3 moon_dir = top; // default to top
	if (LIGHT1_ENABLED) { moon_dir = normalize(LIGHT1_DIRECTION); }
	COLOR = c;
}
