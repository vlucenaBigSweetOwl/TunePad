
boolean leftHeld, rightHeld, shiftHeld, ctrlHeld, altHeld, qHeld, lmHeld, rmHeld;
int rmTimer, lmTimer, qTimer;
int leftTime, rightTime;
int mouseDist;
int hold = 12;
int lastPitch;
boolean metafocused = false;

void mousePressed(){
	if(!metafocused){
		metafocused = true;
		return;
	}
	if(state != EDIT){
		return;
	}
	if(mouseButton == LEFT){
		lmHeld = true;
	} else if(mouseButton == RIGHT){
		rmHeld = true;
	}

	if(tool == PEN){
		int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
		int pitch = rollMid - (rollZoom/2) + row;
		lastPitch = pitch;
		Track t = tracks.get(trackInd);
		t.midibus.sendNoteOn(trackInd,pitch+playBackInd,t.volume);
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
		if(mouseButton == LEFT){
			tgate1 = (int)((XtoS(mouseX) - startTime + (tempo*.5)) / tempo);
			tgate1s = XtoS(mouseX);
		} else if(mouseButton == RIGHT){
			tgate2 = (int)((XtoS(mouseX) - startTime + (tempo*.5)) / tempo);
			tgate2s = XtoS(mouseX);
		}
		
	}
	if(tool == PEN && lmHeld){
		int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
		int pitch = rollMid - (rollZoom/2) + row;
		if(mouseButton == LEFT){
			if(lmTimer > hold){
				//TODO
				if(chosen.length < 0){
					chosen.track.notes.remove(chosen);
					chosen = null;
				}
				if(quan[PEN]){
					float off = (chosen.length + (tempo/tempoDiv)/2)%(tempo/tempoDiv)-(tempo/tempoDiv)/2;
					chosen.length -= off;
					if(chosen.length == 0){
						chosen.length = (int)(tempo/tempoDiv);
					}
				}
				
				
				// note off later?
			} else {
				tracks.get(trackInd).addNote(XtoS(mouseX),pitch,-1, quan[PEN]);
				// TODO: midi volume
			}
		}

		Track t = tracks.get(trackInd);
		t.midibus.sendNoteOn(trackInd,pitch+playBackInd,t.volume);
		t.midibus.sendNoteOff(trackInd,lastPitch,t.volume);
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

	int row = (int)((height - mouseY)/(height*1.0/rollZoom)) + 1;
	int pitch = rollMid - (rollZoom/2) + row;

	if(tool == PEN && lmTimer == hold){
		chosen = tracks.get(trackInd).addNoteX(mouseX,pitch,0, quan[PEN]);
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
			if(pitch != lastPitch){
				Track t = tracks.get(trackInd);
				t.midibus.sendNoteOff(trackInd,lastPitch+playBackInd,t.volume);
				t.midibus.sendNoteOn(trackInd,pitch+playBackInd,t.volume);
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
			for(Track t: tracks){
				t.midibus.sendMessage(176+t.index, 123);
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
	for(Track t: tracks){
		for(Note n: t.notes){
			if(n.touchingPoint(mouseX - width/2,mouseY,s(),step())){
				return n;
			}
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
		println(frameRate);
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
		for(Track t: tracks){
			t.midibus.sendMessage(176+t.index, 123);
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
