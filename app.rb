require 'rubygems'
require 'sinatra'
require 'gap_query'
require 'haml'

set :haml, {:format => :html5 }

get '/' do
  redirect '/the more we * the less we *'
end

post '/' do
  redirect "/#{params[:q]}"
end

get '/:q' do
  @results = GapQuery.new(params[:q]).matching_results
  haml :index
end
