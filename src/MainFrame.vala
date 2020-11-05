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

public class MainFrame : Gtk.Window {

    private string cmd_operation;
    private string cmd_cipher_algo;
    private string cmd_hash_algo;
    private string cmd_hash_strengthen;
    private string cmd_file_path;

    private string[] crypto_values {
        get {
            return gpg_handler.get_cipher_algos();
        }
    }

    private string[] hash_values {
        get {
            return gpg_handler.get_digest_algos();
        }
    }

    private string[] hash_strengthen_values = {"normal", "maximum"};

    private Gtk.Entry open_text_field;
    private Gtk.Label crypto_label;
    private Gtk.ComboBoxText crypto_box;
    private Gtk.Label hash_label;
    private Gtk.ComboBoxText hash_box;
    private Gtk.Label hash_strengthen_label;
    private Gtk.ComboBoxText hash_strengthen_box;

    private Gtk.Label pwlabel1;
    private Gtk.Entry pwfield1;
    private Gtk.Label pwlabel2;
    private Gtk.Entry pwfield2;

    private Gtk.Button run_button;

    private GPGHandler gpg_handler;

    public MainFrame() {
        Object(type: Gtk.WindowType.TOPLEVEL);

        this.title = "GPG-Gui";
        this.border_width = 10;
        this.destroy.connect(Gtk.main_quit);

        this.gpg_handler = new GPGHandler();

        //Set application icon & update application icon if theme changes
        set_application_icon();
        this.style_updated.connect(set_application_icon);

        build_gui();
    }

    private void set_application_icon() {
        const string[] icons = {
            "gdu-encrypted-lock",
            "stock_keyring",
            "keyring-manager",
            "application-x-executable"
        };

        foreach (string icon in icons) {
            try {
                this.icon = Gtk.IconTheme.get_default().load_icon(icon, 48, 0);
            } catch (Error e) {
                stderr.printf(
                    "Could not load icon: " + icon + ". Using fallback icon...\n");
                continue;
            }

            // Found working icon
            break;
        }
    }

    private void build_gui() {
        // Set up main grid
        Gtk.Grid main_grid = new Gtk.Grid();
        main_grid.set_orientation(Gtk.Orientation.VERTICAL);
        main_grid.set_row_spacing(10);
        main_grid.set_column_spacing(50);
        this.add(main_grid);


        // Encrypt / Decrypt operation buttons
        Gtk.RadioButton mode_selector1 = new Gtk.RadioButton.with_label(
            null,
            "Encrypt");
        Gtk.RadioButton mode_selector2 = new Gtk.RadioButton.with_label_from_widget(
            mode_selector1,
            "Decrypt");
        mode_selector1.toggled.connect(set_encrypt);
        mode_selector2.toggled.connect(set_decrypt);
        main_grid.add(mode_selector1);
        main_grid.attach_next_to(
            mode_selector2,
            mode_selector1,
            Gtk.PositionType.RIGHT);


        // File chooser
        Gtk.Label file_label = new Gtk.Label("File:");
        file_label.set_xalign(1);
        file_label.set_yalign((float)0.5);
        main_grid.add(file_label);

        open_text_field = new Gtk.Entry();
        open_text_field.set_text("...");
        open_text_field.set_icon_from_icon_name(
            Gtk.EntryIconPosition.PRIMARY,
            "drive-harddisk");

        Gtk.Image open_button_image = new Gtk.Image.from_icon_name(
            "document-open",
            Gtk.IconSize.BUTTON);
        Gtk.Button open_button = new Gtk.Button.with_mnemonic(
            dgettext("gtk30", "_Open"));
        open_button.set_image(open_button_image);
        open_button.set_image_position(Gtk.PositionType.LEFT);
        open_button.clicked.connect(open_file_chooser);

        Gtk.Box file_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        file_box.set_homogeneous(false);
        file_box.pack_start(open_text_field);
        file_box.pack_start(open_button);
        main_grid.attach_next_to(file_box, file_label, Gtk.PositionType.RIGHT);


        // Password fields
        pwlabel1 = new Gtk.Label("Password:");
        pwlabel1.set_xalign(1);
        pwlabel1.set_yalign((float)0.5);
        pwfield1 = new Gtk.Entry();
        pwfield1.set_visibility(false);
        pwfield1.changed.connect(check_runable);
        main_grid.add(pwlabel1);
        main_grid.attach_next_to(pwfield1, pwlabel1, Gtk.PositionType.RIGHT);

        pwlabel2 = new Gtk.Label("Confirm Password:");
        pwlabel2.set_xalign(1);
        pwlabel2.set_yalign((float)0.5);
        pwfield2 = new Gtk.Entry();
        pwfield2.set_visibility(false);
        pwfield2.changed.connect(check_runable);
        main_grid.add(pwlabel2);
        main_grid.attach_next_to(pwfield2, pwlabel2, Gtk.PositionType.RIGHT);


        // Crypto selection
        crypto_label = new Gtk.Label("Encryption Cipher:");
        crypto_label.set_xalign(1);
        crypto_label.set_yalign((float)0.5);
        crypto_label.set_tooltip_text(
            "TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
        main_grid.add(crypto_label);

        crypto_box = new Gtk.ComboBoxText();
        crypto_box.set_tooltip_text(
            "TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
        crypto_box.changed.connect(set_crypto);
        foreach (string str in crypto_values) {
            crypto_box.append_text(str);
        }
        main_grid.attach_next_to(crypto_box, crypto_label, Gtk.PositionType.RIGHT);


        // Hash selection
        hash_label = new Gtk.Label("Hash Algorithm:");
        hash_label.set_xalign(1);
        hash_label.set_yalign((float)0.5);
        hash_label.set_tooltip_text("SHA512 is the strongest hash.");
        main_grid.add(hash_label);

        hash_box = new Gtk.ComboBoxText();
        hash_box.set_tooltip_text("SHA512 is the strongest hash.");
        hash_box.changed.connect(set_hash);
        foreach (string str in hash_values) {
            hash_box.append_text(str);
        }
        main_grid.attach_next_to(hash_box, hash_label, Gtk.PositionType.RIGHT);


        // Hash strengthen selection
        hash_strengthen_label = new Gtk.Label("Hash Strengthen:");
        hash_strengthen_label.set_xalign(1);
        hash_strengthen_label.set_yalign((float)0.5);
        hash_strengthen_label.set_tooltip_text(
            "'normal' is faster, 'maximum' is stronger.");
        main_grid.add(hash_strengthen_label);

        hash_strengthen_box = new Gtk.ComboBoxText();
        hash_strengthen_box.set_tooltip_text(
            "'normal' is faster, 'maximum' is stronger.");
        hash_strengthen_box.changed.connect(set_hash_strengthen);
        foreach (string str in hash_strengthen_values) {
            hash_strengthen_box.append_text(str);
        }
        main_grid.attach_next_to(
            hash_strengthen_box,
            hash_strengthen_label,
            Gtk.PositionType.RIGHT);


        // Run button
        Gtk.Image run_button_image = new Gtk.Image.from_icon_name(
            "system-run",
            Gtk.IconSize.BUTTON);
        run_button = new Gtk.Button.with_label("Run");
        run_button.set_image(run_button_image);
        run_button.set_image_position(Gtk.PositionType.LEFT);
        run_button.clicked.connect(run);
        main_grid.attach_next_to(
            run_button,
            hash_strengthen_box,
            Gtk.PositionType.BOTTOM);


        // Expand all widgets inside table
        main_grid.foreach( (child) => {
            child.set_hexpand(true);
            child.set_vexpand(true);
        });


        // Select default options
        mode_selector1.set_active(true);
        set_encrypt();

        // Set TWOFISH cipher as default
        crypto_box.set_active(0);
        for (int i = 0; i < crypto_values.length; i++) {
            if (crypto_values[i] == "TWOFISH") {
                crypto_box.set_active(i);
                break;
            }
        }

        // Set SHA256 hash as default
        for (int i = 0; i < hash_values.length; i++) {
            if (hash_values[i] == "SHA256") {
                hash_box.set_active(i);
            }
        }

        // Set 'normal' as default
        hash_strengthen_box.set_active(0);

        check_runable();

        this.show_all();
    }

    private void open_file_chooser() {
        Gtk.FileChooserDialog file_chooser = new Gtk.FileChooserDialog(
            "Open File",
            this,
            Gtk.FileChooserAction.OPEN,
            dgettext("gtk30", "_Cancel"),
            Gtk.ResponseType.CANCEL,
            dgettext("gtk30", "_Open"),
            Gtk.ResponseType.ACCEPT
        );

        if (file_chooser.run() == Gtk.ResponseType.ACCEPT) {
            string filepath = file_chooser.get_filename();

            //Abort if file doesn't exists
            if (!FileUtils.test(filepath, FileTest.EXISTS)) {
                return;
            }

            //set cmd_file_path to selected file
            set_file(filepath);

            //set textFieldText to selected file
            string filename = Filename.display_basename(filepath);
            open_text_field.set_text(filename);
        }

        file_chooser.destroy();
    }

    private void set_file(string str) {
        cmd_file_path = str;
        check_runable();
    }

    private void set_encrypt() {
        cmd_operation = "encrypt";

        //Change sensitivity of some widgets
        pwlabel2.set_sensitive(true);
        pwfield2.set_sensitive(true);
        crypto_label.set_sensitive(true);
        crypto_box.set_sensitive(true);
        hash_label.set_sensitive(true);
        hash_box.set_sensitive(true);
        hash_strengthen_label.set_sensitive(true);
        hash_strengthen_box.set_sensitive(true);

        check_runable();
    }

    private void set_decrypt() {
        cmd_operation = "decrypt";

        // Change sensitivity of some widgets
        pwlabel2.set_sensitive(false);
        pwfield2.set_sensitive(false);
        crypto_label.set_sensitive(false);
        crypto_box.set_sensitive(false);
        hash_label.set_sensitive(false);
        hash_box.set_sensitive(false);
        hash_strengthen_label.set_sensitive(false);
        hash_strengthen_box.set_sensitive(false);

        check_runable();
    }

    private void set_crypto() {
        cmd_cipher_algo = crypto_values[crypto_box.get_active()];
        check_runable();
    }

    private void set_hash() {
        cmd_hash_algo = hash_values[hash_box.get_active()];
        check_runable();
    }

    private void set_hash_strengthen() {
        cmd_hash_strengthen = hash_strengthen_values[hash_strengthen_box.get_active()];
        check_runable();
    }

    private void check_runable() {
        bool runable = true;

        //Check if everything is ok, otherwise set runable to false
        if (cmd_operation == null || cmd_operation == "") {
            runable = false;
        } else if (cmd_operation == "encrypt") {
            if (cmd_file_path == null || cmd_file_path == "") {
                runable = false;
            } else if (pwfield1.get_text() == "") {
                runable = false;
            } else if (pwfield2.get_text() == "") {
                runable = false;
            } else if (pwfield1.get_text() != pwfield2.get_text()) {
                runable = false;
            } else if (cmd_cipher_algo == null || cmd_cipher_algo == "") {
                runable = false;
            } else if (cmd_hash_algo == null || cmd_hash_algo == "") {
                runable = false;
            } else if (cmd_hash_strengthen == null || cmd_hash_strengthen == "") {
                runable = false;
            }
        } else if (cmd_operation == "decrypt") {
            if (cmd_file_path == null || cmd_file_path == "") {
                runable = false;
            } else if (pwfield1.get_text() == "") {
                runable = false;
            }
        }

        // Enable or disable the run button
        if (runable == false) {
            run_button.set_sensitive(false);
        } else {
            run_button.set_sensitive(true);
        }
    }

    private void run() {
        // No need to check if everything is !null, because button to
        // call this function is only clickable if everything is ok
        // see check_runable()

        string input_file = cmd_file_path;

        if (cmd_operation == "encrypt") {
            this.gpg_handler.encrypt(
                pwfield1.get_text(),
                input_file,
                cmd_cipher_algo,
                cmd_hash_algo,
                cmd_hash_strengthen == "maximum");

        } else {
            // Output file will be named like the input file but
            // with .gpg removed if it ends with .gpg input
            // _DECRYPTED will be added as suffix:
            //  - encryptedfile       => encryptedfile_DECRYPTED
            //  - secretphoto.jpg.gpg => secretphoto.jpg

            string output_file;
            if (input_file.length > 4 &&
            input_file.slice(-4, input_file.length) == ".gpg") {
                output_file = input_file.slice(0, -4);
            } else {
                output_file = input_file + "_DECRYPTED";
            }

            this.gpg_handler.decrypt(
                pwfield1.get_text(),
                input_file,
                output_file);
        }
    }
}
