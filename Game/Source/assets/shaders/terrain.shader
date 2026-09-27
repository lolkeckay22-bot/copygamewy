shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D grass_tex : hint_albedo;
uniform sampler2D forest_tex : hint_albedo;
uniform sampler2D grass_normal : hint_normal;
uniform sampler2D forest_normal : hint_normal;
uniform bool detailed_normals=true;
varying vec3 map_position;
varying float camera_distance;
void vertex(){
 map_position=(WORLD_MATRIX*vec4(VERTEX,1.0)).xyz;
 camera_distance=length((MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz);
}
void fragment(){
 vec2 p=map_position.xz;
 vec3 macro=texture(grass_tex,p*0.00035).rgb;
 float blend=smoothstep(0.23,0.48,macro.g);
 vec3 grass=texture(grass_tex,p*0.035).rgb;
 vec3 soil=texture(forest_tex,p*0.11).rgb;
 vec3 close_color=mix(soil,grass,blend);
 vec3 distant=macro*vec3(0.84,1.0,0.76);
 ALBEDO=mix(close_color,distant,smoothstep(600.0,2200.0,camera_distance)*0.65)*(0.8+macro.g*0.5);
 ROUGHNESS=0.95;
 if(detailed_normals){
  NORMALMAP=mix(texture(forest_normal,p*0.11).rgb,texture(grass_normal,p*0.035).rgb,blend);
  NORMALMAP_DEPTH=0.55*(1.0-smoothstep(250.0,1000.0,camera_distance));
 }
}
