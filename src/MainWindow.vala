/*
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
 */

/**
 * Main window of this application.
 */
public class MainWindow : Gtk.Window {

    // Current state for selectable options

    /**
     * Current state of this window
     */
    private State _window_state;
    private State window_state {
        set {
            _window_state = value;
            window_state_changed();
        }
        get {
            return _window_state;
        }
    }

    /**
     * Do not access directly. Use {@link selected_operation}.
     *
     * @see selected_operation
     */
    private GPGOperation _selected_operation;

    /**
     * Currently selected gpg operation
     */
    private GPGOperation selected_operation {
        set {
            _selected_operation = value;

            if (value == GPGOperation.ENCRYPT && operation_selector1 != null) {
                operation_selector1.set_active(true);
            } else if (value == GPGOperation.DECRYPT && operation_selector2 != null) {
                operation_selector2.set_active(true);
            }
            operation_changed();
        }
        get {
            return _selected_operation;
        }
    }

    /**
     * The currently selected input file or empty string if no file
     * has been selected.
     */
    private string? selected_file {
        set {
            if (file_text_field == null) {
                return;
            }

            if (value == null) {
                file_text_field.set_text("");
            } else {
                file_text_field.set_text(value);
            }
        }
        get {
            if (file_text_field == null) {
                return null;
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
        set {
            if (hash_strengthen_button != null) {
                hash_strengthen_button.set_active(value);
            }
        }
        get {
            if (hash_strengthen_button == null) {
                return false;
            }

            return hash_strengthen_button.get_active();
        }
    }

    /**
     * The currently selected compression selection or false if no
     * selection can be determined.
     */
    private bool selected_compression {
        set {
            if (compression_button != null) {
                compression_button.set_active(value);
            }
        }
        get {
            if (compression_button == null) {
                return false;
            }

            return compression_button.get_active();
        }
    }

    /**
     * The currently selected armored selection or false if no
     * selection can be determined.
     */
    private bool selected_armored {
        set {
            if (armored_button != null) {
                armored_button.set_active(value);
            }
        }
        get {
            if (armored_button == null) {
                return false;
            }

            return armored_button.get_active();
        }
    }

    // Available states for selectable options

    /**
     * Possible states this window can be in
     */
    private enum State {
        READY,
        RUNNING,
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

    // Defaults for selectable options

    /**
     * Default operation
     */
    private const GPGOperation DEFAULT_OPERATION = GPGOperation.ENCRYPT;

    /**
     * Default cipher algorithm.
     * This is an array because supported ciphers are gpg version dependant.
     * Use the first value that is supported by gpg as default.
     */
    private const string[] DEFAULT_CIPHER_ALGO = { "TWOFISH", "AES256", "AES" };

    /**
     * Default digest algorithm.
     * This is an array because supported digests are gpg version dependant.
     * Use the first value that is supported by gpg as default.
     */
    private const string[] DEFAULT_DIGEST_ALGO = { "SHA256", "SHA1" };

    /**
     * Default value for hash strengthening
     */
    private const bool DEFAULT_HASH_STRENGTHEN = false;

    /**
     * Default value for gpg compression
     */
    private const bool DEFAULT_COMPRESSION = true;

    /**
     * Default value for armored output
     */
    private const bool DEFAULT_ARMORED = false;

    // Signals

    /**
     * Signal is emitted when window state changes
     */
    private signal void window_state_changed();

    /**
     * Signal is emitted when selected operation is changed
     */
    private signal void operation_changed();

    // Gtk widgets
    #if GPG_GUI_CSD
    private Gtk.HeaderBar header;
    #endif

    private Gtk.Box content;

    private Gtk.RadioButton operation_selector1;
    private Gtk.RadioButton operation_selector2;

    private Gtk.Label file_label;
    private Gtk.Entry file_text_field;
    private Gtk.Button file_button;
    private Gtk.Label pwlabel1;
    private Gtk.Entry pwfield1;
    private Gtk.Label pwlabel2;
    private Gtk.Entry pwfield2;
    private Gtk.Label crypto_label;
    private Gtk.ComboBoxText crypto_box;
    private Gtk.Label hash_label;
    private Gtk.ComboBoxText hash_box;
    private Gtk.Label hash_strengthen_label;
    private Gtk.Switch hash_strengthen_button;
    private Gtk.Label compression_label;
    private Gtk.Switch compression_button;
    private Gtk.Label armored_label;
    private Gtk.Switch armored_button;

    private Gtk.Button run_button;

    private ProgressIndicator progress_indicator;

    /**
     * Handler representing all gpg functionality
     */
    private GPGHandler gpg_handler;

    public MainWindow() {
        Object(type: Gtk.WindowType.TOPLEVEL);
        this.set_position(Gtk.WindowPosition.CENTER);
        this.destroy.connect(Gtk.main_quit);

        this.gpg_handler = new GPGHandler();

        //Set application icon & update application icon if theme changes
        set_application_icon();
        this.style_updated.connect(set_application_icon);

        // Construct window contents
        this.content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.add(this.content);
        build_menu();
        build_gui();
        set_defaults();

        // Connect helper functions to signals
        this.window_state_changed.connect(on_window_state_changed);
        this.operation_changed.connect(on_operation_changed);
    }

    /**
     * Function sets up correct application icon.
     * Function is called everytime icon theme changes.
     */
    private void set_application_icon() {
        const string[] PREFERRED_ICON_NAMES = {
            GPG_GUI_ICON,
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

    /**
     * Helper function for constructor that creates the windows menu(s)
     */
    private void build_menu() {
        // Define actions
        const string action_namespace = "menu";
        GLib.SimpleActionGroup menu_actions = new GLib.SimpleActionGroup();
        {
            var about_action = new SimpleAction("about", null);
            about_action.activate.connect( () => {
                AboutDialog dialog = new AboutDialog(this);
                dialog.present();
            });
            menu_actions.add_action(about_action);
        }
        {
            // ...
        }
        {
            // Define all actions for all menu items here
        }

        // Depending on what kind of menu we want either create a traditional
        // Gtk.MenuBar or use client-side-decorations and create a single
        // menu button in a Gtk.HeaderBar spawning a Gtk.Popover containing
        // the menu.
        #if GPG_GUI_CSD
        {
            // Create client-side titlebar
            header = new Gtk.HeaderBar();
            header.set_title(GPG_GUI_NAME);
            header.set_show_close_button(true);
            this.set_titlebar(header);

            // Button for opening global menu
            var menu_button_image = new Gtk.Image.from_icon_name(
                "open-menu-symbolic",
                Gtk.IconSize.BUTTON);

            var menu_button = new Gtk.MenuButton();
            menu_button.set_image(menu_button_image);
            header.pack_end(menu_button);

            // Popover containing the menu
            var popover = new Gtk.Popover(menu_button);
            popover.insert_action_group(action_namespace, menu_actions);
            menu_button.set_popover(popover);

            // Define menu model
            GLib.Menu global_menu = new GLib.Menu();
            global_menu.append("About", "about");
            popover.bind_model(global_menu, action_namespace);
        }
        #else
        {
            // Set window title (non client-side decorated)
            this.title = GPG_GUI_NAME;

            // Create traditional menu bar
            var menu_bar = new Gtk.MenuBar();
            menu_bar.insert_action_group(action_namespace, menu_actions);
            this.content.add(menu_bar);

            // Define menu model
            GLib.Menu menu = new GLib.Menu();
            menu_bar.bind_model(menu, action_namespace, false);

            GLib.Menu help_menu = new GLib.Menu();
            help_menu.append("About", "about");
            menu.append_submenu("Help", help_menu);
        }
        #endif
    }

    /**
     * Helper function for constructor that creates the GTK interface
     */
    private void build_gui() {
        // Set up main grid
        Gtk.Grid main_grid = new Gtk.Grid();
        main_grid.border_width = 12;
        main_grid.set_row_spacing(10);
        main_grid.set_column_spacing(24);
        main_grid.set_orientation(Gtk.Orientation.VERTICAL);
        this.content.add(main_grid);


        // Encrypt / Decrypt operation buttons
        operation_selector1 = new Gtk.RadioButton.with_label(
            null,
            "Encrypt");
        operation_selector2 = new Gtk.RadioButton.with_label_from_widget(
            operation_selector1,
            "Decrypt");

        operation_selector1.toggled.connect(on_operation_button_select);
        operation_selector2.toggled.connect(on_operation_button_select);

        // Depending on what kind of window titlebar we have (client-side
        // decorated or traditional) we either create two Gtk.RadioButton
        // inside the window content (traditional) or put the Gtk.RadioButton
        // inside a Gtk.StackSwitcher into the titlebar.
        #if GPG_GUI_CSD
        {
            operation_selector1.set_mode(false);
            operation_selector2.set_mode(false);

            // Create button box with css class "linked" to visually link
            // all contained buttons
            Gtk.ButtonBox operation_selector_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
            operation_selector_box.set_layout(Gtk.ButtonBoxStyle.CENTER);
            operation_selector_box.get_style_context().add_class("linked");
            operation_selector_box.add(operation_selector1);
            operation_selector_box.add(operation_selector2);
            header.set_custom_title(operation_selector_box);
        }
        #else
        {
            operation_selector1.set_hexpand(true);
            operation_selector1.set_vexpand(true);
            operation_selector1.set_halign(Gtk.Align.CENTER);
            operation_selector1.set_valign(Gtk.Align.CENTER);
            main_grid.add(operation_selector1);

            operation_selector2.set_hexpand(true);
            operation_selector2.set_vexpand(true);
            operation_selector2.set_halign(Gtk.Align.CENTER);
            operation_selector2.set_valign(Gtk.Align.CENTER);
            main_grid.attach_next_to(
                operation_selector2,
                operation_selector1,
                Gtk.PositionType.RIGHT);
        }
        #endif


        // File chooser
        file_label = new Gtk.Label("File:");
        file_label.set_hexpand(false);
        file_label.set_vexpand(true);
        file_label.set_halign(Gtk.Align.END);
        file_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(file_label);

        file_text_field = new Gtk.Entry();
        file_text_field.set_text("...");
        file_text_field.set_icon_from_icon_name(
            Gtk.EntryIconPosition.PRIMARY,
            "drive-harddisk");
        file_text_field.changed.connect(on_file_text_input);

        Gtk.Image file_button_image = new Gtk.Image.from_icon_name(
            "document-open",
            Gtk.IconSize.BUTTON);
        file_button = new Gtk.Button.with_mnemonic(
            dgettext("gtk30", "_Open"));
        file_button.set_image(file_button_image);
        file_button.set_image_position(Gtk.PositionType.LEFT);
        file_button.clicked.connect(on_file_chooser_button);

        Gtk.Box file_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        file_box.set_homogeneous(false);
        file_box.set_spacing(0);
        main_grid.attach_next_to(file_box, file_label, Gtk.PositionType.RIGHT);

        file_text_field.set_hexpand(true);
        file_text_field.set_vexpand(true);
        file_text_field.set_halign(Gtk.Align.FILL);
        file_text_field.set_valign(Gtk.Align.CENTER);
        file_box.pack_start(file_text_field, true, true);

        file_button.set_hexpand(false);
        file_button.set_vexpand(true);
        file_button.set_halign(Gtk.Align.START);
        file_button.set_valign(Gtk.Align.CENTER);
        file_box.pack_end(file_button, false, false);


        // Password fields
        pwlabel1 = new Gtk.Label("Password:");
        pwlabel1.set_hexpand(false);
        pwlabel1.set_vexpand(true);
        pwlabel1.set_halign(Gtk.Align.END);
        pwlabel1.set_valign(Gtk.Align.CENTER);
        main_grid.add(pwlabel1);

        pwfield1 = new Gtk.Entry();
        pwfield1.set_visibility(false);
        pwfield1.set_input_hints(Gtk.InputHints.NO_SPELLCHECK);
        pwfield1.set_input_purpose(Gtk.InputPurpose.PASSWORD);
        pwfield1.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "dialog-password");
        pwfield1.changed.connect(on_pw_input);
        pwfield1.set_hexpand(true);
        pwfield1.set_vexpand(true);
        pwfield1.set_halign(Gtk.Align.FILL);
        pwfield1.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(pwfield1, pwlabel1, Gtk.PositionType.RIGHT);

        pwlabel2 = new Gtk.Label("Confirm Password:");
        pwlabel2.set_hexpand(false);
        pwlabel2.set_vexpand(true);
        pwlabel2.set_halign(Gtk.Align.END);
        pwlabel2.set_valign(Gtk.Align.CENTER);
        main_grid.add(pwlabel2);

        pwfield2 = new Gtk.Entry();
        pwfield2.set_visibility(false);
        pwfield2.set_input_hints(Gtk.InputHints.NO_SPELLCHECK);
        pwfield2.set_input_purpose(Gtk.InputPurpose.PASSWORD);
        pwfield2.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "dialog-password");
        pwfield2.changed.connect(on_pw_input);
        pwfield2.set_hexpand(true);
        pwfield2.set_vexpand(true);
        pwfield2.set_halign(Gtk.Align.FILL);
        pwfield2.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(pwfield2, pwlabel2, Gtk.PositionType.RIGHT);


        // Crypto selection
        const string crypto_help =
            "TWOFISH and AES256 are the strongest algorithms. AES has hardware "
          + "acceleration support on most platforms and is probably fastest.\n"
          + "OpenPGP compliant algorithms are IDEA, SAFER-SK128, 3DES, CAST5, "
          + "BLOWFISH. Later versions include AES128, AES192, AES256, TWOFISH. "
          + "Even later versions include CAMELLIA.\n"
          + "3DES is required by all OpenPGP implementations.\n"
          + "PGP until version 2.6 only supported IDEA.";

        crypto_label = new Gtk.Label("Encryption Cipher:");
        crypto_label.set_tooltip_text(crypto_help);
        crypto_label.set_hexpand(false);
        crypto_label.set_vexpand(true);
        crypto_label.set_halign(Gtk.Align.END);
        crypto_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(crypto_label);

        crypto_box = new Gtk.ComboBoxText();
        crypto_box.set_tooltip_text(crypto_help);
        crypto_box.changed.connect(refresh_widgets);
        foreach (string algo in cipher_algos) {
            crypto_box.append_text(algo);
        }
        crypto_box.set_hexpand(true);
        crypto_box.set_vexpand(true);
        crypto_box.set_halign(Gtk.Align.FILL);
        crypto_box.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(crypto_box, crypto_label, Gtk.PositionType.RIGHT);


        // Hash selection
        const string hash_help =
            "SHA512 is the strongest algorithm. SHA algorithms have hardware "
          + "acceleration support and are probably fastest.\n"
          + "OpenPGP compliant algorithms are MD2, MD5, RIPE-MD/160, SHA-1. "
          + "Later versions include SHA224, SHA256, SHA384, SHA512.\n"
          + "SHA1 is required by all OpenPGP implementations.";

        hash_label = new Gtk.Label("Hash Algorithm:");
        hash_label.set_tooltip_text(hash_help);
        hash_label.set_hexpand(false);
        hash_label.set_vexpand(true);
        hash_label.set_halign(Gtk.Align.END);
        hash_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(hash_label);

        hash_box = new Gtk.ComboBoxText();
        hash_box.set_tooltip_text(hash_help);
        hash_box.changed.connect(refresh_widgets);
        foreach (string algo in digest_algos) {
            hash_box.append_text(algo);
        }
        hash_box.set_hexpand(true);
        hash_box.set_vexpand(true);
        hash_box.set_halign(Gtk.Align.FILL);
        hash_box.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(hash_box, hash_label, Gtk.PositionType.RIGHT);


        // Hash strengthen button
        const string hash_strengthen_help =
            "Enabling causes gpg to improve s2k passphrase mangling by hashing "
          + "65011712 times. This increases the security against dictionary "
          + "attacks at the cost of encryption time.";

        hash_strengthen_label = new Gtk.Label("Hash Strengthen:");
        hash_strengthen_label.set_tooltip_text(hash_strengthen_help);
        hash_strengthen_label.set_hexpand(false);
        hash_strengthen_label.set_vexpand(true);
        hash_strengthen_label.set_halign(Gtk.Align.END);
        hash_strengthen_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(hash_strengthen_label);

        hash_strengthen_button = new Gtk.Switch();
        hash_strengthen_button.set_tooltip_text(hash_strengthen_help);
        hash_strengthen_button.state_set.connect((b) => {
            refresh_widgets();
            return false;
        });
        hash_strengthen_button.set_hexpand(false);
        hash_strengthen_button.set_vexpand(true);
        hash_strengthen_button.set_halign(Gtk.Align.END);
        hash_strengthen_button.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(
            hash_strengthen_button,
            hash_strengthen_label,
            Gtk.PositionType.RIGHT);


        // Compression button
        const string compression_help =
            "Enabling compression uses the zip algorithm since this is the "
          + "only one that is compatible with PGP. Disabling will break PGP "
          + "compatibility.\n"
          + "Compressing increases entropy and can improve security of the "
          + "encryption.\n"
          + "Using compression on compressable content like text can "
          + "significantly decrease file size. Using compression on "
          + "uncompressable content like images may increase file size "
          + "slightly.";

        compression_label = new Gtk.Label("Compress:");
        compression_label.set_tooltip_text(compression_help);
        compression_label.set_hexpand(false);
        compression_label.set_vexpand(true);
        compression_label.set_halign(Gtk.Align.END);
        compression_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(compression_label);

        compression_button = new Gtk.Switch();
        compression_button.set_tooltip_text(compression_help);
        compression_button.state_set.connect((b) => {
            refresh_widgets();
            return false;
        });
        compression_button.set_hexpand(false);
        compression_button.set_vexpand(true);
        compression_button.set_halign(Gtk.Align.END);
        compression_button.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(
            compression_button,
            compression_label,
            Gtk.PositionType.RIGHT);


        // Armored button
        const string armored_help =
            "Enabling causes output to be wrapped in ASCII armor. This "
          + "significantly increases file size and is not recommended in "
          + "most cases.";

        armored_label = new Gtk.Label("Armored Output:");
        armored_label.set_tooltip_text(armored_help);
        armored_label.set_hexpand(false);
        armored_label.set_vexpand(true);
        armored_label.set_halign(Gtk.Align.END);
        armored_label.set_valign(Gtk.Align.CENTER);
        main_grid.add(armored_label);

        armored_button = new Gtk.Switch();
        armored_button.set_tooltip_text(armored_help);
        armored_button.set_hexpand(false);
        armored_button.set_vexpand(true);
        armored_button.set_halign(Gtk.Align.END);
        armored_button.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(
            armored_button,
            armored_label,
            Gtk.PositionType.RIGHT);


        // Run button (label will be overwritten)
        Gtk.Image run_button_image = new Gtk.Image.from_icon_name(
            "system-run",
            Gtk.IconSize.BUTTON);
        run_button = new Gtk.Button.with_label("Run");
        run_button.set_image(run_button_image);
        run_button.set_image_position(Gtk.PositionType.LEFT);
        run_button.clicked.connect(on_run_button);
        run_button.set_hexpand(true);
        run_button.set_vexpand(true);
        run_button.set_halign(Gtk.Align.END);
        run_button.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(
            run_button,
            armored_button,
            Gtk.PositionType.BOTTOM);


        // Progress indicator
        progress_indicator = new ProgressIndicator();
        progress_indicator.set_hexpand(true);
        progress_indicator.set_vexpand(true);
        progress_indicator.set_halign(Gtk.Align.FILL);
        progress_indicator.set_valign(Gtk.Align.CENTER);
        main_grid.attach_next_to(
            progress_indicator,
            null,
            Gtk.PositionType.BOTTOM,
            2, 1);
        progress_indicator.finished.connect( () => {
            // Return to ready state when gpg process is done
            this.window_state = State.READY;
        });


        // Show all widgets except the progress indicator
        this.show_all();
        progress_indicator.hide();
    }

    /**
     * Apply defaults for selectable options
     */
    private void set_defaults() {
        // Select default mode
        this.selected_operation = DEFAULT_OPERATION;

        // Select the first default algorithm that is supported
        crypto_box.set_active(0);
        foreach (string algo in DEFAULT_CIPHER_ALGO) {
            bool found_algo = false;
            for (int i = 0; i < cipher_algos.length; i++) {
                if (cipher_algos[i] == algo) {
                    crypto_box.set_active(i);
                    found_algo = true;
                    break;
                }
            }
            if (found_algo) {
                break;
            }
        }

        // Set the first default algorithm that is supported
        hash_box.set_active(0);
        foreach (string algo in DEFAULT_DIGEST_ALGO) {
            bool found_algo = false;
            for (int i = 0; i < digest_algos.length; i++) {
                if (digest_algos[i] == algo) {
                    hash_box.set_active(i);
                    found_algo = true;
                    break;
                }
            }
            if (found_algo) {
                break;
            }
        }

        // Set default value for hash strengthening
        selected_hash_strengthen = DEFAULT_HASH_STRENGTHEN;

        // Set default value for compression
        selected_compression = DEFAULT_COMPRESSION;

        // Set default value for armored output
        selected_armored = DEFAULT_ARMORED;

        refresh_widgets();
    }

    /**
     * Set selected operation to given operation
     *
     * @param operation The operation to select
     */
    public void set_operation(GPGOperation operation) {
        this.selected_operation = operation;
    }

    /**
     * Set selected file to given file
     *
     * @param path The file to select
     */
    public void set_file(string path) {
        this.selected_file = path;
    }

    /**
     * This function gets executed if the selected operation changed.
     * It does:
     *
     *  * Update the string of run button according to currently selected operation
     *  * Refresh all widgets
     */
    private void on_operation_changed() {
        // Update lable of run button
        switch (selected_operation) {
            case GPGOperation.ENCRYPT:
                run_button.set_label("Encrypt");
                break;
            case GPGOperation.DECRYPT:
                run_button.set_label("Decrypt");
                break;
            default:
                break;
        }

        // Refresh widgets
        refresh_widgets();
    }

    /**
     * This function gets executed if the current mode of this window changed.
     * It refreshes all widgets.
     */
    private void on_window_state_changed() {
        refresh_widgets();
    }

    /**
     * This function gets executed if a selection via the operation buttons
     * has been made.
     * It changes the currently selected operation.
     */
    private void on_operation_button_select() {
        if (operation_selector1.get_active()) {
            this.selected_operation = GPGOperation.ENCRYPT;
        } else {
            this.selected_operation = GPGOperation.DECRYPT;
        }
    }

    /**
     * This function gets executed if the text of the file entry changed.
     * It refreshes all widgets.
     */
    private void on_file_text_input() {
        refresh_widgets();
    }

    /**
     * This function gets executed if the file chooser button is pressed.
     * It opens a filer chooser for selecting a file.
     */
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

    /**
     * This function gets executed if the text of one of the password
     * text fields changed.
     * It checks whether the content of both passwords fields match
     * and displays a tooltip warning if it does not.
     */
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
     * Set sensitivity of all window widgets depending selected options
     * and state.
     * This function should get executed whenever a selected option
     * changes which could influence the sensitivity of other widgets.
     */
    private void refresh_widgets() {
        if (window_state == RUNNING) {
            operation_selector1.set_sensitive(false);
            operation_selector2.set_sensitive(false);

            file_label.set_sensitive(false);
            file_text_field.set_sensitive(false);
            file_button.set_sensitive(false);
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
            compression_label.set_sensitive(false);
            compression_button.set_sensitive(false);
            armored_label.set_sensitive(false);
            armored_button.set_sensitive(false);

            progress_indicator.show_all();
        } else {
            if (selected_operation == GPGOperation.ENCRYPT) {
                operation_selector1.set_sensitive(true);
                operation_selector2.set_sensitive(true);

                file_label.set_sensitive(true);
                file_text_field.set_sensitive(true);
                file_button.set_sensitive(true);
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
                compression_label.set_sensitive(true);
                compression_button.set_sensitive(true);
                armored_label.set_sensitive(true);
                armored_button.set_sensitive(true);

                progress_indicator.hide();
            } else if (selected_operation == GPGOperation.DECRYPT) {
                operation_selector1.set_sensitive(true);
                operation_selector2.set_sensitive(true);

                file_label.set_sensitive(true);
                file_text_field.set_sensitive(true);
                file_button.set_sensitive(true);
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
                compression_label.set_sensitive(false);
                compression_button.set_sensitive(false);
                armored_label.set_sensitive(false);
                armored_button.set_sensitive(false);

                progress_indicator.hide();
            }
        }

        run_button.set_sensitive(check_runable());
    }

    /**
     * Check whether the run button should be active.
     * Returns true if run button should be clickable, false otherwise.
     */
    private bool check_runable() {
        // If there is already a process running don't start another one
        if (window_state == State.RUNNING) {
            return false;
        }

        if (selected_operation  == GPGOperation.ENCRYPT) {
            if (selected_file == null) {
                return false;
            }
            if (!FileUtils.test(selected_file, FileTest.EXISTS)) {
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
        } else if (selected_operation == GPGOperation.DECRYPT) {
            if (selected_file == null) {
                return false;
            }
            if (!FileUtils.test(selected_file, FileTest.EXISTS)) {
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

    /**
     * This function gets executed if the run button is pressed.
     * It starts the selected gpg operation with the selected options.
     */
    private void on_run_button() {
        // Show progress indicator for child process
        GPGProcess process;

        // Spawn child process
        switch (this.selected_operation) {
        case GPGOperation.ENCRYPT:
            string? input_file = selected_file;
            if (input_file == null) {
                return;
            }

            // Generate encryption output path from input
            string? output_file = encryption_output_path(input_file);
            if (output_file == null) {
                stderr.printf("Error: Could not determine output file from input file\n");
                return;
            }

            process = this.gpg_handler.encrypt(
                pwfield1.get_text(),
                input_file,
                output_file,
                selected_cipher_algo,
                selected_digest_algo,
                selected_hash_strengthen,
                selected_compression,
                selected_armored);

            break;
        case GPGOperation.DECRYPT:
            string? input_file = selected_file;
            if (input_file == null) {
                return;
            }

            // Generate decryption output path from input
            string? output_file = decryption_output_path(input_file);
            if (output_file == null) {
                stderr.printf("Error: Could not determine output file from input file\n");
                return;
            }

            process = this.gpg_handler.decrypt(
                pwfield1.get_text(),
                input_file,
                output_file);

            break;
        default:
            // No valid mode selected
            return;
        }

        // Show progress of child process
        this.progress_indicator.set_process(process);
        this.window_state = State.RUNNING;
    }
}
