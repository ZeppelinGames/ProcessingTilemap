PVector mapPos = new PVector(0, 0);
PVector cameraPos = new PVector(0, 0);
int cameraZoom = 5;
int moveSpeed =3;
PVector playerPos = new PVector(0, 0);
int alphaClipThreshold = 20;

int spriteScale = 2; //Drawing scale

int spriteSize = 8; //Atlas size
ArrayList<PImage> spriteAtlas = new ArrayList<PImage>(); //[Images from sprite sheet]

Map currMap;
ArrayList<Tile> currTiles = new ArrayList<Tile>();
ArrayList<Tile> fileTiles = new ArrayList<Tile>();

PImage playerSprite;
PImage spriteSheet;

int layerMapWidth = 4;
int layerMapHeight = 4;

PVector markerPos = new PVector(0, 0);

int currDrawTileIndex=0;

void setup() {
  fullScreen();
  LoadResources();
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
  JSONObject mapData = loadJSONObject(mapFileName + ".json");
  String mapName = mapData.getString("mapName");
  int mapWidth = mapData.getInt("mapWidth");
  int mapHeight = mapData.getInt("mapHeight");

  int spawnPosX = mapData.getInt("spawnPositionX");
  int spawnPosY = mapData.getInt("spawnPositionY");

  PVector spawnPos = new PVector(spawnPosX, spawnPosY);

  JSONArray tileData = loadJSONArray(mapFileName + "tiles.json");

  for (int n =0; n < tileData.size(); n++) {
    JSONObject tile = tileData.getJSONObject(n); 

    int id = tile.getInt("spriteIndex");
    int posX = tile.getInt("posX");
    int posY = tile.getInt("posY");
    int order = tile.getInt("order");
    boolean collider =tile.getBoolean("collider");

    PVector pos = new PVector(posX, posY);

    Tile newTile = new Tile(id, pos, order, collider);
    currTiles.add(newTile);
  }

  Tile[] tileArray = new Tile[currTiles.size()];
  tileArray = currTiles.toArray(tileArray);
  currMap = new Map(mapName, tileArray, mapWidth, mapHeight, spawnPos);
}

void SaveMap() {
  selectOutput("Save location", "SaveLocation");
}

void SaveLocation(File selection) {
  if (selection != null) {
    String savePath = selection.getAbsolutePath();
    String mapSavePath = savePath.endsWith(".json") ? savePath : savePath + ".json";
    String tilesSavePath = savePath;

    String mapNameFile = savePath;
    if (savePath.endsWith(".json")) {
      String tilePathName = savePath.substring(0, savePath.indexOf('.')-1);
      println(tilePathName);

      tilesSavePath = tilePathName + "tiles.json";
    } else {
      tilesSavePath = savePath + "tiles.json";
    }
    println(tilesSavePath);
    println(mapSavePath);

    PrintWriter mapOutput =  createWriter(mapSavePath);

    mapNameFile = savePath.substring(savePath.lastIndexOf('\\')+1);
    if(mapNameFile.contains(".")) {
      mapNameFile = mapNameFile.substring(0,mapNameFile.indexOf('.')-1);
    } 
    String mapName = mapNameFile;
    println(mapName);

    int mapWidth = 1;
    int mapHeight = 1;
    PVector spawnPos = new PVector(0, 0);

    int left= int(fileTiles.get(0).pos.x);
    int right = int(fileTiles.get(0).pos.x);

    int top =int(fileTiles.get(0).pos.y);
    int bottom= int(fileTiles.get(0).pos.y);
    for (int n=0; n < fileTiles.size(); n++) {
      Tile currTile = fileTiles.get(n);

      left = currTile.pos.x < left ? int(currTile.pos.x) : left;
      right = currTile.pos.x > right ? int(currTile.pos.x) : right;

      top = currTile.pos.y < top ? int(currTile.pos.y) : top;
      bottom = currTile.pos.y > bottom ? int(currTile.pos.y) : bottom;
    }

    mapWidth = right - left +1;
    mapHeight = bottom - top +1;

    mapOutput.println("{");
    mapOutput.println("\"mapName\": \"" + mapName + "\",");
    mapOutput.println("\"mapWidth\":" + mapWidth  + ",");
    mapOutput.println("\"mapHeight\":" + mapHeight  + ",");
    mapOutput.println("\"spawnPositionX\":" + int(spawnPos.x)  + ",");
    mapOutput.println("\"spawnPositionY\":" + int(spawnPos.y));

    mapOutput.println("}"); 

    mapOutput.flush();
    mapOutput.close();


    //Write json data
    PrintWriter output = createWriter(tilesSavePath);
    output.println("[");
    for (int n =0; n < fileTiles.size(); n++) {
      Tile currTile = fileTiles.get(n);

      output.println("{");
      output.println("\"spriteIndex\":" + currTile.sprite +",");
      output.println("\"posX\":" + int(currTile.pos.x) + ",");
      output.println("\"posY\":" + int(currTile.pos.y) + ",");
      output.println("\"order\":" + currTile.order + ",");
      output.println("\"collider\":" + currTile.collider);

      output.print("}");
      if (n != fileTiles.size()-1) {
        output.print(",");
      }
      output.print("\n");
    }
    output.println("]");
    output.flush();
    output.close();
  }
}

void draw() {
  clear();
  DrawTiles();
  DrawMarker();
  UpdateUI();
}


boolean ctrlPressed=false;
void keyPressed() {
  if (key == CODED) {
    if (keyCode == CONTROL) {
      println("control pressed");
      ctrlPressed = true;
    }
  }

  if (keyCode == 83) {
    println("s pressed");
  }

  if (ctrlPressed) {
    if (keyCode == 83) {
      println("SAVING");
      SaveMap();
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = false;
    }
  }
}

void DrawTiles() {
  for (int n =0; n < currTiles.size(); n++) {
    Tile currTile = currTiles.get(n);
    DrawImage(spriteAtlas.get(currTile.sprite), int(currTile.pos.x), int(currTile.pos.y), spriteScale * cameraZoom );
  }
}

void UpdateUI() {
  DrawImage(spriteAtlas.get(currDrawTileIndex), 10, 10, spriteScale*spriteScale);
  fill(255);
  text(currDrawTileIndex, 10, 10);
}

void DrawMarker() {
  stroke(color(255, 255, 255, 255));
  noFill();
  square(markerPos.x, markerPos.y, spriteScale*cameraZoom*spriteSize);
}

void mouseMoved() {
  int scaling = spriteScale*cameraZoom*spriteSize;
  int mX = int(mouseX / scaling) * scaling;
  int mY =  int(mouseY / scaling) * scaling;

  markerPos = new PVector(mX, mY);
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  //-1 UP, 1 DOWN
  currDrawTileIndex += e;
  currDrawTileIndex = currDrawTileIndex > spriteAtlas.size()-1 ? 0 : currDrawTileIndex;
  currDrawTileIndex = currDrawTileIndex < 0 ? spriteAtlas.size()-1 : currDrawTileIndex;
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    int scaling = spriteScale*cameraZoom*spriteSize;
    PVector tilePos = new PVector(int(markerPos.x / scaling), int(markerPos.y/scaling));

    int overlap =0;
    for (int n =0; n < currTiles.size(); n++) {
      Tile currTile = currTiles.get(n);
      int dist = int(sqrt(pow(int(currTile.pos.y - markerPos.y), 2) + (pow(int(currTile.pos.x - markerPos.x), 2))));
      if (dist < (spriteScale * cameraZoom)) {
        overlap++;
      }
    }
    int layer = overlap+1;

    Tile fileTile = new Tile(currDrawTileIndex, tilePos, layer, false);
    Tile newTile = new Tile(currDrawTileIndex, markerPos, layer, false);
    currTiles.add(newTile);
    fileTiles.add(fileTile);
  }

  if (mouseButton == RIGHT) {
    ArrayList<Tile> tilesAtPos = new ArrayList<Tile>();
    for (int n =0; n < currTiles.size(); n++) {
      Tile currTile = currTiles.get(n);
      int dist = int(sqrt(pow(int(currTile.pos.y - markerPos.y), 2) + (pow(int(currTile.pos.x - markerPos.x), 2))));
      if (dist < (spriteScale * cameraZoom)) {
        tilesAtPos.add(currTiles.get(n));
      }
    }

    if (tilesAtPos.size() > 0) {
      int highest=0;
      int highestIndex=0;
      for (int n =0; n < tilesAtPos.size(); n++) {
        if (tilesAtPos.get(n).order > highest) {
          highest =  tilesAtPos.get(n).order;
          highestIndex = n;
        }
      }

      int removeIndex = currTiles.indexOf(tilesAtPos.get(highestIndex));
      currTiles.remove(removeIndex);
      fileTiles.remove(removeIndex);
    }
  }
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
