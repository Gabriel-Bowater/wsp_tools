#!/usr/bin/env ruby

filename = ARGV[0]

if !ARGV[0] || ["-h","--h","-help","--help"].include?(ARGV[0])
	print "Usage: \nruby wsp_formater.rb <file name> <new file name>\n\n"
	filename = nil
end


new_file_name = ARGV[1]

p "formating file #{filename}" if filename

formatted_lines = Array.new
lines = 0
File.open(filename).each do |line|
	lines +=1
	
	if ["1","2","3","4","5","6","7","8","9","0"].include?(line[0])
		split_line = line.split(",")
		split_line[0] = split_line[0].split(":")
		split_line.flatten!

		#reformating UNIX epoch date to 
		split_line[1] = Time.at(split_line[1].to_i)
		#TODO hardcode for NZ time


		formatted_lines << split_line.flatten.join(",")
	else
		formatted_lines << line
	end
end

puts  "formated #{formatted_lines.length} lines."

#assigning a name if not specified
if !new_file_name
	new_file_name = "#{filename.split(".")[0]}.csv"
end

new_file = File.open(new_file_name, "w+") do |file|
	file.puts(formatted_lines)
end