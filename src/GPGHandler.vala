/**
 * Return array of suggestions of gpg paths
 *
 * Paths might be symlinks
 */
private string[] gpg_path_suggestions() {
    // Look in all paths from PATH environment variable
    string[] paths = get_paths_from_env();

    // Search for gpg2 as well as gpg binaries
    const string[] application_names = { "gpg2", "gpg" };

    Array<string> suggestions = new Array<string>();

    foreach (string application in application_names) {
        foreach (string path in paths) {
            File directory = File.new_for_path(path);
            File binary = directory.get_child(application);
            if (binary.query_exists()) {
                suggestions.append_val(binary.get_path());
            }
        }
    }

    // Search for application names in all paths and add them to suggestions

    return suggestions.data;
}

/**
 * Return array of directories from PATH environment variable.
 *
 * Directories are guaranteed to not be a symlink and to exist.
 */
private string[] get_paths_from_env() {
    // Get PATH variable from environment
    string? path_env = Environ.get_variable(Environ.get(), "PATH");

    // If PATH environment variable is not set we dont have any suggestions
    if (path_env == null) {
        return {};
    }

    string[] paths_env = path_env.split(":");

    Array<string> paths = new Array<string>();

    foreach (string path in paths_env) {
        File file = File.new_for_path(path);

        // Ignore paths that don't exist
        if (file.query_exists() == false) {
            continue;
        }

        // Follow symlinks
        try {
            while (file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null) == FileType.SYMBOLIC_LINK) {
                FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
                file = File.new_for_path(file_info.get_symlink_target());
            }
        } catch (Error e) {
            stderr.printf("Error %s\n", e.message);
            continue;
        }

        // Ignore everything that is not a directory
        if (file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null) != FileType.DIRECTORY) {
            continue;
        }

        paths.append_val(file.get_path());
    }

    return paths.data;
}

public class GPGHandler : Object {

    private string? path = null;

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
        // TODO: Fail gracefully if gpg binary cannot be found
    }

    public GPGHandler.for_path(string path) {
        // TODO: Test if binary path exists, is binary, etc.
        assert(false);
    }

    /**
     * Return list of supported cipher algos of this gpg binary
     */
    public unowned string[] get_cipher_algos() {
        // This is only a placeholder
        // TODO: Parse `gpg --version` output
        const string[] cipher_algos = {
            "3DES",
            "CAST5",
            "BLOWFISH",
            "AES",
            "AES192",
            "AES256",
            "TWOFISH",
            "CAMELLIA128",
            "CAMELLIA192",
            "CAMELLIA256"
        };
        return cipher_algos;
    }

    /**
     * Return list of supported digest algos of this gpg binary
     */
    public unowned string[] get_digest_algos() {
        // This is only a placeholder
        // TODO: Parse `gpg --version` output
        const string[] digest_algos = {
            "MD5",
            "SHA1",
            "RIPEMD160",
            "SHA224",
            "SHA256",
            "SHA384",
            "SHA512"
        };
        return digest_algos;
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

        // TODO: replace this with --output option
        // Write gpg stdout to target file
        FileStream stdout_stream = FileStream.fdopen(stdout_fd, "r");
        FileStream output_stream = FileStream.open(output_file, "w");

        const int BUF_STDOUT_LEN = 4096;
        uint8 buf_stdout[BUF_STDOUT_LEN];
        size_t t_stdout;
        while ((t_stdout = stdout_stream.read(buf_stdout, 1)) != 0) {
            output_stream.write(buf_stdout[0:t_stdout], 1);
        }

        // Forward child stderr to application stderr
        FileStream stderr_stream = FileStream.fdopen(stderr_fd, "r");

        const int BUF_STDERR_LEN = 4096;
        uint8 buf_stderr[BUF_STDERR_LEN];
        size_t t_stderr;
        while ((t_stderr = stderr_stream.read(buf_stderr, 1)) != 0) {
            stderr.write(buf_stderr[0:t_stderr], 1);
        }
    }
}
