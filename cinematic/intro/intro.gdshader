shader_type canvas_item;

uniform vec2 speed;

void fragment () {
	COLOR = texture(TEXTURE, vec2(UV.x + TIME * speed.x, UV.y + TIME * speed.y));
}
