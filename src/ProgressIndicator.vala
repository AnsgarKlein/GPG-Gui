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
 * Progress indicator for a running gpg process.
 * Consists of a progress bar and a button for canceling the process.
 */
public class ProgressIndicator : Gtk.Box {

    /**
     * The gpg process this widget monitors the progress of.
     * null if not currently monitoring the progress of any process.
     */
    private GPGProcess? gpg_process;

    private Gtk.ProgressBar progress_bar;
    private Gtk.Button abort_button;

    /**
     * Indicates that the process has stopped and this indicator is not
     * expected to show any more progress.
     * Does not indicate whether process finished successfully.
     */
    public signal void finished();

    /**
     * Creates a new ProgressIndicator widget with a given GPG process.
     *
     * @param gpg_process The process to monitor the progress of
     * or null to not monitor any process.
     */
    public ProgressIndicator(GPGProcess? gpg_process = null) {
        build_gui();
        base.hide.connect(on_hide);
        base.show.connect(on_show);

        set_process(gpg_process);
    }

    private void build_gui() {
        // Progress bar
        progress_bar = new Gtk.ProgressBar();
        progress_bar.set_text("Progress");
        progress_bar.set_show_text(true);
        progress_bar.set_fraction(0.0);
        progress_bar.set_pulse_step(0.3);
        progress_bar.set_hexpand(true);
        progress_bar.set_vexpand(true);
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            this.add(progress_bar);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
            this.append(progress_bar);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            progress_bar.show();
        #endif


        // Abort button
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            Gtk.Image abort_button_image = new Gtk.Image.from_icon_name(
                "_Cancel",
                Gtk.IconSize.BUTTON);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
            Gtk.Image abort_button_image = new Gtk.Image.from_icon_name(
                "_Cancel");
        #endif

        abort_button = new Gtk.Button.with_mnemonic(
            dgettext("gtk30", "_Cancel"));
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            abort_button.set_image(abort_button_image);
            abort_button.set_image_position(Gtk.PositionType.LEFT);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
            abort_button.set_child(abort_button_image);
        #endif
        abort_button.clicked.connect(on_abort_button);
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            this.add(abort_button);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_FOUR
            this.append(abort_button);
        #endif
        #if GPG_GUI_GTK_VERSION_MAJOR_THREE
            abort_button.show();
        #endif
    }

    private void on_hide() {
        this.abort_button.hide();
        this.progress_bar.hide();
    }

    private void on_show() {
        this.abort_button.show();
        this.progress_bar.show();
    }

    /**
     * Set gpg process this progress indicator should monitor.
     *
     * Set to null to stop monitoring the current process
     * (This will *not* stop the process, only the monitoring!)
     *
     * @param gpg_process The process to monitor the progress of
     * or null to stop monitoring.
     */
    public void set_process(GPGProcess? gpg_process) {
        this.gpg_process = gpg_process;

        if (gpg_process == null) {
            return;
        }

        // Poll gpg process and update progress bar
        Timeout.add(100, () => {
            if (this.gpg_process == null) {
                return Source.REMOVE;
            }

            if (this.gpg_process.get_state() == GPGProcess.State.STARTING) {
                progress_bar.set_fraction(0.0);
                return Source.CONTINUE;
            } else if (this.gpg_process.get_state() == GPGProcess.State.FINISHED) {
                progress_bar.set_fraction(1.0);
                finished();
                return Source.REMOVE;
            } else {
                progress_bar.pulse();
                return Source.CONTINUE;
            }
        });
    }

    /**
     * This function gets executed if the abort button is clicked.
     */
    private void on_abort_button() {
        if (gpg_process != null) {
            gpg_process.stop();
        }
    }
}
