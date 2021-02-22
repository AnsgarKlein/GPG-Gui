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
    // This removes all Gtk specific command line options from array
    Gtk.init(ref args);

    // Parse application specific command line options
    string? arg_file = null;
    GPGOperation? arg_op = null;
    for (int i = 1; i < args.length; i++) {
        string arg1 = args[i];
        string arg2 = (i + 1) > args.length ? null : args[i + 1];

        if (arg1 == "-d" || arg1 == "--decrypt") {
            arg_op = GPGOperation.DECRYPT;
        } else if (arg1 == "-e" || arg1 == "--encrypt") {
            arg_op = GPGOperation.ENCRYPT;
        } else if (arg1 == "-f" || arg1 == "--file") {
            if (arg2 == null) {
                stderr.printf("Expected file after \"%s\"\n", arg1);
                print_help(args[0]);
                return 1;
            }
            arg_file = arg2;
            i++;
        } else if (arg1 == "-h" || arg1 == "--help") {
            print_help(args[0]);
            return 0;
        } else if (arg1 == "--version") {
            stdout.printf("%s\n", GPG_GUI_VERSION);
            return 0;
        } else {
            stderr.printf("Unknown option \"%s\"\n", arg1);
            print_help(args[0]);
            return 1;
        }
    }

    // Create main window and apply parsed application parameters
    var window = new MainWindow();
    if (arg_file != null) {
        window.set_file(arg_file);
    }
    if (arg_op != null) {
        window.set_operation(arg_op);
    }

    // Start gtk main loop
    Gtk.main();

    return 0;
}

/**
 * Print help about command line arguments to stdout.
 *
 * @param application_name The application name that was used to start this
 * application. Normally this is recorded in the first (zeroth) command line
 * parameter.
 */
private void print_help(string application_name) {
    stdout.printf("%s [OPTIONS]\n", application_name);
    stdout.printf("\n");
    stdout.printf("gpg-gui always starts with a GUI. Options can be preselected via command line\n");
    stdout.printf("options though.\n");
    stdout.printf("\n");
    stdout.printf("OPTIONS\n");
    stdout.printf("  -d, --decrypt         Start gpg-gui in decryption mode\n");
    stdout.printf("  -e, --encrypt         Start gpg-gui in encryption mode\n");
    stdout.printf("  -f FILE, --file FILE  Start gpg-gui with FILE selected for\n");
    stdout.printf("                        encryption / decryption\n");
    stdout.printf("  -h, --help            Print this help and exit\n");
    stdout.printf("  --version             Print version and exit\n");
}
