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

public class GPGProcess {

    public enum State {
        STARTING,
        RUNNING,
        FINISHED
    }

    /**
     * The current state of this process.
     * Access with get_state()
     */
    private State state = State.STARTING;

    /**
     * PID of the child process if started or stopped.
     * -1 if not yet started.
     */
    private int process_pid = -1;

    /**
     * The current stdout output of the child process.
     * Access with get_stdout()
     */
    private string process_stdout = "";

    /**
     * The current stderr output of the child process.
     * Access with get_stderr()
     */
    private string process_stderr = "";

    /**
     * Whether the process exited successfully or with error.
     * Only meaningful when process is in finished state.
     * Access with get_success()
     */
    private bool process_success;

    /**
     * Private variables that when set will (with some delay)
     * emit the corresponding signals in the correct thread.
     */
    private bool _stdout_changed = false;
    private bool _stderr_changed = false;
    private bool _state_changed = false;

    public signal void stdout_changed();
    public signal void stderr_changed();
    public signal void state_changed();

    public GPGProcess(string[] args, string passphrase) {
        // Start process
        start(args, passphrase);

        // Check if state, stdout or stderr changed in asynchronous function
        // and emit signal if they changed.
        Timeout.add(100, () => {
            if (_stdout_changed) {
                stdout_changed();
                lock (_stdout_changed) {
                    _stdout_changed = false;
                }
            }
            if (_stderr_changed) {
                stderr_changed();
                lock (_stderr_changed) {
                    _stderr_changed = false;
                }
            }
            if (_state_changed) {
                state_changed();
                lock (_state_changed) {
                    _state_changed = false;
                }
            }

            return (get_state() == State.FINISHED) ? Source.REMOVE : Source.CONTINUE;
        });
    }

    /**
     * Returns the state the process is currently in.
     */
    public State get_state() {
        lock (state) {
            return state;
        }
    }

    private void set_state(State s) {
        lock (state) {
            state = s;
        }
        lock (_state_changed) {
            _state_changed = true;
        }
    }

    /**
     * Returns stdout of process.
     */
    public string get_stdout() {
        lock (process_stdout) {
            return process_stdout;
        }
    }

    private void set_stdout(string str) {
        lock (process_stdout) {
            process_stdout = str;
        }
        lock (_stdout_changed) {
            _stdout_changed = true;
        }
    }

    /**
     * Returns stderr of process.
     */
    public string get_stderr() {
        lock (process_stderr) {
            return process_stderr;
        }
    }

    private void set_stderr(string str) {
        lock (process_stderr) {
            process_stderr = str;
        }
        lock (_stderr_changed) {
            _stderr_changed = true;
        }
    }

    /**
     * Send SIGINT signal to child process telling it to stop.
     */
    public void stop() {
        if (process_pid > 0) {
            Posix.kill(process_pid, Posix.Signal.INT);
        }
    }

    /**
     * Returns whether the process finished successfully or with errors.
     * Only meaningful output when process is in finished state.
     */
    public bool get_success() {
        lock (process_success) {
            return process_success;
        }
    }

    private void set_success(bool b) {
        lock (process_success) {
            process_success = b;
        }
    }

    private void start(string[] args, string passphrase) {
        // Start gpg process
        int stdin_fd;
        int stdout_fd;
        int stderr_fd;

        try {
            Process.spawn_async_with_pipes(
                ".",
                args,
                Environ.get(),
                SpawnFlags.DO_NOT_REAP_CHILD,
                null,
                out process_pid,
                out stdin_fd,
                out stdout_fd,
                out stderr_fd
            );
        } catch (SpawnError e) {
            stderr.printf("Error starting gpg decryption!");
            stderr.printf(e.message);
        }

        // Set state to running
        set_state(State.RUNNING);

        // Send passphrase to gpg stdin in separate thread
        new Thread<int>("gpg stdin writer", () => {
            FileStream process_stdin = FileStream.fdopen(stdin_fd, "w");
            process_stdin.printf("%s\n", passphrase);
            process_stdin.flush();

            return 0;
        });

        // Add thread that saves all stderr output
        new Thread<int>("gpg stderr watchdog", () => {
            FileStream process_stderr = FileStream.fdopen(stderr_fd, "r");
            StringBuilder builder = new StringBuilder();
            string? line = null;
            while ((line = process_stderr.read_line()) != null) {
                builder.append(line);
                builder.append_c('\n');
                set_stderr(builder.str);
            }

            set_stderr(builder.str);

            return 0;
        });

        // Add thread that saves all stdout output
        new Thread<int>("gpg stdout watchdog", () => {
            FileStream process_stdout = FileStream.fdopen(stdout_fd, "r");
            StringBuilder builder = new StringBuilder();
            string? line = null;
            while ((line = process_stdout.read_line()) != null) {
                builder.append(line);
                builder.append_c('\n');
                set_stdout(builder.str);
            }

            set_stdout(builder.str);

            return 0;
        });

        // Add child watch because we specified DO_NOT_REAP_CHILD
        ChildWatch.add(process_pid, (pid, status) => {
            // Close pid
            Process.close_pid(pid);

            // Set exit status
            try {
                Process.check_exit_status(status);
                set_success(true);
            } catch {
                set_success(false);
            }

            // Set state to finished
            set_state(State.FINISHED);
        });
    }
}
