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
 * Application entry point of this application
 *
 * @param args Command line arguments for this application
 */
private int main(string[] args) {
    // Check if threads are supported
    if (!Thread.supported()) {
        stderr.printf("Threads are not supported!\n");
        stderr.printf("Cannot run without thread support!\n");
        return 1;
    }

    // Set default locale according to user selection
    Intl.setlocale(LocaleCategory.ALL, "");

    // Set textdomain
    Intl.textdomain(GETTEXT_PACKAGE);

    // Initialize Gtk
    #if GPG_GUI_GTK_VERSION_MAJOR_THREE
        // This removes all Gtk specific command line options from array
        Gtk.init(ref args);
    #endif
    #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
        Gtk.init();
    #endif

    MainWindow window;
    {
        // Parse application specific command line options
        int move_on;
        string? arg_file = null;
        GPGOperation? arg_op = null;
        new CLIParser(args, out move_on, out arg_op, out arg_file);

        // Check whether we should continue with application launch
        if (move_on != 0) {
            return (move_on < 0) ? 0 : 1;
        }

        // Create main window and apply parsed application parameters
        window = new MainWindow();
        if (arg_file != null) {
            window.set_file(arg_file);
        }
        if (arg_op != null) {
            window.set_operation(arg_op);
        }
    }
    window.show();

    // Start main loop
    MainLoop main_loop = new MainLoop();
    #if GPG_GUI_GTK_VERSION_MAJOR_THREE
        window.destroy.connect(() => {
            main_loop.quit();
        });
    #endif
    #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
        window.close_request.connect(() => {
            main_loop.quit();
            return false;
        });
    #endif
    main_loop.run();

    return 0;
}

/**
 * Parser of command line arguments.
 */
private class CLIParser {
    private static bool cli_decrypt;
    private static bool cli_encrypt;
    private static string cli_file;
    private static bool cli_help;
    private static bool cli_version;

    /**
     * Defines the command line arguments this application accepts.
     */
    private const OptionEntry[] cli_options = {
        {
            "decrypt", 'd',
            OptionFlags.NONE, OptionArg.NONE,
            ref cli_decrypt,
            "Start gpg-gui in decryption mode",
            null
        },
        {
            "encrypt", 'e',
            OptionFlags.NONE, OptionArg.NONE,
            ref cli_encrypt,
            "Start gpg-gui in encryption mode",
            null
        },
        {
            "file", 'f',
            OptionFlags.NONE, OptionArg.STRING,
            ref cli_file,
            "Start gpg-gui with FILE selected for encryption / decryption",
            "FILE"
        },
        {
            "help", 'h',
            OptionFlags.NONE, OptionArg.NONE,
            ref cli_help,
            "Print this help and exit",
            null
        },
        {
            "version", '\0',
            OptionFlags.NONE, OptionArg.NONE,
            ref cli_version,
            "Print version and exit",
            null
        },
        {
            null
        }
    };

    /**
     * Creates a new CLIParser that immediately begins to parse the given
     * arguments.
     *
     * @param status Status code indicating whether to continue with
     * application execution with the following meaning:
     * status < 0 means abort execution and return 0 (SUCCESS) exit code.
     * status > 0 means abort execution and return 1 (ERROR) exit code.
     * status == 0 means continue execution.
     * @param operation GPG operation set on command line (null if not set)
     * @param file file to open set on command line (null if not set)
     */
    public CLIParser(string[] args,
                     out int status,
                     out GPGOperation? operation,
                     out string file) {
        // Set default values for static variables
        set_default();

        // Parse command line arguments
        status = parse_command_line(args);

        // Assign parsed arguments to out variables
        if (cli_decrypt) {
            operation = GPGOperation.DECRYPT;
        } else if (cli_encrypt) {
            operation = GPGOperation.ENCRYPT;
        } else {
            operation = null;
        }
        file = cli_file;

        // Set static variables back to default
        set_default();
    }

    /**
     * Set static variables responsible for storing parsed command line
     * parameters to default value.
     */
    private void set_default() {
        CLIParser.cli_decrypt = false;
        CLIParser.cli_encrypt = false;
        CLIParser.cli_file = null;
        CLIParser.cli_help = false;
        CLIParser.cli_version = false;
    }

    /**
     * Parse given command line arguments
     *
     * @param args Command line arguments to parse
     *
     * @return Status code indicating whether to continue with application
     * execution with the following meaning:
     * status < 0 means abort execution and return 0 (SUCCESS) exit code.
     * status > 0 means abort execution and return 1 (ERROR) exit code.
     * status == 0 means continue execution.
     */
    private int parse_command_line(string[] args) {
        // We have to make an extra copy of the array, since .parse
        // assumes that it can remove strings from the array without
        // freing them.
        //string[] args = command_line.get_arguments();
        string[] args_copy = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            args_copy[i] = args[i];
        }

        // Set up option context for command line parsing
        var opt_context = new OptionContext("");
        opt_context.set_help_enabled(false);
        opt_context.set_ignore_unknown_options(false);
        {
            StringBuilder builder = new StringBuilder();
            builder.printf(
                "%s always starts with a GUI. Options can be preselected via command line options though.",
                GPG_GUI_NAME);
            opt_context.set_summary(builder.str);
        }
        {
            StringBuilder builder = new StringBuilder();
            builder.printf(
                "If you encounter any bugs please report them at %s",
                GPG_GUI_WEBSITE);
            opt_context.set_description(builder.str);
        }
        opt_context.add_main_entries(cli_options, null);
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            opt_context.add_group(Gtk.get_option_group(true));
        #endif

        // Parse command line arguments
        try {
            unowned string[] tmp = args_copy;
            opt_context.parse(ref tmp);
        } catch (OptionError e) {
            stderr.printf("Error: %s\n", e.message);
            stderr.printf(opt_context.get_help(false, null));
            return 1;
        }

        // Extract parsed command line options
        if (cli_help) {
            stdout.printf(opt_context.get_help(false, null));
            return -1;
        }

        if (cli_version) {
            stdout.printf("%s\n", GPG_GUI_VERSION);
            return -1;
        }

        GPGOperation? arg_op = null;
        if (cli_decrypt) {
            arg_op = GPGOperation.DECRYPT;
        }
        if (cli_encrypt) {
            arg_op = GPGOperation.ENCRYPT;
        }
        string? arg_file = null;
        if (cli_file != null) {
            arg_file = cli_file;
        }

        return 0;
    }
}
