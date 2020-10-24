/**
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
**/


using Gtk;

public class MainFrame : Gtk.Window {
	
	private string command_operation;
	private string command_cipherAlgo;
	private string command_hashAlgo;
	private string command_hashStrengthen;
	private string command_filePath;
	private string[] cryptoValues = {"3DES", "CAST5", "BLOWFISH", "AES", "AES192", "AES256", "TWOFISH", "CAMELLIA128", "CAMELLIA192", "CAMELLIA256"};
	private string[] hashValues = {"MD5", "SHA1", "RIPEMD160", "SHA224", "SHA256", "SHA384", "SHA512"};
	private string[] hashStrengthenValues = {"normal", "maximum"};
	
	private Gtk.Entry openTextField;
	private Gtk.Label cryptoLabel;
	private Gtk.ComboBoxText cryptoBox;
	private Gtk.Label hashLabel;
	private Gtk.ComboBoxText hashBox;
	private Gtk.Label hashStrengthenLabel;
	private Gtk.ComboBoxText hashStrengthenBox;
	
	private Gtk.Label pwlabel1;
	private Gtk.Entry pwfield1;
	private Gtk.Label pwlabel2;
	private Gtk.Entry pwfield2;
	
	private Gtk.Button runButton;
	
	
	public MainFrame() {
		Object (type: Gtk.WindowType.TOPLEVEL);
		
		this.title = "GPG Gui";
		this.border_width = 10;
		this.destroy.connect(Gtk.main_quit);
		
		//Set Application Icon & update Application Icon if theme changes
		setApplicationIcon();
		this.style_set.connect(setApplicationIcon);
		
		buildgui();
	}
	
	private void setApplicationIcon() {
		string icon1 = "gdu-encrypted-lock";
		string icon2 = "application-x-executable";
		
		try {
			this.icon = IconTheme.get_default().load_icon(icon1, 48, 0);
		} catch (Error e){
			stderr.printf("Could not load icon: "+icon1+" setting fallback icon");
			try {
				this.icon = IconTheme.get_default().load_icon(icon2, 48, 0);
			}
			catch (Error e) {
				stderr.printf("Could not load icon: "+icon2);
			}
		}
	}
	
	private void buildgui() {
		//Setting up main grid
		Gtk.Grid middleTable = new Gtk.Grid();
		middleTable.set_orientation(Gtk.Orientation.VERTICAL);
		middleTable.set_row_spacing(10);
		middleTable.set_column_spacing(50);
		this.add(middleTable);
		
		
		// #!!!!#### Operation Buttons ####!!!!#
		Gtk.RadioButton operationButton1 = new Gtk.RadioButton.with_label(null, "Encrypt");
		Gtk.RadioButton operationButton2 = new Gtk.RadioButton.with_label_from_widget(operationButton1, "Decrypt");
		operationButton1.button_press_event.connect( () => {
			operationButton1.set_active(true);
			operationButton2.set_active(false);
			set_encrypt();
			return true; } );
		operationButton2.button_press_event.connect( () => {
			operationButton1.set_active(false);
			operationButton2.set_active(true);
			set_decrypt();
			return true; } );
		middleTable.add(operationButton1);
		middleTable.attach_next_to(operationButton2, operationButton1, Gtk.PositionType.RIGHT);
		
		// #!!!!#### File Chooser ####!!!!#
		
			// #---!--- Label ---!---#
		Gtk.Label fileLabel = new Gtk.Label("File:");
		fileLabel.set_xalign(1);
		fileLabel.set_yalign((float)0.5);
		middleTable.add(fileLabel);
		
			// #---!--- Chooser ---!---#
		openTextField = new Gtk.Entry();
		openTextField.set_text("...");
		openTextField.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "drive-harddisk");
		
		Gtk.Image openButtonImage = new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.BUTTON);
		Gtk.Button openButton = new Gtk.Button.with_mnemonic(dgettext("gtk30", "_Open"));
		openButton.set_image(openButtonImage);
		openButton.set_image_position(Gtk.PositionType.LEFT);
		openButton.button_press_event.connect( () => {
			open_fileChooser();
			return true;} );
		
		Gtk.Box fileBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
		fileBox.set_homogeneous(false);
		fileBox.pack_start(openTextField);
		fileBox.pack_start(openButton);
		middleTable.attach_next_to(fileBox, fileLabel, Gtk.PositionType.RIGHT);
		
		
		// #!!!!#### Password Fields ####!!!!#
		pwlabel1 = new Gtk.Label("Password:");
		pwlabel1.set_xalign(1);
		pwlabel1.set_yalign((float)0.5);
		pwfield1 = new Gtk.Entry();
		pwfield1.set_visibility(false);
		pwfield1.changed.connect(check_runable);
		middleTable.add(pwlabel1);
		middleTable.attach_next_to(pwfield1, pwlabel1, Gtk.PositionType.RIGHT);
		
		pwlabel2 = new Gtk.Label("Confirm Password:");
		pwlabel2.set_xalign(1);
		pwlabel2.set_yalign((float)0.5);
		pwfield2 = new Gtk.Entry();
		pwfield2.set_visibility(false);
		pwfield2.changed.connect(check_runable);
		middleTable.add(pwlabel2);
		middleTable.attach_next_to(pwfield2, pwlabel2, Gtk.PositionType.RIGHT);
		
		
		// #!!!!#### Crypto ComboBox ####!!!!#
		cryptoLabel = new Gtk.Label("Encryption Cipher:");
		cryptoLabel.set_xalign(1);
		cryptoLabel.set_yalign((float)0.5);
		cryptoLabel.set_tooltip_text("TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
		middleTable.add(cryptoLabel);
		
		cryptoBox = new Gtk.ComboBoxText();
		cryptoBox.set_tooltip_text("TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
		cryptoBox.changed.connect(set_crypto);
		foreach (string str in cryptoValues) {
			cryptoBox.append_text(str);
		}
		middleTable.attach_next_to(cryptoBox, cryptoLabel, Gtk.PositionType.RIGHT);
		
		// #!!!!#### Hash ComboBox ####!!!!#
		hashLabel = new Gtk.Label("Hash Algorithm:");
		hashLabel.set_xalign(1);
		hashLabel.set_yalign((float)0.5);
		hashLabel.set_tooltip_text("SHA512 is the strongest hash.");
		middleTable.add(hashLabel);
		
		hashBox = new Gtk.ComboBoxText();
		hashBox.set_tooltip_text("SHA512 is the strongest hash.");
		hashBox.changed.connect(set_hash);
		foreach (string str in hashValues) {
			hashBox.append_text(str);
		}
		middleTable.attach_next_to(hashBox, hashLabel, Gtk.PositionType.RIGHT);
		
		// #!!!!#### Hash StrengthenBox ####!!!!#
		hashStrengthenLabel = new Gtk.Label("Hash Strengthen:");
		hashStrengthenLabel.set_xalign(1);
		hashStrengthenLabel.set_yalign((float)0.5);
		hashStrengthenLabel.set_tooltip_text("'normal' is faster, 'maximum' is stronger.");
		middleTable.add(hashStrengthenLabel);

		hashStrengthenBox = new Gtk.ComboBoxText();
		hashStrengthenBox.set_tooltip_text("'normal' is faster, 'maximum' is stronger.");
		hashStrengthenBox.changed.connect(set_hash_strengthen);
		foreach (string str in hashStrengthenValues) {
			hashStrengthenBox.append_text(str);
		}
		middleTable.attach_next_to(hashStrengthenBox, hashStrengthenLabel, Gtk.PositionType.RIGHT);

		// #!!!!#### Run Button ####!!!!#
		Gtk.Image runButtonImage = new Gtk.Image.from_icon_name("system-run", Gtk.IconSize.BUTTON);
		runButton = new Gtk.Button.with_label("Run");
		runButton.set_image(runButtonImage);
		runButton.set_image_position(Gtk.PositionType.LEFT);
		runButton.button_press_event.connect( () => {
			run();
			return true; } );
		middleTable.attach_next_to(runButton, hashStrengthenBox, Gtk.PositionType.BOTTOM);
		
		// Expand all widgets inside table
		middleTable.foreach( (child) => {
			child.set_hexpand(true);
			child.set_vexpand(true);
		});
		
		// #!!!!#### Setup ####!!!!#
		operationButton1.set_active(true);
		set_encrypt();				//Activate "Encrypt" Tab
		
		cryptoBox.set_active(6);			//Set TWOFISH cipher as default
		hashBox.set_active(4);				//Set SHA256 hash as default
		hashStrengthenBox.set_active(0);	//Set 'normal' as default
		
		check_runable();
		
		this.show_all();
	}
	
	private void open_fileChooser() {

		Gtk.FileChooserDialog file_chooser = new Gtk.FileChooserDialog(
			"Open File",
			this,
			FileChooserAction.OPEN,
			dgettext("gtk30", "_Cancel"),
			ResponseType.CANCEL,
			dgettext("gtk30", "_Open"),
			ResponseType.ACCEPT
		);
		
        if (file_chooser.run() == ResponseType.ACCEPT) {
			string filepath = file_chooser.get_filename();
			
			//Abort if file doesn't exists
			if (!GLib.FileUtils.test(filepath, GLib.FileTest.EXISTS)) {
				return;
			}
			
			//set command_filePath to selected file
			set_file(filepath);
			
			//set textFieldText to selected file
			string filename = GLib.Filename.display_basename(filepath);
			openTextField.set_text(filename);
		}

		file_chooser.destroy();
	}
	
	
	private void set_file(string str) {
		command_filePath = str;
		check_runable();
	}
	
	
	private void set_encrypt() {
		command_operation = "encrypt";
		
		//Change sensitivity of some widgets
		pwlabel2.set_sensitive(true);
		pwfield2.set_sensitive(true);
		cryptoLabel.set_sensitive(true);
		cryptoBox.set_sensitive(true);
		hashLabel.set_sensitive(true);
		hashBox.set_sensitive(true);
		hashStrengthenLabel.set_sensitive(true);
		hashStrengthenBox.set_sensitive(true);
		
		check_runable();
	}
	
	private void set_decrypt() {
		command_operation = "decrypt";
		
		//Change sensitivity of some widgets
		pwlabel2.set_sensitive(false);
		pwfield2.set_sensitive(false);
		cryptoLabel.set_sensitive(false);
		cryptoBox.set_sensitive(false);
		hashLabel.set_sensitive(false);
		hashBox.set_sensitive(false);
		hashStrengthenLabel.set_sensitive(false);
		hashStrengthenBox.set_sensitive(false);
		
		check_runable();
	}


	private void set_crypto() {
		//stdout.printf(		cryptoValues[	cryptoBox.get_active()	]		);
		command_cipherAlgo = cryptoValues[ cryptoBox.get_active() ];
		check_runable();
	}
	
	private void set_hash() {
		//stdout.printf(		hashValues[		hashBox.get_active()	]		);
		command_hashAlgo = hashValues[ hashBox.get_active() ];
		check_runable();
	}

	private void set_hash_strengthen() {
		//stdout.printf(		hashValues[		hashBox.get_active()	]		);
		command_hashStrengthen = hashStrengthenValues[ hashStrengthenBox.get_active() ];
		check_runable();
	}
	
	
	//debug function, see check_runable()
	/**private void print_values() {
		stdout.printf("\nCommand Operation:\t");
		if (command_operation != null)	{ 		stdout.printf(command_operation);	}
		else { stdout.printf("null"); }
		
		stdout.printf("\nCommand Cipher:\t\t");
		if (command_cipherAlgo != null) {		stdout.printf(command_cipherAlgo);	}
		else { stdout.printf("null"); }
		
		stdout.printf("\nCommand Hash:\t\t");
		if (command_hashAlgo != null)	{		stdout.printf(command_hashAlgo);	}
		else { stdout.printf("null"); }
		
		stdout.printf("\nCommand FilePath:\t");
		if (command_filePath != null)	{		stdout.printf(command_filePath);	}
		else { stdout.printf("null"); }
		
		stdout.printf("\n");
	}**/
	
	private void check_runable() {
		//print_values();	//debug
		
		
		bool runable = true;
		
		//Check if everything is ok, otherwise set runable to false
		if (command_operation == null || command_operation == "") {
			runable = false;
		}
		else if (command_operation == "encrypt") {
			if (command_filePath == null || command_filePath == "") {
				runable = false; }
			else if (pwfield1.get_text() == "") {
				runable = false; }
			else if (pwfield2.get_text() == "") {
				runable = false; }
			else if (pwfield1.get_text() != pwfield2.get_text()) {
				runable = false; }
			else if (command_cipherAlgo == null || command_cipherAlgo == "") {
				runable = false; }
			else if (command_hashAlgo == null || command_hashAlgo == "") {
				runable = false; }
			else if (command_hashStrengthen == null || command_hashStrengthen == "") {
				runable = false; }
		}
		else if (command_operation == "decrypt") {
			if ( command_filePath == null || command_filePath == "") {
				runable = false; }
			else if (pwfield1.get_text() == "") {
				runable = false; }
		}
		
		//Enable or disable the run button
		if (runable == false) {
			runButton.set_sensitive(false);
		}
		else {
			runButton.set_sensitive(true);
		}
	}
	
	
	private void run() {
		/// No need to check if everything is !null, because button to
		/// call this function is only clickable if everything is ok
		/// see check_runable()
		
		if (command_operation == "encrypt") {

			string executeString = "gpg --no-use-agent --batch --no-tty";
			executeString += " --symmetric";

			if (command_hashStrengthen == "normal") {
				executeString += " --digest-algo " + command_hashAlgo;
			}
			else {
				executeString += " --s2k-mode 3 --s2k-count 65011712";
				executeString += " --s2k-digest-algo " + command_hashAlgo;
			}

			executeString += " --cipher-algo " + command_cipherAlgo;
			executeString += " --passphrase ";
			executeString += pwfield1.get_text();
			executeString += " \"" + command_filePath + "\"";
			
			//start encryption
			stdout.printf(executeString+"\n");
			try {
				GLib.Process.spawn_command_line_sync(executeString);
			}
			catch (SpawnError e) {
				stderr.printf("spawn error!");
			}
		} else {
			//New file will be named like the original file but
			//with _DECRYPTED as suffix
			// encryptedfile => encryptedfile_DECRYPTED
			// secretphoto.jpg.gpg => secretphoto.jpg.gpg_ENCRYPTED
			
			string outputFile;
			if (command_filePath.length > 4 &&
			command_filePath.slice(-4, command_filePath.length) == ".gpg") {
				outputFile = command_filePath.slice(0, -4);
			}
			else {
				outputFile = command_filePath+"_DECRYPTED";
			}
			
			string argv[8];
			argv[0] = "gpg";
			argv[1] = "--no-use-agent";
			argv[2] = "--batch";
			argv[3] = "--no-tty";
			argv[4] = "--passphrase";
			argv[5] = pwfield1.get_text();
			argv[6] = "--decrypt";
			argv[7] = command_filePath;
			
			stdout.printf("path: %s\n", command_filePath);
			
			string[] envv = Environ.get();
			int child_stdin_fd;
			int child_stdout_fd;
			int child_stderr_fd;
			
			//start decryption
			try {
				GLib.Process.spawn_async_with_pipes(
					".",
					argv,
					envv,
					SpawnFlags.SEARCH_PATH,
					null,
					null,
					out child_stdin_fd,
					out child_stdout_fd,
					out child_stderr_fd
				);
			} catch (SpawnError e) {
				stderr.printf("spawn error!");
				stderr.printf(e.message);
			}
			
			GLib.FileStream child_stdout_stream = GLib.FileStream.fdopen(child_stdout_fd, "r");
			GLib.FileStream child_stderr_stream = GLib.FileStream.fdopen(child_stderr_fd, "r");
			GLib.FileStream output_stream = GLib.FileStream.open(outputFile, "w");
			///GLib.FileStream filestreamOUTERR = GLib.FileStream.open("./err", "w");
			
			uint8 buf[1];
			size_t t;
			while ((t = child_stdout_stream.read(buf, 1)) != 0) {
				output_stream.write(buf, 1);
			}
			
			/**while ((t = filestreamSTDERR.read(buf, 1)) != 0) {
				filestreamOUTERR.write(buf, 1);
			}**/
		}
	}
}
