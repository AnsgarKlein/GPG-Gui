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
 * GPGHandler handles the internals of the gpg command line and
 * allows easy access to gpgs symmetric encryption / decryption
 * capabilities.
 */
public class GPGHandler : Object {

    private const string[] DEFAULT_CIPHER_ALGOS = {
        "3DES",
        "AES",
        "AES192",
        "AES256",
        "BLOWFISH",
        "CAMELLIA128",
        "CAMELLIA192",
        "CAMELLIA256",
        "CAST5",
        "TWOFISH",
    };

    private const string[] DEFAULT_DIGEST_ALGOS = {
        "MD5",
        "RIPEMD160",
        "SHA1",
        "SHA224",
        "SHA256",
        "SHA384",
        "SHA512",
    };

    /**
     * List of supported cipher algos of this gpg binary
     */
    private string[] cipher_algos;

    /**
     * List of supported digest algos of this gpg binary
     */
    private string[] digest_algos;
    private string? path = null;

    /**
     * Create a GPGHandler for the default gpg binary. The default gpg binary
     * is the first gpg binary from PATH environment variable
     */
    public GPGHandler() {
        // Try to let GLib find gpg
        path = Environment.find_program_in_path("gpg2");
        if (path == null) {
            path = Environment.find_program_in_path("gpg");
        }

        // Try ourself to find gpg
        if (path == null) {
            string[] gpgs = gpg_path_suggestions();
            if (gpgs.length > 0) {
                path = gpgs[0];
            }
        }

        // Fail if we cannot find a gpg binary
        if (path == null) {
            stderr.printf("Could not find gpg binary\n");
            path = "false";
        }

        parse();
    }

    /**
     * Create a GPGHandler for a given gpg binary.
     */
    public GPGHandler.for_path(string path) {
        // TODO: Test if binary path exists, is binary, etc.
        assert_not_reached();
    }

    /**
     * Run 'gpg --version' for the specific binary and parse its output.
     * Set the supported cipher and digest algorithm corresponding to the
     * output.
     */
    private void parse() {
        string child_stdout;
        string child_stderr;
        int child_exit;

        // Start 'gpg --version' with absolute path and without environment
        // to prevent localization of output
        try {
            Process.spawn_sync(
                ".",
                { this.path, "--version" },
                {},
                0,
                null,
                out child_stdout,
                out child_stderr,
                out child_exit);
        } catch {
            stderr.printf("Error launching gpg");
            child_exit = 1;
        }
        if (child_exit != 0) {
            stderr.printf("%s --version, exit-code: %d\n", this.path, child_exit);
            stderr.printf("%s\n", child_stderr);
        }

        string[] lines = child_stdout.split("\n");
        parse_cipher_algos(lines);
        parse_digest_algos(lines);
    }

    /**
     * Extract line(s) of given array of lines that start with given string
     * as well as all "continuing lines".
     *
     * A continuing line is a line after a line that starts with the given
     * string that starts with at least two spaces.
     *
     * All following continuing lines are appended to the first line (starting
     * with the given string)
     *
     * Returns null if line starting with given string cannot be found at all.
     *
     * @param input Array of line to search in
     * @param starter String indicating the starting line
     * @return Starting line and all continuing lines concatenated or null if
     * starting line cannot be found
     */
    private static string? extract_lines_starting_with(string[] input, string starter) {
        StringBuilder builder = new StringBuilder();

        // Find first line
        int starting_line = -1;
        for (int i = 0; i < input.length; i++) {
            string line = input[i].strip();
            if (line.length <= starter.length) {
                continue;
            }
            if (line[0:starter.length].down() == starter.down()) {
                builder.append(line);
                starting_line = i;
                break;
            }
        }
        if (starting_line == -1) {
            return null;
        }

        // Check for continuing lines
        for (int i = starting_line + 1; i < input.length; i++) {
            string line = input[i].chomp();
            if (line.length > 2 && line[0:2] == "  ") {
                builder.append(" ");
                builder.append(line.chug());
            } else {
                // We found the last continuing line
                break;
            }
        }

        return builder.str;
    }

    /**
     * Given the output of 'gpg --version' extracts the supported cipher
     * algorithms and sets the corresponding variable.
     *
     * @param stdout_lines 'gpg --version' output
     */
    private void parse_cipher_algos(string[] stdout_lines) {
        const string key = "Cipher:";
        string? cipher_str = extract_lines_starting_with(stdout_lines, key);
        if (cipher_str == null || cipher_str.length <= key.length) {
            this.cipher_algos = DEFAULT_CIPHER_ALGOS;
            return;
        }

        cipher_str = cipher_str[key.length:cipher_str.length];
        cipher_str = cipher_str.strip();


        string[] ciphers = cipher_str.split(",");
        for (int i = 0; i < ciphers.length; i++) {
            ciphers[i] = ciphers[i].strip();
        }
        sort_string_array(ref ciphers);

        this.cipher_algos = ciphers;
    }

    /**
     * Given the output of 'gpg --version' extracts the supported digest
     * algorithms and sets the corresponding variable.
     *
     * @param stdout_lines 'gpg --version' output
     */
    private void parse_digest_algos(string[] stdout_lines) {
        const string key = "Hash:";
        string? digest_str = extract_lines_starting_with(stdout_lines, key);
        if (digest_str == null || digest_str.length <= key.length) {
            this.digest_algos = DEFAULT_DIGEST_ALGOS;
            return;
        }

        digest_str = digest_str[key.length:digest_str.length];
        digest_str = digest_str.strip();

        string[] digests = digest_str.split(",");
        for (int i = 0; i < digests.length; i++) {
            digests[i] = digests[i].strip();
        }
        sort_string_array(ref digests);

        this.digest_algos = digests;
    }

    /**
     * Returns list of supported cipher algos of this gpg binary.
     *
     * @return list of supported cipher algos of this gpg binary
     */
    public unowned string[] get_cipher_algos() {
        return this.cipher_algos;
    }

    /**
     * Returns list of supported digest algos of this gpg binary.
     *
     * @return list of supported digest algos of this gpg binary
     */
    public unowned string[] get_digest_algos() {
        return this.digest_algos;
    }

    /**
     * Start a GPG process for encrypting a given file.
     *
     * @param passphrase The passphrase for encrypting the given file
     * @param input_file The path of the file to encrypt
     * @param output_file The path to write encrypted file to
     * @param cipher_algo What cipher algorithm to use in encryption process
     * @param digest_algo What digest algorithm to use in encryption process
     * @param digest_strengthen Whether to increase s2k passphrase mangling
     * @param compress Whether to compress the output
     * @param armor Whether to wrap the output in ASCII armor
     *
     * @return GPGProcess that handles the started process
     *
     * @see GPGProcess
     */
    public GPGProcess encrypt(
            string passphrase,
            string input_file,
            string output_file,
            string? cipher_algo,
            string? digest_algo,
            bool digest_strengthen,
            bool compress,
            bool armor) {

        Array<string> args = new Array<string>();
        args.append_val(this.path);
        args.append_val("--batch");
        args.append_val("--no-tty");
        args.append_val("--symmetric");
        args.append_val("--passphrase-fd");
        args.append_val("0");

        // Specify digest algorithm
        if (digest_algo != null) {
            if (digest_strengthen) {
                args.append_val("--s2k-digest-algo");
                args.append_val(digest_algo);
            } else {
                args.append_val("--digest-algo");
                args.append_val(digest_algo);
            }
        }
        if (digest_strengthen) {
            args.append_val("--s2k-mode");
            args.append_val("3");
            args.append_val("--s2k-count");
            args.append_val("65011712");
        }

        // Specify cipher algorithm
        if (cipher_algo != null) {
            args.append_val("--cipher-algo");
            args.append_val(cipher_algo);
        }

        // Compress output if desired
        if (compress) {
            args.append_val("--compress-level");
            args.append_val("9");
            args.append_val("--compress-algo");
            args.append_val("zip");
        } else {
            args.append_val("--compress-algo");
            args.append_val("none");
        }

        // Use ASCII armored output if desired
        if (armor) {
            args.append_val("--armor");
        }

        // Specify output file
        args.append_val("--output");
        args.append_val(output_file);

        // Specify input file
        args.append_val(input_file);

        // Start encryption
        return start_process(args.data, passphrase);
    }

    /**
     * Start a GPG process for decrypting a given file.
     *
     * @param passphrase The passphrase for decrypting the given file
     * @param input_file The path of the file to decrypt
     * @param output_file The path to write decrypted file to
     *
     * @return GPGProcess that handles the started process
     *
     * @see GPGProcess
     */
    public GPGProcess decrypt(
            string passphrase,
            string input_file,
            string output_file) {

        Array<string> args = new Array<string>();
        args.append_val(this.path);
        args.append_val("--batch");
        args.append_val("--no-tty");
        args.append_val("--passphrase-fd");
        args.append_val("0");
        args.append_val("--decrypt");
        args.append_val("--output");
        args.append_val(output_file);
        args.append_val(input_file);

        // Start decryption
        return start_process(args.data, passphrase);
    }

    /**
     * Helper function for encrypt / decrypt functions that creates a
     * GPG process with given arguments.
     *
     * @param args The arguments to use for the GPG process
     * @param passphrase The passphrase to use for the GPG process
     *
     * @see encrypt
     * @see decrypt
     */
    private inline GPGProcess start_process(string[] args, string passphrase) {
        // Start process
        GPGProcess process = new GPGProcess(args, passphrase);

        process.state_changed.connect(() => {
            if (process.get_state() != GPGProcess.State.FINISHED) {
                return;
            }

            // Print stdout
            {
                string[] out_lines = process.get_stdout().split("\n");
                for (int i = 0; i < out_lines.length; i++) {
                    string line = out_lines[i];
                    if (i + 1 != out_lines.length || line != "") {
                        stdout.printf("stdout: %s\n", line);
                    }
                }
            }

            // Print stderr
            {
                string[] err_lines = process.get_stderr().split("\n");
                for (int i = 0; i < err_lines.length; i++) {
                    string line = err_lines[i];
                    if (i + 1 != err_lines.length || line != "") {
                        stdout.printf("stderr: %s\n", line);
                    }
                }
            }

            if (process.get_success()) {
                stdout.printf("GPG: Success\n");
            } else {
                stdout.printf("GPG: Failure\n");
            }
        });

        return process;
    }
}
