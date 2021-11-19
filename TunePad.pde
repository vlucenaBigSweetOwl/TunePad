
import ddf.minim.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
//import themidibus.*;
import java.util.*;
import processing.awt.*;
import processing.javafx.*;
import uibooster.*;
import uibooster.model.*;
import uibooster.components.*;
import javax.sound.midi.*;
//import uk.co.xfactorylibrarians.coremidi4j.*;

// machine learning leading questions?


int LOAD_SONG = 1;
int EDIT = 2;
int LOAD_SAVE = 8;
int SAVE = 9;
int EXIT = 10;
int state = LOAD_SONG;

final int ARROW = 1;
// left on note: move left on edge of note: change length left on nothing: box select?
// right 
final int TEMPO = 2;
final int PEN = 3;
final int TAP = 4;
final int SECTION = 7;
int tool = PEN;

boolean[] quan = new boolean[10];

Minim minim;
FilePlayer song2;
AudioSample sample;
AudioInput input;
AudioOutput out;
TickRate rate;
float[] sig;
int volume = -15;

MyMenuBar menu;
UiBooster uib = new UiBooster(
    UiBoosterOptions.Theme.DARK_THEME
);;
Synthesizer midiSynth;

int playBackInd = 0;
float playBackRate = 1.0;

float offBase = -170;
float off = -170;
float zoom = 69;
float zoomSpeed = 1.10;
int zoomTotal = 0;
int seekTotal = 0;
int rollZoom = 36;
int rollMid = 60;
float waveTrans = 255;

TreeSet<Integer> tempoTaps = new TreeSet<Integer>();
float lastTap = -1;
float startTime;
float tempo;
int tgate1 = -1;
float tgate1s = -1;
int tgate2 = -1;
float tgate2s = -1;
int tempoDiv = 2;
boolean tempoSet = false;


ArrayList<Track> tracks = new ArrayList<Track>();
int trackInd = 0;


String fileName;
String saveName;

int lastS = 0;

Note chosen;

int playDelayStart = -1;
int playDelayLast = -1;

javax.sound.midi.Instrument[] inlist;
String[] inlistNames;
MidiChannel[] channels;

void setup(){
	println("hi");
	try{
		midiSynth = MidiSystem.getSynthesizer();
		midiSynth.open();
		channels = midiSynth.getChannels();
		inlist = midiSynth.getAvailableInstruments();
		inlistNames = new String[inlist.length];
		for(int i = 0; i < inlist.length; i++){
			midiSynth.loadInstrument(inlist[i]);
			inlistNames[i] = inlist[i].getName();
			//println(inlistNames[i]);
		}
	} catch(Exception e){}
	

	menu = new MyMenuBar((PSurfaceAWT)surface,"Test",100,100);
	size(1200, 600);
	//surface.setResizable(true);
	//fullScreen();
	mouseDist = width/20;
	
	minim = new Minim(this);

	
	colorMode(HSB);
	startSongPick();

	println("lo");
}

int s(){
	return (int)((song2.position()+off)/1000.0*sample.sampleRate());
}

int step(){
	return (int)(sig.length*1.0/width / zoom);
}

void draw(){
	background(0);
	if(state == EDIT){

		zoom = zoom * pow(zoomSpeed,zoomTotal);
		off = offBase * playBackRate;
		playBackRate = pow(2,(1/12.0) * playBackInd);
		rate.value.setLastValue(playBackRate);
		int s = s();
		int step = (int)(sig.length*1.0/width / zoom);

		textSize(30);
		textAlign(LEFT,CENTER);
		fill(255);
		text(playBackInd + " cent(s)",50,30);
		String toolString =  "???";
		if(tool==ARROW){toolString="ARROW";}
		if(tool==TEMPO){toolString="TEMPO";}
		if(tool==PEN){toolString="PEN";}
		if(tool==TAP){toolString="TAP";}
		if(tool==SECTION){toolString="SECTION";}
		text("Tool: " + toolString,width - 200,30);
		if(quan[tool]){
			text("Quantize: ON",width - 200,60);
		} else {
			text("Quantize: OFF",width - 200,60);
		}
		

		translate(width/2,0);

		drawWaveForm(s,step);

		stroke(0,0,255);
		line(0,0,0,height);
		
		for(float t: tempoTaps){
			float x = (t-s)/step;
			stroke(255,0,255,20);
			line(x,0,x,height);
		}
		for(int i = 0; i < rollZoom+1; i++){
			float y = i*(height*1.0/rollZoom);
			stroke(255,0,255,100);
			line(-width,y,width,y);
		}
		for(Track t: tracks){
			t.display(s,step);
		}
		if(chosen!=null){
			chosen.display(s,step,tracks.get(trackInd).hue,255);
		}

		
		if(tgate1 != -1 && tgate2 != -1){
			tempoSet = true;
			int beatDif = tgate2 - tgate1;
			float sDif = tgate2s - tgate1s;
			tempo = sDif / beatDif;
			startTime = tgate1s;
			startTime %= tempo;
		}
		if(tempoTaps.size() > 5){
			tempoSet = true;
		}

		if(tempoSet){
			float t = startTime;
			int count = 0;
			float x = (t-s)/step;
			while(x < -width/2){
				t+= tempo/tempoDiv;
				count++;
				x = (t-s)/step;
			}
			while(x < width/2){
				stroke(255,0,255,40);
				if(count%tempoDiv == 0){
					stroke(255,0,255,100);
				}
				line(x,0,x,height);
				t+= tempo/tempoDiv;
				count++;
				x = (t-s)/step;
			}
		}
		if(song2.isPlaying()){
			checkNote(s,lastS);
		} else if(playDelayStart != -1){
			int millis = millis();
			int flastS = (int)((playDelayLast*1.0 - playDelayStart + off)*sample.sampleRate()/1000 - getMIDIoff());
			int fs = (int)((millis*1.0 - playDelayStart + off)*sample.sampleRate()/1000 - getMIDIoff());
			
			checkNote(fs,flastS);
			playDelayLast = millis;
			if(fs > off*sample.sampleRate()/1000){
				song2.loop();
				playDelayStart = -1;
				playDelayLast = -1;
			}
		}


		


		if(s < lastS){
			lastTap = -1;
		}
		lastS = s;
		
		holdTimerUpdate();
		drawTrackPicker();

	} else if (state == LOAD_SONG){
		//background(0);
		//test();
	} else if (state == LOAD_SAVE){

	} else if (state == SAVE){

	} else if (state == EXIT){

	}

	if(!focused){
		fill(30,50,0,150);
		rect(-1000,-1000,10000,10000);
	}
}

void drawWaveForm(int s, int step){
	strokeWeight(1);
	for(int i = -width/2; i < width/2; i+=2){
		int place = constrain(s + step*i,0,sig.length-1);

		float max = 0;
		float min = 0;
		
		int samps = (step*2)/10 ;
		if(samps <= 0){
			samps = 1;
		}

		place += (samps - place%samps)%samps;
		for(int j = 0; j < step*2; j+=samps){
			if(place + j >= sig.length || sig.length < 0){
				break;
			}
			max = max(max,sig[place + j]);
			min = min(min,sig[place + j]);
		}

		noStroke();
		fill(255,waveTrans);
		rect(i,height/2 + min*(height/4),2,max*(height/4) - min*(height/4));
		
	}
}

void exit(){
	midiSynth.close();
	try{
		minim.stop();
	}catch(Exception e){}
	
	if(state != EDIT){
		exitActual();
	}
	state = EXIT; 
	uib.showConfirmDialog(
        "Would you like to save?",
        "Exiting",
        () -> saveFile(),
        () -> exitActual());
	
}


int quanX(int x){
	int step = step();
	int time = s() + (x-width/2)*step;
	int off = (int)((time - startTime + (tempo/tempoDiv)/2 )%(tempo/tempoDiv) - (tempo/tempoDiv)/2);
	x -= off/step;
	return x;
}

int XtoS(int x, boolean quan){
	int time = s() + (x-width/2)*step();
	int off = 0;
	if(quan){
		off = (int)((time - startTime + (tempo/tempoDiv)/2 )%(tempo/tempoDiv) - (tempo/tempoDiv)/2);
	}
	return time - off;
}



void checkNote(float s, float lastS){
	for(Track t: tracks){
		if(t.notes.size() <= 0){continue;}
		
		SortedSet<Note> window = (SortedSet<Note>)(SortedSet<?>)t.getWindow(s+getMIDIoff(),lastS+getMIDIoff(),STOPS);

		for(Note n: window){
			channels[t.index].noteOff(n.pitch+playBackInd,t.volume);
		}

		window = (SortedSet<Note>)(SortedSet<?>)t.getWindow(s+getMIDIoff(), lastS+getMIDIoff(),START);

		for(Note n: window){
			channels[t.index].noteOn(n.pitch+playBackInd,t.volume);
		}
	}
}

int getMIDIoff(){
	return (int)(sample.sampleRate()*0.27*playBackRate);
}


int y = 70;
int w = 200;
int h = 40;
void drawTrackPicker(){
	resetMatrix();
	int i = 0;
	for(Track t: tracks){
		strokeWeight(3);
		if(t.index == trackInd){
			stroke(255);
			fill(t.hue,155,255,200);
			rect(0,y + i*h,w+20,h);
			fill(255);
		} else {
			stroke(255,150);
			fill(t.hue,155,255,100);
			rect(0,y + i*h,w,h);
			fill(255,150);
		}
		textAlign(LEFT,CENTER);
		text(t.name,30,y + (i+.5)*h);
		i++;
	}
	textAlign(CENTER,CENTER);
	fill(255,0,255,200);
	text("+",w/2,y+(i+.5)*h);
}

boolean checkTrackSelector(){
	if(mouseX < w){
		int ind = (mouseY - y)/h;
		if(ind < tracks.size()){
			trackInd = ind;
			return true;
		} else if (ind == tracks.size()){
			newTrack();
			return true;
		}
		
	}
	return false;
}


void newTrack(){
	String name = uib.showTextInputDialog("Track Name:");
	if(name == null || name.equals("")){
		tracks.add(new Track(tracks.size()));
	} else {
		tracks.add(new Track(name,tracks.size()));
	}
	trackInd = tracks.size()-1;
}

void deleteTrack(){
	tracks.remove(trackInd);
	if(trackInd == tracks.size()){
		trackInd--;
	}
}