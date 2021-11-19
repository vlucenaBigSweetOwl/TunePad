

class Note implements Comparable{
	Track track;
	int time;
	int endTime;
	int length;
	int pitch;

	float x,y,w,h;

	Note(Track track,int time, int pitch, int length){
		this.track = track;
		this.time = time;
		this.pitch = pitch;
		this.length = length;
		endTime = time+length;
	}
	Note(Track track, JSONObject notej){
		this.track = track;
		this.time = notej.getInt("time");
		this.pitch = notej.getInt("pitch");
		this.length = notej.getInt("length");
		endTime = time+length;
	}

	void updateDim(int s, int step){
		/* TODO
		if(this == chosen && noteHold){
			x += mouseX - pmouseX;
			y += mouseY - pmouseY;
			return;
		}
		*/
		x = (time*1.0-s)/step;
		float row = (height*1.0/rollZoom);
		y = (int)(-pitch + rollMid + (rollZoom/2))*row;
		w = length/step;
		h = row;
	}

	void reverseDim(int s, int step, boolean quantize){
		time = (int)(x*step+s);
		float off = (time - startTime )%(tempo/tempoDiv);
		time -= off;
		float row = (height*1.0/rollZoom);
		pitch = (int)(-y/row + rollMid + (rollZoom/2));
	}

	void display(int s, int step, float hue, float trans){
		updateDim(s,step);

		fill(hue,100,255,trans/3);
		stroke(hue,100,255,trans);
		rect(x,y,w,h);
	}

	boolean touchingPoint(float inx, float iny, int s, int step){
		updateDim(s,step);

		return x <= inx && inx <= x+w && y <= iny && iny <= y+h;

	}

	int compareTo(Object o){
		int comp = time - ((Note)o).time;
		if(comp == 0){
			comp = pitch - ((Note)o).pitch;
		}
		return comp;
	}


	JSONObject toJ(){
		JSONObject out = new JSONObject();
		out.setInt("time",time);
		out.setInt("pitch",pitch);
		out.setInt("length",length);
		return out;
	}

}






