class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    result = Auth::LoginService.call(email: params[:email], password: params[:password])
    if result.success?
      session[:user_id] = result.user.id
      redirect_to root_path, notice: "Welcome back, #{result.user.name}!"
    else
      flash.now[:alert] = result.errors.first
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "You have been logged out."
  end
end
