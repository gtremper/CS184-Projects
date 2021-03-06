# version 120 

// Mine is an old machine.  For version 130 or higher, do 
// in vec4 color ;  
// in vec4 mynormal ; 
// in vec4 myvertex ;
// That is certainly more modern

varying vec4 color ;
varying vec3 mynormal ; 
varying vec4 myvertex ;
varying vec4 lambertVert; 

uniform sampler2D tex ; 

uniform int istex ;
uniform int islight ; // are we lighting. 
uniform int numLights;

uniform int vertexShading;

uniform int cartoonShading;

/* Color and Position for lights */
uniform vec4 lightPosn[10];
uniform vec4 lightColor[10];

// Now, set the material parameters.  These could be varying and/or bound to 
// a buffer.  But for now, I'll just make them uniform.  
// I use ambient, diffuse, specular, shininess as in OpenGL.  
// But, the ambient is just additive and doesn't multiply the lights.  

uniform vec4 ambient ;
uniform vec4 emission ; 
uniform vec4 diffuse ; 
uniform vec4 specular ; 
uniform float shininess ; 

vec4 ComputePhong (const in vec4 lightcolor, const in vec3 normal, const in vec3 halfvec, const in vec4 myspecular, const in float myshininess) {

        float nDotH = dot(normal, halfvec) ; 
		vec4 phong;

		if (cartoonShading==0){
			phong = myspecular * lightcolor * pow (max(nDotH, 0.0), myshininess) ; 
		} else {
			if(pow (max(nDotH, 0.0), myshininess)>0.5){
				phong = myspecular*lightcolor;
			} else {
				phong = vec4(0,0,0,0);
			}
		}

        return phong ;            
} 

vec4 ComputeLambert (const in vec3 direction, const in vec4 lightcolor, const in vec3 normal, const in vec4 mydiffuse) {

        float nDotL = dot(normal, direction)  ;         
		vec4 lambert;
  		
		if(cartoonShading == 0){
			lambert = mydiffuse * lightcolor * max (nDotL, 0.0) ;
		} else {
			if(max (nDotL, 0.0)>0.65){
				lambert = mydiffuse*lightcolor;
			} else {
				lambert = vec4(0,0,0,0);
			}
 		}
        return lambert ;            
}     

void main (void) 
{   
    if (islight == 0) gl_FragColor = color ; 
    else { 
        /* They eye is always at (0,0,0) looking down -z axis 
           Also compute current fragment position and direction to eye */ 
        const vec3 eyepos = vec3(0,0,0) ; 
        vec4 _mypos = gl_ModelViewMatrix * myvertex ; 
        vec3 mypos = _mypos.xyz / _mypos.w ; // Dehomogenize current location 
        vec3 eyedirn = normalize(eyepos - mypos) ; 

        /* Compute normal, needed for shading. */   
         vec3 normal = normalize(gl_NormalMatrix * mynormal) ; 

		/* Initialize variables */   
		vec3 position, direction, halfAngle;
		vec4 totalLambert = vec4(0,0,0,0);
		vec4 totalPhong = vec4(0,0,0,0);
		
		/* Sum over all lights */ 
		float atten = 1.0; 
		for(int i=0; i<numLights ;i++) {	
			if (lightPosn[i].w==0) {
				direction = normalize(lightPosn[i].xyz);
				atten = 1.0;
			} else {
	        	position = lightPosn[i].xyz / lightPosn[i].w ; 
				float dist = length(position-mypos);
				atten = 1.0/(1.0+0.01*dist+0.001*dist*dist);
				direction = normalize (position-mypos) ;
			}
	        halfAngle = normalize (direction + eyedirn) ;
			
	        totalPhong += ComputePhong(atten*lightColor[i], normal, halfAngle, specular, shininess);
			if (vertexShading==0) {
				totalLambert += ComputeLambert(direction, atten*lightColor[i], normal, diffuse);
			}
		}
		
		if (vertexShading != 0){
			totalLambert = lambertVert;
		}
		
		if (istex != 0) {
			gl_FragColor = (totalPhong+totalLambert) * texture2D(tex, gl_TexCoord[0].st) ; 
		} else {
			gl_FragColor = totalPhong + totalLambert + ambient + emission;
		}		
	}	
}
		
