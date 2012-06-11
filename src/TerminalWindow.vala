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


using Gtk;
using Vte;

public class TerminalWindow : Gtk.Window {
	
	Gtk.Window father;
	
	public TerminalWindow(Gtk.Window father, string command) {
		GLib.Object(type: Gtk.WindowType.TOPLEVEL);
		this.father = father;
		
		if (is_composited()) {
			this.set_opacity(0.9);
		}
		this.set_modal(true);
		//this.set_transient_for(null);
		this.set_transient_for(father);		//keep on top of main window
		this.set_keep_above(true);
		this.set_modal(true);				//prevent interaction with other windows
		
		Gtk.VBox mainbox = new Gtk.VBox(false,0);
		this.add(mainbox);
		
		TermWidget termw = new TermWidget(command);
		mainbox.pack_start(termw);
		
		Gtk.Button closeButton = new Gtk.Button.with_label("Close");
		closeButton.set_sensitive(false);
		closeButton.pressed.connect( () => { this.destroy(); } );
		termw.child_exited.connect( () => { closeButton.set_sensitive(true); } );
		mainbox.pack_start(closeButton);
		
		stdout.printf(this.get_modal().to_string()+"\n");
		stdout.printf(this.get_opacity().to_string()+"\n");
		
		//this.destroy.connect(Gtk.main_quit);
		
		this.show_all();
	}
}

public class TermWidget : Vte.Terminal {
	
	private string shell = get_shell();
	
	public TermWidget(string command) {
		GLib.Object();		//replacement for calling base() constructor
		Gdk.Color fg_color;
		Gdk.Color bg_color;
		Gdk.Color.parse("#ss55rr",out fg_color);
		Gdk.Color.parse("#ffff00",out bg_color);
		this.set_color_foreground(fg_color);
		this.set_color_background(bg_color);
		//this.set_colors_rgba(Gdk.RGBA.red, null, null);
		
		this.set_opacity(32767);		// 0 <-> 65535
		//this.set_background_transparent(true);
		
		this.set_scroll_on_keystroke(true);
		this.set_scroll_on_output(true);
		this.set_emulation("xterm");	//"Unless you know what you do, always use 'xterm'."
		
		
		this.shell = this.get_shell();
		string[] args = {};
		
		try {
			GLib.Shell.parse_argv(this.shell, out args);
			
			this.fork_command_full(PtyFlags.DEFAULT,"/",args,null,SpawnFlags.DO_NOT_REAP_CHILD,null, null);
		}
		catch (ShellError e) {
			stderr.printf("Error occured while parsing shell value: \n");
			stderr.printf(e.message+"\n");
		}
		catch (Error e) {
			stderr.printf("Error occured while creating Terminal: \n");
			stderr.printf(e.message+"\n");
		}
		
		//string[] command1 = {};
		//GLib.Shell.parse_argv("ls", out command1);
		//this.fork_command_full(PtyFlags.DEFAULT,"/",command1,null,SpawnFlags.DO_NOT_REAP_CHILD,null, null);
		
		this.feed_child(command+" && exit\n",-1);
	}
	
	private static string get_shell() {
		//unowned string? shell = GLib.Environment.get_variable("SHELL");
		string? shell = Vte.get_user_shell();
		
		//Basically the same ? +++++++++++++++++++++++++++++++++++++++++++
		//stdout.printf(GLib.Environment.get_variable("SHELL")+"\n");	//+
		//stdout.printf(get_user_shell()+"\n");							//+
		//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		if(shell == null) {
			shell = "/bin/sh";
		}
		
		return (!)(shell);
	}
	
}
