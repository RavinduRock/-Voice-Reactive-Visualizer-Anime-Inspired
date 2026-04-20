import processing.sound.*;
import processing.video.*;

AudioIn mic;
Amplitude loudness;
float volume = 0;
float smoothVol = 0;
float peakVol = 0;    // highest volume reached during current shout

// ---- CAMERA ----
Capture cam;
PImage prevFrame;
float motionAmount = 0;
boolean motionDetected = false;
float MOTION_THRESHOLD = 8.0;  // tune this if needed


float shoutDuration = 0;
boolean isShouting = false;

float HIGH_VOL = 0.04;
float LOW_VOL = 0.03;

// Duration thresholds (in frames)
int VERY_SHORT  = 20;       // under 20   → Cleave / nothing
int SHORT       = 35;       // 20-35      → Gojo select / Blue
int MEDIUM      = 60;       // 35-60      → Switch / Dismantle start
int LONG        = 80;       // 60-80      → Reversal Red / Haaaaaa
int VERY_LONG   = 150;      // 80-150     → Hollow Purple
int DOMAIN      = 180;      // 180+       → Domain trigger zone

//States

int IDLE = 0;
int GOJO = 1;
int SUKUNA = 2;

//Gojo techniques
int GOJO_BLUE = 3;
int GOJO_RED = 4;
int GOJO_PURPLE = 5;
int GOJO_DOMAIN = 6;

//Sukuna techniques
int SUKUNA_CLEAVE = 7;
int SUKUNA_DISMANTLE = 8;
int SUKUNA_DOMAIN = 9;
int STATE = IDLE;
int SORCERER = 0;

float stateTimer = 0;
float ABILITY_DURATION = 180;


ArrayList<Wisp> wisps = new ArrayList<Wisp>();

void setup(){
  
  // Camera setup
  cam = new Capture(this, 320, 240);
  cam.start();
  prevFrame = createImage(320, 240, RGB);
  
  mic = new AudioIn(this, 0);
  mic.start();
  loudness = new Amplitude(this);
  loudness.input(mic);
  
  fullScreen();
  background(0);
  smooth(8);
  for(int i = 0; i<40; i++){
    wisps.add(new Wisp());
  }
}

void draw(){
  background(0,0,0,18);
  
  volume = loudness.analyze();
  smoothVol = lerp(smoothVol, volume, 0.15);
  trackVoice();
  // ---- CAMERA MOTION ----
  if (cam.available()) {
    prevFrame.copy(cam, 0, 0, 320, 240, 0, 0, 320, 240);
    cam.read();
    motionAmount = detectMotion();
    motionDetected = motionAmount > MOTION_THRESHOLD;
  }
  
  stateTimer++;
  
  if(stateTimer > ABILITY_DURATION){
    if(STATE == GOJO_BLUE || STATE == GOJO_RED || STATE == GOJO_PURPLE || STATE == GOJO_DOMAIN){
      STATE = GOJO;
      stateTimer =0;
    }
    else if(STATE == SUKUNA_CLEAVE || STATE == SUKUNA_DISMANTLE ||
               STATE == SUKUNA_DOMAIN){
      STATE = SUKUNA;
      stateTimer = 0;
    }
  }
  // ---- ROUTE TO CORRECT SCREEN ----
  if      (STATE == IDLE)            drawIdle();
  else if (STATE == GOJO)            drawGojo();
  else if (STATE == SUKUNA)          drawSukuna();
  else if (STATE == GOJO_BLUE)       drawBlue();
  else if (STATE == GOJO_RED)        drawRed();
  else if (STATE == GOJO_PURPLE)     drawPurple();
  else if (STATE == GOJO_DOMAIN)     drawInfiniteVoid();
  else if (STATE == SUKUNA_CLEAVE)   drawCleave();
  else if (STATE == SUKUNA_DISMANTLE)drawDismantle();
  else if (STATE == SUKUNA_DOMAIN)   drawMalevolentShrine();
  drawIdle();
  
  // ---- MOTION INDICATOR ----
  // Small dot in corner showing if motion is detected
  // Helps you know when to wave your hands!
  noStroke();
  if (motionDetected) {
    fill(0, 255, 100, 180);   // green = motion detected
  } else {
    fill(255, 0, 0, 100);     // red = no motion
  }
  ellipse(40, 40, 18, 18);
}

void drawIdle(){
  for(int i = wisps.size() - 1; i>=0; i--){
    Wisp w = wisps.get(i);
    w.update();
    w.display();
    if(w.isDead()){
      wisps.set(i, new Wisp());
    }
  }
}

void drawGojo() {
  // Deep blue background tint
  fill(0, 10, 40, 40);
  noStroke();
  rect(0, 0, width, height);

  drawIdle();

  // Six eyes — 6 orbs in a hexagon pattern around center
  float radius = 180;
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i - PI/6;
    float ex = width/2 + cos(angle) * radius;
    float ey = height/2 + sin(angle) * radius;

    // Outer glow
    noStroke();
    fill(96, 207, 255, 30);
    ellipse(ex, ey, 60, 60);

    // Eye white
    fill(200, 230, 255, 180);
    ellipse(ex, ey, 28, 20);

    // Iris
    fill(28, 106, 255, 220);
    ellipse(ex, ey, 16, 16);

    // Pupil
    fill(0, 0, 20, 240);
    ellipse(ex, ey, 8, 8);

    // Highlight
    fill(255, 255, 255, 200);
    ellipse(ex - 3, ey - 3, 4, 4);
  }

  // Infinity symbol at center
  drawInfinitySymbol(width/2, height/2, 60, color(96, 207, 255, 150));

  // Connecting hexagon between eyes
  noFill();
  stroke(28, 106, 255, 60);
  strokeWeight(0.8);
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i - PI/6;
    vertex(width/2 + cos(angle) * radius,
           height/2 + sin(angle) * radius);
  }
  endShape(CLOSE);
}

void drawSukuna() {
  // Deep blood red background tint
  fill(20, 0, 0, 40);
  noStroke();
  rect(0, 0, width, height);

  drawIdle();

  // Torii gates on left and right
  drawTorii(width/2 - 350, height/2, 120);
  drawTorii(width/2 + 350, height/2, 120);
  drawTorii(width/2 - 180, height/2 + 40, 80);
  drawTorii(width/2 + 180, height/2 + 40, 80);

  // Sukuna's four eyes at center
  drawFourEyes(width/2, height/2, 1.0);

  // Subtle flame wisps rising
  for (int i = 0; i < 3; i++) {
    float wx = random(width/2 - 300, width/2 + 300);
    float wy = random(height/2 - 100, height/2 + 200);
    noStroke();
    fill(200, 60, 0, random(30, 80));
    ellipse(wx, wy, random(4, 12), random(4, 12));
  }

  // Diamond tattoo marks
  drawDiamond(width/2, height/2 - 220, 15, color(251, 191, 36, 180));
  drawDiamond(width/2 - 250, height/2, 10, color(220, 38, 38, 160));
  drawDiamond(width/2 + 250, height/2, 10, color(220, 38, 38, 160));
}

void drawBlue() {
  fill(0, 5, 20, 35);
  noStroke();
  rect(0, 0, width, height);

  float pulse = sin(stateTimer * 0.15) * 20;
  float t = stateTimer * 0.02;

  // ---- SHOCKWAVE RINGS ----
  noFill();
  for (int i = 0; i < 5; i++) {
    float ringSize = ((stateTimer * 3 + i * 60) % 600);
    float alpha = map(ringSize, 0, 600, 200, 0);
    stroke(28, 106, 255, alpha);
    strokeWeight(2);
    ellipse(width/2, height/2, ringSize * 2, ringSize * 2);
  }

  // ---- ATTRACTION STREAMS ----
  // Curved lines spiraling inward
  for (int i = 0; i < 24; i++) {
    float angle = TWO_PI / 24 * i + t;
    float startDist = 500;
    float endDist   = 60;
    stroke(96, 207, 255, 80);
    strokeWeight(0.8);
    beginShape();
    for (float d = startDist; d > endDist; d -= 20) {
      float spiral = map(d, endDist, startDist, 0, 0.8);
      float sx = width/2 + cos(angle + spiral) * d;
      float sy = height/2 + sin(angle + spiral) * d;
      vertex(sx, sy);
    }
    endShape();
  }

  // ---- WILD PARTICLES FLYING INWARD ----
  for (int i = 0; i < 12; i++) {
    float angle = random(TWO_PI);
    float dist  = random(100, 480);
    float speed = map(dist, 100, 480, 8, 2);
    float px = width/2 + cos(angle) * dist;
    float py = height/2 + sin(angle) * dist;
    noStroke();
    float r = random(1);
    if (r < 0.6) {
      fill(96, 207, 255, random(120, 220));
    } else if (r < 0.85) {
      fill(28, 106, 255, random(100, 200));
    } else {
      fill(255, 255, 255, random(80, 180));
    }
    ellipse(px, py, random(3, 10), random(3, 10));
  }

  // ---- ELECTRIC ARCS ----
  for (int i = 0; i < 3; i++) {
    drawElectricArc(width/2, height/2, color(96, 207, 255, 160));
  }

  // ---- CORE ----
  noStroke();
  fill(10, 50, 180, 60);
  ellipse(width/2, height/2, 280 + pulse, 280 + pulse);

  fill(28, 106, 255, 100);
  ellipse(width/2, height/2, 180 + pulse, 180 + pulse);

  fill(96, 207, 255, 160);
  ellipse(width/2, height/2, 90, 90);

  fill(180, 225, 255, 220);
  ellipse(width/2, height/2, 45, 45);

  fill(255, 255, 255, 250);
  ellipse(width/2, height/2, 18, 18);

  drawFourEyesGojo(width/2, height/2, 0.4);
}
void drawRed() {
  fill(20, 0, 0, 35);
  noStroke();
  rect(0, 0, width, height);

  float pulse = sin(stateTimer * 0.12) * 25;
  float t = stateTimer * 0.02;

  // ---- EXPLOSION SHOCKWAVES ----
  noFill();
  for (int i = 0; i < 5; i++) {
    float ringSize = ((stateTimer * 3.5 + i * 70) % 700);
    float alpha = map(ringSize, 0, 700, 200, 0);
    stroke(220, 50, 50, alpha);
    strokeWeight(2);
    ellipse(width/2, height/2, ringSize * 2, ringSize * 2);
  }

  // ---- REPULSION STREAMS ----
  // Lines pushing OUTWARD
  for (int i = 0; i < 20; i++) {
    float angle = TWO_PI / 20 * i - t;
    float startDist = 50;
    float endDist   = 480;
    stroke(255, 80, 50, 70);
    strokeWeight(0.8);
    beginShape();
    for (float d = startDist; d < endDist; d += 20) {
      float spiral = map(d, startDist, endDist, 0, 0.6);
      float sx = width/2 + cos(angle + spiral) * d;
      float sy = height/2 + sin(angle + spiral) * d;
      vertex(sx, sy);
    }
    endShape();
  }

  // ---- WILD PARTICLES FLYING OUTWARD ----
  for (int i = 0; i < 14; i++) {
    float angle = random(TWO_PI);
    float dist  = random(60, 500);
    float px = width/2 + cos(angle) * dist;
    float py = height/2 + sin(angle) * dist;
    noStroke();
    float r = random(1);
    if (r < 0.5) {
      fill(255, 80, 50, random(120, 220));
    } else if (r < 0.8) {
      fill(220, 50, 50, random(100, 200));
    } else {
      fill(255, 200, 150, random(80, 180));
    }
    ellipse(px, py, random(3, 12), random(3, 12));
  }

  // ---- ELECTRIC ARCS ----
  for (int i = 0; i < 3; i++) {
    drawElectricArc(width/2, height/2, color(255, 80, 50, 160));
  }

  // ---- CORE ----
  noStroke();
  fill(160, 20, 20, 60);
  ellipse(width/2, height/2, 300 + pulse, 300 + pulse);

  fill(220, 50, 50, 100);
  ellipse(width/2, height/2, 190 + pulse, 190 + pulse);

  fill(255, 120, 80, 160);
  ellipse(width/2, height/2, 95, 95);

  fill(255, 210, 180, 220);
  ellipse(width/2, height/2, 48, 48);

  fill(255, 255, 255, 250);
  ellipse(width/2, height/2, 18, 18);

  drawFourEyesGojo(width/2, height/2, 0.4);
}
void drawPurple() {
  fill(10, 0, 20, 35);
  noStroke();
  rect(0, 0, width, height);

  float pulse = sin(stateTimer * 0.1) * 20;
  float t = stateTimer * 0.015;

  // ---- WILD TRI-COLOR PARTICLES EVERYWHERE ----
  for (int i = 0; i < 20; i++) {
    float angle = random(TWO_PI);
    float dist  = random(40, 520);
    float px = width/2 + cos(angle) * dist;
    float py = height/2 + sin(angle) * dist;
    noStroke();
    float r = random(1);
    if (r < 0.33) {
      fill(28, 106, 255, random(100, 220));   // blue
    } else if (r < 0.66) {
      fill(220, 50, 50, random(100, 220));    // red
    } else {
      fill(180, 80, 255, random(100, 220));   // purple
    }
    ellipse(px, py, random(2, 14), random(2, 14));
  }

  // ---- BLUE ORB LEFT ----
  float blueX = width/2 - 200 + sin(t) * 20;
  noStroke();
  fill(10, 40, 160, 60);
  ellipse(blueX, height/2, 220 + pulse, 220 + pulse);
  fill(28, 106, 255, 120);
  ellipse(blueX, height/2, 120, 120);
  fill(96, 207, 255, 200);
  ellipse(blueX, height/2, 55, 55);
  fill(255, 255, 255, 240);
  ellipse(blueX, height/2, 20, 20);

  // ---- RED ORB RIGHT ----
  float redX = width/2 + 200 - sin(t) * 20;
  fill(160, 20, 20, 60);
  ellipse(redX, height/2, 220 + pulse, 220 + pulse);
  fill(220, 50, 50, 120);
  ellipse(redX, height/2, 120, 120);
  fill(255, 100, 80, 200);
  ellipse(redX, height/2, 55, 55);
  fill(255, 255, 255, 240);
  ellipse(redX, height/2, 20, 20);

  // ---- CONVERGENCE BEAM ----
  // Crackling beam between orbs
  for (int i = 0; i < 4; i++) {
    stroke(200, 100, 255, random(60, 140));
    strokeWeight(random(0.5, 3));
    float midY = height/2 + random(-15, 15);
    line(blueX + 55, height/2, width/2, midY);
    line(width/2, midY, redX - 55, height/2);
  }

  // ---- ELECTRIC ARCS FROM BOTH ORBS ----
  for (int i = 0; i < 2; i++) {
    drawElectricArc(blueX, height/2, color(96, 207, 255, 140));
    drawElectricArc(redX, height/2, color(255, 80, 50, 140));
  }

  // ---- CENTRAL PURPLE EXPLOSION ----
  noStroke();
  fill(80, 20, 160, 70);
  ellipse(width/2, height/2, 350 + pulse*2, 350 + pulse*2);

  fill(140, 60, 220, 110);
  ellipse(width/2, height/2, 200 + pulse, 200 + pulse);

  fill(200, 120, 255, 180);
  ellipse(width/2, height/2, 90, 90);

  fill(230, 180, 255, 230);
  ellipse(width/2, height/2, 42, 42);

  fill(255, 255, 255, 255);
  ellipse(width/2, height/2, 16, 16);

  // ---- SHOCKWAVES ----
  noFill();
  for (int i = 0; i < 4; i++) {
    float ringSize = ((stateTimer * 2.5 + i * 80) % 650);
    float alpha = map(ringSize, 0, 650, 180, 0);
    stroke(180, 80, 255, alpha);
    strokeWeight(1.5);
    ellipse(width/2, height/2, ringSize * 2, ringSize * 2);
  }
}
void drawInfiniteVoid() {
  fill(3, 0, 10, 45);
  noStroke();
  rect(0, 0, width, height);

  float t = stateTimer * 0.01;

  // ---- INSANE TRI-COLOR PARTICLE STORM ----
  for (int i = 0; i < 25; i++) {
    float angle = random(TWO_PI);
    float dist  = random(20, 520);
    float px = width/2 + cos(angle) * dist;
    float py = height/2 + sin(angle) * dist;
    noStroke();
    float r = random(1);
    if (r < 0.33) {
      fill(28, 106, 255, random(80, 200));    // blue
    } else if (r < 0.66) {
      fill(220, 50, 50, random(80, 200));     // red
    } else {
      fill(180, 80, 255, random(80, 200));    // purple
    }
    ellipse(px, py, random(2, 12), random(2, 12));
  }

  // ---- RADIATING GEOMETRY ----
  stroke(100, 50, 180, 20);
  strokeWeight(0.5);
  for (int i = 0; i < 48; i++) {
    float angle = TWO_PI / 48 * i;
    line(width/2, height/2,
         width/2 + cos(angle) * 700,
         height/2 + sin(angle) * 700);
  }

  // ---- MULTI COLOR EXPANDING RINGS ----
  noFill();
  for (int i = 0; i < 8; i++) {
    float ringSize = ((stateTimer * 1.8 + i * 70) % 600);
    float alpha = map(ringSize, 0, 600, 180, 0);
    // Alternate ring colors
    if (i % 3 == 0)      stroke(28, 106, 255, alpha);
    else if (i % 3 == 1) stroke(220, 50, 50, alpha);
    else                 stroke(180, 80, 255, alpha);
    strokeWeight(1);
    ellipse(width/2, height/2, ringSize * 2, ringSize * 2);
  }

  // ---- SIX EYES ROTATING ----
  float eyeRadius = 200 + sin(t * 2) * 25;
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i + t * 1.5;
    float ex = width/2 + cos(angle) * eyeRadius;
    float ey = height/2 + sin(angle) * eyeRadius;

    // Eye glow trail
    noStroke();
    fill(140, 80, 255, 25);
    ellipse(ex, ey, 90, 90);

    fill(200, 230, 255, 180);
    ellipse(ex, ey, 28, 20);

    fill(80, 40, 255, 220);
    ellipse(ex, ey, 16, 16);

    fill(0, 0, 20, 240);
    ellipse(ex, ey, 8, 8);

    fill(255, 255, 255, 200);
    ellipse(ex - 3, ey - 3, 4, 4);

    // Arc from each eye to center
    stroke(140, 80, 255, 40);
    strokeWeight(0.5);
    line(ex, ey, width/2, height/2);
  }

  // ---- ELECTRIC CHAOS ARCS ----
  for (int i = 0; i < 4; i++) {
    color arcCol;
    float r = random(1);
    if (r < 0.33)      arcCol = color(96, 207, 255, 150);
    else if (r < 0.66) arcCol = color(220, 50, 50, 150);
    else               arcCol = color(200, 100, 255, 150);
    drawElectricArc(width/2, height/2, arcCol);
  }

  // ---- PULSING INFINITY ----
  float infSize = 110 + sin(t * 3) * 20;
  // Draw three layered infinity symbols in three colors
  drawInfinitySymbol(width/2, height/2, infSize + 20,
                     color(28, 106, 255, 80));
  drawInfinitySymbol(width/2, height/2, infSize + 10,
                     color(220, 50, 50, 80));
  drawInfinitySymbol(width/2, height/2, infSize,
                     color(200, 100, 255, 180));

  // ---- CORE ----
  noStroke();
  fill(60, 20, 140, 70);
  ellipse(width/2, height/2, 220, 220);

  fill(120, 60, 200, 120);
  ellipse(width/2, height/2, 130, 130);

  fill(180, 100, 255, 180);
  ellipse(width/2, height/2, 65, 65);

  fill(220, 180, 255, 230);
  ellipse(width/2, height/2, 30, 30);

  fill(255, 255, 255, 255);
  ellipse(width/2, height/2, 12, 12);

  // ---- DOMAIN TEXT ----
  if (stateTimer < 90) {
    float alpha = map(stateTimer, 0, 90, 255, 0);
    fill(200, 160, 255, alpha);
    textAlign(CENTER, CENTER);
    textSize(52);
    text("Infinite Void", width/2, height/2 + 190);
    fill(96, 207, 255, alpha * 0.8);
    textSize(22);
    text("Limitless Cursed Technique — Domain Expansion",
         width/2, height/2 + 250);
  }
}
void drawCleave() {
  fill(20, 0, 0, 40);
  noStroke();
  rect(0, 0, width, height);

  // Single devastating diagonal slash
  float progress = min(stateTimer * 4, width * 1.5);
  float alpha = map(stateTimer, 0, ABILITY_DURATION, 220, 0);

  // Main slash line
  stroke(251, 191, 36, alpha);
  strokeWeight(3);
  line(width/2 - progress/2, height/2 - progress/3,
       width/2 + progress/2, height/2 + progress/3);

  // Slash glow layers
  stroke(255, 220, 100, alpha * 0.5);
  strokeWeight(8);
  line(width/2 - progress/2, height/2 - progress/3,
       width/2 + progress/2, height/2 + progress/3);

  stroke(255, 255, 200, alpha * 0.2);
  strokeWeight(16);
  line(width/2 - progress/2, height/2 - progress/3,
       width/2 + progress/2, height/2 + progress/3);

  // Sparks along the slash
  for (int i = 0; i < 5; i++) {
    float t = random(1);
    float sx = lerp(width/2 - progress/2, width/2 + progress/2, t);
    float sy = lerp(height/2 - progress/3, height/2 + progress/3, t);
    noStroke();
    fill(251, 191, 36, random(100, 200));
    ellipse(sx + random(-20, 20),
            sy + random(-20, 20),
            random(2, 8), random(2, 8));
  }

  // Sukuna four eyes faintly visible
  drawFourEyes(width/2, height/2, 0.3);
}
void drawDismantle() {
  fill(20, 0, 0, 40);
  noStroke();
  rect(0, 0, width, height);

  float alpha = map(stateTimer, 0, ABILITY_DURATION, 220, 0);

  // Multiple omnidirectional slashes
  int slashCount = 8;
  for (int i = 0; i < slashCount; i++) {
    float angle = TWO_PI / slashCount * i;
    float progress = min(stateTimer * 3, 500);

    float x1 = width/2 + cos(angle) * 30;
    float y1 = height/2 + sin(angle) * 30;
    float x2 = width/2 + cos(angle) * progress;
    float y2 = height/2 + sin(angle) * progress;

    // Main slash
    stroke(251, 191, 36, alpha);
    strokeWeight(2);
    line(x1, y1, x2, y2);

    // Glow
    stroke(255, 200, 80, alpha * 0.4);
    strokeWeight(6);
    line(x1, y1, x2, y2);
  }

  // Cross slashes — cleave style on top
  stroke(220, 38, 38, alpha * 0.8);
  strokeWeight(2);
  line(width/2 - 400, height/2 - 250,
       width/2 + 400, height/2 + 250);
  line(width/2 + 400, height/2 - 250,
       width/2 - 400, height/2 + 250);

  // Debris particles flying outward
  for (int i = 0; i < 6; i++) {
    float pAngle = random(TWO_PI);
    float dist = random(50, 400);
    float px = width/2 + cos(pAngle) * dist;
    float py = height/2 + sin(pAngle) * dist;
    noStroke();
    fill(251, 191, 36, random(80, 180));
    ellipse(px, py, random(2, 8), random(2, 8));
  }

  // Sukuna four eyes
  drawFourEyes(width/2, height/2, 0.4);
}
void drawMalevolentShrine() {
  // Deep blood black background
  fill(8, 0, 0, 50);
  noStroke();
  rect(0, 0, width, height);

  float t = stateTimer * 0.01;

  // ---- SHRINE GROUND CRACKS ----
  // Cracks spreading from center outward
  stroke(180, 20, 20, 60);
  strokeWeight(0.8);
  for (int i = 0; i < 12; i++) {
    float angle = TWO_PI / 12 * i;
    float progress = min(stateTimer * 2, 500);
    float x1 = width/2 + cos(angle) * 40;
    float y1 = height/2 + sin(angle) * 40;
    float x2 = width/2 + cos(angle + random(-0.2, 0.2)) * progress;
    float y2 = height/2 + sin(angle + random(-0.2, 0.2)) * progress;
    line(x1, y1, x2, y2);
  }

  // ---- TORII GATES RECEDING ----
  // Gates getting smaller as they go back — perspective effect
  float[] gateX = {
    width/2 - 480, width/2 + 480,
    width/2 - 300, width/2 + 300,
    width/2 - 160, width/2 + 160
  };
  float[] gateSizes = {90, 90, 110, 110, 130, 130};

  for (int i = 0; i < gateX.length; i++) {
    drawTorii(gateX[i], height/2, gateSizes[i]);
  }

  // ---- FLAME PILLARS ----
  // Rising flames on both sides
  for (int i = 0; i < 6; i++) {
    float side = (i % 2 == 0) ? -1 : 1;
    float fx = width/2 + side * random(150, 450);
    float fy = height/2 + random(50, 200);

    // Flame layers
    noStroke();
    fill(180, 40, 0, random(20, 60));
    ellipse(fx, fy, random(30, 80), random(60, 140));

    fill(220, 100, 0, random(30, 80));
    ellipse(fx, fy + 20, random(15, 40), random(30, 80));

    fill(251, 191, 36, random(20, 60));
    ellipse(fx, fy + 35, random(8, 20), random(20, 50));
  }

  // ---- OMNIDIRECTIONAL DISMANTLE SLASHES ----
  // Background slashes constantly firing
  if (stateTimer % 8 == 0) {
    float slashAngle = random(TWO_PI);
    stroke(251, 191, 36, random(80, 160));
    strokeWeight(random(0.5, 2));
    float len = random(200, 600);
    float sx = width/2 + cos(slashAngle) * 20;
    float sy = height/2 + sin(slashAngle) * 20;
    line(sx, sy,
         sx + cos(slashAngle) * len,
         sy + sin(slashAngle) * len);
  }

  // ---- EXPANDING DARK RINGS ----
  noFill();
  for (int i = 0; i < 5; i++) {
    float ringSize = ((stateTimer * 1.2 + i * 90) % 600);
    float alpha = map(ringSize, 0, 600, 120, 0);
    stroke(180, 20, 20, alpha);
    strokeWeight(0.8);
    ellipse(width/2, height/2, ringSize * 2, ringSize * 2);
  }

  // ---- SKULL/BARRIER BOUNDARY ----
  // Dashed outer barrier circle — open barrier domain
  stroke(220, 38, 38, 40);
  strokeWeight(1);
  noFill();
  float barrierSize = 580 + sin(t) * 20;
  // Draw dashed circle manually
  int dashCount = 48;
  for (int i = 0; i < dashCount; i += 2) {
    float a1 = TWO_PI / dashCount * i;
    float a2 = TWO_PI / dashCount * (i + 1);
    line(width/2 + cos(a1) * barrierSize,
         height/2 + sin(a1) * barrierSize,
         width/2 + cos(a2) * barrierSize,
         height/2 + sin(a2) * barrierSize);
  }

  // ---- DEBRIS PARTICLES ----
  for (int i = 0; i < 8; i++) {
    float pAngle = random(TWO_PI);
    float dist = random(80, 500);
    float px = width/2 + cos(pAngle) * dist;
    float py = height/2 + sin(pAngle) * dist;
    noStroke();
    float r = random(1);
    if (r < 0.6) {
      fill(251, 191, 36, random(60, 150));   // gold sparks
    } else {
      fill(220, 38, 38, random(60, 150));    // blood red embers
    }
    ellipse(px, py, random(2, 7), random(2, 7));
  }

  // ---- FOUR EYES AT CENTER ----
  // Large and intimidating
  noStroke();
  fill(30, 0, 0, 80);
  ellipse(width/2, height/2, 220, 220);

  fill(180, 20, 20, 60);
  ellipse(width/2, height/2, 140, 140);

  drawFourEyes(width/2, height/2, 1.0);

  // ---- CORE FLAME ----
  fill(180, 40, 0, 50);
  ellipse(width/2, height/2, 200, 200);

  fill(220, 100, 0, 80);
  ellipse(width/2, height/2, 100, 100);

  fill(251, 191, 36, 160);
  ellipse(width/2, height/2, 45, 45);

  fill(255, 240, 200, 240);
  ellipse(width/2, height/2, 16, 16);

  // ---- DOMAIN TEXT FLASH ----
  if (stateTimer < 100) {
    float alpha = map(stateTimer, 0, 100, 255, 0);

    // "Malevolent Shrine" in dramatic red gold
    fill(251, 191, 36, alpha);
    textAlign(CENTER, CENTER);
    textSize(52);
    text("Malevolent Shrine", width/2, height/2 + 200);

    // Subtitle
    fill(220, 38, 38, alpha * 0.8);
    textSize(22);
    text("Innate Domain — Open Barrier", width/2, height/2 + 260);
  }
}

void trackVoice() {
  if (smoothVol > HIGH_VOL) {
    // User is shouting
    isShouting = true;
    shoutDuration++;          // count up every frame (~60fps)
    // Track the highest volume reached this shout
    if (smoothVol > peakVol) {
      peakVol = smoothVol;
    }

  } else if (isShouting) {
    // User just stopped shouting — evaluate what they did
    isShouting = false;
    evaluateShout(shoutDuration);
    shoutDuration = 0;        // reset for next shout
    peakVol = 0;      // reset peak after evaluating
  }
}

void evaluateShout(float duration) {
  println("Shout! Duration: " + duration + " frames");

  // ---- SWITCH COMMAND ----
  // Soft medium shout while a sorcerer is active
  if (SORCERER != 0 && peakVol < 0.045 && duration > 35 && duration < 70) {
    switchSorcerer();
    return;
  }

  // ---- NO SORCERER SELECTED YET ----
  if (SORCERER == 0) {
    if (duration >= 20 && duration <= 35) {
      // Short shout → GOJO
      selectSorcerer(GOJO);
    } else if (duration >= 180) {
      // Very long chant → SUKUNA
      selectSorcerer(SUKUNA);
    }
    return;
  }

  // ---- GOJO ABILITIES ----
  if (SORCERER == GOJO) {
    if (duration < 20) {
      triggerAbility(GOJO_BLUE);
    } else if (duration >= 60 && duration < 80) {
      triggerAbility(GOJO_RED);
    } else if (duration >= 80 && duration < 150) {
      triggerAbility(GOJO_PURPLE);
    } else if (duration >= 180) {
      if (motionDetected) {
        triggerAbility(GOJO_DOMAIN);
      } else {
        println(">> Move your hands to expand the domain!");
      }
    }
    return;
  }

  // ---- SUKUNA ABILITIES ----
  if (SORCERER == SUKUNA) {
    if (duration < 20) {
      triggerAbility(SUKUNA_CLEAVE);
    } else if (duration >= 60 && duration < 150) {
      triggerAbility(SUKUNA_DISMANTLE);
    } else if (duration >= 180) {
      if (motionDetected) {
        triggerAbility(SUKUNA_DOMAIN);
      } else {
        println(">> Move your hands to activate the shrine!");
      }
    }
    return;
  }
}

void selectSorcerer(int s) {
  SORCERER = s;
  if (s == GOJO) {
    STATE = GOJO;
    println(">> GOJO SELECTED");
  } else {
    STATE = SUKUNA;
    println(">> SUKUNA SELECTED");
  }
  stateTimer = 0;
}

void triggerAbility(int ability) {
  STATE = ability;
  stateTimer = 0;
  println(">> ABILITY TRIGGERED: " + ability);
}

void switchSorcerer() {
  println(">> SWITCHING SORCERER");
  SORCERER = 0;
  STATE = IDLE;
  stateTimer = 0;
}

class Wisp{
  float x,y;
  float vx, vy;
  float life, maxLife;
  float sz;
  color col;
  float noiseOffset;
  
  Wisp(){
    reset();
  }
  void reset() {
    x = random(width);
    y = random(height);
    vx = random(-0.5, 0.5);
    vy = random(-0.8, -0.2);   // drift upward slowly
    maxLife = random(120, 300);
    life = maxLife;
    sz = random(2, 8);
    noiseOffset = random(1000); // unique noise seed per wisp

    // Cursed energy color — dark purple to sickly green
    float t = random(1);
    if (t < 0.6) {
      col = color(80, 0, 120);      // dark purple
    } else if (t < 0.85) {
      col = color(20, 80, 20);      // cursed green
    } else {
      col = color(120, 0, 0);       // dark blood red
    }
  }
  void update(){
    float angle = noise(noiseOffset) * TWO_PI * 2;
    vx += cos(angle) * 0.05;
    vy += sin(angle) * 0.05;
    vx *= 0.97;
    vy *= 0.97;

    x += vx;
    y += vy;
    noiseOffset += 0.005;
    life--;
  }
  void display() {
    float alpha = map(life, 0, maxLife, 0, 120);
    noStroke();
    fill(red(col), green(col), blue(col), alpha);
    ellipse(x, y, sz, sz);
  }

  boolean isDead() {
    return life <= 0;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveHD();
  }
}

void saveHD() {
  PGraphics hd = createGraphics(1920, 1080);
  hd.beginDraw();
  hd.background(0);

  // Scale from your screen to 1920x1080
  float scaleX = 1920.0 / width;
  float scaleY = 1080.0 / height;
  hd.scale(scaleX, scaleY);

  // Draw current state onto HD canvas
  // We redraw the background layer
  hd.noStroke();
  hd.fill(0);
  hd.rect(0, 0, width, height);

  // Save current screen as HD image
  hd.endDraw();

  // Capture what's currently on screen and scale it up
  PImage screen = get();
  screen.resize(1920, 1080);

  // Save with state name in filename
  String stateName = getStateName();
  String filename = "JJK_" + stateName + "_" +
                    year() + nf(month(),2) + nf(day(),2) +
                    "_" + nf(hour(),2) + nf(minute(),2) +
                    nf(second(),2) + ".png";
  screen.save(filename);
  println("Saved: " + filename);

  // Flash confirmation on screen
  fill(255, 255, 255, 150);
  rect(0, 0, width, height);
}

String getStateName() {
  if (STATE == IDLE)              return "Idle";
  if (STATE == GOJO)              return "Gojo";
  if (STATE == GOJO_BLUE)         return "Blue";
  if (STATE == GOJO_RED)          return "ReversalRed";
  if (STATE == GOJO_PURPLE)       return "HollowPurple";
  if (STATE == GOJO_DOMAIN)       return "InfiniteVoid";
  if (STATE == SUKUNA)            return "Sukuna";
  if (STATE == SUKUNA_CLEAVE)     return "Cleave";
  if (STATE == SUKUNA_DISMANTLE)  return "Dismantle";
  if (STATE == SUKUNA_DOMAIN)     return "MalevolentShrine";
  return "Unknown";
}
void drawInfinitySymbol(float x, float y, float size, color col) {
  noFill();
  stroke(col);
  strokeWeight(1.5);
  // Two overlapping circles = infinity symbol approximation
  ellipse(x - size * 0.5, y, size, size * 0.7);
  ellipse(x + size * 0.5, y, size, size * 0.7);
}

void drawTorii(float x, float y, float size) {
  stroke(180, 20, 20, 120);
  strokeWeight(size * 0.06);
  noFill();

  // Two pillars
  float pillarSpread = size * 0.4;
  float pillarHeight = size * 1.2;
  line(x - pillarSpread, y + pillarHeight/2,
       x - pillarSpread, y - pillarHeight/2);
  line(x + pillarSpread, y + pillarHeight/2,
       x + pillarSpread, y - pillarHeight/2);

  // Top crossbeam (curved)
  strokeWeight(size * 0.09);
  beginShape();
  vertex(x - pillarSpread * 1.3, y - pillarHeight/2);
  bezierVertex(x - pillarSpread, y - pillarHeight/2 - size * 0.15,
               x + pillarSpread, y - pillarHeight/2 - size * 0.15,
               x + pillarSpread * 1.3, y - pillarHeight/2);
  endShape();

  // Lower crossbeam
  strokeWeight(size * 0.05);
  line(x - pillarSpread * 1.1, y - pillarHeight/2 + size * 0.2,
       x + pillarSpread * 1.1, y - pillarHeight/2 + size * 0.2);
}

void drawFourEyes(float x, float y, float alpha) {
  float spacing = 28;

  // Top two eyes
  drawSukunaEye(x - spacing/2, y - spacing/2, alpha);
  drawSukunaEye(x + spacing/2, y - spacing/2, alpha);

  // Bottom two eyes
  drawSukunaEye(x - spacing/2, y + spacing/2, alpha);
  drawSukunaEye(x + spacing/2, y + spacing/2, alpha);
}

void drawSukunaEye(float x, float y, float alpha) {
  noStroke();
  // Eye white
  fill(220, 200, 200, 180 * alpha);
  ellipse(x, y, 22, 14);

  // Iris — gold
  fill(251, 191, 36, 220 * alpha);
  ellipse(x, y, 12, 12);

  // Pupil — slit like
  fill(10, 0, 0, 240 * alpha);
  rect(x - 2, y - 6, 4, 12, 2);

  // Highlight
  fill(255, 255, 255, 180 * alpha);
  ellipse(x - 3, y - 3, 3, 3);
}

void drawDiamond(float x, float y, float size, color col) {
  noFill();
  stroke(col);
  strokeWeight(1.2);
  beginShape();
  vertex(x, y - size);
  vertex(x + size, y);
  vertex(x, y + size);
  vertex(x - size, y);
  endShape(CLOSE);
}

float detectMotion() {
  float total = 0;
  cam.loadPixels();
  prevFrame.loadPixels();
  for (int i = 0; i < cam.pixels.length; i += 10) {
    color c1 = cam.pixels[i];
    color c2 = prevFrame.pixels[i];
    float diff = abs(red(c1) - red(c2)) +
                 abs(green(c1) - green(c2)) +
                 abs(blue(c1) - blue(c2));
    total += diff;
  }
  return total / 1000;
}
void drawElectricArc(float x, float y, color col) {
  stroke(col);
  strokeWeight(random(0.5, 1.5));
  noFill();
  float angle  = random(TWO_PI);
  float length = random(80, 320);
  int segments = int(random(4, 8));
  beginShape();
  vertex(x, y);
  for (int i = 1; i <= segments; i++) {
    float progress = (float)i / segments;
    float nx = x + cos(angle) * length * progress + random(-25, 25);
    float ny = y + sin(angle) * length * progress + random(-25, 25);
    vertex(nx, ny);
  }
  endShape();
}

// Gojo's six eyes version for ability screens
void drawFourEyesGojo(float x, float y, float alpha) {
  noStroke();
  fill(200, 230, 255, 160 * alpha);
  ellipse(x, y, 28, 20);
  fill(28, 106, 255, 220 * alpha);
  ellipse(x, y, 16, 16);
  fill(0, 0, 20, 240 * alpha);
  ellipse(x, y, 8, 8);
  fill(255, 255, 255, 200 * alpha);
  ellipse(x - 3, y - 3, 4, 4);
}
