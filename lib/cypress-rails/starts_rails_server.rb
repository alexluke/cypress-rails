require_relative "initializer_hooks"
require_relative "manages_transactions"
require_relative "tracks_resets"
require_relative "server"

module CypressRails
  class StartsRailsServer
    def initialize
      @initializer_hooks = InitializerHooks.instance
      @manages_transactions = ManagesTransactions.instance
    end

    def call(config)
      @initializer_hooks.run(:before_server_start)
      if config.transactional_server
        @manages_transactions.begin_transaction
      end

      set_exit_hooks!(config)

      app = create_rack_app
      Server.new(app, port: config.port).tap do |server|
        server.boot
      end
    end

    def configure_rails_to_run_our_state_reset_on_every_request!(transactional_server)
      Rails.application.executor.to_run do
        TracksResets.instance.reset_state_if_needed(transactional_server)
      end
    end

    def create_rack_app
      Rack::Builder.new do
        map "/cypress_rails_reset_state" do
          run lambda { |env|
            TracksResets.instance.reset_needed!
            [202, {"Content-Type" => "text/plain"}, ["Accepted"]]
          }
        end
        map "/" do
          run Rails.application
        end
      end
    end

    private

    def set_exit_hooks!(config)
      at_exit do
        run_exit_hooks_if_necessary!(config)
      end
      Signal.trap("INT") do
        puts "Exiting cypress-rails…"
        exit
      end
    end

    def run_exit_hooks_if_necessary!(config)
      @at_exit_hooks_have_fired ||= false # avoid warning
      return if @at_exit_hooks_have_fired

      if config.transactional_server
        @manages_transactions.rollback_transaction
      end
      @initializer_hooks.run(:before_server_stop)

      @at_exit_hooks_have_fired = true
    end
  end
end
