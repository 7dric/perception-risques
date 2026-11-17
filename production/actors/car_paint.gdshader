// Car body with a new paint colour (ADR-019). The pack's body textures are atlases mixing the
// paint (with baked shading) and the trims (plastic, chrome, black glass). The paint is found
// with the metallic-roughness texture: on all 10 models it is the only area with a roughness
// between about 0.06 and 0.13 (plastic is ~0.7, chrome and black glass ~0).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mr_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_normal = false;
/// New paint colour.
uniform vec3 paint : source_color = vec3(0.5);
/// Average luminance (linear) of the original paint: keeps the baked shading as a ratio.
uniform float ref_luma = 0.3;
uniform float paint_metallic = 0.0;
uniform float paint_roughness = 0.3;
uniform float paint_clearcoat = 0.8;
/// Roughness interval (green channel) that marks the paint.
uniform vec2 paint_rough = vec2(0.055, 0.135);

void fragment() {
	vec4 base = texture(albedo_tex, UV);
	vec4 mr = texture(mr_tex, UV);
	float r = mr.g;
	float mask = smoothstep(paint_rough.x - 0.01, paint_rough.x, r)
		* (1.0 - smoothstep(paint_rough.y, paint_rough.y + 0.015, r));
	float luma = dot(base.rgb, vec3(0.2126, 0.7152, 0.0722));
	float shade = clamp(luma / max(ref_luma, 0.002), 0.35, 1.5);
	ALBEDO = mix(base.rgb, paint * shade, mask);
	METALLIC = mix(mr.b, paint_metallic, mask);
	ROUGHNESS = mix(r, paint_roughness, mask);
	CLEARCOAT = paint_clearcoat * mask;
	CLEARCOAT_ROUGHNESS = 0.12;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
}
