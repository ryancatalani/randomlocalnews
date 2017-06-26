$(function(){

	var places = [
		"Northern California",
		"New York City",
		"Boston",
		"Washington, DC",
		"Seattle",
		"Minnesota",
		"St. Louis",
		"Michigan",
		"North Carolina",
		"Austin",
		"Southern California",
		"Vermont",
		"Colorado",
		"Mid-Missouri",
		"North Texas",
		"Nashville",
		"Southern Colorado",
		"Rhode Island",
		"Western Colorado",
		"Haines, Skagway, and Klukwan, Alaska",
		"East Texas, Louisiana, Arkansas and Mississippi",
		"Central Southeast Alaska",
		"Alabama",
		"Juneau, Alaska",
		"Montana",
		"Greater Philadelphia",
		"Delaware"
	];

	var placesIndex = Math.floor(Math.random() * places.length);
	window.setInterval(function(){
		$('.places').fadeOut(250, function(){
			$(this).text(places[placesIndex]).fadeIn(250);
			if (placesIndex+1 == places.length) {
				placesIndex = 0;
			} else {
				placesIndex++;	
			}
			
		});
	}, 2000);


	var newscast_data_loaded = false;
	var newscast_data = {};
	$.getJSON('/web_demo.json', function(data) {
		newscast_data = data;
		newscast_data_loaded = true;

		$('#inline_player').attr('src', newscast_data.streamUrl);

		var text = '(You’re listening to headlines from <a href="' + newscast_data.redirectionUrl + '" target="_blank">' + newscast_data.titleText + '</a>.)';
		$('#inline_which').html(text);

		$('.inline_is_loading').fadeOut('fast');
		$('#inline_is_paused').show();
	});

	var inline_is_playing = false;
	$('#inline_player_control').click(function(e) {
		e.preventDefault();

		if (!newscast_data_loaded) {
			return false;
		}

		inline_is_playing = !inline_is_playing;

		if (inline_is_playing) {
			$('#inline_player')[0].play();
			$('#inline_is_playing').show();
			$('#inline_is_paused').hide();
			$('#inline_which').fadeIn('fast');
		} else {
			$('#inline_player')[0].pause();
			$('#inline_is_playing').hide();
			$('#inline_is_paused').show();
			$('#inline_which').hide();
		}

		
		return false;
	});

});