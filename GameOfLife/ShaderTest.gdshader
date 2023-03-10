shader_type canvas_item;

#ifdef GL_ES
precision mediump float;
#endif

varying vec2 uv;
uniform float frame;
uniform sampler2D prevtex;
uniform vec2 screen;
uniform float seed;

const float cell = 50.;
const float fstep = 4.;
const float density = 0.2;

uniform float u_time;

float life() {
	vec2 px;
	vec2 uv2;
  	float alive = .0;
  	float c = texture( prevtex, uv2 ).x;
  	for( float y = -1.; y <= 1.; y++ ) {
  	for( float x = -1.; x <= 1.; x++ ) {
    	vec2 o = px * vec2( x, y );
    	float k = abs(x)+abs(y);
    	float v = texture( prevtex, uv2+o ).x;
    	alive += k == .0 ? .0 : v;
  }
  }
  if( c == .0 && alive == 3. ) return 1.;
  if( c == 1. && alive < 2. ) return .0;
  if( c == 1. && alive > 3. ) return .0;
  if( c == 1. ) return 1.;
  return .0;
}

void fragment() {
	vec2 cells = vec2( cell, cell );
	vec2 px;
	vec2 uv2;
	vec2 ar = vec2(1);
  	if( screen.x > screen.y )
    	ar = vec2( screen.x/screen.y, 1 );
  	else 
    	ar = vec2( 1, screen.y/screen.x );
  	cells = floor( ar*cells );
  	px = 1./cells;
  	uv2 = floor(cells*uv)/cells+.5*px;
  	float k = 0.;
  	if( frame == 0. )
    	k = step( 1.-density, sin( 1000.*cos( 700.*( 700.*uv2.x + uv2.y + 100.*seed ) ) ) );
  	else if( fract(frame/fstep) == 0. ) k = life();
  	else k = texture( prevtex, uv2 ).x;
  	COLOR = vec4( k, k, k, 1);
}

