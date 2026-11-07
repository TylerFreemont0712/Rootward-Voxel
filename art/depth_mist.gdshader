shader_type spatial;
// Alpha-only overlay preserves transparent objects already drawn beneath it.
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 day_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 night_color : source_color = vec4(.03,.07,.11,1.0);
uniform float daylight : hint_range(0.0,1.0) = 1.0;
// The mist begins to thicken at fade_top and has closed completely by fade_bottom + (fade_top - fade_bottom) * (1 - solid_by).
// Below that line nothing of the lower town shows through: the town simply stands on a white floor of cloud.
uniform float fade_top = -2.8;
uniform float fade_bottom = -6.0;
uniform float solid_by : hint_range(0.3,1.0) = 0.7;
// Edge haze: beyond the area's own rectangle (world x0, z0, x1, z1) the surrounding town thins into the same mist,
// starting edge_start metres out and reaching edge_max opacity by edge_end. edge_max 0 turns it off.
uniform vec4 area_rect = vec4(0.0);
uniform float edge_start = 4.0;
uniform float edge_end = 24.0;
uniform float edge_max : hint_range(0.0,1.0) = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),f.x),f.y);
}
vec4 view_at(vec2 uv,float depth,mat4 projection_inverse) {
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 vec3 ndc=vec3(uv,depth)*2.0-1.0;
 #else
 vec3 ndc=vec3(uv*2.0-1.0,depth);
 #endif
 vec4 p=projection_inverse*vec4(ndc,1.0);
 return vec4(p.xyz/p.w,1.0);
}
void vertex() { POSITION=vec4(VERTEX.xy,1.0,1.0); }
void fragment() {
 float depth=textureLod(scene_depth,SCREEN_UV,0.0).r;
 vec4 v0=view_at(vec2(.5),0.0,INV_PROJECTION_MATRIX);
 vec4 v1=view_at(vec2(.5),1.0,INV_PROJECTION_MATRIX);
 bool reversed_depth=abs(v0.z)>abs(v1.z);
 bool background=reversed_depth ? depth<0.000001 : depth>0.999999;
 vec3 point=(INV_VIEW_MATRIX*view_at(SCREEN_UV,depth,INV_PROJECTION_MATRIX)).xyz;
 ALBEDO=vec3(0.0);ALPHA=0.0;
 float edge=0.0;
 if (edge_max>0.0 && !background) {
  vec2 outside=max(vec2(area_rect.x-point.x,area_rect.y-point.z),vec2(point.x-area_rect.z,point.z-area_rect.w));
  float away=length(max(outside,vec2(0.0)));
  edge=edge_max*smoothstep(edge_start,edge_end,away);
 }
 // Most of the street is above the mist. Skip cloud noise and ray work there.
 if (background || point.y<fade_top+.25 || edge>0.0) {
  if (background) {
   vec3 near_point=(INV_VIEW_MATRIX*view_at(SCREEN_UV,reversed_depth?1.0:0.0,INV_PROJECTION_MATRIX)).xyz;
   vec3 far_point=(INV_VIEW_MATRIX*view_at(SCREEN_UV,reversed_depth?0.0:1.0,INV_PROJECTION_MATRIX)).xyz;
   float t=(fade_bottom-near_point.y)/(far_point.y-near_point.y);
   point=mix(near_point,far_point,t);
  }
  // A faint, slow wobble keeps the mist's upper edge from looking ruled; it never lets the floor show through.
  vec2 p=point.xz*.16+vec2(TIME*.008,TIME*.005);
  float cloud=.7*noise(p)+.3*noise(p*2.15);
  float depth_into=clamp((fade_top-(point.y+(cloud-.5)*.3))/max(.01,(fade_top-fade_bottom)*solid_by),0.0,1.0);
  float amount=background?1.0:max(smoothstep(0.0,1.0,depth_into),edge*mix(.85,1.0,cloud));
  // At night the mist is moonlit haze lit faintly from the town above, never a black void.
  vec3 night=night_color.rgb*mix(1.25,.8,amount);
  ALBEDO=mix(night,day_color.rgb,daylight)*mix(.97,1.0,cloud);
  ALPHA=amount;
 }
}
