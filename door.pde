class Door{
  final String N ="N";
  final String S = "S";
  final String W ="W";
  final String E ="E";
  
  String direction;
  boolean locked;
  float x,y,w,h;
  boolean hidden;
 
  
  int targetRoomID;
  
  
  Door (float x,float y,float w,float h, boolean locked,boolean hidden,String direction , int targetRoomI){
    this.x =x;
    this.y =y;
    this.w =w;
    this.h=h;
    this.locked =locked;
    this.direction =direction;
    this.targetRoomID =targetRoomI;
    this.hidden =hidden;
  }
  
  boolean canEnter(){
   return !locked; 
  }
  
  String opposite(){
   switch (direction){
     case N: return S;
     case S: return N;
     case W: return E;
     case E: return W;
     default: return null;
   }
     
     
  }
  
 void drawDoor() {
  noStroke();
  
if (!hidden){
  boolean isVertical = (direction.equals("N") || direction.equals("S"));
  float dw = isVertical ? w : h;  // drawn width
  float dh = isVertical ? h : w;  // drawn height

  // outer frame
  fill(200);
  if (direction.equals(E)){
     rect(width-dw, y, dw, dh);
  }
  else{
  rect(x, y, dw, dh);
  }

  // inner opening only if unlocked
  if (!locked) {
    fill(50, 51, 51);             // dark opening
    float ix = x + 0.25f * dw;
    float iy = y + 0.25f * dh;
    float iw = 0.5f * dw;
    float ih = 0.5f * dh;
    if (direction.equals(E)){
      rect(width-iw, iy, iw, ih);
    }
    else{
      rect(ix, iy, iw, ih);
    }
  }
}
  
  
}

// Hitbox must match what we draw visually (same orientation swap)
Hitbox getHitbox() {
  boolean isVertical = (direction.equals("N") || direction.equals("S"));
  float dw = isVertical ? w : h;
  float dh = isVertical ? h : w;
  if (direction.equals(E)){
     return new Hitbox(width -dw, y, dw, dh);
  }
  return new Hitbox(x, y, dw, dh);
}
  
  
}
