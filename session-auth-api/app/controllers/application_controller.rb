class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  before_action :authorized
  
  private 
  
  def current_user
    if session[:user_id]
      @user = User.find_by(id: session[:user_id])
    end
  end
  
  def logged_in?
    !!current_user
  end
  
  def authorized
    render json: { message: 'Please log in' }, status: :unauthorized unless logged_in?
  end
  
end