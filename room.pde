class Room {
  int id;
  ArrayList<Door> doors;
  ArrayList<Enemy> enemies;
  ArrayList<Hitbox> rocks; // obstacles
  boolean cleared, visited;


  Room (int id ) {
    this.id =id;
    this.doors =new ArrayList<>();
    this.rocks = new ArrayList<>();
    this. enemies = new ArrayList<>();
    this. cleared =false;
    this.visited =false;
  }


  /*------ collisions logic ------- */


  /* ------ collision between isaac's shots and the enemies */
  void shotEnemyCo(ArrayList<Shot> shots) {
    for (Shot s : shots) {

      if (!s.alive || s.fromEnemy) {
        continue;
      }
      for (Enemy e : enemies) {
        if (interCrossRect(e.getCross(), s.getHitbox())) {

          e.take_damage(s.damage);
          if (!e.type.equals("boss1")) {
            e.startKnockback(s.vx, s.vy, 1, 6);
          }
          s.alive=false;
        }
      }
    }
  }

  /* ------ Collision between the enemies shots and isaac */
  void enemyShotsHitIsaac( ArrayList <Shot> shots, Isaac isaac) {
    for (int i = shots.size()-1; i >=0; i--) {
      Shot s = shots. get(i);

      if (!s.alive || !s.fromEnemy) {
        continue;
      }
      if (interCrossRect(isaac.getCross(), s.getHitbox())) {
        isaac.recieveDamage(0.5);
        s.alive=false;

        if (isaac.hp <= 0) {
          game =false;
        }
      }
    }
  }


  /* ------- Enemies AI logic (in charge of movement and shooting */
  void enemyLogic(Isaac isaac, ArrayList<Shot> shots) {

    for (int i = enemies.size()-1; i>=0; i--) {
      Enemy e = enemies.get(i);

      if (!e.alive) {
        enemies.remove(i);
        continue;
      }
      e.updateAI(isaac);
      e.moveAndCollide();
      resolveEnemyCollisions(e);

      Shot s = e.tryFireAt(isaac);
      if (s != null) shots.add(s);
    }
    if (!cleared && enemies.isEmpty()) {
      cleared = true;
      unlockIfCleared();
    }
  }

  /* -------- Collision between isaac and the enemies */
  void isaacEnemyCo(Isaac isaac) {
    for (Enemy e : enemies) {
      if (interCrossCross(isaac.getCross(), e.getCross())) {

        if (!e.type.equals("boss1")) {
          //e.startKnockback(isaac.vx, isaac.vy, 1, 6);
          isaac.recieveDamage(0.5);
        } else {
          isaac.recieveDamage(1);
        }

        if (isaac.hp<=0) {
          game =false;
        }
      }
    }
  }


  /* ------ collision between shots and rocks ----- */
  void resolveShotsVsRocks(ArrayList<Shot> shots) {
    for (Shot s : shots) {
      if (!s.alive) continue;
      Hitbox sh = s.getHitbox();
      for (Hitbox r : rocks) {
        if (sh.intersaction(r)) {
          s.alive = false;
          break;
        }
      }
    }
  }






  /* ------ draws enemies -------*/
  void drawEnemies() {
    for ( Enemy e : enemies) {
      e.drawEnemy();
    }
  }


  /* ----- Resolves isaac's collision withthe world (rocks / walls) uses a simple hitbox */
  void resolveIsaacCollisions(Isaac isaac) {
    // bounds clamp
    if (isaac.x < 0) isaac.x = 0;
    if (isaac.x + isaac.w > width) isaac.x = width - isaac.w;
    if (isaac.y < 0) isaac.y = 0;
    if (isaac.y + isaac.h > height) isaac.y = height - isaac.h;

    Hitbox p = isaac.getHitbox();
    for (Hitbox r : rocks) {
      if (p.intersaction(r)) {
        float overlapL = (p.x + p.w) - r.x;
        float overlapR = (r.x + r.w) - p.x;
        float overlapT = (p.y + p.h) - r.y;
        float overlapB = (r.y + r.h) - p.y;

        float minH = min(overlapL, overlapR);
        float minV = min(overlapT, overlapB);

        if (minH < minV) {
          if (overlapL < overlapR) {
            isaac.x -= overlapL;
            isaac.vx = 0;
          } else {
            isaac.x += overlapR;
            isaac.vx = 0;
          }
        } else {
          if (overlapT < overlapB) {
            isaac.y -= overlapT;
            isaac.vy = 0;
          } else {
            isaac.y += overlapB;
            isaac.vy = 0;
          }
        }
        p = isaac.getHitbox();
      }
    }
  }


  /* ------- resolves the enemies collisions with the world (uses a simle hitbox)  -------*/
  void resolveEnemyCollisions(Enemy e) {
    // bounds clamp on screen
    if (e.x < 0) {
      e.x = 0;
      e.vx = 0;
      e.onHitWallX();
    }
    if (e.x + e.w > width) {
      e.x = width - e.w;
      e.vx = 0;
      e.onHitWallX();
    }
    if (e.y < 0) {
      e.y = 0;
      e.vy = 0;
      e.onHitWallY();
    }
    if (e.y + e.h > height) {
      e.y = height - e.h;
      e.vy = 0;
      e.onHitWallY();
    }

    Hitbox hb = e.get_hitbox();
    for (Hitbox r : rocks) {
      if (!hb.intersaction(r)) continue;

      float overlapL = (hb.x + hb.w) - r.x;
      float overlapR = (r.x + r.w) - hb.x;
      float overlapT = (hb.y + hb.h) - r.y;
      float overlapB = (r.y + r.h) - hb.y;

      float minH = min(overlapL, overlapR);
      float minV = min(overlapT, overlapB);

      if (minH < minV) {
        if (overlapL < overlapR) {
          e.x -= overlapL;
          e.vx = 0;
        } else {
          e.x += overlapR;
          e.vx = 0;
        }
        e.onHitWallX();
      } else {
        if (overlapT < overlapB) {
          e.y -= overlapT;
          e.vy = 0;
        } else {
          e.y += overlapB;
          e.vy = 0;
        }
        e.onHitWallY();
      }
      hb = e.get_hitbox(); // refresh for chained overlaps
    }
  }



  // Return an enterable door the player is overlapping, or null
  Door tryDoorTransition(Isaac isaac, int entryCooldown) {

    if (entryCooldown > 0) return null;
    Hitbox hb = isaac.getHitbox();

    for (Door d : doors) {
      if (d.canEnter() && hb.intersaction(d.getHitbox())) {
        return d;
      }
    }
    return null;
  }

  // Draw whole room (rocks, doors, enemies)
  void draw() {
    // rocks
    noStroke();
    fill(90, 80, 70);
    for (Hitbox r : rocks) rect(r.x, r.y, r.w, r.h);

    // doors
    for (Door d : doors) d.drawDoor();

    // enemies
    drawEnemies();
  }

  /* ----- unlocks the doors in the current room if there are no enemies ------ */
  void unlockIfCleared() {
    for (Door d : doors) d.locked = !cleared;
  }


  /*  ------- Adders --------  */
  void addDoor(Door d) {
    doors.add(d);
  }
  void addEnemy(Enemy e) {
    enemies.add(e);
  }
  void addRock(Hitbox r) {
    rocks.add(r);
  }

  // Find the door on a given wall (N/E/S/W)
  Door getDoorByDirection(String dir) {
    for (Door d : doors) if (d.direction != null && d.direction.equals(dir)) return d;
    return null;
  }




  // ---------- One-time spawners (called from onEnter when !visited) ----------


  /* ------- spawn rocks in rooms unless specified otherwise*/
  void spawnRocksIfNeeded() {

    if (id ==4 || id ==6) {
      return;
    }
    int n = 5;
    float rw = 40, rh = 40;
    for (int i = 0; i < n; i++) {
      float rx = random(0, width  - rw);
      float ry = random(0, height - rh);
      // avoid door centers (simple guard)
      rocks.add(new Hitbox(rx, ry, rw, rh));
    }
  }


  /*----- Spawns enemies in a room based on their id */
  void spawnEnemiesIfNeeded() {
    if (visited) return; //  safe-guard to make sure enemies won't respwan
    if (activeWorld == world) {

      if (id == 1) {
        enemies.add(new Enemy (halfWidth, halfHeight, s,s, 8, "chase"));
        enemies.add(new Enemy (fourthWidth*2, halfHeight-50, m, m, 8, "wanderer"));
      } 
      else if (id == 2) {
        enemies.add(new Enemy (600, 700, l, l, 15, "shooter"));
        enemies.add(new Enemy (450, 500, s, s, 18, "chase"));
      }
      else if ( id ==3) {
        enemies.add(new Enemy (650, 450, m, m, 8, "wanderer"));
        enemies.add(new Enemy (500, 300, s, s, 24, "chase"));
      }
      else if (id == 4) {
        enemies.add(new Enemy (halfWidth, halfHeight, b, b, 100, "boss1"));
        enemies.add(new Enemy (fourthWidth*3, fourthHeight, l, l, 9, "shooter"));
        enemies.add(new Enemy (fourthWidth*3, fourthHeight*3, l, l, 9, "shooter"));
        enemies.add(new Enemy (fourthWidth, fourthHeight, l, l, 9, "shooter"));
        enemies.add(new Enemy (fourthWidth, fourthHeight*3, l, l, 9, "shooter"));
      }
      else if (id ==6) {
        enemies.add(new Enemy (500, 300, m, m, 24, "chase"));
        enemies.add(new Enemy (700, 250, l, l, 9, "shooter"));
        enemies.add(new Enemy (700, 750, l, l, 9, "shooter"));
        enemies.add(new Enemy (300, 250, l, l, 9, "shooter"));
        enemies.add(new Enemy (300, 750, l, l, 9, "shooter"));
      }
      else if (id ==7) {
        enemies.add(new Enemy (200, 200, m, m, 8, "wanderer"));
        enemies.add(new Enemy (500, 300, m, m, 10, "wanderer"));
        enemies.add(new Enemy (200, 700, m, m, 12, "wanderer"));
        enemies.add(new Enemy (700, 300, m, m, 6, "wanderer"));
      }
      else if (id== 9) {
        enemies.add(new Enemy (700, 250, l, l, 9, "shooter"));
      }
      else if (id ==8) {
        enemies.add(new Enemy (700, 200, m, m, 14, "chase"));
        enemies.add(new Enemy (500, 300, m, m, 24, "chase"));
      }
    }
    if (activeWorld == world2){
      if (id==6){
        enemies.add(new Enemy (halfWidth-200,0,b,b,100,"boss2"));
      }
    }
  }
}
