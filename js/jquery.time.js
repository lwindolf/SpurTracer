/**
 * Time is a jQuery plugin that simply formats Unix timestamps with a
 * reasonable short and yet descriptive date syntax.
 * 
 * @name time
 * @version 0.0.1
 * @requires jQuery v1.4+
 * @author Lars Lindner
 * @license GPLv2 and later or MIT License - http://www.opensource.org/licenses/mit-license.php
 *
 * Copyright (C) 2012 GFZ Deutsches GeoForschungsZentrum Potsdam <lars.lindner@gfz-potsdam.de>
 */

(function($) {
	$.time = function(timestamp) {
		return nice_date(timestamp);
	};
	var $t = $.time;

	$.extend($.time, {

	dayName: new Array("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
	monthName: new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dez"),

	/* simulates some of the format strings of strptime() */
	strptime: function(format, date) {
		var last = -2;
		var result = "";
		var hour = date.getHours();

		/* Expand aliases */
		format = format.replace(/%D/, "%m/%d/%y");
		format = format.replace(/%R/, "%H:%M");
		format = format.replace(/%T/, "%H:%M:%S");

		/* Note: we fail on strings without format characters */

		while(1) {
			/* find next format char */
			var pos = format.indexOf('%', last + 2);

			if(-1 == pos) {
				/* dump rest of text if no more format chars */
				result += format.substr(last + 2);
				break;
			} else {
				/* dump text after last format code */
				result += format.substr(last + 2, pos - (last + 2));

				/* apply format code */
				formatChar = format.charAt(pos + 1);
				switch(formatChar) {
					case '%':
						result += '%';
						break;
					case 'C':
						result += date.getYear();
						break;
					case 'H':
					case 'k':
						if(hour < 10) result += "0";
						result += hour;
						break;
					case 'M':
						if(date.getMinutes() < 10) result += "0";
						result += date.getMinutes();
						break;
					case 'S':
						if(date.getSeconds() < 10) result += "0";
						result += date.getSeconds();
						break;
					case 'm':
						if(date.getMonth() < 10) result += "0";
						result += date.getMonth();
						break;
					case 'a':
					case 'A':
						result += $t.dayName[date.getDay() - 1];
						break;
					case 'b':
					case 'B':
					case 'h':
						result += $t.monthName[date.getMonth()];
						break;
					case 'Y':
						result += date.getFullYear();
						break;
					case 'd':
					case 'e':
						if(date.getDate() < 10) result += "0";
						result += date.getDate();
						break;
					case 'w':
						result += date.getDay();
						break;
					case 'p':
					case 'P':
						if(hour < 12) {
							result += "am";
						} else {
							result += "pm";
						}
						break;
					case 'l':
					case 'I':
						if(hour % 12 < 10) result += "0";
						result += (hour % 12);
						break;
				}
			}
			last = pos;
		}
		return result;
	},

	/* takes a timestamp in seconds since epoch */
	nice_date: function(timestamp) {
		var now = new Date();
		var date = new Date();

		date.setTime(timestamp*1000);

		if(now.getDate() == date.getDate()) 
			return $t.strptime("Today %T", date); 

		if(now.getDate() == date.getDate() + 1) 
			return $t.strptime("Yesterday %T", date); 

		if(Math.abs(now.getDate() - date.getDate) < 7)
			return $t.strptime("%a %T", date);		

		if(now.getMonth() != date.getMonth()) {
			return $t.strptime("%b %d %T", date);
		}

		if(now.getFullYear() != date.getFullYear()) {
			return $t.strptime("%b %d %Y %T", date);
		}
		
	}
});

$.fn.time = function() {
	var self = this;
	self.each(refresh);
	return self;
};

function refresh() {
	var timestamp = $(this).attr("title");

//	if (!isNaN(timestamp)) {
		$(this).text($t.nice_date(timestamp));
//	}
	return this;
}

}(jQuery));
