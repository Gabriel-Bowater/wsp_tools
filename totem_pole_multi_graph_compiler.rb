#!/usr/bin/env ruby

$string_numbers = ["1","2","3","4","5","6","7","8","9","0"]
def main

	if ["-h","--h","-help","--help"].include?(ARGV[0]) || ARGV == []
		help_docs
		return		
	end

	passed_in_name = ARGV[0]
	new_file_name = ""

	if passed_in_name[-4..-1]==".csv"
		new_file_name = passed_in_name
	else
		new_file_name = passed_in_name+".csv"
	end

	from_date = ARGV[1]
	to_date = ARGV[2]

	if from_date.length < 10 || to_date.length < 10 && to_date.downcase != "latest"
		raise "You must provide a year, month and date in YYYY-MM-DD format"
	end

	from_year = from_date.split("-")[0].to_i
	from_month = from_date.split("-")[1].to_i
	from_day = from_date.split("-")[2].to_i
	if to_date.downcase == "latest"
		to_year = 9999
		to_month = 13
		to_day = 32
	else
		to_year = to_date.split("-")[0].to_i
		to_month = to_date.split("-")[1].to_i
		to_day = to_date.split("-")[2].to_i
	end

	file = Array.new

	data_resolution_flag = nil

	if  ARGV[3][0]=="-" && $string_numbers.include?(ARGV[3][1])
		data_resolution_flag = ARGV[3][1]
		files = ARGV[4..ARGV.length-1]
	else
		files = ARGV[3..ARGV.length-1]
	end

	compiled_data_by_date = Hash.new

	if data_resolution_flag
		compiled_data_by_date = specified_resolutions_grab(files, from_year, from_month, from_day, to_year, to_month, to_day, data_resolution_flag)
	else
		compiled_data_by_date = all_resolutions_grab(files, from_year, from_month, from_day, to_year, to_month, to_day)
	end

	if compiled_data_by_date.length > 0
		File.open(new_file_name, "w+") do |file|

			head_row = "Date"

			files.each do |string|
				head_row += ",#{string.split("/")[0]} #{string.split("/")[-1].split(".")[0]}"
			end


			file.puts head_row
			compiled_data_by_date.each do |k,v|
				file.puts "#{k},#{v}\n"
			end
		end


		reporting_string = "Compiled #{compiled_data_by_date.length} rows from files #{files} \ninto file #{new_file_name} for dates #{from_date} to #{to_date}"
		if data_resolution_flag
			reporting_string += " at data resolution #{data_resolution_flag}"
		end
		report reporting_string 
	else
		report "No data in range. No output has been written."
	end
end

def all_resolutions_grab(files, from_year, from_month, from_day, to_year, to_month, to_day)
	return_hash = Hash.new
	files.each do |file|
		times_added_from_file = Array.new
		File.open(file).each do |line|
			if $string_numbers.include?(line[0])
				split_line = line.split(",")
				date = split_line[1]
				year = date.split("-")[0].to_i
				month = date.split("-")[1].to_i
				day = date.split("-")[2].to_i
				if (year > from_year) || (year == from_year && month > from_month) || (year == from_year && month == from_month && day >= from_day)
					if (year < to_year) || (year == to_year && month < to_month) || (year == to_year && month == to_month && day <= to_day)
						if return_hash[date] && !times_added_from_file.include?(date)
							#add to the values with a seperating comma
							return_hash[date]= return_hash[date]+","+split_line[2].strip
							times_added_from_file << date
						elsif !times_added_from_file.include?(date)
							#create a new entry
							return_hash[date]= split_line[2].strip
							times_added_from_file << date
						end
					end
				end
			end
		end
		#buffer any rows that have missing enteries
		length = csv_length_check(return_hash)
		return_hash.each do |k,v|
			if return_hash[k].split(",").length < length
				return_hash[k] = v + ","
			end
		end
	end
	return_hash
end

def specified_resolutions_grab(files, from_year, from_month, from_day, to_year, to_month, to_day, data_resolution_flag)
	return_hash = Hash.new

	files.each do |file|
		transcribing = false
		times_added_from_file = Array.new
		File.open(file).each do |line|
			if line.split(",")[0].strip == "Archive #{data_resolution_flag} data:"
				transcribing = true
			elsif line[0] == "A" && transcribing
				transcribing = false
			end

			if transcribing && $string_numbers.include?(line[0])
				split_line = line.split(",")
				date = split_line[1]
				year = date.split("-")[0].to_i
				month = date.split("-")[1].to_i
				day = date.split("-")[2].to_i
				if (year > from_year) || (year == from_year && month > from_month) || (year == from_year && month == from_month && day >= from_day)
					if (year < to_year) || (year == to_year && month < to_month) || (year == to_year && month == to_month && day <= to_day)
						if return_hash[date] && !times_added_from_file.include?(date)
							#add to the values with a seperating comma
							return_hash[date]= return_hash[date]+","+split_line[2].strip
							times_added_from_file << date
						elsif !times_added_from_file.include?(date)
							#create a new entry
							return_hash[date]= split_line[2].strip
							times_added_from_file << date
						end
					end
				end
			end
		end
		#buffer any rows that have missing enteries
		length = csv_length_check(return_hash)
		return_hash.each do |k,v|
			if return_hash[k].split(",").length < length
				return_hash[k] = v + ","
			end
		end
	end
	return_hash
end

def help_docs
	puts "*"*80
	puts "TOTEM POLE CHART COMPILER"
	puts "Usage:"
	puts "~/totem_pole_multi_graph_compiler.rb <output file name> <Starting Timestamp (YYYY-MM-DD).> <Ending Timestamp (YYYY-MM-DD). LATEST to run till end of doc> <Data resolution flag (optional)> <Path to File1> <Path to File2>.... "
	puts "E.g. $~/totem_pole_multi_graph_compiler.rb output.csv 2016-05-28 2016-06-15 -3 file1.csv file2.csv file3.csv /somefolder/file4.csv"
	puts "Data resolution flags:  -0 -1 -2 -3."
	puts "Data resolution flags -0: 10 second step. Available for last hour of file only."  
	puts "Data resolution flags -1: 60 second step (1 minute). Available for last day of file only."  
	puts "Data resolution flags -2: 300 second step (5 minutes). Available for last week of file only."
	puts "Data resolution flags -3: 3600 second step (1 hour). Available for last year of file, usually the entire file range"
	puts "Data resolution flags -4: 86400 second step (1 day). Available for up to the last five years of file, doesn't exist in most files"
	puts "If making a chart that covers a step between data resolutions a DRF is recommended to avoid irregularity of data. Lower resolutions (higher flag numbers) should be favoured "
	puts "*"*80
end

def report(string)
	puts "*"*80
	puts "TOTEM POLE CHART COMPILER"
	puts string
	puts "*"*80
end

def csv_length_check(hash)
	longest = 0
	hash.each do |k,v|
		if hash[k].split(",").length > longest
			longest = hash[k].split(",").length
		end
	end
	longest
end

main
