class LevelManager {
  ArrayList<Room> rooms = new ArrayList<>();
  int currentRoomId = 0;
  int entryCooldown = 0;     // frames to prevent instant re-entry
  int entryCooldownFrames = 20;
  
  /*---- theme ----*/
  int themeBg = color(120,96,76);  // default (world 1 ) 
  Room current() { 
    return rooms.get(currentRoomId); 
  }

  void tickCooldown() {
    if (entryCooldown > 0) entryCooldown--;
  }



  // call when you successfully change rooms
  void setRoom(int id) {
    currentRoomId = id;
    entryCooldown = entryCooldownFrames;
    Room r = current();
    if (!r.visited) {
      r.spawnRocksIfNeeded();
      r.spawnEnemiesIfNeeded();
      r.visited = true;
    }
  }

  // convenience
  void addRoom(Room r) { rooms.add(r); }
}
