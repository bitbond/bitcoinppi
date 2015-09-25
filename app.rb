require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"

get "/" do
  erb :landingpage
end

