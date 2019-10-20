extends Control

class WeatherData:
	var raw
	var day
	var season
	var temp
	var wind_speed
	var pressure
	
	func process_data():
		var first_day = raw.result["sol_keys"][0]
		day = first_day
		season = raw.result[first_day]["Season"]
		temp = raw.result[first_day]["AT"]
		wind_speed = raw.result[first_day]["HWS"]
		pressure = raw.result[first_day]["PRE"]
		print (day, season, temp, pressure)

func _ready():
	load_data()
	pass

func _process(delta):
	pass

func load_data():
		$HTTPRequest.request("https://api.nasa.gov/insight_weather/?api_key=P8gxeY9hc6frnMc1ACvkY7UlidS59pLrDcL4IeRN&feedtype=json&ver=1.0")
		pass

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var weather : WeatherData = WeatherData.new()
	weather.raw = JSON.parse(body.get_string_from_utf8())
	weather.process_data()
	$MarginContainer/Elements/Season/Info.text = str(weather.day, " ", weather.season)
	$MarginContainer/Elements/Weather/Temp.text = str(weather.temp["av"]," F")
	$"MarginContainer/Elements/Weather/Wind Speed".text = str(weather.wind_speed["av"]," m/s")
	$MarginContainer/Elements/Weather/Pressure.text = str(weather.pressure["av"], " Pa")

	$MarginContainer/Progress.visible = false;
	$MarginContainer/Elements.visible = true;
