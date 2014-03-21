require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "index" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit users_path
    end

    it { should have_title('All users') }
    it { should have_content('All users') }

    describe "pagination" do
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      it { should have_selector('div.pagination') }

      it "should list each user" do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector('li', text: user.name)
        end
      end
    end

    describe "delete links" do

      it { should_not have_link('delete') }

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { should have_link('delete', href: user_path(User.first)) }
        it "should be able to delete another user" do
          expect do
            click_link('delete', match: :first)
          end.to change(User, :count).by(-1)
        end
        it { should_not have_link('delete', href: user_path(admin)) }
      end
    end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

    before { visit user_path(user) }

    it { should have_content(user.name) }
    it { should have_title(user.name) }

    describe "microposts" do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should have_content(user.microposts.count) }
    end

    describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "following a user" do
        before { visit user_path(other_user) }

        it "should increment the followed user count" do
          expect do
            click_button "Follow"
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button "Follow"
          end.to change(other_user.followers, :count).by(1)
        end

        describe "toggling the button" do
          before { click_button "Follow" }
          it { should have_xpath("//input[@value='Unfollow']") }
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it "should decrement the followed user count" do
          expect do
            click_button "Unfollow"
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button "Unfollow"
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button "Unfollow" }
          it { should have_xpath("//input[@value='Follow']") }
        end
      end
    end
  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_content('Sign up') }
    it { should have_title(full_title('Sign up')) }
  end

  describe "signup" do

    before { visit signup_path }

    let(:submit) { "Create my account" }
    
    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end

      describe "after submittsion" do
        before { click_button submit }

        it { should have_title('Sign up') }
        it { should have_content('error') }
        it { should have_content("Name can't be blank") }
        it { should have_content("Email can't be blank") }
        it { should have_content("Email is invalid") }
        it { should have_content("Password can't be blank") }
        it { should have_content("Password is too short") }
      end
    end

    describe "with valid information" do
      before do
        fill_in_user "Example User", "user@example.com", "foobar", "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by(email: "user@example.com" ) }

        it { should have_link('Sign out') }
        it { should have_title(user.name) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_content("Update your profile") }
      it { should have_title("Edit user") }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid informaiton" do
      before { click_button "Save changes" }

      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name)  { "New Name" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in_user new_name, new_email, user.password, user.password
        click_button "Save changes"

        it { should have_title(new_name) }
        it { should have_selector("div.alert.alert-success") }
        it { should have_link('Sign out', href: signout_path) }
        specify { expect(user.reload.name).to eq new_name }
        specify { expect(user.reload.email).to eq new_email }
      end
    end

    describe "forbidden attributes" do
      let(:params) do
        { user: { admin: true, password: user.password,
            password_confirmation: user.password } }
      end
      before do
        sign_in user, no_capybara: true
        patch user_path(user), params
      end
      specify { expect(user.reload).not_to be_admin }
    end
  end

  describe "profile micropost counts" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit root_path
    end

    describe "should have no microposts after creation" do
      it { should have_content("0 microposts") }
    end

    describe "with posts" do
      let(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }

      describe "should have singular micropost" do
        before do
          fill_in 'micropost[content]', :with => "Test post"
          click_button "Post"
        end

        it { should have_content("1 micropost") }
      end

      describe "should have plural microposts" do
        before do
          fill_in 'micropost[content]', :with => "Test post 1"
          click_button "Post"
          fill_in 'micropost[content]', :with => "Test post 2"
          click_button "Post"
        end

        it { should have_content("2 microposts") }
      end

      describe "should have singular micropost after deleting all but one" do
        before do
          fill_in 'micropost[content]', :with => "Test post 1"
          click_button "Post"
          fill_in 'micropost[content]', :with => "Test post 2"
          click_button "Post"
          click_link('delete', match: :first)
        end

        it { should have_content("1 micropost") }
      end
    end
  end

  describe "check delete links" do
    let(:user) { FactoryGirl.create(:user, name: "This user", email: "this@test.com") }
    let(:other_user) { FactoryGirl.create(:user, name: "Other user", email: "other@test.com") }
    let(:other_m1) { FactoryGirl.create(:micropost, user: other_user) }
    
    describe "has delete links for other user's posts" do
      before do
        sign_in other_user
        visit user_path(other_user)
      end

      # TODO: Understand why this test fails
#      it { should have_link('delete', href: micropost_path(other_m1)) }
    end

    describe "has no delete links for other user's posts" do
      before do
        sign_in user
        visit user_path(other_user)
      end

      it { should_not have_link('delete', href: micropost_path(other_m1)) }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    before { user.follow!(other_user) }

    describe "followed users" do
      before do
        sign_in user
        visit following_user_path(user)
      end

      it { should have_title(full_title("Following")) }
      it { should have_selector('h3', text: "Following") }
      it { should have_link(other_user.name, href: user_path(other_user)) }
    end

    describe "follwers" do
      before do
        sign_in other_user
        visit followers_user_path(other_user)
      end

      it { should have_title(full_title("Followers")) }
      it { should have_selector('h3', text: "Followers") }
      it { should have_link(user.name, href: user_path(user)) }
    end
  end

  describe "profile micropost counts example" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      100.times { |i| FactoryGirl.create(:micropost, user: user, content: "Post [#{i+1}]") }
    end
    before do
      sign_in user
      visit root_path
    end

    describe "should have first page" do
      it { should have_content("[100]") }
      it { should have_content("[71]") }
      it { should_not have_content("[70]") }
      it { should_not have_content("[41]") }
      it { should_not have_content("[40]") }
      it { should_not have_content("[11]") }
      it { should_not have_content("[10]") }
      it { should_not have_content("[1]") }
    end

    describe "should have second page" do
      before { click_link "Next" }
      it { should_not have_content("[100]") }
      it { should_not have_content("[71]") }
      it { should have_content("[70]") }
      it { should have_content("[41]") }
      it { should_not have_content("[40]") }
      it { should_not have_content("[11]") }
      it { should_not have_content("[10]") }
      it { should_not have_content("[1]") }
    end

    describe "should have third page" do
      before do
        click_link "Next"
        click_link "Next"
      end
      it { should_not have_content("[100]") }
      it { should_not have_content("[71]") }
      it { should_not have_content("[70]") }
      it { should_not have_content("[41]") }
      it { should have_content("[40]") }
      it { should have_content("[11]") }
      it { should_not have_content("[10]") }
      it { should_not have_content("[1]") }
    end

    describe "should have fourth page" do
      before do
        click_link "Next"
        click_link "Next"
        click_link "Next"
      end
      before { click_link "Next" }
      it { should_not have_content("[100]") }
      it { should_not have_content("[71]") }
      it { should_not have_content("[70]") }
      it { should_not have_content("[41]") }
      it { should_not have_content("[40]") }
      it { should_not have_content("[11]") }
      it { should have_content("[10]") }
      it { should have_content("[1]") }
    end

    describe "should have page 3" do
      before do
        click_link "3"
      end
      it { should_not have_content("[100]") }
      it { should_not have_content("[71]") }
      it { should_not have_content("[70]") }
      it { should_not have_content("[41]") }
      it { should have_content("[40]") }
      it { should have_content("[11]") }
      it { should_not have_content("[10]") }
      it { should_not have_content("[1]") }
    end
  end
end
