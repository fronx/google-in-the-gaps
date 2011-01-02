require 'rubygems'
require 'sinatra'
require 'gap_query'
require 'haml'
require 'sequel'

set :haml, {:format => :html5 }

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://my.db')

begin
  DB.schema(:queries)
rescue Sequel::Error
  DB.create_table :queries do
   primary_key :id
   String :text
   DateTime :created_at
   index :created_at
  end
end

get '/' do
  redirect '/the more we * the less we *'
end

post '/' do
  DB[:queries].insert(:text => params[:q], :created_at => Time.now)
  redirect "/#{params[:q]}"
end

get '/:q' do
  @results = GapQuery.new(params[:q]).matching_results
  haml :index
end
