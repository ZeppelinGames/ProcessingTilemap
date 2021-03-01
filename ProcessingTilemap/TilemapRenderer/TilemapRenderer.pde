PVector mapPos = new PVector(0, 0);
PVector cameraPos = new PVector(0, 0);
int cameraZoom = 5;
int moveSpeed =3;
PVector playerPos = new PVector(0, 0);
int playerScale = 1;
int alphaClipThreshold = 20;

int spriteScale = 2; //Drawing scale

int spriteSize = 8; //Atlas size
ArrayList<PImage> spriteAtlas = new ArrayList<PImage>(); //[Images from sprite sheet]
Map currMap;
//ArrayList<Layer> layers = new ArrayList<Layer>();
Layer[] layers;
ArrayList<Tile> collisionTiles = new ArrayList<Tile>();

PImage playerSprite;
PImage spriteSheet;

int layerMapWidth = 4;
int layerMapHeight = 4;

void setup() {
  surface.setTitle("Tilemap Renderer");
  fullScreen();
  LoadResources();
  LoadMap("smallIsland");
}

void LoadResources() {
  playerSprite = loadImage("playerSprite.png");
  spriteSheet = loadImage("Tileset2.png");

  println("Sprite sheet: " + spriteSheet.width + "x" + spriteSheet.height);

  for (int y=0; y < spriteSheet.height; y+=spriteSize) {
    for (int x =0; x <spriteSheet.width; x+=spriteSize) {
      PImage newSprite = spriteSheet.get(x, y, spriteSize, spriteSize);
      spriteAtlas.add(newSprite);
    }
  }
  println("Grabbed " + str(spriteAtlas.size()) + " sprites from sprite sheet");
}

void LoadMap(String mapFileName) {

  String mapFileNameEdited = mapFileName.endsWith(".json") ? mapFileName : mapFileName + ".json";

  File mapF = new File(dataPath(mapFileNameEdited));
  if (mapF.exists()) {
    JSONObject mapData = loadJSONObject(mapFileNameEdited);
    String mapName = mapData.getString("mapName");
    int mapWidth = mapData.getInt("mapWidth");
    int mapHeight = mapData.getInt("mapHeight");

    int spawnPosX = mapData.getInt("spawnPositionX");
    int spawnPosY = mapData.getInt("spawnPositionY");

    PVector spawnPos = new PVector(spawnPosX, spawnPosY);

    JSONArray tileData = loadJSONArray(mapFileName + "tiles.json");
    Tile[] newTiles = new Tile[tileData.size()];
    int highestLayer=0;

    for (int n =0; n < tileData.size(); n++) {
      JSONObject tile = tileData.getJSONObject(n); 

      int id = tile.getInt("spriteIndex");
      int posX = tile.getInt("posX");
      int posY = tile.getInt("posY");
      int order = tile.getInt("order");
      boolean collider =tile.getBoolean("collider");

      PVector pos = new PVector(posX, posY);

      if (order > highestLayer) {
        highestLayer = order;
      }

      newTiles[n] = new Tile(id, pos, order, collider);
    }

    currMap = new Map(mapName, newTiles, mapWidth, mapHeight, spawnPos);
    int scaling = -(spriteScale * spriteSize * cameraZoom);
    cameraPos = new PVector(int(spawnPos.x * scaling - (scaling*2)), 
      int(spawnPos.y * scaling - (scaling*2)));
    println("Set camPos to " + cameraPos);

    collisionTiles = new ArrayList<Tile>();
    for (int n =0; n < currMap.tiles.length; n++) {
      if (currMap.tiles[n].collider) {
        collisionTiles.add(currMap.tiles[n]);
      }
    }

    layers = new Layer[highestLayer+1];
    for (int n =0; n < layers.length; n++) {
      layers[n] = new Layer(new ArrayList<Tile>());
    }

    for (int n=0; n < currMap.tiles.length; n++) {
      Tile currTile = currMap.tiles[n];
      layers[currTile.order].tiles.add(currTile);
    }
  } else
  {
    println("[ERROR] Unable to load map");
  }
}

int moveX =0;
int moveY =0;
void draw() {
  clear();
  UpdateMovement();
  CheckCollisions();
  UpdateCameraPosition();
  UpdateMapPosition();
  DrawLayers();
  DrawPlayer();
}

boolean keyUp, keyDown, keyLeft, keyRight;

void UpdateMovement() {
  moveX = 0;
  moveY =0;
  if (keyUp) {
    moveY += 1;
  }
  if (keyDown) {
    moveY += -1;
  }
  if (keyLeft) {
    moveX += 1;
  }
  if (keyRight) {
    moveX += -1;
  }

  if (moveX !=0) {
    moveX = moveX > 0 ? 1 : -1;
  }
  if (moveY !=0) {
    moveY = moveY > 0 ? 1 : -1;
  }
}

void keyPressed() {
  if (key == 'w' || keyCode == UP) {
    keyUp=true;
  }
  if (key == 's' || keyCode == DOWN) {
    keyDown=true;
  }

  if (key == 'a' || keyCode == LEFT) {
    keyLeft=true;
  }

  if (key == 'd' || keyCode == RIGHT) {
    keyRight=true;
  }
}

void CheckCollisions() {
  int rePos = (spriteScale*spriteSize*cameraZoom);
  int rePPos = (playerScale*spriteSize * cameraZoom);

  for (int n =0; n < collisionTiles.size(); n++) {
    //Check if colliding 
    Tile currTile = collisionTiles.get(n);
    PVector tilePos = new PVector(currTile.pos.x * rePos + mapPos.x, currTile.pos.y * rePos + mapPos.y);

    if (BoxCollision(playerPos, rePPos/2, new PVector(tilePos.x, tilePos.y), rePos)) {
      PVector dir  = new PVector(ceil(playerPos.x - tilePos.x), ceil(playerPos.y - tilePos.y));

      if (dir.x != 0) {
        dir.x  = dir.x > 0 ? 1:-1;
      }
      if (dir.y != 0) {
        dir.y = dir.y > 0 ? 1 : -1;
      }

      moveX = dir.x > 0 && moveX > 0 ? 0 : moveX;
      moveX = dir.x < 0 && moveX < 0 ? 0 : moveX;
      
      moveY = dir.y < 0 && moveY < 0 ? 0 : moveY;
      moveY = dir.y > 0 && moveY > 0 ? 0 : moveY;
    }
  }
}

boolean circleCollision(PVector p1, int p1R, PVector p2, int p2R) {
  float dist = sqrt(pow(p2.y - p1.y, 2) + (pow(p2.x-p1.x, 2)));

  boolean collision =false;
  if (dist < p1R + p2R) {
    collision = true;
  }
  return collision;
}

boolean BoxCollision(PVector p1, int p1WH, PVector p2, int p2WH) { 
  boolean collision =false;
  if (p1.x < p2.x + p2WH) {
    if (p1.x + p1WH > p2.x) {
      if (p1.y < p2.y + p2WH) {
        if (p1.y + p1WH > p2.y) {
          collision =true;
        }
      }
    }
  }
  return collision;
}

void keyReleased() {
  if (key == 'w' || keyCode == UP) {
    keyUp=false;
  }
  if (key == 's' || keyCode == DOWN) {
    keyDown=false;
  }

  if (key == 'a' || keyCode == LEFT) {
    keyLeft=false;
  }

  if (key == 'd' || keyCode == RIGHT) {
    keyRight=false;
  }
} 


void UpdateCameraPosition() {
  int mX = moveX * moveSpeed;
  int mY = moveY * moveSpeed;

  cameraPos = new PVector(cameraPos.x + mX, cameraPos.y + mY);
}

void UpdateMapPosition() {
  mapPos = new PVector(cameraPos.x - (currMap.mapWidth), cameraPos.y - (currMap.mapHeight));
}

void DrawLayers() {
  for (int n =0; n < layers.length; n++) {
    for (int i=0; i < layers[n].tiles.size(); i++) {
      Tile currTile = layers[n].tiles.get(i);
      DrawImage(spriteAtlas.get(currTile.sprite), 
        int(currTile.pos.x*(spriteScale*spriteSize*cameraZoom) + mapPos.x), 
        int(currTile.pos.y*(spriteScale*spriteSize*cameraZoom) + mapPos.y), spriteScale * cameraZoom);
    }
  }
}

void DrawPlayer() {
  int scaling = ((spriteScale * spriteSize * cameraZoom)/2);
  playerPos = new PVector((width/2) - scaling, (height/2)- scaling);
  DrawImage(playerSprite, int(playerPos.x), int(playerPos.y), (playerScale*cameraZoom));
}

void DrawImage(PImage img, int x, int y, int scale) {
  for (int pX=0; pX < img.width; pX++) {
    for (int pY =0; pY < img.height; pY++) {
      color c = img.get(pX, pY);
      if (alpha(c) > alphaClipThreshold) {
        noStroke();
        fill(c);
        square(x + (pX*scale), y + (pY*scale), scale);
      }
    }
  }
}

class Map {
  String mapName;
  Tile[] tiles;

  int mapWidth;
  int mapHeight;

  PVector spawnPosition;

  Map(String mapName, Tile[] tiles, int mapWidth, int mapHeight, PVector spawnPos) {
    this.mapName = mapName;
    this.tiles = tiles;
    this.mapWidth = mapWidth;
    this.mapHeight = mapHeight;
    this.spawnPosition = spawnPos;
  }
}

class Layer {
  ArrayList<Tile> tiles;

  Layer (ArrayList<Tile> tiles) {
    this.tiles = tiles;
  }

  void AddTile(Tile tile) {
    tiles.add(tile);
  }
}

class Tile {
  int sprite;
  PVector pos;
  int order;
  boolean collider;

  Tile(int sprite, PVector pos, int order, boolean collider) {
    this.sprite = sprite;
    this.pos = pos;
    this.order = order;
    this.collider= collider;
  }
}
