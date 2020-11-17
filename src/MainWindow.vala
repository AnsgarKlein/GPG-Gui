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

public class MainWindow : Gtk.Window {

    private enum Mode {
        READY_ENCRYPT,
        READY_DECRYPT,
        RUNNING,
    }

    /**
     * The currently selected input file or empty string if no file
     * has been selected.
     */
    private string selected_file {
        get {
            if (file_text_field == null) {
                return "";
            }

            return file_text_field.get_text();
        }
    }

    /**
     * The currently selected cipher algorithm or null if no cipher algorithm
     * has been selected.
     */
    private string? selected_cipher_algo {
        get {
            if (crypto_box == null) {
                return null;
            }

            int selection = crypto_box.get_active();
            if (selection < 0 || selection > cipher_algos.length - 1) {
                // Selection out of scope
                return null;
            }

            return cipher_algos[selection];
        }
    }

    /**
     * The currently selected digest algorithm or null if no digest algorithm
     * has been selected.
     */
    private string? selected_digest_algo {
        get {
            if (hash_box == null) {
                return null;
            }

            int selection = hash_box.get_active();
            if (selection < 0 || selection > digest_algos.length - 1) {
                // Selection out of scope
                return null;
            }

            return digest_algos[selection];
        }
    }

    /**
     * The currently selected hash strengthen selection or false if no
     * selection can be determined.
     */
    private bool selected_hash_strengthen {
        get {
            if (hash_strengthen_button == null) {
                return false;
            }

            return hash_strengthen_button.get_active();
        }
    }

    /**
     * Array of all available cipher algos
     */
    private string[] cipher_algos {
        get {
            return gpg_handler.get_cipher_algos();
        }
    }

    /**
     * Array of all available digest algos
     */
    private string[] digest_algos {
        get {
            return gpg_handler.get_digest_algos();
        }
    }

    /**
     * Handler representing all gpg functionality
     */
    private GPGHandler gpg_handler;

    /**
     * Currently active mode of this application
     */
    private Mode _mode;
    private Mode mode {
        set {
            _mode = value;
            mode_changed();
        }
        get {
            return _mode;
        }
    }

    /**
     * Signal is emitted when mode is changed
     */
    private signal void mode_changed();

    // Gtk widgets
    private Gtk.RadioButton mode_selector1;
    private Gtk.RadioButton mode_selector2;

    private Gtk.Label file_label;
    private Gtk.Entry file_text_field;
    private Gtk.Label pwlabel1;
    private Gtk.Entry pwfield1;
    private Gtk.Label pwlabel2;
    private Gtk.Entry pwfield2;
    private Gtk.Label crypto_label;
    private Gtk.ComboBoxText crypto_box;
    private Gtk.Label hash_label;
    private Gtk.ComboBoxText hash_box;
    private Gtk.Label hash_strengthen_label;
    private Gtk.CheckButton hash_strengthen_button;

    private Gtk.Button run_button;

    private ProgressIndicator progress_indicator;

    public MainWindow() {
        Object(type: Gtk.WindowType.TOPLEVEL);
        this.set_position(Gtk.WindowPosition.CENTER);

        this.title = "GPG-Gui";
        this.border_width = 10;
        this.destroy.connect(Gtk.main_quit);

        this.gpg_handler = new GPGHandler();

        //Set application icon & update application icon if theme changes
        set_application_icon();
        this.style_updated.connect(set_application_icon);

        build_gui();
        set_defaults();

        this.mode_changed.connect(on_mode_change);
    }

    private void set_application_icon() {
        const string[] PREFERRED_ICON_NAMES = {
            "gdu-encrypted-lock",
            "stock_keyring",
            "keyring-manager",
            "application-x-executable"
        };

        const int[] DESIRED_ICON_SIZES = { 48, 32, 16, 64, 128, };

        Gtk.IconTheme theme = Gtk.IconTheme.get_default();

        foreach (string icon_name in PREFERRED_ICON_NAMES) {
            try {
                // Try to get selected icon
                // This may throw error in which case we try next icon
                Gdk.Pixbuf first_icon = theme.load_icon(
                    icon_name,
                    DESIRED_ICON_SIZES[0],
                    Gtk.IconLookupFlags.FORCE_SIZE);

                // Icon is contained in icon theme
                // => Get icon in multiple sizes
                var icon_list = new List<Gdk.Pixbuf>();
                icon_list.append(first_icon);

                for (int i = 1; i < DESIRED_ICON_SIZES.length; i++) {
                    int icon_size = DESIRED_ICON_SIZES[i];

                    Gdk.Pixbuf icon = theme.load_icon(
                        icon_name,
                        icon_size,
                        0);
                    if (icon != null) {
                        icon_list.append(icon);
                    }
                }

                this.set_icon_list(icon_list);
            } catch (Error e) {
                // Could not find icon in current theme
                // => Try next icon
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
        mode_selector1 = new Gtk.RadioButton.with_label(
            null,
            "Encrypt");
        mode_selector2 = new Gtk.RadioButton.with_label_from_widget(
            mode_selector1,
            "Decrypt");
        mode_selector1.toggled.connect(on_mode_button_select);
        mode_selector2.toggled.connect(on_mode_button_select);

        mode_selector1.set_hexpand(true);
        mode_selector1.set_vexpand(true);
        main_grid.add(mode_selector1);

        mode_selector2.set_hexpand(true);
        mode_selector2.set_vexpand(true);
        main_grid.attach_next_to(
            mode_selector2,
            mode_selector1,
            Gtk.PositionType.RIGHT);


        // File chooser
        file_label = new Gtk.Label("File:");
        file_label.set_xalign(1);
        file_label.set_yalign((float)0.5);
        file_label.set_hexpand(true);
        file_label.set_vexpand(true);
        main_grid.add(file_label);

        file_text_field = new Gtk.Entry();
        file_text_field.set_text("...");
        file_text_field.set_icon_from_icon_name(
            Gtk.EntryIconPosition.PRIMARY,
            "drive-harddisk");
        file_text_field.changed.connect(on_file_text_input);

        Gtk.Image open_button_image = new Gtk.Image.from_icon_name(
            "document-open",
            Gtk.IconSize.BUTTON);
        Gtk.Button open_button = new Gtk.Button.with_mnemonic(
            dgettext("gtk30", "_Open"));
        open_button.set_image(open_button_image);
        open_button.set_image_position(Gtk.PositionType.LEFT);
        open_button.clicked.connect(on_file_chooser_button);

        Gtk.Box file_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        file_box.set_homogeneous(false);

        file_text_field.set_hexpand(true);
        file_text_field.set_vexpand(true);
        file_box.pack_start(file_text_field);

        open_button.set_hexpand(true);
        open_button.set_vexpand(true);
        file_box.pack_start(open_button);

        file_box.set_hexpand(true);
        file_box.set_vexpand(true);
        main_grid.attach_next_to(file_box, file_label, Gtk.PositionType.RIGHT);


        // Password fields
        pwlabel1 = new Gtk.Label("Password:");
        pwlabel1.set_xalign(1);
        pwlabel1.set_yalign((float)0.5);
        pwlabel1.set_hexpand(true);
        pwlabel1.set_vexpand(true);
        main_grid.add(pwlabel1);

        pwfield1 = new Gtk.Entry();
        pwfield1.set_visibility(false);
        pwfield1.set_input_hints(Gtk.InputHints.NO_SPELLCHECK);
        pwfield1.set_input_purpose(Gtk.InputPurpose.PASSWORD);
        pwfield1.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "dialog-password");
        pwfield1.changed.connect(on_pw_input);
        pwfield1.set_hexpand(true);
        pwfield1.set_vexpand(true);
        main_grid.attach_next_to(pwfield1, pwlabel1, Gtk.PositionType.RIGHT);

        pwlabel2 = new Gtk.Label("Confirm Password:");
        pwlabel2.set_xalign(1);
        pwlabel2.set_yalign((float)0.5);
        pwlabel2.set_hexpand(true);
        pwlabel2.set_vexpand(true);
        main_grid.add(pwlabel2);

        pwfield2 = new Gtk.Entry();
        pwfield2.set_visibility(false);
        pwfield2.set_input_hints(Gtk.InputHints.NO_SPELLCHECK);
        pwfield2.set_input_purpose(Gtk.InputPurpose.PASSWORD);
        pwfield2.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "dialog-password");
        pwfield2.changed.connect(on_pw_input);
        pwfield2.set_hexpand(true);
        pwfield2.set_vexpand(true);
        main_grid.attach_next_to(pwfield2, pwlabel2, Gtk.PositionType.RIGHT);


        // Crypto selection
        crypto_label = new Gtk.Label("Encryption Cipher:");
        crypto_label.set_xalign(1);
        crypto_label.set_yalign((float)0.5);
        crypto_label.set_tooltip_text(
            "TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
        crypto_label.set_hexpand(true);
        crypto_label.set_vexpand(true);
        main_grid.add(crypto_label);

        crypto_box = new Gtk.ComboBoxText();
        crypto_box.set_tooltip_text(
            "TWOFISH, AES256, and CAMELLIA256 are the strongest ciphers.");
        crypto_box.changed.connect(refresh_widgets);
        foreach (string algo in cipher_algos) {
            crypto_box.append_text(algo);
        }
        crypto_box.set_hexpand(true);
        crypto_box.set_vexpand(true);
        main_grid.attach_next_to(crypto_box, crypto_label, Gtk.PositionType.RIGHT);


        // Hash selection
        hash_label = new Gtk.Label("Hash Algorithm:");
        hash_label.set_xalign(1);
        hash_label.set_yalign((float)0.5);
        hash_label.set_tooltip_text("SHA512 is the strongest hash.");
        hash_label.set_hexpand(true);
        hash_label.set_vexpand(true);
        main_grid.add(hash_label);

        hash_box = new Gtk.ComboBoxText();
        hash_box.set_tooltip_text("SHA512 is the strongest hash.");
        hash_box.changed.connect(refresh_widgets);
        foreach (string algo in digest_algos) {
            hash_box.append_text(algo);
        }
        hash_box.set_hexpand(true);
        hash_box.set_vexpand(true);
        main_grid.attach_next_to(hash_box, hash_label, Gtk.PositionType.RIGHT);


        // Hash strengthen button
        hash_strengthen_label = new Gtk.Label("Hash Strengthen:");
        hash_strengthen_label.set_xalign(1);
        hash_strengthen_label.set_yalign((float)0.5);
        hash_strengthen_label.set_tooltip_text(
            "Strengthening increases security but increases encryption time");
        hash_strengthen_label.set_hexpand(true);
        hash_strengthen_label.set_vexpand(true);
        main_grid.add(hash_strengthen_label);

        hash_strengthen_button = new Gtk.CheckButton();
        hash_strengthen_button.set_tooltip_text(
            "Strengthening increases security but increases encryption time");
        hash_strengthen_button.toggled.connect(refresh_widgets);
        hash_strengthen_button.set_hexpand(true);
        hash_strengthen_button.set_vexpand(true);
        main_grid.attach_next_to(
            hash_strengthen_button,
            hash_strengthen_label,
            Gtk.PositionType.RIGHT);


        // Run button
        Gtk.Image run_button_image = new Gtk.Image.from_icon_name(
            "system-run",
            Gtk.IconSize.BUTTON);
        run_button = new Gtk.Button.with_label("Run");
        run_button.set_image(run_button_image);
        run_button.set_image_position(Gtk.PositionType.LEFT);
        run_button.clicked.connect(on_run_button);
        run_button.set_hexpand(true);
        run_button.set_vexpand(true);
        main_grid.attach_next_to(
            run_button,
            hash_strengthen_button,
            Gtk.PositionType.BOTTOM);


        // Progress indicator
        progress_indicator = new ProgressIndicator();
        progress_indicator.set_hexpand(true);
        progress_indicator.set_vexpand(true);
        main_grid.attach_next_to(
            progress_indicator,
            null,
            Gtk.PositionType.BOTTOM,
            2, 1);
        progress_indicator.finished.connect( () => {
            // Set mode to mode selected by buttons
            if (mode_selector1.get_active()) {
                this.mode = Mode.READY_ENCRYPT;
            } else {
                this.mode = Mode.READY_DECRYPT;
            }
        });


        // Show all widgets except the progress indicator
        this.show_all();
        progress_indicator.hide();
    }

    private void set_defaults() {
        // Select default options
        mode_selector1.set_active(true);
        this.mode = Mode.READY_ENCRYPT;

        // Set TWOFISH cipher as default
        crypto_box.set_active(0);
        for (int i = 0; i < cipher_algos.length; i++) {
            if (cipher_algos[i] == "TWOFISH") {
                crypto_box.set_active(i);
                break;
            }
        }

        // Set SHA256 hash as default
        hash_box.set_active(0);
        for (int i = 0; i < digest_algos.length; i++) {
            if (digest_algos[i] == "SHA256") {
                hash_box.set_active(i);
            }
        }

        // Disable hash strengthening per default
        hash_strengthen_button.set_active(false);

        refresh_widgets();
    }

    private void on_mode_change() {
        refresh_widgets();
    }

    private void on_mode_button_select() {
        if (mode_selector1.get_active()) {
            this.mode = Mode.READY_ENCRYPT;
        } else {
            this.mode = Mode.READY_DECRYPT;
        }
    }

    private void on_file_text_input() {
        refresh_widgets();
    }

    private void on_file_chooser_button() {
        // Open file chooser
        Gtk.FileChooserNative file_chooser = new Gtk.FileChooserNative(
            "Open File",
            this,
            Gtk.FileChooserAction.OPEN,
            dgettext("gtk30", "_Open"),
            dgettext("gtk30", "_Cancel")
        );

        // Set content of text field to selected file
        if (file_chooser.run() == Gtk.ResponseType.ACCEPT) {
            file_text_field.set_text(file_chooser.get_filename());
        }

        file_chooser.destroy();
    }

    private void on_pw_input() {
        const string pw_warning = "Passwords do not match";

        // If both password entries don't have same content
        // display warning icon with tooltip
        if (pwfield1.get_text() != pwfield2.get_text()) {
            pwfield2.set_icon_from_icon_name(
                Gtk.EntryIconPosition.SECONDARY,
                "dialog-warning");
            pwfield2.set_icon_tooltip_text(
                Gtk.EntryIconPosition.SECONDARY,
                pw_warning);
        } else {
            pwfield2.set_icon_from_gicon(
                Gtk.EntryIconPosition.SECONDARY,
                null);
        }

        refresh_widgets();
    }

    /**
     * Set sensitivity of all window widgets depending on mode
     * and other variables.
     */
    private void refresh_widgets() {
        if (this.mode == Mode.READY_ENCRYPT) {
            mode_selector1.set_sensitive(true);
            mode_selector2.set_sensitive(true);

            file_label.set_sensitive(true);
            file_text_field.set_sensitive(true);
            pwlabel1.set_sensitive(true);
            pwfield1.set_sensitive(true);
            pwlabel2.set_sensitive(true);
            pwfield2.set_sensitive(true);
            crypto_label.set_sensitive(true);
            crypto_box.set_sensitive(true);
            hash_label.set_sensitive(true);
            hash_box.set_sensitive(true);
            hash_strengthen_label.set_sensitive(true);
            hash_strengthen_button.set_sensitive(true);

            progress_indicator.hide();
        } else if (this.mode == Mode.READY_DECRYPT) {
            mode_selector1.set_sensitive(true);
            mode_selector2.set_sensitive(true);

            file_label.set_sensitive(true);
            file_text_field.set_sensitive(true);
            pwlabel1.set_sensitive(true);
            pwfield1.set_sensitive(true);
            pwlabel2.set_sensitive(false);
            pwfield2.set_sensitive(false);
            crypto_label.set_sensitive(false);
            crypto_box.set_sensitive(false);
            hash_label.set_sensitive(false);
            hash_box.set_sensitive(false);
            hash_strengthen_label.set_sensitive(false);
            hash_strengthen_button.set_sensitive(false);

            progress_indicator.hide();
        } else {
            mode_selector1.set_sensitive(false);
            mode_selector2.set_sensitive(false);

            file_label.set_sensitive(false);
            file_text_field.set_sensitive(false);
            pwlabel1.set_sensitive(false);
            pwfield1.set_sensitive(false);
            pwlabel2.set_sensitive(false);
            pwfield2.set_sensitive(false);
            crypto_label.set_sensitive(false);
            crypto_box.set_sensitive(false);
            hash_label.set_sensitive(false);
            hash_box.set_sensitive(false);
            hash_strengthen_label.set_sensitive(false);
            hash_strengthen_button.set_sensitive(false);

            progress_indicator.show_all();
        }

        run_button.set_sensitive(check_runable());
    }

    /**
     * Check whether the run button should be active
     */
    private bool check_runable() {
        if (this.mode  == Mode.READY_ENCRYPT) {
            if (selected_file == "" || !FileUtils.test(selected_file, FileTest.EXISTS)) {
                return false;
            }
            if (pwfield1.get_text() == "") {
                return false;
            }
            if (pwfield2.get_text() == "") {
                return false;
            }
            if (pwfield1.get_text() != pwfield2.get_text()) {
                return false;
            }
            if (selected_cipher_algo == null) {
                return false;
            }
            if (selected_digest_algo == null) {
                return false;
            }
        } else if (this.mode == Mode.READY_DECRYPT) {
            if (selected_file == "" || !FileUtils.test(selected_file, FileTest.EXISTS)) {
                return false;
            }
            if (pwfield1.get_text() == "") {
                return false;
            }
        } else {
            return false;
        }

        return true;
    }

    private void on_run_button() {
        // Show progress indicator for child process
        GPGProcess process;

        // Spawn child process
        if (this.mode == Mode.READY_ENCRYPT) {
            string input_file = selected_file;

            process = this.gpg_handler.encrypt(
                pwfield1.get_text(),
                input_file,
                selected_cipher_algo,
                selected_digest_algo,
                selected_hash_strengthen);
        } else if (this.mode == Mode.READY_DECRYPT) {
            // Output file will be named like the input file but
            // with .gpg removed if it ends with .gpg input
            // _DECRYPTED will be added as suffix:
            //  - encryptedfile       => encryptedfile_DECRYPTED
            //  - secretphoto.jpg.gpg => secretphoto.jpg

            string input_file = selected_file;
            string output_file;
            if (input_file.length > 4 &&
            input_file.slice(-4, input_file.length) == ".gpg") {
                output_file = input_file.slice(0, -4);
            } else {
                output_file = input_file + "_DECRYPTED";
            }

            process = this.gpg_handler.decrypt(
                pwfield1.get_text(),
                input_file,
                output_file);
        } else {
            // No valid mode selected - error
            stderr.printf("Error: Unknown mode (encrypt/decrypt) selected\n");
            return;
        }

        // Show progress of child process
        this.progress_indicator.set_process(process);
        this.mode = Mode.RUNNING;
    }
}
