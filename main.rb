require 'dotenv/load'
require 'smarter_csv'
require 'rss'
require 'sinatra'
require 'time'
require 'json'
require 'staccato'

class Newscast
	attr_reader :station_title, :newscast_url, :station_url, :callsign

	def initialize(data, **args)
		@station_title = args[:station_title] || self.class.get_station_title(data) || nil
		@newscast_url = args[:newscast_url] || self.class.get_newscast_url(data) || nil
		@station_url = args[:station_url] || data[:station_url] || nil
		@callsign = args[:callsign] || data[:station] || nil
	end

	def self.get_random_newscast(**args)
		newscasts = SmarterCSV.process('newscasts.csv')
		newscasts_easy = newscasts.select{|a| !a[:direct_url].nil? || !a[:feed_url].nil? }
		
		random_newscast_data = newscasts_easy.shuffle.first
		newscast_url = self.get_newscast_url(random_newscast_data, args)

		if newscast_url.nil?
			while newscast_url.nil?
				random_newscast_data = newscasts_easy.shuffle.first
				newscast_url = self.get_newscast_url(random_newscast_data, args)
			end
		end

		Newscast.new(random_newscast_data, newscast_url: newscast_url)
	end

	def self.find_by_callsign(callsign)
		newscasts = SmarterCSV.process('newscasts.csv')
		newscast_found = newscasts.select{|a| a[:station].downcase == callsign.downcase}.first
		Newscast.new(newscast_found)
	end

	def self.alexa_capable_count
		capable_newscasts = []
		
		newscasts = SmarterCSV.process('newscasts.csv')
		newscasts_easy = newscasts.select{|a| !a[:direct_url].nil? || !a[:feed_url].nil? }
		newscasts_easy.each do |n|
			newscast_url = self.get_newscast_url(n, alexa_capable: true)
			capable_newscasts << n unless newscast_url.nil?
		end

		puts "Count: #{capable_newscasts.count}"
		capable_newscasts.each{|n| puts n.inspect}
		return capable_newscasts.count
	end

	private

	def self.get_station_title(data)
		ret = [data[:station]]

		if !data[:name].nil?
			ret << ', '
			ret << data[:name]
		end

		if !data[:location].nil?
			ret << ', from '
			ret << data[:location]
		end

		ret.join('')
	end

	def self.get_newscast_url(data, **args)
		url = nil

		if !data[:direct_url].nil?
			url = data[:direct_url]
		elsif !data[:feed_url].nil?
			begin
				rss = RSS::Parser.parse(data[:feed_url], false)

				if !data[:feed_filter].nil?
					filter_on, filter_term = data[:feed_filter].split(':')
					filtered_rss = rss.items.select {|item| item.public_send(filter_on).to_s.downcase.include?(filter_term) }
					url = filtered_rss.first.enclosure.url
				else
					url = rss.items.first.enclosure.url
				end
			rescue => e
				puts "Error on #{data[:feed_url]}"
				puts e
			end
		end

		format_check = /mp4|mp3|m4a|wav/
		if args[:alexa_capable]
			format_check = /mp4|mp3|m4a/
		end

		if !url.nil? && url.split('.').last =~ format_check
			return url
		else
			return nil
		end
	end

end

enable :sessions

helpers do
	def staccato_track_event(opts={})
		if @staccato_tracker.nil?
			tracking_id = settings.development? ? ENV['GA_DEV'] : ENV['GA_PROD']
			if session[:ga_client_id]
				ga_client_id = session[:ga_client_id]
			else
				ga_client_id = session[:ga_client_id] = Staccato.build_client_id
			end
			@staccato_tracker = Staccato.tracker(tracking_id, ga_client_id, ssl: true)
		end

		ga_options = {
			data_source: 'sinatra',
			user_ip: request.ip,
			user_agent: request.user_agent,
			referrer: request.referer,
			user_language: request.env['HTTP_ACCEPT_LANGUAGE']
		}.merge(opts)

		@staccato_tracker.event(ga_options)
	end
end

get '/afb' do
	content_type :json

	staccato_track_event({
		category: 'Alexa',
		action: 'Activate Flash Briefing'
	})

	newscast = Newscast.get_random_newscast(alexa_capable: true)
	domain = settings.development? ? "https://34efde41.ngrok.io" : "https://randomlocalnews.herokuapp.com"

	ret = {
		uid: "#{newscast.callsign}-#{Time.now.utc.iso8601}",
		updateDate: Time.now.utc.iso8601,
		titleText: "Local headlines from #{newscast.station_title}",
		mainText: "",
		streamUrl: "#{domain}/afb/audio/#{newscast.callsign}",
		redirectionUrl: newscast.station_url
	}

	JSON.pretty_generate(ret)
end

get '/afb/audio/:callsign' do

	staccato_track_event({
		category: 'Alexa',
		action: 'Get Flash Briefing Audio',
		label: params[:callsign]
	})

	newscast = Newscast.find_by_callsign(params[:callsign])
	redirect newscast.newscast_url
end