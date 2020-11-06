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

    private string[] cipher_algos;
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
        assert(false);
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
     * A continuing line is a line after a line that starts with the given
     * string that starts with at least two spaces.
     * All following continuing lines are appended to the first line (starting
     * with the given string)
     *
     * Returns null if line starting with given string cannot be found at all.
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
     * Return list of supported cipher algos of this gpg binary
     */
    public unowned string[] get_cipher_algos() {
        return this.cipher_algos;
    }

    /**
     * Return list of supported digest algos of this gpg binary
     */
    public unowned string[] get_digest_algos() {
        return this.digest_algos;
    }

    public void encrypt(
            string passphrase,
            string input_file,
            string? cipher_algo,
            string? digest_algo,
            bool digest_strengthen) {

        Array<string> argv = new Array<string>();
        argv.append_val(this.path);
        argv.append_val("--batch");
        argv.append_val("--no-tty");
        argv.append_val("--symmetric");
        argv.append_val("--passphrase-fd");
        argv.append_val("0");

        // Specify digest algorithm
        if (digest_algo != null) {
            if (digest_strengthen) {
                argv.append_val("--s2k-digest-algo");
                argv.append_val(digest_algo);
            } else {
                argv.append_val("--digest-algo");
                argv.append_val(digest_algo);
            }
        }
        if (digest_strengthen) {
            argv.append_val("--s2k-mode");
            argv.append_val("3");
            argv.append_val("--s2k-count");
            argv.append_val("65011712");
        }

        // Specify cipher algorithm
        if (cipher_algo != null) {
            argv.append_val("--cipher-algo");
            argv.append_val(cipher_algo);
        }

        // Specify input file
        argv.append_val(input_file);

        // Start encryption
        int stdin_fd;
        int stdout_fd;
        int stderr_fd;

        try {
            Process.spawn_async_with_pipes(
                ".",
                argv.data,
                Environ.get(),
                0,
                null,
                null,
                out stdin_fd,
                out stdout_fd,
                out stderr_fd
            );
        } catch (SpawnError e) {
            stderr.printf("Error starting gpg encryption!");
            stderr.printf(e.message);
        }

        // Send passphrase to gpg stdin
        FileStream stdin_stream = FileStream.fdopen(stdin_fd, "w");
        stdin_stream.printf("%s\n", passphrase);
        stdin_stream.flush();

        // Forward child stderr to application stderr
        // TODO: only forward stderr on non-0 exit code
        FileStream stderr_stream = FileStream.fdopen(stderr_fd, "r");

        const int BUF_LEN = 4096;
        uint8 buf[BUF_LEN];
        size_t t;
        while ((t = stderr_stream.read(buf, 1)) != 0) {
            stderr.write(buf[0:t], 1);
        }
    }

    public void decrypt(
            string passphrase,
            string input_file,
            string output_file) {

        Array<string> argv = new Array<string>();
        argv.append_val(this.path);
        argv.append_val("--batch");
        argv.append_val("--no-tty");
        argv.append_val("--passphrase-fd");
        argv.append_val("0");
        argv.append_val("--decrypt");
        argv.append_val("--output");
        argv.append_val(output_file);
        argv.append_val(input_file);

        // Start decryption
        int stdin_fd;
        int stdout_fd;
        int stderr_fd;

        try {
            Process.spawn_async_with_pipes(
                ".",
                argv.data,
                Environ.get(),
                0,
                null,
                null,
                out stdin_fd,
                out stdout_fd,
                out stderr_fd
            );
        } catch (SpawnError e) {
            stderr.printf("Error starting gpg decryption!");
            stderr.printf(e.message);
        }

        // Send passphrase to gpg stdin
        FileStream stdin_stream = FileStream.fdopen(stdin_fd, "w");
        stdin_stream.printf("%s\n", passphrase);
        stdin_stream.flush();

        // Forward child stderr to application stderr
        // TODO: only forward stderr on non-0 exit code
        FileStream stderr_stream = FileStream.fdopen(stderr_fd, "r");

        const int BUF_STDERR_LEN = 4096;
        uint8 buf_stderr[BUF_STDERR_LEN];
        size_t t_stderr;
        while ((t_stderr = stderr_stream.read(buf_stderr, 1)) != 0) {
            stderr.write(buf_stderr[0:t_stderr], 1);
        }
    }
}
