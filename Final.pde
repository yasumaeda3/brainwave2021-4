import oscP5.*;
import netP5.*;
 
final int N_CHANNELS = 4;

final int PORT = 5000;
OscP5 oscP5 = new OscP5(this, PORT);

//Initialize 4x30 array "alpha"
float[][] alpha = new float[N_CHANNELS][30];

void oscEvent(OscMessage msg){
  float data;
  if(msg.checkAddrPattern("/muse/elements/alpha_relative")){
    //Store new value of alpha to "data" 
    for(int ch = 0; ch < N_CHANNELS; ch++){
      data = msg.get(ch).floatValue();
      for(int i=1; i<30; i++){
        //Shift 29 old values of alpha from n to n+1
      alpha[ch][i] = alpha[ch][i-1];
      }
      //Append new alpha value to alpha[ch][0]
      alpha[ch][0] = data;
      
  }
}
}

//Define array "circle". "circle" stores 8 attributes of each circle for all 50 circles on screen at any given moment
float circle[][] = new float[50][8];
int size = 0;

void setup() {
  //Initialize all 50 circles
  for(int i=0; i<50; i++){
    circle[i][0] = int(random(1919)); //x coordinate
    circle[i][1] = int(random(1079)); //y coordinate
    circle[i][2] = int(random(200)); // size
    circle[i][3] = random(1,3); //growth rate
    circle[i][4] = random(1); 
    circle[i][5] = random(1); 
    circle[i][6] = random(1); 
    circle[i][7] = 30; //opacity
  }
  //Initialize canvas
  size(1920, 1080);
  frameRate(30);
}

void draw() {
  //Define colorMode as HSB
   colorMode(HSB,1,1,1);
   background(1,0,1);
   noFill(); //remove border from circles
   //Define float circle_color as the sum of most recent values of "alpha" across 4 channels
   float circle_color = 0.8*(alpha[0][0] + alpha[1][0] + alpha[2][0] + alpha[3][0]);
   
   //Calculate stdev of 30  values of alpha[0]
   float average=0;
   for(int i=0;i<30;i++){
     average = average + alpha[0][i];
   }
   average = average/30;
   float sums=0;
   for(int i=0;i<30;i++){
     sums = sums + (alpha[0][i]-average)*(alpha[0][i]-average);
   }
   float circle_speed = 1 +  sums*100000;
   
   
   for(int i=0; i<50; i++){
     circle[i][2] = circle[i][2] + circle[i][3];   
     circle(circle[i][0], circle[i][1], circle[i][2]);
     noStroke();
     fill(circle[i][4],1,1,circle[i][7]);
   }
   
   for(int i=0; i<50; i++){
     if((circle[i][2] > 100) && (circle[i][2]<150)){
       circle[i][7] = circle[i][7] + 2;
     }
     if((circle[i][2]>150)){
       circle[i][7] = circle[i][7] - 2;
     }
}
  for(int i=0; i<50; i++){
   if(circle[i][7]<0){
    circle[i][0] = int(random(1919)); //x coordinate
    circle[i][1] = int(random(1079)); //y coordinate
    circle[i][2] = int(random(200)); // size
    circle[i][3] = circle_speed*5; //growth rate
    circle[i][4] = circle_color; //r
    circle[i][5] = 1; //g
    circle[i][6] = 1; //b
    circle[i][7] = 30; //opacity
   }
  }
  print(circle_color);
  print(circle_speed);
  print("\n");
}
