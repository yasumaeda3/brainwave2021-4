import ddf.minim.*;
import ddf.minim.analysis.*;
import oscP5.*;
import netP5.*;

final int N_CHANNELS = 4;
final int N_BANDS = 5;
final int BUFFER_SIZE = 220;
// final float MAX_MICROVOLTS = 1682.815;
// final float DISPLAY_SCALE = 200.0;
final float DISPLAY_SCALE = - 400.0;
final String[] LABELS = new String[] {
  "TP9", "FP1", "FP2", "TP10"
};

final color BG_COLOR = color(0, 0, 0);
final color AXIS_COLOR = color(255, 0, 0);
// final color GRAPH_COLOR = color(0, 0, 255);
final color[] GRAPH_COLORS = { color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), 
             color(0, 255, 255), color(0, 255, 255) };
final color LABEL_COLOR = color(255, 255, 0);
final int LABEL_SIZE = 21;

final int PORT = 5000;
OscP5 oscP5 = new OscP5(this, PORT);

float[][][] buffer = new float[N_BANDS][N_CHANNELS][BUFFER_SIZE];
// int pointer = 0;
int[] pointer = { 0, 0, 0, 0, 0 };
float[] offsetX = new float[N_CHANNELS];
float[] offsetY = new float[N_CHANNELS];
Minim minim;
AudioPlayer song;
FFT fft;

// Variables that define the "areas" of the spectrum
// For example, for bass, we take only the first 4% of the total spectrum
float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

// This leaves 64% of the possible spectrum that will not be used.
// These values are generally too high for the human ear anyway.

// Score values for each zone
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Previous values, to soften the reduction
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Softening value
float scoreDecreaseRate = 25;

// Cubes that appear in space
int nbCubes;
Cube[] cubes;

//Lines that appear on the sides
int nbMurs = 50;
Mur[] murs;
 
void setup()
{
  //Display in 3D on the whole screen
  fullScreen(P3D);
 
  //Load the minim library
  minim = new Minim(this);
 
  //Load song
  song = minim.loadFile("song.mp3");
  
  //Create the FFT object to analyze the song
  fft = new FFT(song.bufferSize(), song.sampleRate());
  
  //One cube per frequency band
  nbCubes = abs(Math.round(1000*buffer[1][1][1]));
  cubes = new Cube[nbCubes];
  
  //As many walls as we want
  murs = new Mur[nbMurs];

  //Create all objects
  //Create the cube objects
  for (int i = 0; i < nbCubes; i++) {
   cubes[i] = new Cube(); 
  }
  
  //Create the wall objects
  //Left walls
  for (int i = 0; i < nbMurs; i+=4) {
   murs[i] = new Mur(0, height/2, 10, height); 
  }
  
  //Straight walls
  for (int i = 1; i < nbMurs; i+=4) {
   murs[i] = new Mur(width, height/2, 10, height); 
  }
  
  //Low walls
  for (int i = 2; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, height, width, 10); 
  }
  
  //High walls
  for (int i = 3; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, 0, width, 10); 
  }
  
  //Black background
  background(0);
  
  //Start song
  song.play(0);
}
 
void draw()
{
  //Advance the song. We draw () for each "frame" of the song ...
  fft.forward(song.mix);
  
  //Calculation of "scores" (power) for three categories of sound
  //First, save the old values
  oldScoreLow = scoreLow;
  oldScoreMid = scoreMid;
  oldScoreHi = scoreHi;
  
  //Reset values
  scoreLow = 0;
  scoreMid = 0;
  scoreHi = 0;
 
  //Calculate the new "scores"
  for(int i = 0; i < fft.specSize()*specLow; i++)
  {
    scoreLow += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
  {
    scoreMid += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
  {
    scoreHi += fft.getBand(i);
  }
  
  //Slow down the descent.
  if (oldScoreLow > scoreLow) {
    scoreLow = oldScoreLow - scoreDecreaseRate;
  }
  
  if (oldScoreMid > scoreMid) {
    scoreMid = oldScoreMid - scoreDecreaseRate;
  }
  
  if (oldScoreHi > scoreHi) {
    scoreHi = oldScoreHi - scoreDecreaseRate;
  }
  
  //Volume for all frequencies at this time, with louder sounds more prominent.
  //This allows the animation to go faster for higher pitched sounds that are more noticeable.
  float scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
  
  //Subtle color of background
  background(scoreLow/100, scoreMid/100, scoreHi/100);
   
  //Cube for each frequency band
  for(int i = 0; i < nbCubes; i++)
  {
    //Frequency band value
    float bandValue = fft.getBand(i);
    
    //The color is represented as: red for bass, green for mid-range, and blue for high.
    //Opacity is determined by the tape volume and the overall volume.
    cubes[i].display(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
  }
  
  //The opacity is determined by the volume of the a and the overall volume.
  float previousBandValue = fft.getBand(0);
  
  //Distance between each line point, negative because on dimension z
  float dist = -25;
  
  //Multiply the height by this constant
  float heightMult = 2;
  
  //For each band
  for(int i = 1; i < fft.specSize(); i++)
  {
    //Value of the frequency band, we multiply the bands further away so that they are more visible.
    float bandValue = fft.getBand(i)*(1 + (i/50));
    
    //Selection of color according to the strengths of different types of sounds
    stroke(100+scoreLow, 100+scoreMid, 100+scoreHi, 255-i);
    strokeWeight(1 + (scoreGlobal/100));
    
    //lower left line
    line(0, height-(previousBandValue*heightMult), dist*(i-1), 0, height-(bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), height, dist*(i-1), (bandValue*heightMult), height, dist*i);
    line(0, height-(previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), height, dist*i);
    
    //upper left line
    line(0, (previousBandValue*heightMult), dist*(i-1), 0, (bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), 0, dist*(i-1), (bandValue*heightMult), 0, dist*i);
    line(0, (previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), 0, dist*i);
    
    //lower right line
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width, height-(bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), height, dist*(i-1), width-(bandValue*heightMult), height, dist*i);
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), height, dist*i);
    
    //upper straight line
    line(width, (previousBandValue*heightMult), dist*(i-1), width, (bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), 0, dist*(i-1), width-(bandValue*heightMult), 0, dist*i);
    line(width, (previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), 0, dist*i);
    
    //Save the value for the next loop round
    previousBandValue = bandValue;
  }
  
  //Rectangular walls
  for(int i = 0; i < nbMurs; i++)
  {
    //We assign a band to each wall, and we send its strength to it.
    float intensity = fft.getBand(i%((int)(fft.specSize()*specHi)));
    murs[i].display(scoreLow, scoreMid, scoreHi, intensity, scoreGlobal);
  }
}

//Class for cubes that float in space
class Cube {
  //Position Z de "spawn" et position Z maximale
  float startingZ = -10000;
  float maxZ = 1000;
  
  //Position values
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
  //Builder
  Cube() {
    //Spawn the cube in a random location
    x = random(0, width);
    y = random(0, height);
    z = random(startingZ, maxZ);
    
    //Give the cube a random rotation
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  }
  
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Color selection, opacity determined by intensity (band volume)
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, intensity*5);
    fill(displayColor, 255);
    
    //Color lines, they disappear with the individual intensity of the cube
    color strokeColor = color(255, 150-(20*intensity));
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal/300));
    
    //Creation of a transformation matrix to perform rotations, enlargements
    pushMatrix();
    
    //Shift
    translate(x, y, z);
    
    //Calculation of rotation as a function of intensity for the cube
    sumRotX += intensity*(rotX/1000);
    sumRotY += intensity*(rotY/1000);
    sumRotZ += intensity*(rotZ/1000);
    
    //Applying rotation
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);
    
    //Creation of the box, variable size according to the intensity for the cube
    box(100+(intensity/2));
    
    //Application of the matrix
    popMatrix();
    
    //Z displacement
    z+= (1+(intensity/5)+(pow((scoreGlobal/150), 2)));
    
    //Replace the box at the back when it is no longer visible
    if (z >= maxZ) {
      x = random(0, width);
      y = random(0, height);
      z = startingZ;
    }
  }
}


//Class to display the lines on the sides
class Mur {
  //Minimum and maximum position Z
  float startingZ = -10000;
  float maxZ = 50;
  
  //Position values
  float x, y, z;
  float sizeX, sizeY;
  
  //Builder
  Mur(float x, float y, float sizeX, float sizeY) {
    //Make the line appear at the specified location
    this.x = x;
    this.y = y;
    //Random depth
    this.z = random(startingZ, maxZ);  
    
    //We determine the size because the walls to the floors have a different size than those on the sides
    this.sizeX = sizeX;
    this.sizeY = sizeY;
  }
  
  //Display function
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Color determined by low, medium and high sounds
    //Opacity determined by overall volume
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, scoreGlobal);
    
    //Make the lines disappear in the distance to give an illusion of fog
    fill(displayColor, ((scoreGlobal-5)/1000)*(255+(z/25)));
    noStroke();
    
    //First band, the one that moves according to the force
    //Transformation matrix
    pushMatrix();
    
    //Shift
    translate(x, y, z);
    
    //Enlargement
    if (intensity > 100) intensity = 100;
    scale(sizeX*(intensity/100), sizeY*(intensity/100), 20);
    
    //Creation of the "box"
    box(1);
    popMatrix();
    
    //Second strip, the one that is always the same size
    displayColor = color(scoreLow*0.5, scoreMid*0.5, scoreHi*0.5, scoreGlobal);
    fill(displayColor, (scoreGlobal/5000)*(255+(z/25)));
    //Transformation matrix
    pushMatrix();
    
    //Shift
    translate(x, y, z);
    
    //Enlargement
    scale(sizeX, sizeY, 10);
    
    //Creation of the "box"
    box(1);
    popMatrix();
    
    //Z displacement
    z+= (pow((scoreGlobal/150), 2));
    if (z >= maxZ) {
      z = startingZ;  
    }
  }
}
