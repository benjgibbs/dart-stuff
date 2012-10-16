
import 'dart:html';
import 'dart:math';

class Cell{
  static const int ALIVE = 1;
  static const int DEAD = 0;
  num cellAge = 0;
  int status;
  Cell([status = ALIVE]){
    this.status = status;
  }
  void age(){
    cellAge++;
  }
  String toString(){
    return status == ALIVE ? "Alive" : "Dead";
  }
  bool isAlive() {
    return status == ALIVE;
  }
  static final Cell Dead = new Cell(status: DEAD);
}


class Simulation{
  List<Cell> cells = [];
  
  final num gridWidth;
  final num gridHeight;
  final num startingPc;
  CanvasElement canvas;
  num fpsAverage;
  num renderTime;
  
  Simulation(this.gridWidth, this.gridHeight, this.startingPc, this.canvas){
  
  }
  
  int cellCount(){
    return gridWidth*gridHeight;
  }
  
  int index(num xpos, num ypos){
    return xpos + gridWidth * ypos;
  }
  
  int xpos(int index){
    return index % gridWidth;
  }
  
  int ypos(int index){
    return index ~/ gridWidth;
  }
  
  Cell cell(num xpos, num ypos){
    int idx = index(xpos,ypos);
    if(idx >= cellCount()){
     throw new Exception('Position ($xpos,$ypos) is out of bounds.');
    }
    return cells[idx];
  }
  
  void setup(){
    print('Setting up');

    Random r = new Random();
    for(num i = 0; i < cellCount(); i++){
      cells.add((r.nextDouble() * 100 > startingPc) ? Cell.Dead : new Cell());
    }
    requestRedraw();
  }
  
  void timeout(){
    draw(new Date.now().millisecondsSinceEpoch);
  }
  
  void draw(int time) {
    if (time == null) {
      // time can be null for some implementations of requestAnimationFrame
      time = new Date.now().millisecondsSinceEpoch;
    }
    if (renderTime != null) {
      showFps((1000 / (time - renderTime)));
    }
    renderTime = time;

    num xPixels = canvas.width;
    num yPixels = canvas.height;

    num xLen = xPixels/gridWidth;
    num yLen = yPixels/gridHeight;
    
    print('Using $xLen pixels per x unit and $yLen pixels per y unit');
    print('There are ${cells.filter( (c) => c.isAlive()).length}/${cells.length} living cells');
    
    CanvasRenderingContext2D ctxt = canvas.context2d;

    try{
      ctxt.fillStyle = "#FFFFFF";
      ctxt.strokeStyle = "#FFFFFF";
      ctxt.beginPath();
      ctxt.fillRect(0, 0, xPixels, yPixels);
      ctxt.closePath();
      ctxt.stroke();
      
      ctxt.lineWidth = 0.5;
      ctxt.fillStyle = "#00F0F0";
      ctxt.strokeStyle = "#00A0A0";
      
      for(num r = 0; r < gridHeight; r++){
        for(num c = 0; c < gridWidth; c++){
          if(cells[index(c,r)].status == Cell.ALIVE){
            ctxt.beginPath();
            ctxt.rect(c*xLen, r*yLen, xLen, yLen);
            ctxt.fill();
            ctxt.closePath();
            ctxt.stroke();
          }
        }
      }
    }finally{
      ctxt.restore();
    }
    
    nextStep();
    requestRedraw();
  }
  
  void requestRedraw() {
    window.setTimeout(timeout, 2000);
    //window.requestAnimationFrame(draw);
  }
  
  void showFps(num fps) {
    if (fpsAverage == null) {
      fpsAverage = fps;
    }

    fpsAverage = fps * 0.05 + fpsAverage * 0.95;

    query("#notes").text = "${(fpsAverage*10).round()/10} fps";
  }
  
  /**
   * From: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
   * Transitions occur:
   * Any live cell with fewer than two live neighbours dies, as if caused by under-population.
   * Any live cell with two or three live neighbours lives on to the next generation.
   * Any live cell with more than three live neighbours dies, as if by overcrowding.
   * Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
   */
  void nextStep(){
    List<Cell> newCells = [];
    for(num i = 0; i < cellCount(); i++){
      num x = xpos(i);
      num y = ypos(i);
          
      Cell cell = cell(x,y);
      
      switch(neighbours(x,y)){
        case 2:
          if(cell.isAlive()){
            cell.age();
          }
          break;
        case 3: 
          if(cell.isAlive()){
            cell.age();
          }else{
            cell = new Cell();
          }
          break;
        default:
          cell = Cell.Dead;
          break;
      }
      newCells.add(cell);
    }
    cells = newCells;
  }
  
  num neighbours(num x, num y){
    num result = 0;
    if(x > 0){
      result += cell(x-1,y).status;
      if(y > 0){
        result += cell(x-1,y-1).status;
      }
      if(y < (gridHeight - 1)){
        result += cell(x-1, y+1).status;
      }
    }
    if(x < (gridWidth - 1)){
      result += cell(x+1,y).status;
      if(y > 0){
        result += cell(x+1,y-1).status;
      }
      if(y < (gridHeight - 1)){
        result += cell(x+1, y+1).status;
      }
    }
    return result;
  }
  
}

void main() {
  CanvasElement canvas = query("#container");
  int width = canvas.width;
  int height = canvas.height;
  num gridWidth = 100;//250;
  num gridHeight = 80;//200;
  num startingPc = 5;
  print('Creating a new simulation');
  Simulation sim = new Simulation(gridWidth, gridHeight, startingPc, canvas);
  sim.setup();
}
