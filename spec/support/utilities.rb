include ApplicationHelper

def sign_in(user, options={})
  if options[:no_capybara]
    # Sign in when not using Capybara
    remember_token = User.new_remember_token
    cookies[:remember_token] = remember_token
    user.update_attribute(:remember_token, User.hash(remember_token))
  else
    visit signin_path
    fill_in "Email",    with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
  end
end

def fill_in_user(uName, uEmail, uPwd, uPwdConf)
  fill_in "Name",             with: uName
  fill_in "Email",            with: uEmail
  fill_in "Password",         with: uPwd
  fill_in "Confirm Password", with: uPwdConf
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    expect(page).to have_selector('div.alert.alert-error', text: message)
  end
end
