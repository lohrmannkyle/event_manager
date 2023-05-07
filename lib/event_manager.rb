require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(number)
    number = number.to_s.gsub(/[^\d]/, '')
    if number.to_s.length == 11 && number[0] == '1'
        number[1..10]
    elsif number.length == 10
        number
    else
        "0000000000"
    end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody' ]
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'        
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
    
    filename = "output/thanks_#{id}.html"
    
    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def to_time(dates)
    format = "%m/%d/%y %k:%M"
    dates.map {|date| Time.strptime(date,format) }
end

def peak_registration_hour(dates)
     hours = dates.map(&:hour)
    (hours.sum / hours.count).to_s + ":00"
end

def peak_registration_day(dates)
    days = dates.map(&:wday)
    greatest = days.tally.sort_by { |_,v| v}.last[0]
    Date::DAYNAMES[greatest]
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
header_converters: :symbol
)

date_strings = []

contents.each do |row|
    id = row[:id]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    date_strings.push(row[:regdate])

    phonenumber = clean_phonenumber(row[:homephone])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    
    save_thank_you_letter(id, form_letter)

end

dates = to_time(date_strings)

peak_hour = peak_registration_hour(dates)

peak_day = peak_registration_day(dates)

puts "Peak registration was around #{peak_hour} on #{peak_day}"