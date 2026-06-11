module Admin
  class UsersController < Admin::ApplicationController
    def create
      resource = User.new(resource_params)
      if resource.save
        redirect_to(
          [namespace, resource],
          notice: "User created successfully."
        )
      else
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) },
               status: :unprocessable_content
      end
    end

    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end

      if resource.update(resource_params)
        redirect_to(
          [namespace, resource],
          notice: "User updated successfully."
        )
      else
        render :edit, locals: { page: Administrate::Page::Form.new(dashboard, resource) },
               status: :unprocessable_content
      end
    end

    private

    def resource_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :active)
    end
  end
end
