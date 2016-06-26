require 'minitest/stub_const'

module StubSettingsHelper
  def stub_settings
    Object.stub_const(:Settings, Settings.clone) do
      yield
    end
  end
end
