class ApplicationController < ActionController::Base
  def index
    render plain: 'Yay! You\'re on Rails!'
  end
end
