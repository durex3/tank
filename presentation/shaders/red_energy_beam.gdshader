shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float phase = 0.0;
uniform float opacity = 1.0;
uniform float thickness = 1.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0)),f.x),f.y);
}
void fragment() {
	float y=UV.y;
	float x=0.5+(UV.x-0.5)/max(0.05,thickness);
	float taper=pow(max(0.0,sin(y*3.14159)),0.35);
	float drift=(noise(vec2(y*9.0-phase*0.37,3.7))-0.5)*0.25*taper;
	float tissue=noise(vec2(UV.x*24.0,y*48.0-phase*2.7));
	float body=0.0;
	float core=0.0;
	float fog=0.0;
	for (int i=0; i<3; i++) {
		float k=float(i);
		float winding=sin(y*(17.0+k*3.0)-phase*0.65+k*2.094);
		float center=0.5+drift+winding*(0.10+k*0.025)*taper;
		center+=(noise(vec2(y*27.0-phase*1.4,k*7.0))-0.5)*0.045*taper;
		float swell=noise(vec2(y*14.0-phase*1.2,k*13.0));
		float width=(0.035+0.14*pow(swell,1.2))*(0.4+0.6*taper);
		float d=abs(x-center)/width;
		float strand=exp(-d*d*1.7);
		float tear=smoothstep(0.18,0.65,tissue+swell*0.23);
		body+=strand*(0.35+0.65*tear);
		core+=exp(-d*d*16.0)*smoothstep(0.20,0.70,swell)*tear;
		fog+=exp(-d*d*0.15)*(0.25+0.75*tissue);
	}
	float edge=smoothstep(0.0,0.025,y)*(1.0-smoothstep(0.975,1.0,y));
	vec3 color=mix(vec3(0.08,0.007,0.018),vec3(0.48,0.015,0.035),min(1.0,body));
	color=mix(color,vec3(0.72,0.08,0.08),min(0.65,core));
	ALBEDO=color;
	ALPHA=min(0.98,body*0.95+fog*0.22)*edge*opacity;
}
