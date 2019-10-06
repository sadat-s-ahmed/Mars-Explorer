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

varying float height_value;
varying vec3 normal;
void vertex(){
	height_value = VERTEX.y;
	normal = NORMAL;
}

float get_slope_of_terrain(float height_normal){
	float slope = pow(clamp(abs(height_normal), 0., 1.), 16.);
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
	
	NORMALMAP = mix(rock_n, dirt_n, slope);
	NORMALMAP_DEPTH = 8.0;
//	NORMAL  = mix(normalize(NORMAL + dirt_n), normalize(NORMAL + rock_n), slope);
	
	ALBEDO = albedo;
}
float fresnel(float n1, float n2, float cos_theta) {
	float R0 = pow((n1 - n2) / (n1+n2), 2);
	return R0 + (1.0 - R0)*pow(1.0 - cos_theta, 5);
}

void light(){
	float NdotL = max(dot(NORMAL, LIGHT), 0.);

	float NdotV = max(dot(NORMAL, VIEW), 0.);
	float slope = get_slope_of_terrain(normal.y);
	float reflectiveness = clamp(fresnel(1.000, mix(rock_fresnel, dirt_fresnel, -pow(slope, 2.0)), NdotV), 0., 1.);
	reflectiveness *= 1.0-abs(dot(LIGHT, VIEW));

	vec3 specular = LIGHT_COLOR * ALBEDO * pow(NdotL, max(256.0 * mix(rock_specularity, dirt_specularity, slope), 2.0));
	specular += LIGHT_COLOR * ALBEDO * reflectiveness;

	vec3 diffuse = ALBEDO * LIGHT_COLOR * NdotL;
	diffuse += ALBEDO * LIGHT_COLOR * reflectiveness * NdotL;
	DIFFUSE_LIGHT += (diffuse+specular) * ATTENUATION;
	SPECULAR_LIGHT += (specular) * ATTENUATION;
}