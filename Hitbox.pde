class Hitbox{
 float x,y,w,h;
 float buffer =10;
 
 
 /* ----- Hitbox object ----- */
 public Hitbox (float x, float y, float w, float h){ 
  this.x =x;
  this.y =y;
  this.w =w;
  this.h =h;
 }
 
 Hitbox inset(float dx, float dy) {
  return new Hitbox(x + dx, y + dy, w - 2*dx, h - 2*dy);
}

  
 
 /* ----- checks for collisions ------ */
 boolean intersaction (Hitbox other){
   return !(x+w <other.x || x> other.x +other.w || y+h <other.y || y> other.y +other.h);
 }
}
 
 // --- Collision helpers (global functions) ---
boolean interRectRect(Hitbox a, Hitbox b) {
  return !(a.x + a.w < b.x || a.x > b.x + b.w || a.y + a.h < b.y || a.y > b.y + b.h);
}

boolean interCrossRect(CrossHitbox c, Hitbox r) {
  return interRectRect(c.h, r) || interRectRect(c.v, r);
}

boolean interCrossCross(CrossHitbox a, CrossHitbox b) {
  return interRectRect(a.h, b.h) || interRectRect(a.h, b.v)
      || interRectRect(a.v, b.h) || interRectRect(a.v, b.v);
}
 
 
