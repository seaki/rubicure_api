require "sinatra"
require "sinatra/json"
require "slim"
require "yaml"
require "active_support/all"
require "rollbar/middleware/sinatra"
require "rubicure"
require "icalendar"
require "icalendar/tzinfo"
require "date"

class Object
  def to_pretty_json
    JSON.pretty_generate(self)
  end
end

class App < Sinatra::Base
  use Rollbar::Middleware::Sinatra

  configure do
    mime_type :ics, "text/calendar"
  end

  get "/" do
    @girls = Precure.all
    @series = Precure.map(&:itself)
    slim :index
  end

  get "/series.json" do
    # convert to plain Hash
    all_series = Precure.map{ |s| Hash[s] }

    json all_series, @json_options
  end

  get "/series/:name.json" do
    name = params[:name].to_sym
    halt 404 unless Rubicure::Series.valid?(name)

    series = Rubicure::Series.find(name)

    # convert to plain Hash
    json Hash[series], @json_options
  end

  get "/girls.json" do
    # convert to plain Hash
    girls = Precure.all.map{ |g| Hash[g] }

    json girls, @json_options
  end

  get "/girls/:name.json" do
    name = params[:name].to_sym
    halt 404 unless Rubicure::Girl.valid?(name)

    girl = Rubicure::Girl.find(name)

    # convert to plain Hash
    json Hash[girl], @json_options
  end

  get "/girls/birthday.ics" do
    content_type :ics
    date_girls = girl_birthdays(Date.today.year, Date.today.year + 2)
    birthday_ical(date_girls)
  end

  before do
    @json_options = {}
    @json_options[:json_encoder] = :to_pretty_json if params[:format] == "pretty"
  end

  helpers do
    def girl_birthdays(from_year, to_year)
      date_girls = {}
      girls = Precure.all.select(&:have_birthday?)

      girls.each do |girl|
        (from_year..to_year).each do |year|
          date = Date.parse("#{year}/#{girl.birthday}")
          date_girls[date] = girl
        end
      end

      Hash[date_girls.sort]
    end

    def birthday_ical(date_girls)
      cal = Icalendar::Calendar.new

      cal.append_custom_property("X-WR-CALNAME;VALUE=TEXT", "プリキュアの誕生日")

      date_girls.each do |date, girl|
        cal.event do |e|
          e.summary = "#{girl.precure_name}（#{girl.human_name}）の誕生日"
          e.dtstart = Icalendar::Values::Date.new(date)
        end
      end

      cal.publish
      cal.to_ical
    end
  end
end
