shader_type sky;

// HOW IS THIS POSSIBLE WOAHHH
const float INFINITY = 1.0 / 0.0;

// the planet
const float PLANET_RADIUS = 6371000.0; // radius of the planet, duh
const vec3 PLANET_CENTER = vec3(0.0, -PLANET_RADIUS-0.250000015, 0.0); // assumes y=0 is planet surface/sea level
const float ATMOSPHERE_HEIGHT = 100000.0; // how high the atmosphere is, this one uses the karman line
// atmosphere
// rayleigh
const vec3 RAYLEIGH_BETA = vec3(5.8e-6, 13.5e-6, 33.1e-6); // correct ratios, values not true
const float RAYLEIGH_SCALE_HEIGHT = 8300.0;
// mie
const vec3 MIE_BETA = vec3(2.0e-6);
const float MIE_SCALE_HEIGHT = 1200.0;
uniform float mie_factor = 0.85;

// what would be good variable names for these?
// how does one explain their purpose
uniform int process_steps = 8;
uniform int sunlight_steps = 4;

uniform float exposure = 30.0;

// general line-sphere intesection formula
// https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
// vec2 because it is vec2(t0, t1)
// t0 and t1 just being the time you enter/exit the sphere
vec2 get_sphere_intersection(float sphere_radius, vec3 sphere_center, vec3 line_origin, vec3 line_direction) {
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
vec2 get_atmosphere_intersection(vec3 ray_origin, vec3 ray_direction) {
	// since we are calculating light intersecting the atmosphere, we are using planet radius + atmosphere height
	return get_sphere_intersection(PLANET_RADIUS+ATMOSPHERE_HEIGHT, PLANET_CENTER, ray_origin, ray_direction);
}

// the place of the ray that intersects the ground / solid part of the planet
vec2 get_ground_intersection(vec3 ray_origin, vec3 ray_direction) {
	return get_sphere_intersection(PLANET_RADIUS, PLANET_CENTER, ray_origin, ray_direction);
}

// general planet intersection that considers only the segment that travels through the atmosphere
// starts at atmosphere entry and ends at either atmosphere exit or ground hit
vec2 get_planet_intersection(vec3 ray_origin, vec3 ray_direction) {
	vec2 atm = get_atmosphere_intersection(ray_origin, ray_direction);
	// if never intersected atmosphere or behind?
	if (atm.y <= 0.0) {
		return vec2(-1.0);
	}
	// if origin is inside atmosphere, it will result in negative t0
	// just clamp it to 0 if that's the case
	// note, t0 should always be somewhere in the atmosphere
	float t0 = max(atm.x, 0.0);
	// already checked atm.y, all good
	// t1 could either be ground contact or atmosphere exit
	// the first one to reach is considered
	float t1 = atm.y;
	// consider ground intersection
	vec2 gnd = get_ground_intersection(ray_origin, ray_direction);
	if (gnd.x > 0.0) {
		t1 = min(t1, gnd.x);
	}
	// extra check just in case, gets rid of invalid ray segments
	if (t1 < t0) {
		return vec2(-1.0);
	}
	return vec2(t0, t1);
}

// the height above/below sea level
// distance from center - planet radius
float get_altitude(vec3 point) {
	// determined by a vec3 point
	return length(point - PLANET_CENTER) - PLANET_RADIUS;
}

// density is how dense the air is or how dense/powerful the scattering is
// we are modeling the density using an equation and a scale height
// general model: density = e^(-altitude / scale height)
float get_rayleigh_density(float altitude) {
	return exp(-max(altitude, 0.0) / RAYLEIGH_SCALE_HEIGHT);
}

// same thing for mie
float get_mie_density(float altitude) {
	return exp(-max(altitude, 0.0) / MIE_SCALE_HEIGHT);
}

// phase is light scatter
// how likely the scattered light will be in the direction of the camera
float get_rayleigh_phase(float mu) {
	// rayleigh phase = 3/4 * (1 + cos^2(scattering angle))
	// normalize by multiplying 1/4pi
	// mu = cos(scattering angle) which is actually just dot(view_dir, sun_dir)
	return (1.0 + mu * mu) * 3.0 / (16.0 * PI);
}

float get_mie_phase(float mu, float g) {
	// mie scattering using the henyey greenstein (HG) model
	// probability of scattering = (1 / 4pi) * (1 - g^2)/(1 + g^2 - 2gcos(scattering angle))^3/2
	// g is the asymmetry factor, or mie_factor
	float g2 = g * g;
	float denominator_part = max(1e-3, 1.0 + g2 - 2.0 * g * mu);
	return (1.0 - g2) / (4.0 * PI * pow(denominator_part, 1.5));
}

// optical depth
// calculates the total amount of rayleigh air and mie haze a ray is passing through
// taking n steps throughout its journey, adds them up to a sum
// or actually approximation of the integral of the function
// does this calculation for both rayleigh and mie, so returns vec2
vec2 get_optical_depth(vec3 ray_origin, vec3 ray_direction, float t0, float t1, int steps) {
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
	for (int i = 0; i < 64; i++) {
		if (i >= steps) {break;}
		// sample each value at the middle
		// find the x value, or time t to sample
		float time = t0 + (0.5 + float(i)) * step_size;
		// get the actual point location that we are sampling
		vec3 point = ray_origin + ray_direction * time;
		// get the altitude of the point to find density
		float altitude = get_altitude(point);
		// get the values of the rayleigh and mie
		float rayleigh_density = get_rayleigh_density(altitude);
		float mie_density = get_mie_density(altitude);
		// first one is rayleigh, second is mie, third (if it exists) is ozone
		// multiply by step size to approximate the integral
		total_depth += vec2(rayleigh_density, mie_density) * step_size;
	}
	return total_depth;
}

// absorb light based on the optical depth of the air
// returns the factor of rgb that are left
vec3 get_ray_absorb(vec2 optical_depth) {
	// modified beer lambert law
	// transmittance = e^-(total optical depth)
	// total optical depth = (rayleigh beta * rayleigh optical depth) + (mie beta * mie optical depth) + (ozone beta * ozone optical depth)
	return exp(-(optical_depth.x * RAYLEIGH_BETA + optical_depth.y * MIE_BETA));
}

// how much scattered light still reaches the camera
// returns the amount of light you should add back in
vec3 get_ray_scatter(vec3 ray_origin, vec3 ray_direction, vec3 sun_direction,
float t0, float t1, int view_steps, int sun_steps) {
	// length of the ray that is inside the atmosphere
	float ray_length = t1 - t0;
	// if the ray is invalid, negative or no length
	if (ray_length <= 0.0) {
		return vec3(0.0);
	}
	// get the size of the step
	float step_size = ray_length / float(view_steps);

	// the optical depth, accumulates over time so that it can calculate
	// the amount of optical depth that goes from the camera to the current scatter point
	vec2 view_optical_depth = vec2(0.0);
	// the amount of skylight that got scattered but still reached the camera
	vec3 radiance = vec3(0.0);

	// the cos(scattering angle) referenced in the phase functions
	float mu = clamp(dot(ray_direction, sun_direction), -1.0, 1.0);

	float rayleigh_phase = get_rayleigh_phase(mu);
	float mie_phase = get_mie_phase(mu, mie_factor);

	// calculate scattering
	for (int i = 0; i < 64; i++) {
		if (i >= view_steps) {break;}
		// first transmittance
		// the factor loss of sunlight from scatter point to the camera
		// same thing as optical depth loop above
		float time = t0 + (0.5 + float(i)) * step_size;
		vec3 point = ray_origin + ray_direction * time;
		float altitude = get_altitude(point);
		float rayleigh_density = get_rayleigh_density(altitude);
		float mie_density = get_mie_density(altitude);
		view_optical_depth += vec2(rayleigh_density, mie_density) * step_size;
		vec3 view_transmittance = get_ray_absorb(view_optical_depth);
		// second transmittance
		// the factor loss of the sunlight from top of atmosphere to the scatter point
		vec2 sunlight_segment = get_planet_intersection(point, sun_direction);
		if (sunlight_segment.x < 0.0) {
			continue;
		}
		float scatter_t0 = max(sunlight_segment.x, 0.0);
		float scatter_t1 = sunlight_segment.y;
		vec2 sunlight_optical_depth = get_optical_depth(point, sun_direction, scatter_t0, scatter_t1, sun_steps);
		vec3 sunlight_transmittance = get_ray_absorb(sunlight_optical_depth);
		// the amount of rgb light that gets redirected back into view per meter traveled at this point
		vec3 scatter_coefficient =
			RAYLEIGH_BETA * rayleigh_density * rayleigh_phase +
			MIE_BETA * mie_density * mie_phase;
		// how much more the sky glows from this segment is added to the total
		// size * scatter coefficient is the x * y for integral estimation
		// then multiply that area (now the amount of light) by how much makes it through the two stages
		// the two stages being loss from top of atmosphere -> scatter point and
		// loss from scatter point -> camera
		radiance += view_transmittance * sunlight_transmittance * scatter_coefficient * step_size;
	}
	return radiance;
}

// the final function...
vec3 get_sky_radiance(vec3 view_dir, vec3 sun_dir) {
	// ray starts at the camera
	vec3 ray_origin = vec3(0.0);
	// the actual segment that
	vec2 view_segment = get_planet_intersection(ray_origin, view_dir);
	// if the ray is invalid
	if (view_segment.x < 0.0) {
		return vec3(0.0);
	}
	// the ultimate call
	vec3 skylight = get_ray_scatter(ray_origin, view_dir, sun_dir, view_segment.x, view_segment.y, process_steps, sunlight_steps);
	return skylight;
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
	// get the sky radiance
	c = get_sky_radiance(view_dir, sun_dir);
	COLOR = c * exposure;
}
