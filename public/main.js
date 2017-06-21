$(function(){

	var places = [
		"Northern California",
		"New York City",
		"Boston",
		"Washington, D.C",
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

});