require 'open-uri'
require 'xmlsimple'
require 'yaml'
require 'serialport'

def add_arriving_trains(train_hash, line_name)
	if train_hash
		train_hash.each do |train|
			if train['isApp'].include? '1'
				@arriving_trains[line_name].push(train['nextStaNm'][0])
			end	
		end
	end
end

def add_arriving_trains_to_light_array(line_name)
	@arriving_trains[line_name].each do |arriving_train|
		subbed_arriving_train = arriving_train.gsub!(/[^0-9A-Za-z]/, '_')
		if !subbed_arriving_train.nil?
			arriving_train = subbed_arriving_train
		end
		light_number = @station_lights[line_name][arriving_train]
		if !light_number.nil?
			@lights_serial_array[light_number-1] = 1
		end
	end
end

def create_serial_string
	@light_serial_string = ''
	@lights_serial_array.each do |light_on|
		@light_serial_string = @light_serial_string + light_on.to_s + ','
	end

	@light_serial_string = @light_serial_string + 'x'
end

api_key = ARGV[0]
@lights_serial_array = Array.new(25, 0)

trains = open("http://lapi.transitchicago.com/api/1.0/ttpositions.aspx?key=#{api_key}&rt=red&rt=blue&rt=brn&rt=G&rt=Org&rt=P&rt=Pink&rt=Y")
response_status = trains.status
response_body = trains.read

if response_status.include? '200'
	
	# MAP ALL TRAINS TO CORRESPONDING LINE HASH MAP
	routes_hash = XmlSimple.xml_in(response_body)['route']
	routes_hash.each do |route|
		case route['name']
		when 'red'
  		@red_trains_hash = route['train']
		when 'blue'
  		@blue_trains_hash = route['train']
		when 'brn'
  		@brown_trains_hash = route['train']
		when 'g'
  		@green_trains_hash = route['train']
		when 'org'
  		@orange_trains_hash = route['train']
  	when 'p'
  		@purple_trains_hash = route['train']
  	when 'pink'
  		@pink_trains_hash = route['train']
  	when 'y'
  		@yellow_trains_hash = route['train']
		else
  		puts 'Does not mapp to a station'
		end
	end

	@arriving_trains = { "red_line" => [], "blue_line" => [], "brown_line" => [], "green_line" => [], "orange_line" => [], "purple_line" => [], "pink_line" => [], "yellow_line" => [] }

	add_arriving_trains(@red_trains_hash,'red_line')
	add_arriving_trains(@blue_trains_hash,'blue_line')
	add_arriving_trains(@brown_trains_hash,'brown_line')
	add_arriving_trains(@green_trains_hash,'green_line')
	add_arriving_trains(@orange_trains_hash,'orange_line')
	add_arriving_trains(@purple_trains_hash,'purple_line')
	add_arriving_trains(@pink_trains_hash,'pink_line')
	add_arriving_trains(@yellow_trains_hash,'yellow_line')
	

	puts @arriving_trains
	
	@station_lights = YAML.load_file('lights.yml')

	add_arriving_trains_to_light_array('red_line')

	create_serial_string
	
	puts @light_serial_string

end