class Isaac {
  /*Constants*/
  
  final String NUETRAL ="neutral";
  final String HURT ="hurt";
  
 
  /* isaac prameters */
  float x,y,w,h;
  String state;
  float hp =4;
  boolean shooting;
  float fire_cool =0.8;
  String facing ="";
  int invulnFrames = 0;  // how many frames left of invulnerability
  int invulnDuration = 90; // ~1.5 seconds at 60fps
  
  /*Movement fields*/
  int speed =7;
  int vx =0;
  int vy =0;
  
  Isaac (float x, float y, float w, float h, String state, String facing){
   this. x= x;
   this. y =y;
   this. w =w;
   this.h =h;
   this.state =state;
   this. facing =facing;
  }
  
  void updateMovement(boolean left, boolean right, boolean down, boolean up){
    vx =0;
    vy =0;
    if ( left){
      vx-=speed;
    }
    if (right){
     vx+=speed; 
    }
    if (down){
     vy +=speed; 
    }
    if (up){
     vy -=speed; 
    }
    this.x +=vx;
    this.y+=vy;
  }
  
  void drawIsaac(boolean left, boolean right, boolean down, boolean up){
    if (invulnFrames >0){
     invulnFrames--; 
    }
   float eye_r =x+7*(w/10);
   float eye_y =y+2.5*(h/10);
   float eye_l =x+2*(w/10);
   ellipseMode(CORNER);
   stroke(10);
   
    if (state.equals(NUETRAL)){
      fill(76,171,181);
      ellipse(x,y,w,h);
    }
    else{
      fill(76,171,181);
      ellipse(x,y,w,h);
      if (invulnFrames % 6 ==0){
      fill(216,220,227,180);
      ellipse(x,y,w,h);
      if (invulnFrames <=0){
        state = NUETRAL;
      }
      }
    }
   
    
    fill(255);
    
    if (right || facing.equals("right")){
      ellipse(eye_r, eye_y,10,10);
      
      this.facing ="right";
    }
    if (left || facing.equals("left")){
     ellipse(eye_l,eye_y,10,10); 
   
     this.facing ="left";
    }
    if (down || facing.equals("down")){
      ellipse(eye_r, eye_y,10,10);
      ellipse(eye_l,eye_y,10,10); 
     
      this.facing ="down";
    }
    if (up || facing.equals("up")){
      this.facing = "up";
    }
    
  }
  
  void recieveDamage(float damage){
    if (invulnFrames <= 0) {   // only if not already invulnerable
    hp -= damage;
    state = HURT;
    invulnFrames = invulnDuration;
  }
  }
  
    Hitbox getHitbox(){
      return new Hitbox (x,y,w,h);
  }
  
  CrossHitbox getCross() {
  float cx = x + w/2f, cy = y + h/2f;
  float t  = 0.55f * min(w, h);     // bar thickness

  // Horizontal bar: full width, thickness t, centered vertically
  Hitbox hbar = new Hitbox(x, cy - t/2f, w, t);

  // Vertical bar: thickness t, full height, centered horizontally
  Hitbox vbar = new Hitbox(cx - t/2f, y, t, h);

  return new CrossHitbox(hbar, vbar);
}
  
}
