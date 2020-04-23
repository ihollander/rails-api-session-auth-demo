class UsersController < ApplicationController
  skip_before_action :authorized, only: [:login, :signup]

  def login
    user = User.find_by(username: params[:username])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      render json: user
    else
      render json: { errors: "Invalid username or password" }, status: :bad_request
    end
  end

  def signup
    user = User.create(username: params[:username], password: params[:password])

    if user.valid?
      session[:user_id] = user.id
      render json: user
    else
      render json: { errors: user.errors.full_messages }, status: :bad_request
    end
  end

  def autologin
    if @user
      render json: @user
    end
  end

  def logout
    session.delete(:user_id)

    render json: { message: "Logged out" }
  end

end
