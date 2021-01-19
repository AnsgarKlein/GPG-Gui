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

/**
 * Generate path for encryption output depending on input file
 * used for encryption.
 */
private static string? encryption_output_path(string input_path) {
    const int max_loop = 100;

    // Output file is input file with .gpg appended
    string output_path = input_path + ".gpg";
    if (!File.new_for_path(output_path).query_exists()) {
        return output_path;
    }

    // If input file with .gpg suffix appended already exists keep
    // adding " (x)" suffix:
    //   "input (1).gpg"
    //   "input (2).gpg"
    //   "input (3).gpg"
    //   ...
    // up to a maximum until the file does not already exist.
    StringBuilder builder = new StringBuilder.sized(input_path.length + 8);
    int loop = 1;
    do {
        builder.truncate(0);
        builder.append(input_path);
        builder.append_printf(" (%d).gpg", loop);

        output_path = builder.str;

        // Fail after maximum attempts
        if (loop >= max_loop) {
            return null;
        }

        loop++;
    } while (File.new_for_path(output_path).query_exists());

    return output_path;
}

/**
 * Generate path for decryption output depending on input file
 * used for decryption.
 */
private static string? decryption_output_path(string input_path) {
    string input_dir = Path.get_dirname(input_path);
    string input_file = Path.get_basename(input_path);

    // If input file ends with '.gpg' output file is input file
    // with '.gpg' suffix removed
    if (input_file.length > 4 &&
    input_file.slice(-4, input_file.length) == ".gpg") {
        string output_file = input_file.slice(0, -4);
        string output_path = Path.build_filename(input_dir, output_file);

        if (!File.new_for_path(output_path).query_exists()) {
            return output_path;
        }
    }

    // If input file does not have '.gpg' suffix or file with suffix removed
    // already exists then output file is input file with '.decrypted'
    // appended.
    string output_path = input_path + ".decrypted";

    if (!File.new_for_path(output_path).query_exists()) {
        return output_path;
    }

    // We could not determine output path for given input path
    return null;
}
