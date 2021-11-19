
boolean leftHeld, rightHeld, shiftHeld, ctrlHeld, altHeld, qHeld, lmHeld, rmHeld;
int rmTimer, lmTimer, qTimer;
int leftTime, rightTime;
int mouseDist;
int hold = 10;
int lastPitch;
boolean metafocused = false;
int pressX,pressY;

void mousePressed(){
	if(!metafocused){
		metafocused = true;
		return;
	}
	if(state != EDIT){
		return;
	}
	if(checkTrackSelector()){
		return;
	}

	if(mouseButton == LEFT){
		lmHeld = true;
	} else if(mouseButton == RIGHT){
		rmHeld = true;
	}
	pressX = mouseX;
	pressY = mouseY;
	if(tool == PEN){
		int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
		int pitch = rollMid - (rollZoom/2) + row;
		lastPitch = pitch;
		Track t = tracks.get(trackInd);
		channels[trackInd].noteOn(pitch+playBackInd,t.volume);
		if(mouseButton == LEFT){
			chosen = checkChosen();
			if(chosen != null){
				chosen.track.removeNote(chosen);
				chosen = null;
				lmHeld = false;
			}
		}
	}

	/*
	//TODO
	chosen = checkChosen();
	if(chosen != null){
		noteHold = true;
	}
	*/
}

void mouseReleased(){
	if(state != EDIT){
		return;
	}
	int s = s();
	int step = step();

	if(tool == TAP){
		if(lmTimer > hold){
			tracks.get(trackInd).addTapX(mouseX,quan[tool]);
		}
	}
	if(tool == TEMPO){
		if(lmHeld){
			tgate1 = (int)((XtoS(mouseX) - startTime + (tempo*.5)) / tempo);
			tgate1s = XtoS(mouseX);
		} else if(rmHeld){
			tgate2 = (int)((XtoS(mouseX) - startTime + (tempo*.5)) / tempo);
			tgate2s = XtoS(mouseX);
		}
		
	}
	if(tool == PEN){
		int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
		int pitch = rollMid - (rollZoom/2) + row;
		if(lmHeld){
			if(lmTimer > hold){
				//TODO
				if(chosen.length < 0){
					chosen.track.notes.remove(chosen);
					chosen = null;
				}
				if(quan[PEN]){
					float off = (chosen.length + (tempo/tempoDiv)/2)%(tempo/tempoDiv)-(tempo/tempoDiv)/2;
					int length = (int)(chosen.length - off);
					
					if(length <= 0){
						chosen.track.removeNote(chosen);
					} else {
						chosen.track.setNoteLength(chosen,(int)(tempo/tempoDiv));
					}
				}
			} else {
				tracks.get(trackInd).addNote(XtoS(mouseX),pitch,-1, quan[PEN]);
				// TODO: midi volume
			}
		}

		Track t = tracks.get(trackInd);
		channels[trackInd].noteOff(lastPitch,t.volume);
		channels[trackInd].noteOff(pitch,t.volume);
	}
	
	//TODO
	if(false){
		chosen.track.notes.remove(chosen);
		chosen.reverseDim(s,step,true);
		chosen.track.notes.add(chosen);
	}

	if(mouseButton == LEFT){
		lmHeld = false;
	} else if(mouseButton == RIGHT){
		rmHeld = false;
	}
	rmTimer = 0;
	lmTimer = 0;
	qTimer = 0;
}

void holdTimerUpdate(){
	resetMatrix();
	if(!focused){
		metafocused = false;
	}
	if(rmHeld){
		rmTimer++;
	}
	if(lmHeld){
		lmTimer++;
	}
	if(qHeld){
		qTimer++;
	}

	

	if(tool == PEN && lmTimer == hold){
		int row = (int)((height - pressY)/(height*1.0/rollZoom)) + 1;
		int pitch = rollMid - (rollZoom/2) + row;
		chosen = tracks.get(trackInd).addNoteX(pressX,pitch,0, quan[PEN]);
	}
	if(lmTimer > hold){
		if(tool == TAP){
			stroke(tracks.get(trackInd).hue,255,255);
			int x = mouseX;
			if(quan[TAP]){
				x = quanX(x);
			}
			line(x,0,x,height);
		} else if (tool == PEN){
			chosen.length = XtoS(mouseX) - chosen.time;
		} else if(tool == TEMPO){
			stroke(150,20,255,150);
			int x = mouseX;
			line(x,0,x,height);
		}
	}

	if(rmTimer > hold){
		if(tool == PEN){
			int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
			int pitch = rollMid - (rollZoom/2) + row;
			if(pitch != lastPitch){
				Track t = tracks.get(trackInd);
				channels[trackInd].noteOff(lastPitch+playBackInd,t.volume);
				channels[trackInd].noteOn(pitch+playBackInd,t.volume);
				lastPitch = pitch;
			}
		} else if(tool == TEMPO){
			stroke(150,20,255,150);
			int x = mouseX;
			line(x,0,x,height);
		}
	}

	if(leftHeld){
		if(song2.isPlaying()){
			song2.pause();
			for(MidiChannel c: channels){
				c.allNotesOff();
			}
		}
		song2.skip((int)(-leftTime*3 *(60/frameRate)));
		leftTime++;
	} else if(rightHeld){
		song2.skip((int)(rightTime*3 *(60/frameRate)));
		rightTime++;
	}

	if(seekTotal != 0){
		song2.skip((int)(seekTotal*step()/2));
	}

	zoomTotal = 0;
	seekTotal = 0;
}

Note checkChosen(){
	for(Note n: tracks.get(trackInd).notes){
		if(n.touchingPoint(mouseX - width/2,mouseY,s(),step())){
			return n;
		}
	}
	return null;
}

void mouseWheel(MouseEvent event) {
	if(shiftHeld){
		if(ctrlHeld){
			rollZoom += event.getCount();
			rollZoom = constrain(rollZoom,5,87);
			rollMid = constrain(rollMid,21+(rollZoom/2),108-(rollZoom/2));
		} else {
			seekTotal += event.getCount();
		}
	} else if(ctrlHeld){
		rollMid += event.getCount();
		rollMid = constrain(rollMid,21+(rollZoom/2),108-(rollZoom/2));
	} else {
		zoomTotal += event.getCount();
	}
}

void keyPressed(){
	if(state != EDIT){
		return;
	}
	key = Character.toLowerCase(key);
	int s = s();
	if(key == '.'){
		println(frameRate + " " + zoom);
	}
	if(key == 'q'){
		qHeld = true;
	}
	if(key == 'n'){
		tempoTaps.clear();
		lastTap = -1;
		startTime = 0;
		tempo = 0;
	}
	if(key == 't' || key == 'y'){
		if(tool == TAP){
			tracks.get(trackInd).addTap(s(),quan[tool]);
		}
		if(tool == TEMPO){
			if(key == 't'){
				tgate1 = (int)((s - startTime + (tempo*.5)) / tempo);
				tgate1s = s;
			} else {
				tgate2 = (int)((s - startTime + (tempo*.5)) / tempo);
				tgate2s = s;
			}
		}
		
	}
	if(key == 'u' && tool == TEMPO){
		if(lastTap != -1){
			int size = tempoTaps.size();
			float dist = s - lastTap;
			if(tempoTaps.size() < 5 || dist < tempo*2){
				tempo = (tempo * size + dist) / (size + 1);
				float start = s % tempo;
				
				if(start > tempo/2){
					start -= tempo;
				}
				startTime = (startTime + start) / 2.0;
			}
			//startTime = (startTime * size + start) / (size + 1);
		}
		tempoTaps.add(s);
		lastTap = s;
	}
	if(key == 'x'){
		if(tool == TEMPO){
			tgate1 = -1;
			tgate1s = -1;
			tgate2 = -1;
			tgate2s = -1;
			tempoTaps.clear();
			lastTap = -1;
			tempoSet = false;
		} if (tool == PEN){
			tracks.get(trackInd).clearNotes();
		} if (tool == TAP){
			tracks.get(trackInd).clearTaps();
		}
	}
	if(key == 's'){
		if(!song2.isPlaying()){
			playBackInd = 0;
		}
		song2.pause();
		for(MidiChannel c: channels){
			c.allNotesOff();
		}
	} else if(key == 'd'){
		if(song2.isPlaying()){
			playBackInd++;
		} else {
			if(song2.position() <= 0){
				song2.cue(0);
				playDelayStart = millis();
				playDelayLast = playDelayStart;
			} else {
				song2.loop();
			}
		}
	} else if(key == 'a'){
		if(song2.isPlaying()){
			playBackInd--;
		} else {
			playBackInd--;
		}
	}
	if(keyCode == LEFT && !leftHeld){
		leftHeld = true;
		leftTime = 0;
	}
	if(keyCode == RIGHT && !rightHeld){
		rightHeld = true;
		rightTime = 0;
	}
	if(keyCode == SHIFT){
		shiftHeld = true;
	}
	if(keyCode == CONTROL){
		ctrlHeld = true;
	}
	if(keyCode == ALT){
		altHeld = true;
	}

	int num = key - '0';
	if(num >= 0 && num <= 9){
		tool = num;
	}

	if(key == 's' && shiftHeld){
		startSaveFile();
	}
}

void keyReleased(){
	if(state != EDIT){
		return;
	}
	key = Character.toLowerCase(key);
	if(lmTimer < hold){
		//SortedSet<Integer> window = (SortedSet<Integer>)tracks.get(trackInd).getWindowX(mouseX - mouseDist, mouseX + mouseDist,TAP);

	}

	if(keyCode == LEFT){
		leftHeld = false;
		leftTime = 0;
	}
	if(keyCode == RIGHT){
		rightHeld = false;
		rightTime = 0;
	}
	if(keyCode == SHIFT){
		shiftHeld = false;
	}
	if(keyCode == CONTROL){
		ctrlHeld = false;
	}
	if(keyCode == ALT){
		altHeld = false;
	}
	if(key == 'q'){
		qHeld = true;
		quan[tool] = !quan[tool];
	}

}
