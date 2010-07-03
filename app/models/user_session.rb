class UserSession < Authlogic::Session::Base

  def validate_by_password
    user = search_for_record(find_by_login_method, send(login_field))
    
    if user.blank?
      errors.add_to_base "Sorry, the email could not be found in our database"
      return
    end
    
    unless user.allow_login
      # user is not allowed to login, add an error telling the user they are not allowed
      errors.add_to_base "Sorry, login has been disabled for your account"
      return
    end

    # user is allowed to login, call the normal base class method in
    # AuthLogic::Session::Password to actually validate the user's login
    super

  end

end