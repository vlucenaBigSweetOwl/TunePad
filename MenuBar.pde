import java.awt.*;
import javax.swing.*;
import javax.swing.UIManager;
import javax.swing.SwingUtilities;
import uibooster.*;
import uibooster.model.*;
import uk.co.xfactorylibrarians.coremidi4j.CoreMidiDeviceProvider;
import uk.co.xfactorylibrarians.coremidi4j.CoreMidiNotification;
import uk.co.xfactorylibrarians.coremidi4j.CoreMidiException;
import javax.sound.midi.MidiDevice;

class MyMenuBar {
	JFrame frame;
	
	MyMenuBar(PSurfaceAWT surface, String name, int width, int height) {
		System.setProperty("apple.laf.useScreenMenuBar", "true");
		try{
			//UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		}catch(Exception e){println("nope");}


		frame = (JFrame)((processing.awt.PSurfaceAWT.SmoothCanvas)surface.getNative()).getFrame();
		frame.setTitle(name);

		//SwingUtilities.updateComponentTreeUI(frame);
		//frame.pack();

		// Creates a menubar for a JFrame
		JMenuBar menuBar = new JMenuBar();
		// Add the menubar to the frame
		frame.setJMenuBar(menuBar);
		
		// Define and add two drop down menu to the menubar
		JMenu filem = new JMenu("File");
		JMenu trackm = new JMenu("Tracks");
		JMenu controlm = new JMenu("Control");
		JMenu helpm = new JMenu("Help");

		menuBar.add(filem);
		menuBar.add(trackm);
		menuBar.add(controlm);
		menuBar.add(helpm);
		
		// Create and add simple menu item to one of the drop down menu
		JMenuItem itemSongLoad = new JMenuItem("Open New Song");
		JMenuItem itemRecent = new JMenuItem("Open Recent");
		JMenuItem itemLoad = new JMenuItem("Load Pad");
		JMenuItem itemSave = new JMenuItem("Save Pad");
		JMenuItem itemSaveAs = new JMenuItem("Save As");
		JMenuItem itemExit = new JMenuItem("Exit");

		filem.add(itemSongLoad);
		filem.add(itemRecent);
		filem.addSeparator();
		filem.add(itemLoad);
		filem.add(itemSave);
		filem.add(itemSaveAs);
		filem.addSeparator();
		filem.add(itemExit);
		
		// Add a listener to the New menu item. actionPerformed() method will
		// invoked, if user triggred this menu item
		
		itemSongLoad.addActionListener(
			(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					startSongPick();
				}
			})
		);

		itemLoad.addActionListener(
			(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					startLoadFile();
				}
			})
		);


		itemSave.addActionListener(
			(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					saveFile();
				}
			})
		);

		itemSaveAs.addActionListener(
			(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					startSaveFile();
				}
			})
		);
		
		itemExit.addActionListener(
			(new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					exit();
				}
			})
		);
		
		JMenuItem itemSelectTrack = new JMenuItem("Select Track");
		JMenuItem itemNewTrack = new JMenuItem("New Track");
		JMenuItem itemDeleteTrack = new JMenuItem("Delete Track");
		JMenuItem itemTrackName = new JMenuItem("Set Track Name");
		JMenuItem itemTrackInstr = new JMenuItem("Set Track Instrument");
		JMenuItem itemTrackColor = new JMenuItem("Set Track Color");
		//MenuItem itemRecent = new MenuItem("Open Recent");

		trackm.add(itemSelectTrack);
		trackm.add(itemNewTrack);
		trackm.add(itemDeleteTrack);
		trackm.addSeparator();
		trackm.add(itemTrackName);
		trackm.add(itemTrackInstr);
		trackm.add(itemTrackColor);

		itemSelectTrack.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					ArrayList<String> list = new ArrayList<String>();
					for(Track t: tracks){
						list.add(t.name);
					}
					String selection = uib.showSelectionDialog(
						"Select a Track",
						"Tracks",
						list);
					for(int i = 0; i < tracks.size(); i++){
						if(tracks.get(i).name.equals(selection)){
							trackInd = i;
							break;
						}
					}
				}}));

		itemNewTrack.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					newTrack();
				}}));

		itemDeleteTrack.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					deleteTrack();
				}}));

		itemTrackName.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					String name = uib.showTextInputDialog("Track Name:");
					if(name != null){
						tracks.get(trackInd).name = name;
					}
				}}));

		itemTrackInstr.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					String selection = uib.showSelectionDialog(
						"Pick and Instrument ...",
						"Track Instrument",
						instrumentList);

					int i = Arrays.asList(instrumentList).indexOf(selection);
					if(i != -1){
						tracks.get(trackInd).setInstrument(i);
					}
				}}));

		itemTrackColor.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					Color col = uib.showColorPicker("Pick a color for " +tracks.get(trackInd).name, "Pick Track Color");
					colorMode(RGB);
					float hue = hue(color(col.getRed(),col.getGreen(),col.getBlue()));
					colorMode(HSB);
					tracks.get(trackInd).hue = hue;
				}}));

		JMenuItem itemVolume = new JMenuItem("Volume");
		JMenuItem itemTempoDiv = new JMenuItem("Beat Division");
		//MenuItem itemRecent = new MenuItem("Open Recent");

		controlm.add(itemVolume);
		controlm.add(itemTempoDiv);

		itemTempoDiv.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					Integer divs = uib.showSlider("Split each tempo into how many parts?", "Beat Division",
						1, 16, tempoDiv, 2, 1);

					tempoDiv = divs;

				}}));

		itemVolume.addActionListener((new java.awt.event.ActionListener() {
				public void actionPerformed(java.awt.event.ActionEvent a) {
					
					FormBuilder fb = uib.createForm("Test");
			        fb.addSlider("Volume", -30, 5, volume, 5, 1).setID("Vol");
			        for(Track t: tracks){
			        	fb.addSlider(t.name, 0, 127, t.volume, 10, 5).setID(t.index + t.name);
			        }

			        fb.setChangeListener((element,value,form) -> {
			        	if(element.getId().equals("Vol")){
			        		volume = element.asInt();
			        		out.setGain(volume);
			        	}
			        	for(Track t: tracks){
			        		if(element.getId().equals(t.index+t.name)){
			        			t.volume = element.asInt();
			        		}
			        	}
			        });
			        fb.show();
					

				}}));

		JMenuItem itemMidiDevice = new JMenuItem("MidiDevice");
		JMenuItem itemControls = new JMenuItem("Controls");
		//MenuItem itemRecent = new MenuItem("Open Recent");

		helpm.add(itemMidiDevice);
		helpm.add(itemControls);
		itemMidiDevice.addActionListener((new java.awt.event.ActionListener() {
			public void actionPerformed(java.awt.event.ActionEvent a) {
				ArrayList<String> options = new ArrayList<String>();
				for (javax.sound.midi.MidiDevice.Info device : CoreMidiDeviceProvider.getMidiDeviceInfo()) {
		            options.add(device.toString());
		        }
		        try{println(CoreMidiDeviceProvider.isLibraryLoaded());}catch(Exception e){}
		        String selection = uib.showSelectionDialog(
						"Select a MIDI Output Device\nWindows: Microsoft GS Wavetable Synth\nMac: CoreMidi4j",
						"MIDI Device",
						options);
		        midiDevice = selection;
		        for(Track t: tracks){
		        	t.setMidiDevice(selection);
		        }
			}}));

		itemControls.addActionListener((new java.awt.event.ActionListener() {
			public void actionPerformed(java.awt.event.ActionEvent a) {
				new UiBooster().showInfoDialog("General Controls:\n   d: play/ speed up\n   s: stop/ reset speed\n   a: speed down\n   left: seek back\n   right: seek forward\n   scroll: zoom\n   shift+scroll: seek\n   ctrl+scroll: up/down piano roll\n   ctrl+shift+scroll: piano roll zoom\n" + 
					"   \n   1: arrow tool   2: tempo tool   3: pen tool   4: tap tool\n" +
					"\nArrow Tool:\n   left click: add note\n   right click: play/test note\n   left click and drag: control length\n" +
					"\nPen Tool:\n   left click: add note\n   right click: play/test note\n   left click and drag: control length\n" +
					"\nTap Tool:\n   t/y: add tap at play head\n   left click: add tap at mouse\n   Best use is tapping t to moments you hear in the music as is plays\n" +
					"\nTempo Tool:\n   t/y: add tap at play head\n   left click: add first goalpost\n   right click: add second goalpost\n   You'll want to tap like a metronome with t, and once it looks kinda close, the goalposts will extrapolate the tempo from just those two points\n" +
					"\nOther:\n   q: toggle quantize (snapping to the beats)\n   x: clears current track's notes or taps (based on tool)"
					);
			}}));

		frame.setVisible(true);
		
	}
}
		
