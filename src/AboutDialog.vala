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

public class AboutDialog : Gtk.AboutDialog {
    public AboutDialog(Gtk.Window parent) {
        set_destroy_with_parent(true);
        set_transient_for(parent);
        set_modal(true);

        set_program_name(GPG_GUI_NAME);
        set_comments("Graphical user interface for GnuPG (GPG) file encryption");
        set_logo_icon_name(GPG_GUI_ICON);
        set_license(GPL3_LICENSE_SHORT);
        set_website(GPG_GUI_WEBSITE);
        set_website_label("GitHub");
        set_version(GPG_GUI_VERSION);
    }
}
