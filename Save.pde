

void startSongPick(){
	state = LOAD_SONG;
	println(dataFile("..\\songs\\pick a song..."));
	selectInput("Select a song file:","songPick",dataFile("songs\\pick a song ..."));
	fill(255,40);
	rect(-1000,-1000,10000,10000);
}

void songPick(File f){
	WaitingDialog dialog = uib.showWaitingDialog("Starting", "Please wait",true);
	if(f == null){
		//selectInput("Select a song file:","songPick");
    	dialog.close();
		return;
	} else {
		try{
			fileName = f.getCanonicalPath();
		} catch(Exception e){
			//
		}
	}
	
	try{
		song2 = new FilePlayer(minim.loadFileStream(fileName));
	} catch (Exception e){
		uib.showErrorDialog("Failed to load\n" + fileName + "\n", "ERROR");
    	dialog.close();
	}

	sample = minim.loadSample(fileName,1024);
	input = minim.getLineIn();
	out = minim.getLineOut(minim.STEREO, 1024, sample.sampleRate());

	rate = new TickRate(1.0);
	sig = sample.getChannel(AudioSample.LEFT);
	float[] tempSig = sample.getChannel(AudioSample.RIGHT);
	// add left and right channels to temp
	for(int i = 0; i < sig.length; i++){
		tempSig[i] = max(sig[i],tempSig[i]);
	}
    dialog.setMessage("Ready");
    dialog.close();
	// blur temp into sig
	int range = 0; // how many steps to the left and right of current pos you go
	float tot = 0;
	/*
	for(int j = 0; j <= range*2; j++){
		tot += pow(tempSig[j], .5) * (1.0/(range*2+1));
	}
	*/
	for(int i = range; i < sig.length - range-1; i++){
		/*
		if(tempSig[i] < 0){
			sig[i] = -pow(-tempSig[i],.5);
		} else {
			sig[i] = pow(tempSig[i],.5);
		}
		*/
		sig[i] = tempSig[i];
		
		//tot += pow(tempSig[i+range+1],.5) * (1.0/(range*2+1));
		//tot -= pow(tempSig[i-range],.5) * (1.0/(range*2+1));
	}
	tracks.add(new Track("Master",0));

	song2.patch(rate).patch(out);
	rate.setInterpolation(true);

	println(out.hasControl(Controller.VOLUME));
	println(out.hasControl(Controller.GAIN));
	out.setGain(volume);

	
	int ind = fileName.lastIndexOf('\\');
	if(ind == -1){
		ind = fileName.lastIndexOf('/');
		if(ind != -1){
			saveName = dataPath("")+"/saves/"
			+ fileName.substring(fileName.lastIndexOf('/'),fileName.lastIndexOf('.'))
			+ "SAVE.json";
		} else {
			saveName = "";
		}
	} else {
		saveName = dataPath("")+"\\saves\\"
		+ fileName.substring(fileName.lastIndexOf('\\'),fileName.lastIndexOf('.'))
		+ "SAVE.json";
	}

	File temp = new File(saveName);
	if(temp.exists()){
		uib.showConfirmDialog(
	        "We detected save data! Load it?",
	        "Load Save",
	        () -> loadFile(temp),
	        () -> state = EDIT);
	}
	state = EDIT;
}

void startSaveFile(){
	if(state != EXIT){
		state = SAVE;
	}
	selectOutput("Choose save file:","saveFile");
	fill(255,40);
	rect(-1000,-1000,10000,10000);
}

void startLoadFile(){
	state = LOAD_SAVE;
	selectInput("Choose file to load:","loadFile");
	fill(255,40);
	rect(-1000,-1000,10000,10000);
}

void loadFile(File f){
	state = EDIT;
	if(f == null){
		return;
	}
	JSONObject json;
	String uh = "";
	try{
		uh = f.getCanonicalPath();
		json = loadJSONObject(uh);
	}catch(Exception e){return;}

	fileName = json.getString("filePath");
	// TODO load song if no song loaded
	saveName = uh;

	tool = json.getInt("tool");
	trackInd = json.getInt("trackInd");

	JSONArray quanj = json.getJSONArray("quan");
	for(int i = 0; i < quanj.size(); i++){
		quan[i] = quanj.getBoolean(i);
	}

	JSONObject tempoj = json.getJSONObject("tempo");
	tempo = tempoj.getFloat("tempo");
	startTime = tempoj.getFloat("startTime");
	tgate1 = tempoj.getInt("tgate1");
	tgate1s = tempoj.getFloat("tgate1s");
	tgate2 = tempoj.getInt("tgate2");
	tgate2s = tempoj.getFloat("tgate2s");
	tempoSet = tempoj.getBoolean("tempoSet");
	tempoDiv = tempoj.getInt("tempoDiv");

	JSONArray tracksj = json.getJSONArray("tracks");

	tracks.clear();
	for(int i = 0; i < tracksj.size(); i++){
		tracks.add(new Track(tracksj.getJSONObject(i),i));
	}
}

void saveFile(){
	saveFile(new File(saveName));
}

void saveFile(File f){
	if(f == null){
		if(state == EXIT){
			exitActual();
		}
		state = EDIT;
		return;
	}
	JSONObject json = new JSONObject();
	json.setString("filePath",fileName);
	json.setInt("tool",tool);
	json.setInt("trackInd",trackInd);

	JSONArray quanj = new JSONArray();
	for(int i = 0; i < quan.length; i++){
		quanj.setBoolean(i,quan[i]);
	}
	json.setJSONArray("quan",quanj);

	JSONObject tempoj = new JSONObject();
	tempoj.setFloat("tempo",tempo);
	tempoj.setFloat("startTime",startTime);
	tempoj.setInt("tgate1",tgate1);
	tempoj.setFloat("tgate1s",tgate1s);
	tempoj.setInt("tgate2",tgate2);
	tempoj.setFloat("tgate2s",tgate2s);
	tempoj.setBoolean("tempoSet",tempoSet);
	tempoj.setInt("tempoDiv",tempoDiv);
	json.setJSONObject("tempo",tempoj);

	JSONArray tracksj = new JSONArray();
	for(int i = 0; i < tracks.size(); i++){
		tracksj.setJSONObject(i,tracks.get(i).toJ());
	}
	json.setJSONArray("tracks",tracksj);

	try{
		saveJSONObject(json, f.getCanonicalPath());
		saveName = f.getCanonicalPath();
	}catch(Exception e){}

	if(state == EXIT){
		exitActual();
	}
	state = EDIT;
}