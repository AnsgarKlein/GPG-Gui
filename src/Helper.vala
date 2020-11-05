/**
 * Return array of directories from PATH environment variable.
 *
 * Directories are guaranteed to not be a symlink and to exist.
 */
private static string[] get_paths_from_env() {
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

/**
 * Given reference to an array of strings sort it using strcmp.
 * Uses BubbleSort
 */
private static void sort_string_array(ref string[] arr) {
    bool unsorted = true;

    int sort_end = arr.length;
    while (unsorted) {
        unsorted = false;

        for (int i = 1; i < sort_end; i++) {
            if (strcmp(arr[i], arr[i - 1]) < 0) {
                unsorted = true;

                // Swap
                string tmp = arr[i];
                arr[i] = arr[i - 1];
                arr[i - 1] = tmp;
            }
        }

        sort_end--;
    }
}

/**
 * Return array of suggestions of gpg paths
 *
 * Paths might be symlinks
 */
private static string[] gpg_path_suggestions() {
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
