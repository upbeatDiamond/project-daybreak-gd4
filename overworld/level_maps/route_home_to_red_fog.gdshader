shader_type canvas_item;
render_mode blend_add;

uniform vec2 scroll_speed = vec2(0.1, -0.05);

void fragment() {
    // Calculate the scrolled UV coordinates
    vec2 scrolled_uv = UV + scroll_speed * TIME;
    
    // Wrap the UV coordinates to create a looping effect
    scrolled_uv = fract(scrolled_uv);
    
    // Sample the texture with the scrolled UV
    vec4 color = texture(TEXTURE, scrolled_uv);
    
    // Output the final color
    COLOR = color;
}
