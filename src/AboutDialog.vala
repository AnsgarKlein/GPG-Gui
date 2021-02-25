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
 * Short version of the GPLv3+ license text.
 * Full version at: [[http://www.gnu.org/licenses/]]
 */
private const string GPL3_LICENSE_SHORT =
"""This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses""";

public Gtk.AboutDialog show_about_dialog(Gtk.Window parent) {
    Gtk.AboutDialog dialog = new Gtk.AboutDialog();
    dialog.set_destroy_with_parent(true);
    dialog.set_transient_for(parent);
    dialog.set_modal(true);

    dialog.set_program_name(GPG_GUI_NAME);
    dialog.set_comments("Graphical user interface for GnuPG (GPG) file encryption");
    dialog.set_logo_icon_name(GPG_GUI_ICON);
    dialog.set_license(GPL3_LICENSE_SHORT);
    dialog.set_website(GPG_GUI_WEBSITE);
    dialog.set_website_label("GitHub");
    dialog.set_version(GPG_GUI_VERSION);

    return dialog;
}
