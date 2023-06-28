shader_type canvas_item;

uniform sampler2D dissolve_texture : source_color;
uniform sampler2D flowMap; //Displacement map
uniform float strength;    //Force of the effect
uniform float speed;       //Speed of the effect
uniform int frames : hint_range(1, 10); //Frames of the effect

//Returns a value between 0 and 1 depending of the frames -> exemple: frames = 4, frame 1 = 0.25
float clock(float time){
	float fframes = float(frames);
	return floor(mod(time * speed, fframes)) / fframes;
}

void fragment(){

    float c = clock(TIME); //Get clock frame
    vec4 offset = texture(flowMap, vec2(UV.x + c, UV.y + c)) * strength; //Get offset 

    vec4 main_texture = texture(TEXTURE, vec2(UV.x,UV.y) + offset.xy - vec2(0.5,0.5) * strength); //texture(TEXTURE, UV);
    float dissolve_value = mix(0.5, 0.6, sin(TIME));
    vec4 noise_texture = texture(dissolve_texture, UV+vec2(10.0*sin(TIME/5.0),10.0*cos(TIME/5.0))/5.0);
    float mult = floor( dissolve_value + min(1, noise_texture.x) ) ; //floor();
    main_texture.g *= mult;
    main_texture.r -= (mult - 0.1) / 2.0;
    main_texture.g -= mult - 0.1;
    main_texture.b -= (mult - 0.1) / 3.0;
    COLOR = main_texture;
}



/*
void fragment(){


	COLOR = texture(TEXTURE, vec2(UV.x,UV.y) + offset.xy - vec2(0.5,0.5)*strength); //We need to remove the displacement 
}
*/