shader_type sky;

// HOW IS THIS POSSIBLE WOAHHH
const float INFINITY = 1.0 / 0.0;

// the planet
const float PLANET_RADIUS = 6371000.0; // radius of the planet, duh
const vec3 PLANET_CENTER = vec3(0.0, -PLANET_RADIUS, 0.0); // assumes y=0 is planet surface/sea level
const float ATMOSPHERE_HEIGHT = 100000.0; // how high the atmosphere is, this one uses the karman line

group_uniforms world;
	uniform float camera_altitude: hint_range(0.5, 99999.0, 0.01) = 0.5;
	uniform float exposure: hint_range(0.0, 80.0, 0.5) = 13.5;
	uniform vec3 ground_color: source_color = vec3(0.12, 0.09, 0.07);

group_uniforms sun;
	uniform float sun_strength: hint_range(0.0, 500.0, 1.0) = 300.0;
	uniform float sun_size_deg: hint_range(0.0, 20.0, 0.1) = 3.0;
	uniform float sun_softness: hint_range(0.01, 1.0, 0.01) = 0.15;
	uniform float sun_glow_size: hint_range(0.0, 40.0, 0.1) = 5.0;
	uniform float sun_glow_strength: hint_range(0.0, 1.0, 0.01) = 0.3;
	uniform vec3 sun_base_color: source_color = vec3(1.0, 1.0, 1.0);

group_uniforms moon;
	// currently not implemented...
	uniform float moon_strength: hint_range(0.0, 50.0, 0.1) = 3.0;
	uniform float moon_size_deg: hint_range(0.0, 20.0, 0.1) = 5.0;
	uniform float moon_softness: hint_range(0.01, 0.3, 0.01) = 0.03;
	uniform float moon_glow_size: hint_range(0.0, 20.0, 0.5) = 1.5;
	//uniform float moon_glow_

group_uniforms rayleigh;
	uniform float rayleigh_strength: hint_range(0.0, 8.0, 0.1) = 1.0;
	uniform float rayleigh_scale_height: hint_range(1000.0, 20000.0, 50.0) = 8300.0;
	const vec3 RAYLEIGH_BETA = vec3(5.802, 13.558, 33.100) * 1e-6; // correct ratios, values not true

group_uniforms mie;
	uniform float mie_strength: hint_range(0.0, 8.0, 0.1) = 1.0;
	uniform float mie_scale_height: hint_range(500.0, 15000.0, 50.0) = 1200.0;
	uniform float mie_g: hint_range(0.0, 0.99, 0.01) = 0.85;
	const vec3 MIE_BETA = vec3(3.996) * 1e-6;

group_uniforms ozone;
	uniform float ozone_strength: hint_range(0.0, 8.0, 0.1) = 1.0;
	uniform float ozone_scale_height: hint_range(1000.0, 20000.0, 50.0) = 7000.0;
	uniform float ozone_peak_altitude: hint_range(1000.0, 50000.0, 100.0) = 20000.0;
	const vec3 OZONE_BETA = vec3(0.650, 1.881, 0.085) * 1e-6;

group_uniforms sampling_steps;
	uniform int view_ray_steps: hint_range(1, 64, 1) = 16;
	uniform int sun_ray_steps: hint_range(1, 64, 1) = 3;

group_uniforms importance_sampling;
	// essentially importance sampling is placing more steps where it is important
	uniform bool enable_importance_sampling = true;
	// 'is' for importance sampling
	// 0 is completely uniform distribution
	// 1 is extremely unequal distribution
	uniform float is_factor: hint_range(0.0, 1.0, 0.01) = 0.5;
	// the relative weights/more or less steps that these three components get
	uniform float rayleigh_weight: hint_range(-1.0, 1.0, 0.01) = 0.0;
	uniform float mie_weight: hint_range(-1.0, 1.0, 0.01) = 0.0;
	uniform float ozone_weight: hint_range(-1.0, 1.0, 0.01) = 0.0;
	const int IS_WEIGHT_STEPS = 16;

group_uniforms adaptive_step_size;
	uniform bool enable_adaptive_step = false;
	// how extreme the curve, or the difference between high and low samples
	// higher -> better performance & lower quality
	uniform float as_factor: hint_range(0.0, 30.0, 0.1) = 10.0;
	// samples along the camera to the pixel ray
	// high performance impact
	// performance / quality
	// for better quality and no color banding, try 16 & 36
	uniform int view_ray_min_steps: hint_range(1, 64, 1) = 16;
	uniform int view_ray_max_steps: hint_range(1, 64, 1) = 36;
	// sample along the sample to sun ray
	// best to leave the same, or there will be bands of differing light strengths
	uniform int sun_ray_min_steps: hint_range(1, 64, 1) = 3;
	uniform int sun_ray_max_steps: hint_range(1, 64, 1) = 3;

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

// handles the rays that go from the camera to a pixel in the sky
// ground is a valid point unlike sunlight intersection below
vec2 get_planet_intersection(vec3 ray_origin, vec3 ray_direction) {
	vec2 atm = get_atmosphere_intersection(ray_origin, ray_direction);
	// if never intersected atmosphere or behind origin
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
	float t1 = max(atm.y, 0.0);
	// consider ground intersection
	vec2 gnd = get_ground_intersection(ray_origin, ray_direction);
	if (gnd.x > 0.0) {
		t1 = min(t1, gnd.x);
	}
	// extra check just in case, gets rid of invalid ray segments
	if (t1 <= t0) {
		return vec2(-1.0);
	}
	return vec2(t0, t1);
}

// handles the rays that goes from the sunlight to the scatter point
// if the sunlight hits the ground, then it is invalid
vec2 get_sunlight_intersection(vec3 point, vec3 sun_dir) {
	vec2 atm = get_atmosphere_intersection(point, sun_dir);
	// if never intersected atmosphere or behind origin
	if (atm.y <= 0.0) {
		return vec2(-1.0);
	}
	float t0 = max(atm.x, 0.0);
	float t1 = atm.y;
	vec2 gnd = get_ground_intersection(point, sun_dir);
	// if the planet was hit before leaving atmosphere
	if (gnd.x > 0.0 && gnd.x < t1) {
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
// returns 0..1 for thin -> dense atmosphere
float get_rayleigh_density(float altitude) {
	return exp(-max(altitude, 0.0) / rayleigh_scale_height);
}

// same thing for mie
float get_mie_density(float altitude) {
	return exp(-max(altitude, 0.0) / mie_scale_height);
}

// ozone is a bit different since it's only near the top
float get_ozone_density(float altitude) {
	// using the chapman theory
	// taken from here
	// https://en.wikipedia.org/wiki/Chapman_function
	float x = (max(altitude, 0.0) - ozone_peak_altitude) / ozone_scale_height;
	return exp(-x - exp(-x));
}

// overall function for all 3 densities
vec3 get_atmosphere_density(float altitude) {
	return vec3(get_rayleigh_density(altitude), get_mie_density(altitude), get_ozone_density(altitude));
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
	// g is the asymmetry factor, or mie_g
	float g2 = g * g;
	float denominator_part = max(1e-3, 1.0 + g2 - 2.0 * g * mu);
	return (1.0 - g2) / (4.0 * PI * pow(denominator_part, 1.5));
}

// there is exponentially less high steps than low steps
// as the varying vector increases, the amount of steps exponentially increases
// weighing horizon as important to sample more
int get_adaptive_steps(float mu, int low_steps, int high_steps) {
	// get the horizon factor so that zenith is 0 and horizon is 1
	float horizon_factor = 1.0 - abs(mu);
	// how the two steps values are mixed
	float mix_factor = pow(horizon_factor, as_factor);
	// get the smooth float version of the steps
	float steps_float = mix(float(low_steps), float(high_steps), mix_factor);
	// round up or down properly
	int steps = int(floor(steps_float + 0.5));
	return steps;
}

// simple helper to convert -1..1 to 0.25..4.0
float get_is_multiplier(float weight) {
	return exp2(2.0 * weight);
}

float get_importance_weight(float altitude) {
	vec3 density = get_atmosphere_density(altitude);
	vec3 multiplier = vec3(
		get_is_multiplier(rayleigh_weight),
		get_is_multiplier(mie_weight),
		get_is_multiplier(ozone_weight));
	// weigh importance based on density for now
	// just a simple dot product will consider both multiplier and density
	// so we end up with a single weight value
	float weight = dot(density, multiplier);
	// clamp to just above 0
	return max(weight, 1e-6);
}

// when we're getting more weight, the sample position will be more concentrated
// returns the shifted u value for a given u
// 'u' is just the location we are taking the sample (called 'time' in the other function)
// we are shifting u based on the weight
// on a high level, we are trying to get a more accurate approximation of the integral of the scatter function
// by making a second function get_importance_weight() that tells us where the first function is important
// we now know where the first function is important, but we have limited steps, so how do we evenly distribute it?
// if we just approximate the integral of the second function get_importance_weight()
// we can use that area below the function and divide it up so that each step has the same slice of area
// so the altitudes with less weight has steps that cover a larger horizontal distance x (or in our case, altitude)
// and the altitudes with more weight would have steps that cover a smaller horizontal distance x (altitude)
// so yay! we now have steps that are more concentrated on the important parts
// we can pretty easily find 'u' now because we know where each step starts and ends
// this little bit of integral approximation concept only took me a couple hours to understand...
float get_weighted_u(vec3 ray_origin, vec3 ray_dir, float t0, float t1, float u) {
	float ray_length = t1 - t0;
	if (ray_length < 0.0) {
		return u;
	}
	// let's call the function that tells us the weight of the scatter function 'w'
	// w will be approximated first by IS_WEIGHT_STEPS of steps
	float w_step_size = ray_length / float(IS_WEIGHT_STEPS); // how wide each step is for approximating w
	float w_area = 0.0; // integral approximation/total area of w
	// part 1
	// find the total area of w
	// loooooooooooooop for w
	for (int j = 0; j < IS_WEIGHT_STEPS; j++) {
		// the u (location of midpoint sample) for this segment/step
		float w_u = t0 + (0.5 + float(j)) * w_step_size;
		// get point so we can calculate altitude
		vec3 point = ray_origin + ray_dir * w_u;
		// the altitude at this point
		float altitude = get_altitude(point);
		// now we calculate the weight here
		float w = get_importance_weight(altitude);
		// add the area approximation in this step
		w_area += w * w_step_size;
	}
	// just in case if there isn't really anything significant
	// we just don't even sample by weight
	// shouldn't happen normally though, unless the atmosphere is very thin
	if (w_area <= 1e-8) {
		return u;
	}
	// part 2
	// find the x value, or weighted u based on the given u
	// using the given u and total area of w we can find the target area we want
	// essentially finding the x that corresponds to the accumulated area of the integral function
	// almost the same thing, but in reverse
	float target_area = u * w_area;
	float accumulated_area = 0.0;
	// almost the same loop, but we are trying to find the x rather than total area
	for (int j = 0; j < IS_WEIGHT_STEPS; j++) {
		// the u (location of midpoint sample) for this segment/step
		float w_u = t0 + (0.5 + float(j)) * w_step_size;
		// get point so we can calculate altitude
		vec3 point = ray_origin + ray_dir * w_u;
		// the altitude at this point
		float altitude = get_altitude(point);
		// now we calculate the weight here
		float w = get_importance_weight(altitude);
		// get the area approximation in this step
		float step_area = w * w_step_size;
		// check if the target area has been reached this step
		if (accumulated_area + step_area >= target_area) {
			// now we pinpoint exactly where it is to give back the weighted u
			// this would just be a linear approximation of the weighted u
			// the x is at which fraction/percentage inside this step? (assuming linear increase)
			float step_percent = (target_area - accumulated_area) / max(step_area, 1e-8); // no divide by 0
			// at what x value did this step start?
			float step_start = float(j) * w_step_size;
			// finally, add up the x, or weighted u value and return
			return step_start + step_percent * w_step_size;
		}
		// if no hit, just add up the area and continue
		accumulated_area += step_area;
	}
	// uh oh, somehow there wasn't a hit???
	// just return something
	return u;
}

// optical depth
// calculates the total amount of rayleigh air and mie haze a ray is passing through
// taking n steps throughout its journey, adds them up to a sum
// or actually approximation of the integral of the function
// does this calculation for both rayleigh and mie, so returns vec2
vec3 get_optical_depth(vec3 ray_origin, vec3 ray_direction, float t0, float t1, int steps) {
	// length of the ray that is inside the atmosphere
	float ray_length = t1 - t0;
	// if the ray is invalid, negative or no length
	if (ray_length <= 0.0) {
		return vec3(0.0);
	}
	// total length / how many steps
	float step_size = ray_length / float(steps);
	// total depth to be added up
	vec3 total_depth = vec3(0.0);
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
		// first one is rayleigh, second is mie, third is ozone
		// multiply by step size to approximate the integral
		total_depth += get_atmosphere_density(altitude) * step_size;
	}
	return total_depth;
}

// absorb light based on the optical depth of the air
// returns the factor of rgb that are left
vec3 get_ray_absorb(vec3 optical_depth) {
	// modified beer lambert law
	// transmittance = e^-(total optical depth)
	// total optical depth = (rayleigh beta * rayleigh optical depth) + (mie beta * mie optical depth) + (ozone beta * ozone optical depth)
	return exp(-(optical_depth.x * RAYLEIGH_BETA * rayleigh_strength +
		optical_depth.y * MIE_BETA * mie_strength +
		optical_depth.z * OZONE_BETA * ozone_strength));
}

// dims the side opposite of the sun
// currently unused
vec3 get_antisolar_absorb(vec3 view_dir, vec3 sun_dir) {
	vec3 top = vec3(0.0,1.0,0.0);
	// how close the sun is to the top
	// zenith to horizon: 0..1
	float sun_alt = 1.0 - clamp(dot(sun_dir, top) * 0.5 + 0.5, 0.0, 1.0);
	// how opposite this ray is to the sun
	// opposite to same: 0..1
	float opposite = clamp(dot(view_dir, sun_dir) * 0.5 + 0.5, 0.0, 1.0);

	vec3 antisolar_beta = vec3(0.85, 0.90, 0.95);
	return antisolar_beta * exp(opposite);
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
	vec3 view_optical_depth = vec3(0.0);
	// the amount of skylight that got scattered but still reached the camera
	vec3 radiance = vec3(0.0);
	// the cos(scattering angle) referenced in the phase functions
	float mu = clamp(dot(ray_direction, sun_direction), -1.0, 1.0);
	// get the phases/scattering values
	float rayleigh_phase = get_rayleigh_phase(mu);
	float mie_phase = get_mie_phase(mu, mie_g);
	// keep track of the previous time so we don't accidently go back
	float previous_time = t0;
	// calculate scattering
	for (int i = 0; i < 64; i++) {
		if (i >= view_steps) {break;}
		// first transmittance
		// the factor loss of sunlight from scatter point to the camera
		// getting the u so we can send it over if needed
		float u = (0.5 + float(i)) / float(view_steps);
		// now we calculate the weighted u, if applicable
		if (enable_importance_sampling && is_factor > 0.0) {
			float u_weighted = get_weighted_u(ray_origin, ray_direction, t0, t1, u);
			// mix it up! by the user defined factor of course
			u = mix(u, u_weighted, is_factor);
		}
		// here is the actual time we're using
		float time = t0 + u * ray_length;
		// just to make sure we're not going backwards
		time = max(time, previous_time);
		// the new step size for this step
		// replaces the original step_size
		float weighted_step_size = time - previous_time;
		// and then just update the previous time for next iteration
		previous_time = time;
		vec3 point = ray_origin + ray_direction * time;
		float altitude = get_altitude(point);
		float rayleigh_density = get_rayleigh_density(altitude);
		vec3 atmosphere_density = get_atmosphere_density(altitude);
		view_optical_depth += atmosphere_density * weighted_step_size;
		vec3 view_transmittance = get_ray_absorb(view_optical_depth);
		// second transmittance
		// the factor loss of the sunlight from top of atmosphere to the scatter point
		vec2 sunlight_segment = get_sunlight_intersection(point, sun_direction);
		float scatter_t0 = max(sunlight_segment.x, 0.0);
		float scatter_t1 = sunlight_segment.y;
		vec3 sunlight_transmittance = vec3(0.0);
		if (sunlight_segment.x >= 0.0) {
			vec3 sunlight_optical_depth = get_optical_depth(point, sun_direction, scatter_t0, scatter_t1, sun_steps);
			sunlight_transmittance = get_ray_absorb(sunlight_optical_depth);
		}
		// the amount of rgb light that gets redirected back into view per meter traveled at this point
		vec3 scatter_coefficient =
			RAYLEIGH_BETA * rayleigh_strength * atmosphere_density.x * rayleigh_phase +
			MIE_BETA * mie_strength * atmosphere_density.y * mie_phase;
		// how much more the sky glows from this segment is added to the total
		// size * scatter coefficient is the x * y for integral estimation
		// then multiply that area (now the amount of light) by how much makes it through the two stages
		// the two stages being loss from top of atmosphere -> scatter point and
		// loss from scatter point -> camera
		radiance += view_transmittance * sunlight_transmittance * scatter_coefficient * weighted_step_size;
	}
	return radiance;
}

// calculates the proper disc in the sky of any celestial
float get_celestial_disc(vec3 view_dir, vec3 c_dir, float c_strength, float c_size_deg, float c_softness) {
	float angle = clamp(dot(view_dir, c_dir), -1.0, 1.0);
	// turn the -1..1 into radians -pi..pi
	float angle_rad = acos(angle);
	float disc_radius = radians(c_size_deg * 0.5); // planet disc in rad
	// the hard disc
	float disc = smoothstep(disc_radius, disc_radius * 0.5, angle_rad);
	// the soft edge
	float edge = smoothstep(disc_radius * (1.0 + c_softness), disc_radius, angle_rad) - disc;
	return clamp(disc * c_strength + edge, 0.0, c_strength);
}

// calculates the proper glow in the sky of any celestial
float get_celestial_glow(vec3 view_dir, vec3 c_dir, float c_size_deg,
float c_glow_size, float c_glow_strength, float disc_mask) {
	float angle = clamp(dot(view_dir, c_dir), -1.0, 1.0);
	// turn the -1..1 into radians -pi..pi
	float angle_rad = acos(angle);
	float disc_radius = radians(c_size_deg * 0.5); // planet disc in rad
	float glow_radius = disc_radius + radians(c_glow_size); // planet glow in rad
	// part for the exponential decay
	float glow_falloff = max(1e-6, glow_radius - disc_radius);
	// the glow with exponential falloff
	float glow = exp(-angle_rad / glow_falloff);
	// removes the glow boost to the disc itself
	glow *= (1.0 - disc_mask);
	return clamp(glow * c_glow_strength, 0.0, c_glow_strength);
}

// calculates the sun's color based on its elevation
// the color after it goes through the atmosphere
vec3 get_sun_transmittance(vec3 ray_origin, vec3 view_dir) {
	vec2 ray_segment = get_sunlight_intersection(ray_origin, view_dir);
	// if invalid, just skip
	if (ray_segment.x < 0.0) {
		return vec3(0.0);
	}
	int steps = sun_ray_max_steps;
	vec3 optical_depth = get_optical_depth(ray_origin, view_dir, ray_segment.x, ray_segment.y, steps);
	return get_ray_absorb(optical_depth);
}

// the moon function
// gets the moon phase from new moon -> full moon: 0..1
float get_moon_phase(vec3 view_dir, vec3 sun_dir, vec3 moon_dir) {
	
	return 0.0;
}

// the final function...
vec3 get_sky_radiance(vec3 top, vec3 view_dir, vec3 sun_dir, vec3 ray_origin, float exposure_sky) {
	// the actual segment that passes through the atmosphere only
	vec2 view_segment = get_planet_intersection(ray_origin, view_dir);
	// if the ray is invalid
	if (view_segment.x < 0.0) {
		return vec3(0.0);
	}
	float mu = clamp(dot(top, view_dir), -1.0, 1.0);
	int view_steps = view_ray_steps;
	int sun_steps = sun_ray_steps;
	if (enable_importance_sampling) {
		// TODO make the function
		view_steps = view_steps;
		sun_steps = sun_steps;
	} else if (enable_adaptive_step) {
		view_steps = get_adaptive_steps(mu, view_ray_min_steps, view_ray_max_steps);
		sun_steps = get_adaptive_steps(mu, sun_ray_min_steps, sun_ray_max_steps);
	}
	// the ultimate call
	vec3 skylight = get_ray_scatter(ray_origin, view_dir, sun_dir,
		view_segment.x, view_segment.y, view_steps, sun_steps);
	return skylight * exposure_sky; // as a color rgb
}

// Called for every visible pixel in the sky background, as well as all pixels
// in the radiance cubemap.
void sky() {
	// environment stuff
	vec3 c = vec3(0.0); // final color that will be applied
	vec3 top = vec3(0.0,1.0,0.0); // the top of the world/zenith
	vec3 view_dir = normalize(EYEDIR); // the direction where this pixel is
	float height = view_dir.y; // how high this pixel is, -1..1
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0); // shifting height -1..1 to 0..1\
	vec3 camera_origin = PLANET_CENTER + vec3(0.0, PLANET_RADIUS + camera_altitude, 0.0);
	// sun and moon
	vec3 sun_dir = top; // default to top
	if (LIGHT0_ENABLED) { sun_dir = normalize(LIGHT0_DIRECTION); }
	vec3 moon_dir = top; // default to top
	if (LIGHT1_ENABLED) { moon_dir = normalize(LIGHT1_DIRECTION); }
	// get the sky radiance
	// the camera origin is where the ray should start, ray origin
	c = get_sky_radiance(top, view_dir, sun_dir, camera_origin, exposure);
	// add the sun
	float sun_disc = get_celestial_disc(view_dir, sun_dir, sun_strength, sun_size_deg, sun_softness);
	float sun_glow = get_celestial_glow(view_dir, sun_dir, sun_size_deg, sun_glow_size, sun_glow_strength, sun_disc);
	if (sun_disc + sun_glow > 1e-4) {
		vec3 sun_color = sun_base_color * get_sun_transmittance(camera_origin, view_dir);
		// decrease the glow factor as we reach the horizon, don't want much glow in the night
		float glow_factor = clamp(dot(top, sun_dir) + 0.15, 0.0, 1.0);
		c += sun_color * sun_disc + sun_color * sun_glow * glow_factor;
	}
	COLOR = c;
}
