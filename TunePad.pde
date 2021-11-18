
import ddf.minim.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import themidibus.*;
import java.util.*;
import processing.awt.*;
import processing.javafx.*;
import uibooster.*;
import uibooster.model.*;
import uibooster.components.*;
import javax.sound.midi.*;
import uk.co.xfactorylibrarians.coremidi4j.*;

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
String midiDevice = "Microsoft GS Wavetable Synth";

int playBackInd = 0;
float playBackRate = 1.0;

float offBase = -170;
float off = -170;
float zoom = 1;
float zoomSpeed = 1.10;
int zoomTotal = 0;
int seekTotal = 0;
int rollZoom = 36;
int rollMid = 60;

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

String[] instrumentList;

void setup(){
	Synthesizer syn;
	try{
		syn = MidiSystem.getSynthesizer();
		syn.open();
		javax.sound.midi.Instrument[] inlist = syn.getAvailableInstruments();
		instrumentList = new String[inlist.length];
		for(int i = 0; i < inlist.length; i++){
			instrumentList[i] = inlist[i].getName();
			//println(instrumentList[i]);
		}
	} catch(Exception e){}
	
	menu = new MyMenuBar((PSurfaceAWT)surface,"Test",100,100);
	size(1200, 600);
	//surface.setResizable(true);
	//fullScreen();
	mouseDist = width/20;
	
	minim = new Minim(this);

	textSize(30);
	colorMode(HSB);
	startSongPick();

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

		fill(255);
		text(playBackInd + " cent(s)",50,50);
		String toolString =  "???";
		if(tool==ARROW){toolString="ARROW";}
		if(tool==TEMPO){toolString="TEMPO";}
		if(tool==PEN){toolString="PEN";}
		if(tool==TAP){toolString="TAP";}
		if(tool==SECTION){toolString="SECTION";}
		text("Tool: " + toolString,width - 200,50);
		if(quan[tool]){
			text("Quantize: ON",width - 200,100);
		} else {
			text("Quantize: OFF",width - 200,100);
		}
		

		translate(width/2,0);
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
			fill(255);
			rect(i,height/2 + min*(height/4),2,max*(height/4) - min*(height/4));
			
		}
		

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

	} else if (state == LOAD_SONG){
		//background(0);
		//test();
	} else if (state == LOAD_SAVE){

	} else if (state == SAVE){

	} else if (state == EXIT){

	}

	if(!focused){
		fill(30,30,255,140);
		rect(-1000,-1000,10000,10000);
	}
}

void exit(){
	for(Track t: tracks){
		t.midibus.clearAll();
	}
	minim.stop();
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

int XtoS(int x){
	int time = s() + (x-width/2)*step();
	return time;
}



void checkNote(float s, float lastS){
	for(Track t: tracks){
		if(t.notes.size() <= 0){continue;}
		
		SortedSet<Note> window = (SortedSet<Note>)(SortedSet<?>)t.getWindow(s+getMIDIoff(),lastS+getMIDIoff(),STOPS);

		for(Note n: window){
			t.midibus.sendNoteOff(t.index,n.pitch+playBackInd,t.volume);
		}

		window = (SortedSet<Note>)(SortedSet<?>)t.getWindow(s+getMIDIoff(), lastS+getMIDIoff(),START);

		for(Note n: window){
			t.midibus.sendNoteOn(t.index,n.pitch+playBackInd,t.volume);
		}
	}
}

int getMIDIoff(){
	return (int)(sample.sampleRate()*0.27*playBackRate);
}