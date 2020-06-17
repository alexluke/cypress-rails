require_relative "starts_rails_server"
require_relative "config"

module CypressRails
  class StartServer
    def initialize
      @starts_rails_server = StartsRailsServer.new
    end

    def call(config = Config.new)
      @starts_rails_server.call(config)
    end
  end
end