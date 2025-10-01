class Shot{ 
  float x, y;
  float vx, vy;
  float size;
  float damage;
  int lifetime;   // frames remaining
  boolean alive = true;
  boolean crit;
  boolean fromEnemy;

  Shot(float x, float y, float vx, float vy, float size, float damage, int lifetime, boolean crit) {
    this.x = x;
    this.y = y;
    this.vx = vx; 
    this.vy = vy;
    this.size = size;
    this.damage = damage;
    this.lifetime = lifetime;
    this.crit = crit;
  }
  
  Shot(float x, float y, float vx, float vy, float size, float damage, int lifetime,boolean crit ,boolean fromEnemy) {
  this.x = x; 
  this.y = y;
  this.vx = vx;
  this.vy = vy;
  this.size = size;
  this.damage = damage;
  this.lifetime = lifetime;
  this.crit = crit;
  this.fromEnemy = fromEnemy;  // true for enemy shots
}

  void update() {
    x += vx;
    y += vy;
    lifetime--;
    if (lifetime <= 0) alive = false; // if the liftime is below zero delete the shot

    // checks if the shot is ooff the screen
    if (x + size < 0 || x > width || y + size < 0 || y > height) {
      alive = false;
    }
  }
  
  

  void draw() {
    stroke(1);
    if (fromEnemy){
      fill (200,50,200);
    }
    else{
    fill(crit ? color(153,17,17) : color(77,159,191));
    }
    ellipseMode(CORNER);
    ellipse(x, y, size, size);
  }

   Hitbox getHitbox(){
      return new Hitbox (x,y,size,size);
  }
  
}
