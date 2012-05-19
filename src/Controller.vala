using Gtk;

static void main(string[] args) {
	stdout.printf("\n");
	
	Gtk.init(ref args);
	new MainFrame();
	Gtk.main();
	
	stdout.printf("\n");
}
