
boolean down,up,left,right;
boolean shot_r,shot_l,shot_u,shot_d;

LevelManager world;
LevelManager world2;
LevelManager activeWorld;
Isaac isaac;
int isaacSize;

/* magic numbers (some global coordinates) */

// widths: 
float halfWidth;
float fourthWidth;
float thirdWidth;   

// Heights:
float halfHeight;
float fourthHeight;
float thirdHeight;

// enemy sizes: 
float s;
float m;
float l;
float b;

// === Boss2 Fight Timer (frames at 60 fps) ===
int bossTimerFrames ; // boos timer for 60s
boolean timerActive = false;
boolean finishWindow = false;  // becomes true when timer hits 0

// Time gained per hit (no cap)
int timeAddPerHitFrames = 60;  // +1s per hit

// simple boolean to determine victory against the final boss
boolean boss2Victory = false;
boolean killedBoss2 = false;

boolean game;

ArrayList <Enemy> enemies; 
/*--- Shots variables --- */
ArrayList<Shot> shots;

int damage =2;                // base damage (could be modified uising powerups 
int fireCooldown = 40;         // frames until next shot allowed
int fireRateFrames = 30;       // ~6 shots/sec at 60fps (tune later)
int shotSize = 20;             // px
int shotSpeed = 10;            // px/frame
int shotLifetimeFrames = 60;   // frames (~1s at 60fps)



void setup(){
 fullScreen(); 
 frameRate(60);
 game =true;
 isaacSize =width/20;
 isaac = new Isaac(width/2,height-isaacSize,isaacSize,isaacSize,"neutral","down");
 shots =new ArrayList<>();
 enemies = new ArrayList<>();
 
 // widths: 
 halfWidth        = width/2;
 fourthWidth      = width/4;
 thirdWidth       = width/3;    

 // Heights:
 halfHeight       = height/2;
 fourthHeight     = height/4;
 thirdHeight      = height/3;

  // enemy sizes: 
  s           = width/15;
  m           = width/13;
  l           = width/11;
  b           = width/7;
 
 initializeWorld1();
 initializeWorld2();  // prepare it now so we can swap instantly
 activeWorld = world; // start at world 1 
 


}



void draw (){
  if (game){
  background(activeWorld.themeBg);
  Room current = activeWorld.current();
  current.draw();
  activeWorld.tickCooldown();
  tickBossTimer();
  
  isaac_functions();
  current.resolveIsaacCollisions(isaac);
  handleShooting();    // may spawn a shot if cooldown ready
  updateShots();
  
  current.resolveShotsVsRocks(shots);
  current.shotEnemyCo(shots);
  current.enemyLogic(isaac,shots);
  current.enemyShotsHitIsaac(shots, isaac);
  current.isaacEnemyCo(isaac);

  
  doorTraversal(current,isaac);
  draws();
  }
  else{
    textSize(50);
    if ( boss2Victory){ 
      background(56,96,161);
      text("You won!!!", width/4, height/2);
      text("Well done figuring out how to defeat the final boss!", width/4,height/3);
    }
    else{
      background(0);
      text("game over!" ,width/4 ,height/2);
      if (killedBoss2){
      text("Boss 2 is special, defeating it might require some thought, good luck!",width/4,height/3); 
      }
    }
  }

}






void draws(){
  textSize(20);
  text("hp: " +isaac.hp,10,20);
 
  drawShots();
 
  isaac.drawIsaac(shot_l,shot_r,shot_d,shot_u);// render
}



void isaac_functions(){
  isaac.updateMovement(left,right,down,up);
  edges_check();
  
}


void edges_check(){
if (isaac.x <=0){
  isaac.x =0;
}
 if (isaac.x+isaac.w >= width){
   isaac.x =width-isaac.w;
 }
 
 if(isaac.y <=0){
   isaac.y =0;
 }
 if (isaac.y +isaac.h >= height){
   isaac.y =height-isaac.h;
 }
  
}


void drawShots() {
  for (Shot s : shots) {
    s.draw();
  }
}



/* ------- Shot logic, contains:
1. a methods that spawns the shots based on direction
2. a method that handles direction and cooldown between shots 
3. a method that removes shots when they are expired
*/


/*----- spawns the shots ------- 
1. spawns the shots using dir (the direction) 
2. creates spread by introducing a variable 
3. decides the damage and if it will be a crit or not 
4. adds a new shot to the list 
*/
void spawnShot(String dir) {
  float sx = 0, sy = 0;     // spawn position
  float vx = 0, vy = 0;     // velocity

  // offsets so the tear appears just outside Isaac
  if (dir.equals("right")) {
    sx = isaac.x + isaac.w;
    sy = isaac.y + 0.40f * isaac.h;
    vx = +shotSpeed; vy = 0;
  }
  else if (dir.equals("left")) {
    sx = isaac.x - shotSize;
    sy = isaac.y + 0.40f * isaac.h;
    vx = -shotSpeed; vy = 0;
  }
  else if (dir.equals("down")) {
    sx = isaac.x + 0.35f * isaac.w;
    sy = isaac.y + isaac.h;
    vx = 0; vy = +shotSpeed;
  }
  else if (dir.equals("up")) {
    sx = isaac.x + 0.35f * isaac.w;
    sy = isaac.y - shotSize;
    vx = 0; vy = -shotSpeed;
  }
  
  /*Creates spread when moving */
  final float k = 0.5f;
  vy += k * isaac.vy;
  vx += k * isaac.vx;

  // decide damage/crit 
  boolean crit = (random(1) >= 0.9);           // 10% crit
  int damage1 = crit ? this.damage * 2 : this.damage; //double damage for crits

  shots.add(new Shot( sx, sy, vx, vy, shotSize, damage1, shotLifetimeFrames, crit));
}

/* ------ Handels the shooting -------
1. checks for direction
2. makes sure shots will be fired in the right time (fire rate) 
3. spawns the shot 
*/
void handleShooting() {
  if (fireCooldown > 0) fireCooldown--;

  String dir = null;
  if (shot_r)      dir = "right";
  else if (shot_l) dir = "left";
  else if (shot_d) dir = "down";
  else if (shot_u) dir = "up";

  if (dir != null && fireCooldown <= 0) {
    spawnShot(dir);
    fireCooldown = fireRateFrames;
  }
}

/*----- shots manager , makes sure that there no shots leeft on the screen -----*/
void updateShots() {
  for (int i = shots.size() - 1; i >= 0; i--) {
    Shot s = shots.get(i);
    s.update();
    if (!s.alive) shots.remove(i);
  }
}





/* ------ World logic ------- */

void initializeWorld1(){
  
  world = new LevelManager();

// ------ rooms initialazation and creation 
  Room r0 = new Room(0);
  Room r1 = new Room(1);
  Room r2 = new Room(2);
  Room r3 = new Room(3);
  Room r4 = new Room(4);
  Room r5 = new Room(5);
  Room r6 = new Room(6);
  Room r7 = new Room(7);
  Room r8 = new Room(8);
  Room r9 = new Room(9);
  Room r10 = new Room(10);
  // ------ world rooms 
  world.addRoom(r0);
  world.addRoom(r1);
  world.addRoom(r2);
  world.addRoom(r3);
  world.addRoom(r4);
  world.addRoom(r5);
  world.addRoom(r6);
  world.addRoom(r7);
  world.addRoom(r8);
  world.addRoom(r9);
  world.addRoom(r10);
  
  // enter the start room; spawn its content on first entry
  world.setRoom(0);

  // add some fixed rocks so collisions are testable
  r0.addRock(new Hitbox(360, 350, 80, 80));
  r0.addRock(new Hitbox(540, 500, 100, 40));

  r1.addRock(new Hitbox(220, 260, 120, 60));
  r2.addRock(new Hitbox(600, 300, 60, 120));

  // doors: x,y,w,h are door rectangles on walls
  // north & south centered, east & west centered
  float dw = 120, dh = 40; // door size
  
  float Ex = width - dw - 10, Ey = height/2 - dh/2;  // east door (x,y) coordinates 
  float Wy =height/2 - dh/2; // West door y coordinates 
  float Sx =width/2 - dw/2, Sy =height - dh - 10; // south door (x,y) coordinates 
  float Nx = width/2 - dw/2; // north door x coordinates 

  /* ---- r0 doors  ------ 
  1. door to room 1, direction - east
  2. door to room 7, direction - west 
  3. door to room 8, direction - north
  */ 
  r0.addDoor(new Door(Ex, Ey, dw, dh, true , false ,"E", 1));
  r0.addDoor(new Door(0,Wy,dw,dh,true,false,"W",7));
  r0.addDoor(new Door(Nx, 0, dw, dh, true, false , "N", 8));
  
  /* ----- r1 doors  ----- 
  1. door to room 0, direction - west or W
  2. door to room 2, direction - south or S
  3. door to room 3, direction - east or E
  */
  r1.addDoor(new Door(0,Wy, dw, dh, true , false ,"W", 0)); 
  r1.addDoor(new Door(Sx, Sy, dw, dh, true , false ,"S", 2));
  r1.addDoor(new Door(Ex, Ey, dw, dh, true , false ,"E", 3 ));
  
  /* ------ r2 doors ------ 
  1. door to room 1, direction - north or N
  */
  r2.addDoor(new Door(Nx, 0, dw, dh, true, false , "N", 1));
  
  /*------ r3 doors -------
  1. door to room 1, direction - west or W
  2. door to room 4 , direction - east or E 
  3. door to room 5, direction - north or N 
  */
  r3.addDoor(new Door(0, Wy, dw, dh, true, false ,"W", 1));
  r3.addDoor(new Door(Ex, Ey, dw, dh, true, false , "E", 4));
  r3.addDoor(new Door(Nx, 0, dw, dh, true, false , "N", 5));
  
  /* ------ r4 (boss room)  doors  ------- 
  1. door to room  3, direction - west or W 
  2. door to world2!
  */
  r4.addDoor(new Door(0,Wy, dw, dh, true, false , "W", 3));
  r4.addDoor(new Door(width/2 - 60, height/2-60, dw, dw, true, false, "N", -999));  // targetRoomID=-999 means go to world2
  
  
  /* ----- r5 doors ------- 
  1. door to room 3, direction - south or S
  2. hidden door to room 6, direction - north east will use N 
  */
  r5.addDoor(new Door (Sx,Sy,dw,dh,true, false ,"S",3));
  r5.addDoor(new Door(Ex, 0, dw, dh, true, true ,"N", 6));
  
  /* ------ r6 doors ------ 
  1. door to room 5, direction south 
  */
  r6.addDoor(new Door (Sx,Sy,dw,dh,true, false ,"S",5));
  
  /* ---- r7 doors  ------ 
  1. door to room 0, direction - east
  2. door to room 9 , direction- north 
  */ 
  r7.addDoor(new Door(Ex,Ey,dw,dh,true,false,"E",0));
  r7.addDoor(new Door(Nx,0,dw,dh,true,false,"N",9));


/* ---- r8 doors  ------
1. door to room 0, direction - south
2. door to room 9, direction - west 
*/ 
r8.addDoor(new Door(0, Wy, dw, dh, true, false ,"W", 9));
r8.addDoor(new Door(Sx, Sy, dw, dh, true, false ,"S", 0));


/* ---- r9 doors  ------
1. door to room 8, direction - east
2. door to room 7, direction - north
3. hidden door to room 10, direction - west 
*/ 
r9.addDoor(new Door(Sx,Sy,dw,dh,true,false,"S",7));
r9.addDoor(new Door(Ex,Ey,dw,dh,true,false,"E",8));
r9.addDoor(new Door(0, Wy, dw/2, dh/2, true, true ,"W", 10));


/* ---- r10 doors  ------ 
1. door to room 9 , direction - east
*/ 
r10.addDoor(new Door(Ex, Ey, dw, dh, true, false ,"E", 9));
}





/*------ world 2 initialization ---------*/
void initializeWorld2(){
  
  world2 = new LevelManager(); // creates a new level manager objects 
  world2.themeBg = color(64, 96, 122);  //redder tone
  
  
  
   Room a0 = new Room(0);
  Room a1 = new Room(1);
  Room a2 = new Room(2);
  Room a3 = new Room(3);
  Room a4 = new Room(4);
  Room a5 = new Room(5);
  Room a6 = new Room(6);   // Boss 2 room
  
  
  // Add to world2
  world2.addRoom(a0);
  world2.addRoom(a1);
  world2.addRoom(a2);
  world2.addRoom(a3);
  world2.addRoom(a4);
  world2.addRoom(a5);
  world2.addRoom(a6);
  
   // doors: x,y,w,h are door rectangles on walls
  // north & south centered, east & west centered
  float dw = 120, dh = 40; // door size
  
  float Ex = width - dw - 10, Ey = height/2 - dh/2;  // east door (x,y) coordinates 
  float Wy =height/2 - dh/2; // West door y coordinates 
  float Sx =width/2 - dw/2, Sy =height - dh - 10; // south door (x,y) coordinates 
  float Nx = width/2 - dw/2; // north door x coordinates 
  
  
  
   // a0 <-> a1 (E/W)
  a0.addDoor(new Door(Ex, Ey, dw, dh, true, false, "E", 1));
  a1.addDoor(new Door(0,  Wy, dw, dh, true, false, "W", 0));

  // a1 <-> a2 (S/N)
  a1.addDoor(new Door(Sx, Sy, dw, dh, true, false, "S", 2));
  a2.addDoor(new Door(Nx,  0,  dw, dh, true, false, "N", 1));

  // a1 <-> a3 (E/W)
  a1.addDoor(new Door(Ex, Ey, dw, dh, true, false, "E", 3));
  a3.addDoor(new Door(0,  Wy, dw, dh, true, false, "W", 1));

  // a3 <-> a4 (S/N)
  a3.addDoor(new Door(Sx, Sy, dw, dh, true, false, "S", 4));
  a4.addDoor(new Door(Nx,  0,  dw, dh, true, false, "N", 3));

  // a4 <-> a5 (E/W)
  a4.addDoor(new Door(Ex, Ey, dw, dh, true, false, "E", 5));
  a5.addDoor(new Door(0,  Wy, dw, dh, true, false, "W", 4));

  // a5 <-> a6 (S/N)  — a6 is BOSS 2
  a5.addDoor(new Door(Ex, Ey, dw, dh, true, false, "E", 6));
  a6.addDoor(new Door(0,  Wy,  dw, dh, true, false, "W", 5));
  
  addRandomEnemies(a0, 3, 5);
  addRandomEnemies(a1, 2, 4);
  addRandomEnemies(a2, 2, 3);
  addRandomEnemies(a3, 3, 5);
  addRandomEnemies(a4, 2, 4);
  addRandomEnemies(a5, 2, 3);
  
  world2.setRoom(0);

}






/*----- door logic ------
This function is in charge of traversing between doors and worlds and it does it like so: 
1. checks if a door is enterable or not by calling tryDoorTransition from the Room class (if it's not the function will end) 
2. checks the target id, if it's -999 the world will change 
2. a) if the id is -999, world 2 would be selected and the rooms will be set using world 2 
2. b) The player will spawn at the bottom of room 0 at world 2

3. if the id is not -999 the function will set the next room to the target room
4. isaac will spawn a bit far away from the door depends on the door's direction 
*/
void doorTraversal(Room current,Isaac isaac){
  
  Door d = current.tryDoorTransition(isaac, activeWorld.entryCooldown);
if (d == null) return;

  // Inter-world doorway
  if (d.targetRoomID == -999) {
    activeWorld = world2;        // switch worlds
    activeWorld.setRoom(0);      // world 2 start room (or pick another)
    damage++; // gets a power up when moving to the next world
    isaac.hp=4; // resets the hp
   
      // fallback: bottom center
      isaac.x = width/2 - isaac.w/2;
      isaac.y = height- isaac.h/2;
    return;
  }

  // Normal same-world traversal
  activeWorld.setRoom(d.targetRoomID);
  Room nxt = activeWorld.current();
  Door opp = nxt.getDoorByDirection(d.opposite());
  if (opp != null) {
    if (opp.direction.equals("N")) { isaac.x = opp.x + opp.w/2 - isaac.w/2; isaac.y = opp.y + opp.h + 8; isaac.facing = "down"; }
    else if (opp.direction.equals("S")) { isaac.x = opp.x + opp.w/2 - isaac.w/2; isaac.y = opp.y - isaac.h - 8; isaac.facing = "up"; }
    else if (opp.direction.equals("W")) { isaac.x = opp.x + opp.w + 8; isaac.y = opp.y + opp.h/2 - isaac.h/2; isaac.facing = "right"; }
    else if (opp.direction.equals("E")) { isaac.x = opp.x - isaac.w - 8; isaac.y = opp.y + opp.h/2 - isaac.h/2; isaac.facing = "left"; }
  }
  
}

  
  
 /*======== Boss 2 timer functions ============*/
 void startBossTimer (int seconds) { 
  bossTimerFrames = seconds*60;
  timerActive =true; // starts the timer 
  finishWindow = false; 
  boss2Victory =false; 
 }
  
  void stopBossTimer(){
    timerActive = false;  // stops the timer
  }
  
  void tickBossTimer(){
    if (!timerActive){ // the boss has been defeated or the player was defeated 
     return; 
    }
    if (bossTimerFrames >0){
      bossTimerFrames--;
      
      if (bossTimerFrames <=0){
        bossTimerFrames =0;
        finishWindow =true; // never goes back to false (even if the player keeps raising the time
        
        Room cur = activeWorld.current();
        
        if (cur != null && cur.enemies != null){
          for (Enemy e: cur.enemies){
             if (e.type.equals("boss2") && e.alive){
              e.beginAutoDefeat(); // starts the defeat part of the boss fight 
             }
          }
        }
        stopBossTimer(); 
      }   
    }    
  }
  
  /* ------- adds time per hit on the boss ------ */
  void addTimeOnBoss2Hit() {
    if (!timerActive){
      return;
    }
      bossTimerFrames += timeAddPerHitFrames;
}



 /* ------ Key presses section ------ */

void keyPressed(){
  if (key =='w' || key == 'W'){
    up =true;
  }
  if (key =='S' || key =='s'){
    down =true;
  }
  if (key == 'd' || key== 'D') {
    right = true;
  }
  if (key == 'a'|| key == 'A') {
    left =true;
  }
  if (keyCode == RIGHT){
    shot_r =true;
  }
  if (keyCode == LEFT ){
    shot_l =true;
  }
  if (keyCode == DOWN){
    shot_d =true;
  }
  if (keyCode ==UP ){
    shot_u =true;
  }
  
}

void keyReleased(){
   if (key =='w' || key == 'W'){
    up =false;
  }
  if (key =='S' || key =='s'){
    down =false;
  }
  if (key == 'd' || key== 'D') {
    right = false;
  }
  if (key == 'a'|| key == 'A') {
    left =false;
  }
  if (keyCode == RIGHT){
    shot_r =false;
  }
  if (keyCode == LEFT ){
    shot_l =false;
  }
  if (keyCode == DOWN){
    shot_d =false;
  }
  if (keyCode ==UP ){
    shot_u =false;
  }
}

  
  
