#-*- coding: utf-8 -*-
require 'json'
require 'net/http'
require 'open-uri'

module WoopraRailsSDK
	class WoopraTracker
		@@default_config = {
			domain: "", 
			cookie_name: "wooTracker",
			cookie_domain: "",
			cookie_path: "/",
			ping: true,
			ping_interval: 12000,
			idle_timeout: 300000,
			download_tracking: true,
			outgoing_tracking: true,
			download_pause: 200,
			outgoing_pause: 400,
			ignore_query_url: true,
			hide_campaign: false,
			ip_address: "",
			cookie_value: ""
		}
		def initialize(request)
			@request = request
			@current_config = @@default_config
			@custom_config = {}
			@user = {}
			@events = []
			@user_up_to_date = true
			@has_pushed = false
			@current_config[:domain] = @request.host
			@current_config[:cookie_domain] = @request.host
			@current_config[:ip_address] = get_client_ip
			@current_config[:cookie_value] = @request.cookies["cookie_name"] || random_cookie
			return self
		end

		def config(data)
			data.each do |key, value|
				if @@default_config.has_key?(key)
					@current_config[key] = value
					if key != :ip_address && key != :cookie_value
						@custom_config[key] = value
					end	
				end
			end
		end

		def identify(user)
			@user = user
			@user_up_to_date = false
			return self
		end

		def track(event_name = nil, event_data = nil, back_end_tracking = false)
			if back_end_tracking
				woopra_http_request(true, [event_name, event_data])
			else
				@events << [event_name, event_data]
			end
			return self
		end

		def push(back_end_tracking = false)
			if not @user_up_to_date
				if back_end_tracking
					woopra_http_request(false)
				else
					has_pushed = true
				end
			end
		end

		def js_code
			code = "\n" + '<!-- Woopra code starts here -->'.html_safe + "\n"
			code += '<script>'.html_safe + "\n"
			code += '   (function(){'.html_safe + "\n"
			code += '   var t,i,e,n=window,o=document,a=arguments,s="script",r=["config","track","identify","visit","push","call"],c=function(){var t,i=this;for(i._e=[],t=0;r.length>t;t++)(function(t){i[t]=function(){return i._e.push([t].concat(Array.prototype.slice.call(arguments,0))),i}})(r[t])};for(n._w=n._w||{},t=0;a.length>t;t++)n._w[a[t]]=n[a[t]]=n[a[t]]||new c;i=o.createElement(s),i.async=1,i.src="//static.woopra.com/js/w.js",e=o.getElementsByTagName(s)[0],e.parentNode.insertBefore(i,e)'.html_safe + "\n"
			code += '   })("woopra");'.html_safe + "\n"
			if @custom_config.length != 0
				code += "   woopra.config(".html_safe + @custom_config.to_json.html_safe + ");".html_safe + "\n"
			end
			if not @user_up_to_date
				code += "   woopra.identify(".html_safe + @user.to_json.html_safe + ");".html_safe + "\n"
			end
			for event in @events
				if event[0] == nil
					code += "   woopra.track();".html_safe + "\n"
				else
					code += "   woopra.track('".html_safe + event[0].html_safe + "', ".html_safe + event[1].to_json.html_safe + ");".html_safe + "\n"
				end
			end
			if @has_pushed
				code += "   woopra.push();".html_safe + "\n"
			end
			code += "</script>".html_safe + "\n"
			code += "<!-- Woopra code ends here -->".html_safe + "\n"
			return code.html_safe
		end

		def set_woopra_cookie(cookies)
			cookies[@current_config[:cookie_name]] = @current_config[:cookie_value]
		end

		private

		def woopra_http_request(is_tracking, event = nil)
			base_url = "www.woopra.com"
			get_params = {}

			# Configuration
			get_params["host"] = @current_config[:domain].to_s
			get_params["cookie"] = @current_config[:cookie_value].to_s
			get_params["ip"] = @current_config[:ip_address].to_s
			get_params["timeout"] = @current_config[:idle_timeout].to_s

			# Identification
			@user.each do |key, value|
				get_params["cv_" + key.to_s] = value.to_s
			end

			if not is_tracking
				url = "/track/identify/?"
				get_params.each do |key, value|
					url += URI::encode(key) + "=" + URI::encode(value) + "&"
				end
				url = url[0..-1]
			else
				if event == nil
					get_params["ce_name"] = "pv"
					get_params["ce_url"] = @request.url.to_s
				else
					get_params["ce_name"] = event[0].to_s
					event[1].each do |key, value|
						get_params["ce_" + key.to_s] = value.to_s
					end
				end
				url = "/track/ce/?"
				get_params.each do |key, value|
					url += URI::encode(key) + "=" + URI::encode(value) + "&"
				end
				url = url[0..-1]
			end
			http = Net::HTTP.new(base_url)
			req = Net::HTTP::Get.new(url, {'User-Agent' => @request.env['HTTP_USER_AGENT']})
			response = http.request(req)
		end

		def random_cookie
			o = [('0'..'9'), ('A'..'Z')].map { |i| i.to_a }.flatten
			return (0...12).map{ o[rand(o.length)] }.join
		end

		def get_client_ip
			return @request.env['HTTP_X_FORWARDED_FOR'] || @request.remote_ip
		end

	end
end