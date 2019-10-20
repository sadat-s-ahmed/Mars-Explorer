shader_type spatial;

uniform vec4 rock_tint :hint_color = vec4(1.0);
uniform sampler2D rock_texture :hint_albedo;
uniform sampler2D rock_normal :hint_normal;
uniform vec2 rock_uv_scale = vec2(1.);
uniform float rock_fresnel = 4.208;
uniform float rock_specularity = 0.0;

uniform vec4 dirt_tint :hint_color = vec4(1.0);
uniform sampler2D dirt_texture :hint_albedo;
uniform sampler2D dirt_normal :hint_normal;
uniform vec2 dirt_uv_scale = vec2(1.);
uniform float dirt_fresnel = 2.42;
uniform float dirt_specularity = 0.2;

uniform vec4 subsurf_color : hint_color;

uniform bool has_normal_map = false;
uniform bool has_subsurface = false;
uniform bool has_sheen = true;
uniform bool has_specularity = true;
uniform bool has_roughness = true;

uniform float specularity : hint_range(0.0, 1.0) = 0.5;
uniform float specular_tint : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float sheen : hint_range(0.0, 1.0) = 0.5;
uniform float sheen_tint : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.5;
uniform float subsurface : hint_range(0.0, 1.0) = 0.0;

varying float height_value;
varying vec3 normal;
void vertex(){
	height_value = VERTEX.y;
	normal = NORMAL;
}

float get_slope_of_terrain(float height_normal){
	float slope = pow(clamp(abs(height_normal), 0., 1.), 8.);
	return slope;
}

vec3 get_tinted_color(vec3 tint, vec3 tex){
	return (tex.xyz * tint.xyz);
//	return tex.xyz + (tex.xyz * tint.xyz);
}

vec3 get_sampled_texture(sampler2D tex, vec2 uv, vec2 uv_scale){
	vec4 col = texture(tex, uv * uv_scale);
	return col.xyz;
}

void fragment(){
	vec2 uv = UV;
	vec3 dirt = get_tinted_color(dirt_tint.xyz, get_sampled_texture(dirt_texture, uv, dirt_uv_scale));
	vec3 rock = get_tinted_color(rock_tint.xyz, get_sampled_texture(rock_texture, uv, rock_uv_scale));
	vec3 rock_n = get_sampled_texture(rock_normal, uv, rock_uv_scale);
	vec3 dirt_n = get_sampled_texture(dirt_normal, uv, dirt_uv_scale);
	
	float slope = get_slope_of_terrain(normal.y);
	
	vec3 albedo = mix(rock, dirt, slope);
	
	if (has_normal_map){
		NORMALMAP = mix(rock_n, dirt_n, slope);
		NORMALMAP_DEPTH = 0.6;
	}
	ALBEDO = albedo;
	
	// DEBUG
//	ALBEDO = normal;
}

// Simplified fresnel equation taken from the Disney BRDF paper
float fresnel(float LdotH){
	return pow(clamp(1.0-LdotH, 0., 1.), 5.);
}

// Taken Straight from Disney BRDF. Loved the color space selection!
// Adds a nice little depth to the colors
vec3 mon2lin(vec3 color){
	return vec3(pow(color.x, 2.2),pow(color.y, 2.2),pow(color.z, 2.2));
	
}

// Use lambertian diffuse as the base
vec3 calculate_lambertian_diffuse(float NdotL, vec3 color, vec3 light_col){
	float PI = 3.14159265358979323846;
	float theta = smoothstep(0., 1., NdotL);
	vec3 diffuse_component = ((light_col * color) * theta);
	return diffuse_component;
}

// Adjust lambertian diffuse using the scattering effect of micro facets
float calculate_scattering_diffuse(float LdotH, float fresnel_NdotL, float fresnel_NdotV){
	fresnel_NdotV = abs(fresnel_NdotV);
	fresnel_NdotL = abs(fresnel_NdotL);
	float adjacent_fresnel = 0.5 + 2. * pow(LdotH, 2.) * roughness;
	return mix(1., adjacent_fresnel, fresnel_NdotL) * mix(1., adjacent_fresnel, fresnel_NdotV);
}

// Adjust lambertian diffuse using subsurface scattering
float calculate_subsurface_diffuse(float LdotH, float fresnel_NdotL, float fresnel_NdotV, float NdotL, float NdotV){
	float adjacent_fresnel = sqrt(LdotH) * roughness;
	float subsurf_diffuse = pow(mix(1., adjacent_fresnel, fresnel_NdotL) * 
							mix(1., adjacent_fresnel, fresnel_NdotV), 2.);
	float intensity_adjustment =  1.25 * (subsurf_diffuse * (1. / (NdotL + NdotV) - .5) + .5);
	return intensity_adjustment;
}

// Calculate specular based on the blinn-phong shader
vec3 calculate_lambertian_specular(float NdotH, float NdotL, vec3 color, vec3 light_col){
	float spec = pow(NdotH, 256.0 * max(0.0001, specularity));
	float theta = smoothstep(0., 1., NdotL);
	return (20.0 * max((1. / 20.),metallic)) * mix(color, mix(light_col, color, max(specular_tint, metallic)), specularity) * spec * theta;
}

// Add sheen fro the burley shader based on the luminance and viewing angle between light and view
vec3 calculate_burley_sheen(vec3 color, vec3 light, float fresnel_LdotH){
	float lum = .3*color.x + .6*color.y  + .1*color.z;
	vec3 tint = lum > 0. ? color/lum : light;
    vec3 color_sheen = mix(light, tint, sheen_tint);
	return (sqrt(fresnel_LdotH) * color_sheen) * (sheen + metallic);
}

void light(){
	float PI = 3.14159265358979323846;
	
	vec3 color = mon2lin(ALBEDO);
	vec3 light = mon2lin(LIGHT_COLOR);
	
	vec3 H = normalize(LIGHT+VIEW);
	float NdotL = dot(NORMAL, LIGHT);
	float NdotV = dot(NORMAL, VIEW);
	
//	if (NdotL < 0. || NdotV < 0.){
//		return;
//	}
	
	float NdotH = dot(NORMAL, H);
	float LdotH = dot(LIGHT, H);
	float LdotV = dot(LIGHT, VIEW);
	
	float fresnel_NdotL = fresnel(NdotL);
	float fresnel_NdotV = fresnel(NdotV);
	float fresnel_LdotH = fresnel(LdotH);
	
	vec3 light_comp = calculate_lambertian_diffuse(NdotL, color, light);
	float scattering_comp = 1.0;
	if (has_roughness){
		scattering_comp = calculate_scattering_diffuse(LdotH, fresnel_NdotL, fresnel_NdotV) * (1.0 - subsurface);
	}
	if (has_subsurface){
		scattering_comp += calculate_subsurface_diffuse(LdotH, fresnel_NdotL, fresnel_NdotV, NdotL, NdotV) * (subsurface);
		vec3 scattered_color = subsurf_color.xyz * scattering_comp * subsurface;
		light_comp += scattered_color;
	}
	light_comp *= scattering_comp;
	light_comp *= (1.0-metallic);
	vec3 specular_comp = vec3(0.);
	if (has_sheen){
		specular_comp += (calculate_burley_sheen(color, light, fresnel_LdotH) * NdotL) * pow(1.0 - NdotV, 4.);
	}
	if (has_specularity){
		specular_comp += calculate_lambertian_specular(NdotH, NdotL, color, light);
	}
	light_comp += specular_comp;
	light_comp *= smoothstep(0., 1., NdotL);
	light_comp /= PI;
	DIFFUSE_LIGHT += clamp(light_comp, vec3(0.), vec3(1.)) * ATTENUATION;
}
