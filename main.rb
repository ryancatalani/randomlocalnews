require 'smarter_csv'
require 'rss'
require 'sinatra'
require 'time'
require 'json'

class Newscast
	attr_reader :station_title, :newscast_url, :station_url, :callsign

	def initialize(data, **args)
		@station_title = args[:station_title] || self.class.get_station_title(data) || nil
		@newscast_url = args[:newscast_url] || self.class.get_newscast_url(data) || nil
		@station_url = args[:station_url] || data[:station_url] || nil
		@callsign = args[:callsign] || data[:station] || nil
	end

	def self.get_random_newscast
		newscasts = SmarterCSV.process('newscasts.csv')
		newscasts_easy = newscasts.select{|a| !a[:direct_url].nil? || !a[:feed_url].nil? }
		
		random_newscast_data = newscasts_easy.shuffle.first
		newscast_url = self.get_newscast_url(random_newscast_data)

		if newscast_url.nil?
			while newscast_url.nil?
				random_newscast_data = newscasts_easy.shuffle.first
				newscast_url = self.get_newscast_url(random_newscast_data)
			end
		end

		Newscast.new(random_newscast_data, newscast_url: newscast_url)
	end

	def self.find_by_callsign(callsign)
		newscasts = SmarterCSV.process('newscasts.csv')
		newscast_found = newscasts.select{|a| a[:station].downcase == callsign.downcase}.first
		Newscast.new(newscast_found)
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

	def self.get_newscast_url(data)
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
				puts e
			end
		end

		if !url.nil? && url.split('.').last =~ /mp4|mp3|wav/
			return url
		else
			return nil
		end
	end

end

get '/afb' do
	content_type :json

	newscast = Newscast.get_random_newscast
	domain = settings.development? ? "https://34efde41.ngrok.io" : "TKTK"

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
	newscast = Newscast.find_by_callsign(params[:callsign])
	redirect newscast.newscast_url
end