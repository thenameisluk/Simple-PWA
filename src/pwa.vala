// compile: valac --pkg gtk4 --pkg webkitgtk-6.0 --pkg glib-2.0 pwa.vala -o pwa

using Gtk;
using WebKit;

public class PwaApp : Gtk.Application {
    private string target_url;
    private string data_dir;

	private WebView webview;
	private ApplicationWindow window;

	bool rounded_favicon = true;//TODO: cmdline option or sth?

    public PwaApp (string url) {
        Object (application_id:get_domain_from_url(url) ,flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    public static string get_domain_from_url (string url) {
		return Uri.parse(url,NONE).get_host();
    }

    private string build_data_dir (string url) {//all data will be stored in ~/.local/share/pwa
        string domain = get_domain_from_url (url);
        string datadir = GLib.Path.build_filename (Environment.get_user_data_dir (), "pwa", domain);
        DirUtils.create_with_parents (datadir, 0700);
        return datadir;
    }

    private void setup_persistent_cookies (WebView webview) {//because we want to see cookie dialog only once
		var network_session = webview.network_session;
		
        CookieManager cookie_manager = network_session.get_cookie_manager();

        string cookie_file = GLib.Path.build_filename (data_dir, "cookies.sqlite");
		print(@"cookies at : $(cookie_file)");
        cookie_manager.set_persistent_storage (cookie_file, CookiePersistentStorage.SQLITE);
    }
	private void enable_favicon(WebView webview){//they are disabled by default
		webview.get_network_session().get_website_data_manager().set_favicons_enabled(true);
	}

	private void disable_pinch_zoom(WebView webview){//this doesn't work, webkit seams to just ignore this property
		//if someone manages to find another way, feel free to submit a pr

		UserStyleSheet block_pinch_zoom = new UserStyleSheet(
															 "body {touch-action: pan-x pan-y !important;}",
															 ALL_FRAMES,
															 AUTHOR, null,null);
		
		webview.get_user_content_manager().add_style_sheet(block_pinch_zoom);
	}

	public void onload(){//updates window title
		window.title = webview.get_title();
	}
	
	public void favicon(){//save favicons to disk
		if(rounded_favicon){
			save_rounded_favicon(webview.favicon,webview.favicon.get_width()/8);
		}else{
			save_favicon(webview.favicon);
		}
		
	}

    public override void activate () {
		webview =  new WebView ();
		window = new ApplicationWindow (this);
		
		setup_persistent_cookies (webview);
		enable_favicon(webview);
		//disable_pinch_zoom(webview);//broken

		// webview.get_settings().enable_developer_extras = true;
		
        window.decorated = false;

		webview.load_changed.connect(onload);
		webview.notify["favicon"].connect(favicon);
        webview.load_uri (target_url);

        window.set_child (webview);
        window.present ();
    }

	public override int command_line (ApplicationCommandLine cmdline) {
		string[] args = cmdline.get_arguments();
		
		string url = args[1];

		target_url = url;
		data_dir = build_data_dir (target_url);
		
        activate ();
        cmdline.set_exit_status (0);
        return 0;
    }


	
    public static int main (string[] args) {
		if(args.length!=2){
			print("please provide the url and only the url");
			return 2;
		}
		
		var app = new PwaApp (args[1]);//while i would love to parse it in the function above
		//gtk will yell at me if i set the application id too
		//and it's very important for icon to display propertly
		
        return app.run (args);
    }

	//favicon stuff
	//i keep it down since it's not really that important yet it might scare sb off from  reading the actual code

	
	public Cairo.ImageSurface Texture2Surface(Gdk.Texture source){//because we cannot do it in any move convenient way
		int w = source.get_width ();
		int h = source.get_height ();
		Cairo.ImageSurface source_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, w, h);

		unowned uchar[] data = source_surface.get_data ();
		int stride = source_surface.get_stride ();

		source.download( data, stride);
		source_surface.mark_dirty ();

		return source_surface;
	}

    public void save_rounded_favicon (Gdk.Texture source, double radius) {
		int w = source.get_width ();
		int h = source.get_height ();
		double r = double.min (radius, double.min (w, h) / 2.0);

		Cairo.ImageSurface source_surface = Texture2Surface(source);

		Cairo.ImageSurface rounded_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, w, h);
		Cairo.Context cr = new Cairo.Context (rounded_surface);

		cr.new_sub_path ();
		cr.arc (w - r, r, r, -Math.PI_2, 0);               // />
		cr.arc (w - r, h - r, r, 0, Math.PI_2);             // \>
		cr.arc (r, h - r, r, Math.PI_2, Math.PI);           // </
		cr.arc (r, r, r, Math.PI, Math.PI + Math.PI_2);     // <\
		cr.close_path ();
		cr.clip ();

		cr.set_operator (Cairo.Operator.SOURCE);
		cr.set_source_surface (source_surface, 0, 0);
		cr.paint ();

	    save_relevent_favicon_sizes(rounded_surface);
	}

	public void save_favicon(Gdk.Texture source){

		save_relevent_favicon_sizes(Texture2Surface(source));
	}

	public Cairo.ImageSurface resize_surface(Cairo.ImageSurface src,int size){
		Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, size, size);
		Cairo.Context context = new Cairo.Context (surface);

		double scale = (double)size/(double)src.get_width();
		
		context.scale(scale,scale);
		context.set_source_surface(src,0,0);
		context.paint();

		return surface;
	}

	public void save_relevent_favicon_sizes(Cairo.ImageSurface src){
		const int[] sizes = {16,24,32,48,64,96,128,192,256};//these are all directories i have on my machine so yes

		foreach(int size in sizes){
			if(src.get_width()<size)
				continue;

			Cairo.ImageSurface output;

			if(src.get_width()==size){
				output = src;
			}else{
				output = resize_surface(src,size);
			}


			string domain = get_domain_from_url(target_url);//.replace(".","_");
			
			
			string icon_file = GLib.Path.build_filename(Environment.get_user_data_dir (),@"/icons/hicolor/$(size)x$(size)/apps/",@"$(domain).png");
			//this might fail if no parent directory?

			output.write_to_png(icon_file);
			print(@"saved icon : $(icon_file)\n");
		}
	}
}