/*	Originally written, and successfully refactored, by CMDR Abexuro, Discord: Abex#5089
*	Edited/updated/adapted by CMDRs Mechan and Orodruin
*	"Professionalized" by CMDR AlterNERDtive
*
*	### INSTALLATION ###
*	-	If you haven't already, download LiveSplit from https://livesplit.org/downloads/
*	-	Enable netLogs in-game in the main_menu/networking screen
*	-	In this file, set journalPath in the "init" section to point to your journal*.log location.
*	-	In this file, set netLogPath in the "init" section to point to your netLog*.log location [note this varies between Horizons and Odyssey!].
*	-	In LiveSplit do the following:
*	-		Right click, Open Splits, select the appropriate *.lss file (Cyclops/Basilisk/Medusa/Hydra)
*	-		Right click, Open Layout, select the appropriate *.lsl file (Cyclops/Basilisk/Medusa/Hydra)
*	-		Right click, Edit Layout, Layout Settings, then in Scriptable Auto Splitter, set the appropriate *.asl file as the script path (Cyclops/Basilisk/Medusa/Hydra)
*
*/

state("EliteDangerous64") {}

startup {
	// Set up regular expressions for start, split, and reset
	vars.startMusicRegex = new System.Text.RegularExpressions.Regex(".*MusicTrack.*Combat_Unknown.*");
	vars.splitHeartRegex = new System.Text.RegularExpressions.Regex(".*HeartManager.*SetExertedHeartSlotIndex.*4294967295.*");
	vars.splitBondRegex = new System.Text.RegularExpressions.Regex(".*FactionKillBond.*faction_Thargoid.*");
	vars.resetSupercruiseRegex = new System.Text.RegularExpressions.Regex(".*SupercruiseEntry.*");
	vars.resetHyperspaceRegex = new System.Text.RegularExpressions.Regex(".*StartJump.*JumpType.*Hyperspace.*");

	// Initialize heart counter
	vars.heartCounter = 0;
	// Initialize settings
	settings.Add("odyssey", false, "Odyssey client");
	settings.SetToolTip("odyssey", "Enable this if you are loaded into Odyssey, keep this disabled if you are loaded into Horizons");
	settings.Add("logging", false, "Log to file");
	settings.SetToolTip("logging", "Write the auto splitter log to a file for debugging purposes");

	// Initialize log file
	string logDirectoyPath = Path.Combine(
		Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
		"LiveSplit",
		"Thargoid_Interceptors"
		);
	vars.logFile = new FileInfo(Path.Combine(logDirectoyPath, "autosplitter.log"));
	try {
		if (!Directory.Exists(logDirectoyPath)) {
			Directory.CreateDirectory(logDirectoyPath);
		}
		if (!vars.logFile.Exists) {
			vars.logFile.Create();
		}
	}
	catch (Exception e) {
		MessageBox.Show("Could not create log file:\n" + vars.logFile.FullName);
	}

	vars.log = (Action<string>)((string logLine) => {
		print(logLine);
		// needs to check settings too, but those aren’t available in startup …
		try {
			using (StreamWriter writer = vars.logFile.AppendText()) {
				writer.WriteLine(System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss:fff") + ": " + logLine);
			}
		}
		catch (Exception e) {
			print(e.Message);
		}
	});

	vars.log("Autosplitter loaded");
}

init {
	// Open Journal - Edit journalPath to match where your journal file is
	string journalPath = "C:\\Users\\FScog\\Saved Games\\Frontier Developments\\Elite Dangerous";
	string[] journalFiles = Directory.GetFiles(journalPath, "journal.*.log");
	Array.Sort(journalFiles, StringComparer.OrdinalIgnoreCase);
	journalFiles = journalFiles.Reverse().ToArray();
	vars.log("Found Journal: " + journalFiles[0]);
	vars.journalReader = new StreamReader(new FileStream(journalFiles[0], FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
	vars.journalReader.ReadToEnd();

	// Open netLog - Edit netLogPath to match where your netLog file is, and note it varies between Horizons and Odyssey!
	string netLogPath = "C:\\Users\\FScog\\AppData\\Local\\Frontier_Developments\\Products\\elite-dangerous-64\\Logs";
	string[] netLogFiles = Directory.GetFiles(netLogPath, "netLog.*.log");
	Array.Sort(netLogFiles, StringComparer.OrdinalIgnoreCase);
	netLogFiles = netLogFiles.Reverse().ToArray();
	vars.log("Found NetLog: " + netLogFiles[0]);
	vars.netlogReader = new StreamReader(new FileStream(netLogFiles[0], FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
	vars.netlogReader.ReadToEnd();
}

update {
	vars.journalString = vars.journalReader.ReadToEnd();
	vars.netlogString = vars.netlogReader.ReadToEnd();
	if (vars.journalString == null && vars.netlogString == null) return false; // Nothing new, don't run any other code blocks
}

start {
	if (vars.startMusicRegex.Match(vars.journalString).Success) {
		vars.log("Start run: Combat music detected");
		return true; // Combat started
	} else {
		return false;
	}
}

split {
	if (vars.journalString == null && vars.netlogString == null) return false; // Nothing new, don't run this block

	if (vars.splitHeartRegex.Match(vars.netlogString).Success) {
		vars.log("Split: Heart " + ++vars.heartCounter + " down");
		return true;
	}
	if (vars.splitBondRegex.Match(vars.journalString).Success) {
		vars.log("Finish run: Bond received");
		return true;
	}
}

reset {
	if (vars.resetSupercruiseRegex.Match(vars.journalString).Success) {
		vars.log("Reset: Jumped to Supercruise");
		return true;
	}

	if (vars.resetHyperspaceRegex.Match(vars.journalString).Success) {
		vars.log("Reset: Jumped to Hyperspace");
		return true;
	}

	// NOTE: As alterNERDtive suggested, need to add more reset conditions such as rebuy here ... TBD --CMDR Mechan

}
