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

# @param [String] line_name
# @return [none]
def assign_light(line_name)

  puts line_name
  puts @arriving_trains[line_name].length

	@arriving_trains[line_name].each do |arriving_train|
		subbed_arriving_train = arriving_train.gsub!(/[^0-9A-Za-z]/, '_')
		unless subbed_arriving_train.nil?
			arriving_train = subbed_arriving_train
		end
		light_number = @station_lights[line_name][arriving_train]
		unless light_number.nil?
			case line_name
				when 'red_line'
					@lights_serial_array[light_number-1] = 'R'
				when 'blue_line'
					@lights_serial_array[light_number-1] = 'B'
				when 'brown_line'
					@lights_serial_array[light_number-1] = 'W'
				when 'green_line'
					@lights_serial_array[light_number-1] = 'G'
				when 'orange_line'
					@lights_serial_array[light_number-1] = 'O'
				when 'purple_line'
					@lights_serial_array[light_number-1] = 'P'
				when 'pink_line'
					@lights_serial_array[light_number-1] = 'K'
				when 'yellow_line'
					@lights_serial_array[light_number-1] = 'Y'
				else
					puts "I don't know how you got here"
			end
		end
  end

end

def create_serial_string
	@light_serial_string = '<'
	@lights_serial_array.each do |light_on|
		@light_serial_string = @light_serial_string + light_on.to_s
	end
	@light_serial_string = @light_serial_string + '>'
end

api_key = ARGV[0]
test = ARGV[1]

@lights_serial_array = Array.new(25, 0)
@station_lights = YAML.load_file('lights.yml')

unless test
  port_str = '/dev/cu.usbmodem1411'
  baud_rate = 9600
  data_bits = 8
  stop_bits = 1
  parity = SerialPort::NONE
  serial_port = SerialPort.open(port_str, baud_rate, data_bits, stop_bits, parity)
  sleep(4)
end

while true do

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

		@arriving_trains = { 'red_line' => [], 'blue_line' => [], 'brown_line' => [], 'green_line' => [], 'orange_line' => [], 'purple_line' => [], 'pink_line' => [], 'yellow_line' => [] }

		add_arriving_trains(@red_trains_hash,'red_line')
		add_arriving_trains(@blue_trains_hash,'blue_line')
		add_arriving_trains(@brown_trains_hash,'brown_line')
		add_arriving_trains(@green_trains_hash,'green_line')
		add_arriving_trains(@orange_trains_hash,'orange_line')
		add_arriving_trains(@purple_trains_hash,'purple_line')
		add_arriving_trains(@pink_trains_hash,'pink_line')
		add_arriving_trains(@yellow_trains_hash,'yellow_line')

    @lights_serial_array = Array.new(300, 0)
		assign_light('red_line')
    assign_light('blue_line')
    assign_light('brown_line')
    assign_light('green_line')
    assign_light('orange_line')
    assign_light('purple_line')
    assign_light('pink_line')
    assign_light('yellow_line')

		create_serial_string

    if test
      puts @light_serial_string
    else
      serial_port.write(@light_serial_string)
    end

	end

	sleep 5

end