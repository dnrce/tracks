class UsersController < ApplicationController
  
  before_filter :admin_login_required, :only => [ :index, :show, :destroy ]

  # GET /users GET /users.xml
  def index
    respond_to do |format|
      format.html do
        @page_title = "TRACKS::Manage Users"
        @users = User.order('login ASC').paginate :page => params[:page]
        @total_users = User.count
        # When we call users/signup from the admin page we store the URL so that
        # we get returned here when signup is successful
        store_location
      end
      format.xml do
        @users  = User.order('login')
        render :xml => @users.to_xml(:except => [ :password ])
      end
    end
  end

  # GET /users/id GET /users/id.xml
  def show
    @user = User.find(params[:id])
    render :xml => @user.to_xml(:except => [ :password ])
  end

  # DELETE /users/id DELETE /users/id.xml
  def destroy
    @deleted_user = User.find(params[:id])
    @saved = @deleted_user.destroy
    @total_users = User.count

    respond_to do |format|
      format.html do
        if @saved
          notify :notice, t('users.successfully_deleted_user', :username => @deleted_user.login)
        else
          notify :error, t('users.failed_to_delete_user', :username => @deleted_user.login)
        end
        redirect_to users_url
      end
      format.js
      format.xml { head :ok }
    end
  end

  def change_password
    @page_title = t('users.change_password_title')
  end

  def update_password
    # is used for focing password change after sha->bcrypt upgrade
    current_user.change_password(user_params[:password], user_params[:password_confirmation])
    notify :notice, t('users.password_updated')
    redirect_to preferences_path
  rescue Exception => error
    notify :error, error.message
    redirect_to change_password_user_path(current_user)
  end

  def change_auth_type
    @page_title = t('users.change_auth_type_title')
  end

  def update_auth_type
    current_user.auth_type = user_params[:auth_type]
    if current_user.save
      notify :notice, t('users.auth_type_updated')
      redirect_to preferences_path
    else
      notify :warning, t('users.auth_type_update_error', :error_messages => current_user.errors.full_messages.join(', '))
      redirect_to change_auth_type_user_path(current_user)
    end
  end

  def refresh_token
    current_user.generate_token
    current_user.save!
    notify :notice, t('users.new_token_generated')
    redirect_to preferences_path
  end

  private

  def user_params
    params.require(:user).permit(:login, :first_name, :last_name, :password_confirmation, :password, :auth_type, :open_id_url)
  end

  def get_new_user
    if session['new_user']
      user = session['new_user']
      session['new_user'] = nil
    else
      user = User.new
    end
    user
  end

end
