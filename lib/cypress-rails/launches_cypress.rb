require_relative "finds_bin"
require_relative "config"
require_relative "starts_rails_server"

module CypressRails
  class LaunchesCypress
    def initialize
      @starts_rails_server = StartsRailsServer.new
      @finds_bin = FindsBin.new
    end

    def call(command, config)
      puts config.to_s
      server = @starts_rails_server.call(config)
      bin = @finds_bin.call(config.dir)

      command = <<~EXEC
        CYPRESS_BASE_URL="http://#{server.host}:#{server.port}#{config.base_path}" "#{bin}" #{command} --project "#{config.dir}" #{config.cypress_cli_opts}
      EXEC

      puts "\nLaunching Cypress…\n$ #{command}\n"
      system command
    end
  end
end
