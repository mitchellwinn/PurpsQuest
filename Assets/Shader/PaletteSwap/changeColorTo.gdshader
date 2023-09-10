shader_type canvas_item;

uniform int numberOfColors : hint_range(0, 6, 1);
uniform vec4 C1 : source_color;
uniform vec4 C2 : source_color;
uniform vec4 C3 : source_color;
uniform vec4 C4 : source_color;
uniform vec4 C5 : source_color;
uniform vec4 C6 : source_color;
uniform vec4 T1 : source_color;
uniform vec4 T2 : source_color;
uniform vec4 T3 : source_color;
uniform vec4 T4 : source_color;
uniform vec4 T5 : source_color;
uniform vec4 T6 : source_color;


void fragment() {
	
	vec4 referenceColors[12];
	referenceColors[0] = C1;
	referenceColors[1] = C2;
	referenceColors[2] = C3;
	referenceColors[3] = C4;
	referenceColors[4] = C5;
	referenceColors[5] = C6;
	referenceColors[6] = T1;
	referenceColors[7] = T2;
	referenceColors[8] = T3;
	referenceColors[9] = T4;
	referenceColors[10] = T5;
	referenceColors[11] = T6;
	

	//COLOR = vec4(0.0);
	for (int i; i<numberOfColors; ++i){
		if (abs((COLOR.g*2.0) - (referenceColors[i].g*2.0))<.015 && abs((COLOR.r*2.0) - (referenceColors[i].r*2.0))<.015 && abs((COLOR.b*2.0) - (referenceColors[i].b*2.0))<.015){
			COLOR.rgb = referenceColors[i+6].rgb;
		}
	}
	//COLOR.rgb = referenceColors[int(floor(tex_color.r) * float(numberOfColors))].rgb;
}
