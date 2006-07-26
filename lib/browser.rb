require "#{ENV['TM_SUPPORT_PATH']}/lib/plist"

module Browser
  class << self
    def load_url(url)
      browsers = [
        { :name => "Camino",  :id => "org.mozilla.camino" },
        { :name => "OmniWeb", :id => "com.omnigroup.omniweb5" },
        { :name => "Safari",  :id => "com.apple.safari" },
        { :name => "Safari",  :id => "org.webkit.nightly.webkit" },
      ]

      fav = favorite.to_s.downcase
      browsers.each do |browser|
        if fav == browser[:id] && %x{ps -xc|grep -sq #{browser[:name]}} then
          return if self.send(browser[:id].tr('.', '_') + '_did_load?', url)
        end
      end

      %x{open '#{url}'}
    end

    def favorite
      rec = nil
      open(File.expand_path("~/Library/Preferences/com.apple.LaunchServices.plist")) do |io|
        rec = PropertyList.load(io)["LSHandlers"].find { |info| info["LSHandlerURLScheme"] == "http" }
      end
    rescue
    ensure
      return rec ? rec["LSHandlerRoleAll"] : nil
    end

    def org_mozilla_camino_did_load?(url)
      %x{osascript <<'APPLESCRIPT'
      	tell app "Camino"
      		if windows is not { }
      			set the_url to URL of first window
      			if the_url is "#{url}" then
      				activate
      				do javascript "window.location.reload();"
      				return true
      			end if
      		end if
      	end tell
APPLESCRIPT} =~ /true/
    end

    def com_omnigroup_omniweb5_did_load?(url)
      %x{osascript <<'APPLESCRIPT'
      	tell app "OmniWeb"
        	if browsers is not { }
        		set the_url to address of first browser
        		if the_url is "#{url}" then
        			activate
        			tell app "System Events" to keystroke "r" using {command down}
        			return true
        		end if
        	end if
        end tell
APPLESCRIPT} =~ /true/
    end

    def com_apple_safari_did_load?(url)
      %x{osascript <<'APPLESCRIPT'
      	tell app "Safari"
      		if documents is not { }
      			set the_url to URL of first document
      			if the_url is "#{url}" then
      				activate
      				do JavaScript "window.location.reload();" in first document
      				return true
      			end if
      		end if
      	end tell
APPLESCRIPT} =~ /true/
    end

    def org_webkit_nightly_webkit_did_load?(url)
      %x{osascript <<'APPLESCRIPT'
      	tell app "WebKit"
      		if documents is not { }
      			set the_url to URL of first document
      			if the_url is "#{url}" then
      				activate
      				do JavaScript "window.location.reload();" in first document
      				return true
      			end if
      		end if
      	end tell
APPLESCRIPT} =~ /true/
    end
  end
end
