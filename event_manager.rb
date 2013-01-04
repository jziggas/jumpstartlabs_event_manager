# Dependencies
require "sunlight"
require "csv"

# Class Definition
class EventManager
	INVALID_ZIPCODE = "00000"
	INVALID_PHONE_NUMBER = "0000000000"
	Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

	def initialize filename
		puts "EventManager Initialized."
		@file = CSV.open(filename, {headers: true, header_converters: :symbol})
	end

	def print_names
		@file.each do |line|
			puts line[:first_name] + ' ' + line[:last_name]
			#puts line.inspect
		end
	end

	def print_numbers
    @file.each do |line|
      number = clean_number(line[:homephone])
      puts number
    end
  end

	def clean_number original
		number = original.gsub(/[\.+\-+\(+\)\s+]/, '')
			if number.length == 10
				# Do nothing
			elsif number.length == 11
				if number.start_with?("1")
					number = number[1..-1]
				else
					number = INVALID_PHONE_NUMBER
				end
			else
				number = INVALID_PHONE_NUMBER
			end
		number
	end

	def print_zipcodes
		@file.each do |line|
			zipcode = clean_zipcode(line[:zipcode])
			puts zipcode
		end
	end

	def clean_zipcode original
		result = original
		if original.nil?
			result = INVALID_ZIPCODE	# If it is nil, it's junk
		elsif original.length < 5
			(5 - original.length).downto(1) do
				result = "0" + result
			end
		else
			# Do nothing
		end

		result
	end

	def output_data filename
		output = CSV.open(filename, "w")
		@file.each do |line|
			if @file.lineno == 2
				output << line.headers
			end
			line[:homephone] = clean_number(line[:homephone])
			line[:zipcode] = clean_zipcode(line[:zipcode])
			output << line
		end
	end

	def rep_lookup
		5.times do
			line = @file.readline

			representative = "unknown"
			# API Lookup goes here
			legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))

			names = legislators.collect do |leg|
				first_name = leg.firstname
				first_initial = first_name[0]
				last_name = leg.lastname
				party = leg.party[0]
				title = leg.title[0..2]

				"#{title} #{first_initial}. #{last_name} (#{party})"
			end

			puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, Representatives: #{names.join(',')}"
		end
	end

	def create_form_letters
		letter = File.open("form_letter.html", "r").read
		20.times do
			line = @file.readline

			# Do string substitutions here
			custom_letter = letter.gsub("#first_name", line[:first_name].to_s)
			custom_letter = custom_letter.gsub("#last_name", line[:last_name].to_s)
			custom_letter = custom_letter.gsub("#street", line[:street].to_s)
			custom_letter = custom_letter.gsub("#city", line[:city].to_s)
			custom_letter = custom_letter.gsub("#state", line[:state].to_s)
			custom_letter = custom_letter.gsub("#zipcode", line[:zipcode].to_s)

			filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
			output = File.new(filename, "w")
			output.write(custom_letter)
		end
	end

	def rank_times
		hours = Array.new(24){0}
		@file.each do |line|
			#count here
			hour = line[:regdate].split[1].split(':')[0].to_i
			hours[hour] += 1
		end
		hours.each_with_index{|counter, hour| puts "#{hour}\t#{counter}"}
	end

	def day_stats
		days = Array.new(7){0}
		@file.each do |line|
			date = Date.strptime(line[:regdate], "%m/%d/%y")
			days[date.wday] += 1
		end
		days.each_with_index { |counter, day| puts "#{day}\t#{counter}"}
	end

	def state_stats
		state_data = {}
		@file.each do |line|
			state = line[:state]
			if state_data[state].nil?
				state_data[state] = 1
			else
				state_data[state] += 1
			end
		end
		# This tutorial is making a misleading statement, "Thankfully hash has a method named sort_by..."
		# When in the following line it is actually turning the state data into an array, then sorting. Beware!
		#ranks = state_data.sort_by{|state, counter| -counter}.collect{|state,counter| state}
		#state_data = state_data.select{|state, counter| state}.sort_by{|state, counter| state unless state.nil? }
		#state_data.each do |state, counter|
		#	puts "#{state}\t#{counter}\t(#{ranks.index(state) + 1})"
		#end
		ranks = state_data.sort_by{|state, counter| counter}.collect{|state, counter| state}
		state_data = state_data.select{|state, counter| state}.sort_by{|state, counter| state}

		state_data.each do |state, counter|
		  puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})"
		end
	end

end

# Script
manager = EventManager.new "event_attendees.csv"
#manager.output_data "event_attendees_clean.csv"
manager.create_form_letters