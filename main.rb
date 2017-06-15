require 'smarter_csv'
require 'rss'

def station_title(data)
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

def newscast_url(data)
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
		rescue
			# log
		end
	end

	if !url.nil? && url.split('.').last =~ /mp4|mp3|wav/
		return url
	else
		return nil
	end
end

newscasts = SmarterCSV.process('newscasts.csv')

newscasts_easy = newscasts.select{|a| !a[:direct_url].nil? || !a[:feed_url].nil? }
random_newscast_data = newscasts_easy.shuffle.first

puts station_title(random_newscast_data)
puts newscast_url(random_newscast_data)


