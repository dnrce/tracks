require 'test_helper'
require 'support/stub_settings_helper'

class MailgunControllerTest < ActionController::TestCase
  include StubSettingsHelper

  def setup
    @user = users(:sms_user)
    @inbox = contexts(:inbox)
  end

  def load_message(filename)
    File.read(File.join(Rails.root, 'test', 'fixtures', filename))
  end

  def test_mailgun_signature_verifies
    stub_settings do
      Settings.mailgun_api_key = "123456789"
      Settings.email_dispatch  = 'from'

      post :mailgun, {
        "timestamp" => "1379539674",
        "token"     => "5km6cwo0e3bfvg78hw4s69znro09xhk1h8u6-s633yasc8hcr5",
        "signature" => "da92708b8f2c9dcd7ecdc91d52946c01802833e6683e46fc00b3f081920dd5b1",
        "body-mime" => load_message('mailgun_message1.txt')
      }

      assert_response :success
    end
  end

  def test_mailgun_creates_todo_with_mailmap
    stub_settings do
      Settings.mailgun_api_key = "123456789"
      Settings.email_dispatch  = 'to'
      Settings.mailmap         = {
        '5555555555@tmomail.net' => ['incoming@othermail.com', 'notused@foo.org']
      }

      todo_count = Todo.count
      post :mailgun, {
        "timestamp" => "1379539674",
        "token"     => "5km6cwo0e3bfvg78hw4s69znro09xhk1h8u6-s633yasc8hcr5",
        "signature" => "da92708b8f2c9dcd7ecdc91d52946c01802833e6683e46fc00b3f081920dd5b1",
        "body-mime" => load_message('mailgun_message2.txt')
      }

      assert_response :success

      assert_equal(todo_count+1, Todo.count)
      message_todo = Todo.where(:description => "test").first
      assert_not_nil(message_todo)
      assert_equal(@inbox, message_todo.context)
      assert_equal(@user, message_todo.user)
    end
  end

  def test_mailgun_signature_fails
    stub_settings do
      Settings.mailgun_api_key = "invalidkey"
      Settings.email_dispatch  = 'from'

      post :mailgun, {
        "timestamp" => "1379539674",
        "token"     => "5km6cwo0e3bfvg78hw4s69znro09xhk1h8u6-s633yasc8hcr5",
        "signature" => "da92708b8f2c9dcd7ecdc91d52946c01802833e6683e46fc00b3f081920dd5b1",
        "body-mime" => load_message('mailgun_message1.txt')
      }

      assert_response 406
    end
  end

end
