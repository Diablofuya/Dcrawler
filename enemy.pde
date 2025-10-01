class Enemy {

  /* -----Types of enemies -----*/
  final String WAND ="wanderer";
  final String CHAS ="chase";
  final String SHOT = "shooter";
  final String BOSS1 = "boss1";
  final String BOSS2 = "boss2";

  /* ----- regular enemies fields ----- */
  float x, y, w, h;
  String type;
  boolean alive;
  float hp;
  float vx, vy;
  float speed;
  float maxSpeed;
  float chargeSpeed;
  float accel; //accelaration

  /* ----- Ai fields -----*/
  int decisionInterval;
  int aiTimerFrames;

  int knockbackFrames =0;
  float targetVX;
  float targetVY;
  float drag =0.95;
  float kb_vx=0, kb_vy=0;

  /* ----- firing fields -----*/
  int fireCD = 0;
  int fireRate = 90;
  float projSpeed = 6.0;  // enemy bullet speed
  float projSize  = 16;
  float projDmg   = 1.0;


  /* ----- BOSS1 constants ----- */
  final String B_IDLE   = "idle";
  final String B_WINDUP = "windup";
  final String B_CHARGE = "charge";
  final String B_RECOV  = "recover";

  /* ----- BOSS1 fields ----- */
  int windUpFrames =20;
  int chargeFrames =width/15;
  int recoverFrames =18;

  String bState;

  int phaseTimer =0;  //counts down the curent phase
  float chargeDirX =0, chargeDirY=0;
  float chargeCool =60; // at least one seconds between attacks
  int chargeCoolTimer =0; //counts down the time between charges


  /* ===== BOSS2: constants (states & helpers) ===== */
  final String B2_INTRO     = "b2_intro";     // slow descent (plays once)
  final String B2_P1        = "b2_p1";        // phase 1 random movement/ charging 
  final String B2_P2        = "b2_p2";        // phase 2 loop (spawning unlocked)
  final String B2_P3        = "b2_p3";        // phase 3 loop (spams attacks faster, lower cooldowns, faster movements ) 
  final String B2_WINDUP    = "b2_windup";    // pre-dash telegraph
  final String B2_CHARGE    = "b2_charge";    //  dash
  final String B2_RECOVER   = "b2_recover";   // recovery from dashing 
  final String B2_SPAWN     = "b2_spawn";     // spawns minions (random enemies) (no cooldown as it's supposed to be too hard)
  
  

  /* Phase thresholds (fractions of max HP) */
  final float  B2_THR_P2 = 0.70f;   // <= 70% → Phase 2
  final float  B2_THR_P3 = 0.40f;   // <= 40% → Phase 3

  /* Timings (for 60fps) */
  int   b2_introFrames        = 36;    // 0.6s total 
  int   b2_windupFrames       = 36;    // 0.6s telegraph
  int   b2_chargeFrames       = 42;    // 0.7s dash
  int   b2_recoverFrames      = 18;    // 0.3s recovery
  int   b2_spawnFrames        = 40;    // 0.6


  /* -------------------------------- Cooldowns (randomized windows, in frames) */
  
  // Independent cooldowns (count down to 0)
  int b2_chargeCD = 0;
  int b2_spawnCD = 0;
  
  //---------------------------------------phase 1: 
  int b2_chargeCDMin_P1 = 180, b2_chargeCDMax_P1 = 240;  // 3-4s (charge attack) 

  // --------------------------------------phase 2: 
  int b2_chargeCDMin_P2 = 120, b2_chargeCDMax_P2 = 180;  // 2-3s ( chargge attack) 
  int b2_spawnCDMin_P2  = 360, b2_spawnCDMax_P2  = 600;  // 6-10s ( spawn enemies) 
   
  //---------------------------------------phase 3: 
  int b2_chargeCDMin_P3 =  78, b2_chargeCDMax_P3 = 120;  // 1.3-2s (charge attack)
  int b2_spawnCDMin_P3  = 180, b2_spawnCDMax_P3  = 360;  // 3-6s (spawn enemies) 

  /* Speeds / movement */
  float b2_chargeSpeed   = 12.0f;  // dash speed
  float b2_chargeDirX    = 0, b2_chargeDirY = 0;
  float b2_rotSpeed =0, b2_rotAngle=0; // rotation angle and speed 
  float b2_spawnScale =0f; // will only be used when the boss spawns in the room 

  /* Boss2 state + timers */
  String b2State = B2_INTRO;   // current Boss2 sub-state
  int    b2PhaseTimer = 0;     // counts down current sub-state

  /* Health tracking for phase thresholds */
  float  maxHp;                // set in constructor = initial hp

  /* Timed-boss integration */
  boolean b2TimedBoss      = false;  // marks that this enemy uses the timer rules
  float   b2TimeBonusOnHit = 0.5f;   // seconds added to timer per hit 
  boolean b2FinishWindow   = false;  // becomes true when global timer reaches 0
  
  // Phase base spin speeds (radians per frame; tune to taste)
  float b2_spinRoam_P1 = 0.02f;
  float b2_spinRoam_P2 = 0.03f;
  float b2_spinRoam_P3 = 0.045f;
  float b2_spinWindup  = 0.08f;
  float b2_spinCharge  = 0.14f;
  float b2_spinRecover = 0.05f;

  // Roam decision intervals per phase
  int b2_decision_P1 = 66;
  int b2_decision_P2 = 52;
  int b2_decision_P3 = 38;

  // Internal flag to keep charging despite phase swaps
  boolean b2MidCharge = false;
  boolean timerStarted = false;

  


  /* ---- Constructor ---- */
  Enemy( float x, float y, float w, float h, float hp, String type ) {
    this.x =x;
    this.y =y;
    this.w =w;
    this.h =h;
    this.hp =hp;
    this.type =type;

    initialize();
  }

  /* ------ Initialize the important fields ------ */
  void initialize() {
    this.alive =true;
    vx =0;
    vy=0;
    targetVX=0;
    targetVY=0;

    if (type.equals(WAND)) {

      decisionInterval =60;
      aiTimerFrames=10;
      speed =2.5;
    }
    else if (type.equals(CHAS)) {

      decisionInterval =30;
      aiTimerFrames =7;
      speed =2.5;
      maxSpeed =4.5;
      accel =0.3;
    }
    else if (type.equals(SHOT)) {

      decisionInterval = 60;
      aiTimerFrames = 0;
      speed = 4;
      fireCD = 30;         // initial delay so it doesn't shoot on the first frame
    } 
    else if (type.equals(BOSS1)) {

      decisionInterval = 20; // not used for wandering, we use it as "next attempt" spacing
      aiTimerFrames = 0;
      speed = 0;             // boss doesn't drift; it charges only
      maxSpeed = 0;
      accel = 0;
      chargeSpeed = 15;      // fast!
      bState = B_IDLE;
      phaseTimer = 0;
      chargeCoolTimer = 30;    // a short delay before its very first charge
    } 
    else if (type.equals(BOSS2)) {
      // Base body
      decisionInterval = 60; // will be overridden per phase
      aiTimerFrames = 0;
      speed = 3.0;           // used by chooseNewDirection()
      maxSpeed = 0;          // not used (we set vx/vy directly)
      accel = 0;

      // Timed boss + phases
      maxHp = hp;
      b2TimedBoss = true;
      b2FinishWindow = false;

      // Spawn intro
      b2State = B2_INTRO;
      b2PhaseTimer = b2_introFrames;
      b2_spawnScale = 0f;
      b2_rotAngle = 0f;
      b2_rotSpeed = b2_spinCharge; // fast spin during intro

      // Seed CDs after intro ends
      b2_chargeCD = 0;
      b2_spawnCD = 0;

      // No motion until intro finishes
      vx = 0;
      vy = 0;
    }
  }

  /* ----- Boss functions ------ */

  void beginWindup(Isaac isaac) {
    // lock a direction from boss center to Isaac center
    float cx = x + 0.5f*w, cy = y + 0.5f*h;
    float px = isaac.x + 0.5f*isaac.w, py = isaac.y + 0.5f*isaac.h;
    float dx = px - cx, dy = py - cy;
    float len = sqrt(dx*dx + dy*dy);

    if (len < 0.0001f) {
      dx = 1;
      dy = 0;
      len = 1;
    }
    chargeDirX = dx / len;
    chargeDirY = dy / len;

    vx = 0;
    vy = 0;
    bState = B_WINDUP;
    phaseTimer = windUpFrames;
  }

  void beginCharge() {
    vx = chargeSpeed * chargeDirX;
    vy = chargeSpeed * chargeDirY;
    bState = B_CHARGE;
    phaseTimer = chargeFrames;
  }


  void beginRecover() {
    vx = 0;
    vy = 0;
    bState = B_RECOV;
    phaseTimer = recoverFrames;
    chargeCoolTimer = (int)chargeCool;  // start cooldown before next windup
  }




  /* ----- movement functions ------*/

  void applySteering() {
    // Nudge velocity toward target
    vx += accel * (targetVX - vx);
    vy += accel * (targetVY - vy);

    // Smooth a bit
    vx *= drag;
    vy *= drag;

    // Clamp to max_speed
    float s = sqrt(vx*vx + vy*vy);
    if (s > maxSpeed && s > 0) {
      float k = maxSpeed / s;
      vx *= k;
      vy *= k;
    }
  }

  /*Chooses a new direction
   1. creates a random number from 0 to 7
   2. multiplies a circle with the number then divides it by 8 to get an angle (in radians)
   3. updates the velocities to match the direction.
   */
  void chooseNewDirection() {

    int k = (int) random(8);
    float ang = TWO_PI * k/ 8.0f;
    vx = speed*cos(ang);
    vy = speed * sin(ang);
  }

/*=========================================== AI behaviour =================================*/
  void updateAI(Isaac isaac) {

    if (!alive) {
      return;
    }

    if (type.equals(WAND) || type.equals(SHOT)) {
      aiTimerFrames++;

      if (aiTimerFrames >= decisionInterval) {
        chooseNewDirection();
        aiTimerFrames=0;
      }
    } else if (type.equals(CHAS)) {
      // chase: go for isaac
      float cx = x+ 0.5f *w;
      float cy = y +0.5f *h;
      float px = isaac.x + 0.5f *isaac.w;
      float py = isaac.y + 0.5f *isaac.h;

      float dx = px -cx;
      float dy =py -cy;
      float len = sqrt(dx*dx + dy*dy);

      if (len > 0.0001f) {
        targetVX = (dx / len) * maxSpeed;
        targetVY = (dy / len) * maxSpeed;
      } 
      else {
        targetVX =0;
        targetVY =0;
      }

      applySteering();
    } 
    else if (type.equals(BOSS1)) {
      if (chargeCoolTimer >0) {
        chargeCoolTimer--;
      }

      if (bState.equals(B_IDLE)) {
        aiTimerFrames++;

        if (chargeCoolTimer ==0 && aiTimerFrames >= decisionInterval) {
          aiTimerFrames =0;
          beginWindup(isaac);
        }
      } 
      else if (bState.equals(B_WINDUP)) {
        phaseTimer--;
        if (phaseTimer <= 0) {
          beginCharge();
        }
      }
      else if (bState.equals(B_CHARGE)) {
        phaseTimer--;
        if (phaseTimer <=0) {
          beginRecover();
        }
      } 
      else if (bState.equals(B_RECOV)) {
        phaseTimer--;
        if (phaseTimer <= 0) {
          bState = B_IDLE;
        }
      }
    } 
    else if (type.equals(BOSS2)) {
     // check 1, timer reached 0
      if (b2TimedBoss && bossTimerFrames <=0 && !b2FinishWindow){
       b2FinishWindow =true; 
      }
      
     // check 2, Intro sequence: 
     if (b2State.equals(B2_INTRO)){
       // grow the intro scale
        b2_spawnScale = min(1.0f, b2_spawnScale + (1.0f / max(1, b2_introFrames)));
      // spin fast during intro
        b2_rotAngle += b2_spinCharge;  // or whatever fast value you chose
       // count down and exit intro
      if (--b2PhaseTimer <= 0) {
        String loop = b2PhaseFromHp();   // B2_P1 at full hp
        b2EnterPhaseLoop(loop);          // sets decisionInterval, rotSpeed, and rolls CDs
      }
        return;
     }
      
      // spin update (never stops) 
      b2_rotAngle += b2_rotSpeed;
      
      //check 3, spawn check  (runs no matter the state) 
      if (b2_spawnCD > 0){
      b2_spawnCD--;
      }
      b2TrySpawnEvent(b2CurrentPhase());
      
      
      // ------check 4, state checks
      if (b2State.equals(B2_WINDUP)) { // wind up phase (before a charge) 
        // stand still, countdown to charge
        if (--b2PhaseTimer <= 0) {
          b2BeginCharge();
        }
      }
      else if (b2State.equals(B2_CHARGE)) { // charge phase (before recovery) 
        // keep moving; walls are handled in onHitWallX/Y (reflection)
        if (--b2PhaseTimer <= 0) {
          b2BeginRecover();
        }
      }
      else if (b2State.equals(B2_RECOVER)) { // recovery period (before returning to one of the idle phases (P (1-3)) 
        if (--b2PhaseTimer <= 0) {
          b2MidCharge = false;
          b2EnterPhaseLoop(b2CurrentPhase());
        }
      }
      else if (b2State.equals(B2_P1) || b2State.equals(B2_P2) || b2State.equals(B2_P3)) { // idle phases (between attack phases) 
        // Random roaming (chooseNewDirection cadence)
        aiTimerFrames++; // uused to select a new decision
        if (aiTimerFrames >= decisionInterval) { 
          chooseNewDirection(); // roams in another direction
          aiTimerFrames = 0; // resets the time for the next decision
        }
        // Charge scheduling
        if (b2_chargeCD > 0){ // if the charge cooldown is >0 lower it
          b2_chargeCD--;
        }
        if (b2_chargeCD == 0) { // if the charge cooldown is 0 enter the wind up phase (charge loop) 
          b2BeginWindup(isaac);
          return; // so the charge won't cancel
        }
        
        // If HP crossed a threshold, update loop tuning (dont interrupt active charge)
        String want = b2CurrentPhase(); // current idle phase 
        if (!b2MidCharge && !b2State.equals(want)) { // when the boss isn't charging and the desired phase isn't the current one 
          b2EnterPhaseLoop(want); // change the phase to the wanted one 
        }
      }
      
      
      
    }
  }

  /* ----- collision functions ------*/

  void onHitWallX() {
    if (type.equals(BOSS2) && b2State.equals(B2_CHARGE) || type.equals(BOSS1) && bState.equals(B_CHARGE)) {
      // changes the velocity (keep charging just in the other direction) 
      vx = -vx;
      return;
    }
    if (type.equals(WAND)) {
      // immediately pick a new direction
      chooseNewDirection();
      aiTimerFrames = 0;
    } else if (type.equals(CHAS)) {
      // damp side motion briefly
      vx = 0;
    }
  }

  void onHitWallY() {
    if (type.equals(BOSS2) && b2State.equals(B2_CHARGE) || type.equals(BOSS1) && bState.equals(B_CHARGE)) {
      // changes the velocity (keep charging just in the other direction) 
      vy = -vy;
      return;
    }
    if (type.equals(WAND)) {
      chooseNewDirection();
      aiTimerFrames = 0;
    } else if (type.equals(CHAS)) {
      vy = 0;
    }
  }

  void moveAndCollide() {
    if (!alive){
      return;
    }
    // --- Apply  knockback  ---
    applyKnockback();

    boolean hitX = false, hitY = false;
    boolean bossCharging = isBossCharging();

    // ----- X axis -----
    x += vx;
    if (x < 0) {
      x = 0;
      if (!bossCharging){
        vx = 0;
      }
      hitX = true;
    }
    else if (x + w > width) {
      x = width - w;
      if (!bossCharging){
        vx = 0;
      }
      hitX = true;
    }

    if (hitX){
      onHitWallX();
    }

    // ----- Y axis -----
    y += vy;
    if (y < 0) {
      y = 0;
      if (!bossCharging){
        vy = 0;
      }
      hitY = true;
    } 
    else if (y + h > height) {
      y = height - h;
      if (!bossCharging){
        vy = 0;
      }
      hitY = true;
    }

    if (hitY) {
      onHitWallY();
    }
  }


  void applyKnockback() {
    if (knockbackFrames > 0) {
      vx += kb_vx;
      vy += kb_vy;
      // decay knockback so it fades out
      kb_vx *= 0.2f;
      kb_vy *= 0.2f;
      knockbackFrames--;
    }
  }

  void startKnockback(float dirX, float dirY, float strength, int frames) {
    float len = sqrt(dirX*dirX + dirY*dirY);
    if (len > 0.0001f) {
      kb_vx = strength * (dirX / len);
      kb_vy = strength * (dirY / len);
    } else {
      kb_vx = kb_vy = 0;
    }
    knockbackFrames = frames;
  }




  Shot tryFireAt(Isaac isaac) {
    if (!type.equals(SHOT)) return null;
    if (fireCD > 0) {
      fireCD--;
      return null;
    }
    fireCD = fireRate;

    // aim from enemy center to Isaac center
    float cx = x + 0.5f * w, cy = y + 0.5f * h;
    float px = isaac.x + 0.5f * isaac.w, py = isaac.y + 0.5f * isaac.h;
    float dx = px - cx, dy = py - cy;
    float len = sqrt(dx*dx + dy*dy);
    if (len < 0.0001f) return null;

    float vx = projSpeed * dx / len;
    float vy = projSpeed * dy / len;

    // spawn slightly in front of the enemy so it doesn't collide with itself
    float sx = cx + 0.5f * vx;
    float sy = cy + 0.5f * vy;

    // use your 2-boolean Shot constructor (crit=false, fromEnemy=true)
    return new Shot(sx, sy, vx, vy, projSize, projDmg, 90, false, true);
  }


  /*================================= Boss 2 functions ========================================*/

  /*-------- boss 2 auto defeat -------*/
  void beginAutoDefeat() {
    // Stop moving/attacking
    vx = 0;
    vy = 0;
    b2_rotSpeed = 0.01f; // slows down dramatically 
     
    // Stopping all future attacks by increasing the cooldowns to the maximum number 
    b2_chargeCD = Integer.MAX_VALUE;
    b2_spawnCD  = Integer.MAX_VALUE;
    
    boss2Victory =true; 
    game =false; 
   
  }
  
  String b2CurrentPhase(){
   return b2PhaseFromHp(); 
  }

  /* ---- Decides which phase state we should be in based on HP -----
   calculates the hp and return what phase the boss should be at
   1. if the current hp < threshold of phase 3 it will return phase 3
   2. if the current hp< threshhold of phase 2 it will return phase 2
   3. if both the other conditions are false it will return phase 1
   */
  String b2PhaseFromHp() {
    float r = (maxHp <= 0) ? 1 : (hp / maxHp);
    if (r <= B2_THR_P3) return B2_P3;
    if (r <= B2_THR_P2) return B2_P2;
    return B2_P1;
  }
  
  void b2EnterPhaseLoop(String phase){
    b2State =phase;
    aiTimerFrames=0;
    // change the decision speed and base spin based on the state
    
    if (phase.equals(B2_P1)){
     decisionInterval = b2_decision_P1; 
     b2_rotSpeed =b2_spinRoam_P1;
    }
    else if(phase.equals(B2_P2)){
      decisionInterval = b2_decision_P2; 
     b2_rotSpeed =b2_spinRoam_P2;
    }
    else{
     decisionInterval = b2_decision_P3; 
     b2_rotSpeed =b2_spinRoam_P3; 
     
     if (!timerStarted){
       startBossTimer(30);
       timerStarted=true;
       println("timer started");
     }
    }
    
    if (!b2MidCharge){
     b2_chargeCD = b2RollChargeCD(phase);
    }
    
    if (b2_spawnCD <=0){
      b2_spawnCD =b2RollSpawnCD(phase);
    }
    
    
  }
  
   int b2RollChargeCD(String phase) {
    if (phase.equals(B2_P1)) {
      return randomInt(b2_chargeCDMin_P1, b2_chargeCDMax_P1);
    }
    if (phase.equals(B2_P2)){
      return randomInt(b2_chargeCDMin_P2, b2_chargeCDMax_P2);
    }
    return randomInt(b2_chargeCDMin_P3, b2_chargeCDMax_P3);
  }

  int b2RollSpawnCD(String phase) {
    if (phase.equals(B2_P2)){
      return randomInt(b2_spawnCDMin_P2, b2_spawnCDMax_P2);
    }
    return randomInt(b2_spawnCDMin_P3, b2_spawnCDMax_P3);
  }
  
  // Try to fire a spawn event without changing state
  void b2TrySpawnEvent(String phase) {
    if (b2_spawnCD > 0) return;
    // ---- SPAWN NOW ----
    // Replace 'currentRoom' with your actual active room variable:
    if (phase.equals(B2_P1)) {
      return; // can't spawn in this phase
    }
    else if (phase.equals(B2_P2)){
      addRandomEnemies(activeWorld.current(), 2, 3);
    }
    else{
      addRandomEnemies(activeWorld.current(), 3, 4);
    }
    // -------------------
    b2_spawnCD = b2RollSpawnCD(phase);
  }


  /* ======================================= Boss 2 attack functions */

  // Begin BOSS2 attacks
  void b2BeginWindup(Isaac isaac) {
    // lock direction toward Isaac
    float cx = x + 0.5f*w, cy = y + 0.5f*h;
    float px = isaac.x + 0.5f*isaac.w, py = isaac.y + 0.5f*isaac.h;
    float dx = px - cx, dy = py - cy, len = sqrt(dx*dx + dy*dy);
    if (len < 0.0001f) {
      dx = 1;
      dy = 0;
      len = 1;
    }
    b2_chargeDirX = dx/len;
    b2_chargeDirY = dy/len;

    vx = 0;
    vy = 0;
    b2MidCharge =true;
    b2State = B2_WINDUP;
    b2PhaseTimer = b2_windupFrames;
    b2_rotSpeed=b2_spinWindup;
  }

  void b2BeginCharge() {
     vx = b2_chargeSpeed * b2_chargeDirX;
    vy = b2_chargeSpeed * b2_chargeDirY;
    b2State = B2_CHARGE;
    b2PhaseTimer = b2_chargeFrames;
    b2_rotSpeed = b2_spinCharge;
  }


  /*Recovery from charging */
  void b2BeginRecover() {
    vx = 0;
    vy = 0;
    b2State = B2_RECOVER;
    b2PhaseTimer = b2_recoverFrames;
    b2_rotSpeed = b2_spinRecover;
  }


  










  /* =================================== draw functions ==================================*/
  void drawEnemy() {
    ellipseMode(CORNER);
    noStroke();
    if (type.equals(BOSS2)) {
      pushMatrix();
      // transform from the center
      float cx = x + w*0.5f, cy = y + h*0.5f;
      translate(cx, cy);
      rotate(b2_rotAngle);
      
      // Intro scale-in only during B2_INTRO
      float s = (b2State.equals(B2_INTRO)) ? (max(0.001f, b2_spawnScale)) : 1.0f;
      //println(b2State, b2_spawnScale, b2PhaseTimer);
      scale(s);
      
      // Colour by state 
      if (b2State.equals(B2_CHARGE)) {
        fill(225, 70, 70);
      }
      else if (b2State.equals(B2_WINDUP)){
        fill(230, 210, 60); //yellow
      }
      else if (b2State.equals(B2_P1)){
        fill(54, 121, 228); // blue 
      }
      else if ( b2State.equals(B2_P2)){
        fill(245,135,76); // orange 
      }
      else{
        fill(186,38,35); // red 
      }
      
      // Draw an isosceles triangle pointing up; size based on min(w,h)
      float R = 0.55f * min(w, h);    // radius
      // Vertices relative to center
      beginShape();
      vertex(0, -R);
      vertex(-0.8f*R, 0.6f*R);
      vertex(0.8f*R, 0.6f*R);
      endShape(CLOSE);

      popMatrix();
      return; // prevent drawing other enemies for BOSS2

    }

    if ( type.equals(BOSS1)) {

      if (bState.equals(B_CHARGE)) {
        fill(220, 80, 80);    // flash red
      } else if (bState.equals(B_WINDUP)) {
        fill(200, 200, 80);                    // yellow telegraph
      } else {
        fill(120, 107, 108);    // base
      }

      rect(x, y, w, h);
    } else if (type.equals(WAND)) {

      fill(255, 140, 0);  // orange
      ellipse(x, y, w, h);
    } else if (type.equals(CHAS)) {

      fill(200, 40, 40); // red
      ellipse(x, y, w, h);
    } else if ( type.equals(SHOT)) {

      fill (64, 68, 74);
      ellipse(x, y, w, h);
    }
  }



  /* ----- helpers ----- */
  void take_damage(float amount) {
   
    hp -= amount;
    
    if (type.equals(BOSS2)){
     if (hp<=0) {
       boss2Victory =false;
       killedBoss2 =true;
       game=false; 
     }
    }
    
    if (type.equals(BOSS2) && b2TimedBoss){
     bossTimerFrames+= timeAddPerHitFrames;
     
    }
    
    if (hp <= 0) {
      alive =false;
    }
  }
  
  boolean isBossCharging() {
  return (type.equals(BOSS1) && bState.equals(B_CHARGE)) ||
         (type.equals(BOSS2) && b2State.equals(B2_CHARGE));
}

  /* ============================= Hitboxes ============================================= */
  Hitbox get_hitbox() {
    return new Hitbox(x, y, w, h);
  }

  CrossHitbox getCross() {
    float cx = x + w/2f, cy = y + h/2f;
    float t  = 0.55f * min(w, h);

    Hitbox hbar = new Hitbox(x, cy - t/2f, w, t);
    Hitbox vbar = new Hitbox(cx - t/2f, y, t, h);
    return new CrossHitbox(hbar, vbar);
  }

  Hitbox b2BodyHurtbox() {
    float pad = 0.20f * min(w, h);  // buffer of 20% 
    return new Hitbox(x + pad, y + pad, w - 2*pad, h - 2*pad);
  }
}

/*===================================== gloabls ========================================== */

/* ----- Randomize enemy spawns for a room (used at world 2 only)  ------ */
void addRandomEnemies(Room r, int minCount, int maxCount) {

  int n = (int)random(minCount, maxCount+1);
  for (int i = 0; i < n; i++) {
    String t;
    float roll = random(1);
    // 45% wanderer, 35% chaser, 20% shooter
    if (roll < 0.45) t = "wanderer";
    else if (roll < 0.80) t = "chase";
    else t = "shooter";

    float es = random(60, 120);
    // try a few times to avoid spawning inside a rock/near edges
    float ex = random(300, width - 80 - es);
    float ey = random(120, height - 120 - es);

    r.enemies.add(new Enemy(ex, ey, es, es, t.equals("wanderer") ? 6 : (t.equals("chase") ? 8 : 10), t));
  }
}

int randomInt(int a, int b) {
  return (int)random(a, b + 1);
}
