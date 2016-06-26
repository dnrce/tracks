module Tracks
  
  class Config

    def self.auth_schemes
      Settings.authentication_schemes || []
    end
    
    def self.openid_enabled?
      auth_schemes.include?('open_id')
    end

    def self.cas_enabled?
      auth_schemes.include?('cas')
    end
    
    def self.prefered_auth?
      Settings.preferred_auth || auth_schemes.first
    end
    
  end
  
end
