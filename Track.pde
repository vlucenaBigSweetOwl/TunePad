
Note checks = new Note(null,0,0,0);
Note checklast = new Note(null,0,0,0);

int START = 1;
int STOPS = 2;

class Track{
	int index;
	String name;
	TreeSet<Note> notes;
	TreeSet<Note> stops;
	float hue;
	TreeSet<Integer> taps;
	int instrument;
	int volume = 60;


	Track(int i){
		index = i;
		name = "Track "+i;
		notes = new TreeSet<Note>();
		stops = new TreeSet<Note>(new Comparator<Note>(){
			int compare(Note a, Note b){
				int comp = a.endTime - b.endTime;
				if(comp == 0){
					comp = a.pitch - b.pitch;
				}
				return comp;
			}
		});
		taps = new TreeSet<Integer>();
		hue = random(0,255);
		channels[index].programChange(192+index,0);
	}
	Track(String name, int i){
		index = i;
		this.name = name;
		notes = new TreeSet<Note>();
		stops = new TreeSet<Note>(new Comparator<Note>(){
			int compare(Note a, Note b){
				int comp = a.endTime - b.endTime;
				if(comp == 0){
					comp = a.pitch - b.pitch;
				}
				return comp;
			}
		});
		taps = new TreeSet<Integer>();
		hue = random(0,255);
		channels[index].programChange(192+index,0);
	}
	Track(JSONObject trackj, int ind){

		index = ind;
		notes = new TreeSet<Note>();
		stops = new TreeSet<Note>(new Comparator<Note>(){
			int compare(Note a, Note b){
				int comp = a.endTime - b.endTime;
				if(comp == 0){
					comp = a.pitch - b.pitch;
				}
				return comp;
			}
		});
		taps = new TreeSet<Integer>();

		name = trackj.getString("name");
		hue = trackj.getFloat("hue");
		instrument = trackj.getInt("instrument");

		JSONArray notesj = trackj.getJSONArray("notes");
		for(int i = 0; i < notesj.size(); i++){
			Note j = new Note(this,notesj.getJSONObject(i));
			notes.add(j);
			stops.add(j);
		}
		JSONArray tapsj = trackj.getJSONArray("taps");
		for(int i = 0; i < tapsj.size(); i++){
			taps.add(tapsj.getInt(i));
		}
		channels[index].programChange(192+index,instrument); // TODO
	}

	void setInstrument(int i){
		channels[index].programChange(192+index,i);
	}

	void setNoteLength(Note n, int length){
		notes.remove(n);
		stops.remove(n);
		n.length = length;
		notes.add(n);
		notes.add(n);
	}

	void clearNotes(){
		notes.clear();
		stops.clear();
	}

	void clearTaps(){
		taps.clear();
	}

	Note addNoteX(int x, int pitch, int length, boolean quantize){
		return addNote(s() + (x-width/2)*step(),pitch,length, quantize);
	}

	Note addNote(int time, int pitch, int length, boolean quantize){
		if(quantize){
			float off = (time - startTime )%(tempo/tempoDiv);
			time -= off;
		}
		if(length == -1){
			length = (int)(tempo/tempoDiv);
		}
		Note n = new Note(this,time,pitch,length);
		if(!notes.add(n)){
			notes.remove(n);
			stops.remove(n);
		} else {
			stops.add(n);
		}
		return n;
	}

	void removeNote(Note n){
		notes.remove(n);
		stops.remove(n);
	}

	void addTapX(int x, boolean quantize){
		addTap(s() + (x-width/2)*step(), quantize);
	}

	void addTap(int time, boolean quantize){
		if(quantize){
			float off = (time - startTime + (tempo/tempoDiv)/2)%(tempo/tempoDiv) - (tempo/tempoDiv)/2;
			time -= off;
		}
		taps.add(time);
	}

	void display(int s, int step){
		if(notes.size() != stops.size()){
			println(notes.size() + " " +stops.size());
		}
		float trans = 100;
		if(index == trackInd){
			trans = 230;
		}
		for(int tap: taps){
			float x = (tap*1.0-s)/step;
			stroke(hue,255,255,trans);
			line(x,0,x,height);
		}
		for(Note n: notes){
			n.display(s,step,hue,trans);
		}
	}

	SortedSet<?> getWindowX(int x, int x2, int from){
		float s = s() + step()*(x-width/2);
		float lastS = s() + step()*(x2-width/2);
		return getWindow(s,lastS,from);
	}

	SortedSet<?> getWindow(float s, float lastS, int from){
		SortedSet<?> out;

		TreeSet<?> general;
		if(from == START){
			checks.time = (int)(s);
			checklast.time = (int)(lastS);
			general = notes;
		} else if(from == STOPS){
			checks.endTime = (int)(s);
			checklast.endTime = (int)(lastS);
			general = stops;
		} else if(from == TAP){
			general = taps;
		} else {
			//TODO error
			return null;
		}

		if(from == START || from == STOPS){
			if(s < lastS){
				out = (SortedSet<Note>) new TreeSet<Note>();
			} else {
				out = ((TreeSet<Note>)general).subSet(checklast,true,checks,true);
			}
		} else if (from == TAP){
			if(s - lastS < 0){
				out = (SortedSet<Integer>) new TreeSet<Integer>();
			} else {
				out = ((TreeSet<Integer>)general).subSet((int)lastS,true,(int)s,true);
			}
		} else {
			out = (SortedSet<Integer>) new TreeSet<Integer>();
		}
			
		return out;
		
		
	}

	JSONObject toJ(){
		JSONObject out = new JSONObject();

		out.setString("name",name);
		out.setFloat("hue",hue);
		out.setInt("instrument",instrument);

		JSONArray notesj = new JSONArray();
		int i = 0;
		for(Note n: notes){
			notesj.setJSONObject(i,n.toJ());
			i++;
		}
		out.setJSONArray("notes",notesj);

		JSONArray tapsj = new JSONArray();
		i = 0;
		for(Integer t: taps){
			tapsj.setInt(i,t);
			i++;
		}
		out.setJSONArray("taps",tapsj);


		return out;
	}

}