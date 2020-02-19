import java.util.*;

//Change the preset mirror arrangement below.
//Click to move the origin of the ray. It shoots towards your cursor.
//A few arrangements are coded in below, but the classes developed here
//can be used in many ways.

PVector origin;
List<Mirror> obstacles; //this is the mirror arrangement
float epsilon = 0.01;
String[] modes = {"random lines", "focus", "two ellipses", "two lines"};
String mode = modes[2]; //play with this variable to see the different presets
int brightness = 300; //number of times a light ray will reflect

void setup(){
  size(640, 360);
  noFill();
  stroke(0);
  
  origin = new PVector(width/2, height/2);
  
  obstacles = new ArrayList<Mirror>();
  obstacles.add(new Mirror(3)); //this is the outer box that catches all runaway light rays
  if(mode == modes[2]){ //some sample mirror arrangements and selectors based on the mode
    obstacles.add(new RoundMirror(width/4, height/2, width/8, width));
    obstacles.add(new RoundMirror(width*3/4, height/2, width/8, width));
  }
  if(mode == modes[1]){
    obstacles.add(new RoundMirror(width/4, height/2, width/8, width/4));
  }
  if(mode == modes[3]){
    obstacles.add(new FlatMirror(width/4, height/4, width/4, height*3/4));
    obstacles.add(new FlatMirror(width*3/4, height/4, width*3/4, height*3/4));
  }
  if(mode == modes[0]){ //randomly generates an arrangement of straight mirrors
    List<FlatMirror> bees = new ArrayList<FlatMirror>();
    for(int i=0; i<50; i++){ //play with the upper limit
      FlatMirror worm = new FlatMirror(width*random(1), height*random(1), width*random(1), height*random(1));
      boolean gotten = false;
      for (FlatMirror earlyBird : bees){
        if(intersect(worm, earlyBird)){
          i--;
          gotten = true;
          break;
        }
      }
      if(!gotten){
        bees.add(worm);
      }
    }
    obstacles.addAll(bees);
  }
}

void draw(){
  background(250);
  
  if(mousePressed){ //click to move the light source
    origin = new PVector(mouseX, mouseY);
  }
  
  PVector mousey = new PVector(mouseX, mouseY); //the light travels towards your cursor
  mousey.sub(origin);
  Rainbow nbow = new Rainbow(new Ray(origin.x, origin.y, angle(mousey)), obstacles, brightness);
  
  nbow.display(); //displays the light rays
  for(Mirror m : obstacles){ //displays the mirrors
    m.display();
  }
  ellipse(origin.x, origin.y, 2, 2); //displays the light source
  if(mode == modes[1]){ //displays the focus of a certain ellipse when on the focus mode
    ellipse(width/4, height/2+width*sqrt(3)/8, 2, 2);
  }
}

boolean intersect(FlatMirror l1, FlatMirror l2){ //tests whether two flat mirrors intersect using some nice linear algebra
  float d = (l1.x1-l1.x0)*(l2.y0-l2.y1) - (l1.y1-l1.y0)*(l2.x0-l2.x1); //the determinant of a certain matrix
  float lambda = ((l1.y0-l1.y1)*(l2.x0-l1.x0)+(l1.x1-l1.x0)*(l2.y0-l1.y0))/d;
  float t = ((l2.y0-l2.y1)*(l2.x0-l1.x0)-(l2.x0-l2.x1)*(l2.y0-l1.y0))/d;
  if(d == 0 | lambda <= epsilon | lambda >= 1-epsilon | t <= epsilon | t >= 1-epsilon){
    return false;
  } else{
    return true;
  }
}

float angle(PVector v){ //gives the angle of a vector, measured clockwise from a vector pointing right, in the positive x direction
  float raw = PVector.angleBetween(new PVector(1,0), v);
  if(v.y > 0){
    return raw;
  } else{
    return TWO_PI - raw;
  }
}

class Ray{ //represents a single straight segment in a ray of light
  float x0;
  float y0;
  float theta;
  float x1;
  float y1;
  
  Ray(float ix0, float iy0, float itheta){
    x0 = ix0;
    y0 = iy0;
    theta = itheta;
  }
  
  void end(float t){ //gives the ray an endpoint making it a segment, used when the ray hits a mirror
    x1 = x0 + cos(theta)*t;
    y1 = y0 + sin(theta)*t;
  }
  
  void end(Mirror m){
    end(m.rayDistance(this));
  }
  
  void end(List<Mirror> obs){
    end(target(obs));
  }
  
  Mirror target(List<Mirror> obs){ //finds the first mirror that the ray hits
    return Collections.max(obs, new MirrorComp(this));
  }
  
  void display(){
    line(x0, y0, x1, y1);
  }
  
}

class Rainbow{ //a collection of rays that bounces of the mirrors, tracing the full path of a ray of light
  List<Ray> nbow = new ArrayList();
  List<Mirror> obs;
  int depth; //the number of times the light bounces before dissapearing
  
  Rainbow(Ray mond, List<Mirror> iobs, int idepth){
    nbow.add(mond);
    obs = iobs;
    depth = idepth;
    for(int i=0; i<depth; i++){
      Ray charles = nbow.get(0);
      Mirror stevie = charles.target(obs);
      Ray ban;
      try{ //when the light hits the outer box, an error is thrown telling the Rainbow to stop
        ban = stevie.reflect(charles);
      } catch(RayNotTrappedException e){
        break;
      }
      nbow.add(0, ban);
    }
    nbow.get(0).end(obs);
  }
  
  void display(){
    for(Ray mond : nbow){
      mond.display();
    }
  }
  
}

class MirrorComp implements Comparator<Mirror>{ //a special comparator used in the Ray.target() function
  Ray charles;
  
  MirrorComp(Ray mond){
    charles = mond;
  }
  
  @Override
  int compare(Mirror m1, Mirror m2){ //finds the closest mirror that is in front of the ray, so it sorts by least positive distance
    float d1 = m1.rayDistance(charles);
    float d2 = m2.rayDistance(charles);
    if(d1 > 0 & (d2 <= 0 | d2 > d1)){
      return 1;
    } else if(d2 > 0 & (d1 <= 0 | d1 > d2)){
      return -1;
    } else{
      return 0;
    }
  }
}

class RayNotTrappedException extends Exception{ //used to stop Rainbow when it leaves the playing field
  RayNotTrappedException(){} 
}

class Mirror{ //parent class for all mirrors, also the box that holds everything
  int extra = 0; //used to make the box bigger than the window when necessary
  
  Mirror(){}
  
  Mirror(int iextra){
    extra = iextra*(height+width);
  }
  
  void display(){}
  
  float rayDistance(Ray mond){ //returns the smallest positive distance from mond to this mirror, gives a negative number if there's no intersection in the positive direction of the ray.
    List<Mirror> boundary = new ArrayList<Mirror>(); //the four walls
    boundary.add(new FlatMirror(-extra, -extra, width+extra, -extra));
    boundary.add(new FlatMirror(width+extra, -extra, width+extra, height+extra));
    boundary.add(new FlatMirror(width+extra, height+extra, -extra, height+extra));
    boundary.add(new FlatMirror(-extra, height+extra, -extra, -extra));
    return mond.target(boundary).rayDistance(mond);
  }
  
  Ray reflect(Ray mond) throws RayNotTrappedException{
    throw new RayNotTrappedException();
  }
  
}

class RoundMirror extends Mirror{ //elliptic mirror
  float cx; //center coordinates
  float cy;
  float rx; //radii
  float ry;
  
  RoundMirror(float icx, float icy, float irx, float iry){
    cx = icx;
    cy = icy;
    rx = irx;
    ry = iry;
  }
  
  @Override
  void display(){
    ellipse(cx, cy, 2*rx, 2*ry);
  }
  
  @Override
  float rayDistance(Ray mond){ //gives the signed distance from the ray to this mirror
    float cos = cos(mond.theta);
    float sin = sin(mond.theta);
    float a = cos*cos/rx/rx + sin*sin/ry/ry; //coefficients of a quadratic
    float b = 2*cos*(mond.x0-cx)/rx/rx + 2*sin*(mond.y0-cy)/ry/ry;
    float c = (mond.x0-cx)*(mond.x0-cx)/rx/rx + (mond.y0-cy)*(mond.y0-cy)/ry/ry - 1;
    float d = b*b-4*a*c; //discriminant of that quadratic
    if(d < 0){
      return -1; //if there is no intersection at all, returns -1 so that the comparator will ignore this.
    } else if(-b-sqrt(d) > 0){
      return (-b-sqrt(d))/2/a;
    } else{
      return (-b+sqrt(d))/2/a;
    }
  }
  
  @Override
  Ray reflect(Ray mond){ //ends mond and returns the reflection
    mond.end(this);
    PVector normal = new PVector((mond.x1-cx)*ry/rx, (mond.y1-cy)*rx/ry);
    float phi = 2*angle(normal) + PI - mond.theta;
    return new Ray(mond.x1+cos(phi)*epsilon, mond.y1+sin(phi)*epsilon, phi);
  }
  
}

class FlatMirror extends Mirror{ //open line segment mirror
  float x0; //endpoint coordinates
  float y0;
  float x1;
  float y1;
  
  FlatMirror(float ix0, float iy0, float ix1, float iy1){
    x0 = ix0;
    y0 = iy0;
    x1 = ix1;
    y1 = iy1;
  }
  
  @Override
  void display(){
    line(x0, y0, x1, y1);
  }
  
  @Override
  float rayDistance(Ray mond){ //uses some nice linear algebra
    float cos = cos(mond.theta);
    float sin = sin(mond.theta);
    float d = cos*(y0-y1) - sin*(x0-x1); //determinant of a certain matrix
    float lambda = (-sin*(x0-mond.x0)+cos*(y0-mond.y0))/d;
    if(d == 0 | lambda <= epsilon | lambda >= 1-epsilon){
      return -1;
    } else{
      return ((y0-y1)*(x0-mond.x0)-(x0-x1)*(y0-mond.y0))/d;
    }
  }
  
  @Override
  Ray reflect(Ray mond){
    mond.end(this);
    PVector tangent = new PVector(x1-x0, y1-y0);
    float phi = 2*angle(tangent) - mond.theta;
    return new Ray(mond.x1+cos(phi)*epsilon, mond.y1+sin(phi)*epsilon, phi);
  }
  
}
