# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require 'action_controller/railtie'
require 'active_model'

# We define our single Rails application here, one time, upon the first inclusion
# Tests should feel free to define their own Controllers locally, but if they
# need anything special at the Application level, put it here
if !defined?(MyApp)

  ENV['NEW_RELIC_DISPATCHER'] = 'test'

  class MyApp < Rails::Application
    # We need a secret token for session, cookies, etc.
    config.active_support.deprecation = :log
    config.secret_token = "49837489qkuweoiuoqwehisuakshdjksadhaisdy78o34y138974xyqp9rmye8yrpiokeuioqwzyoiuxftoyqiuxrhm3iou1hrzmjk"
  end
  MyApp.initialize!

  MyApp.routes.draw do
    get('/bad_route' => 'test#controller_error',
        :constraints => lambda do |_|
          raise ActionController::RoutingError.new('this is an uncaught routing error')
        end)
    get '/:controller(/:action(/:id))'
  end

  MyApp.config.after_initialize do
    class DebugListener
      def start(name, id, payload)
        p "----------> #{name}(#{id}) : #{payload}" if $debug
      end

      def finish(name, id, payload)
        p "<---------- #{name}(#{id}) : #{payload}" if $debug
      end
    end
    ActiveSupport::Notifications.subscribe(nil, DebugListener.new)
  end

  class ApplicationController < ActionController::Base; end

  # a basic active model compliant model we can render
  class Foo
    extend ActiveModel::Naming
    def to_model
      self
    end

    def to_partial_path
      'foos/foo'
    end

    def valid?()      true end
    def new_record?() true end
    def destroyed?()  true end

    def raise_error
      raise 'this is an uncaught model error'
    end

    def errors
      obj = Object.new
      def obj.[](key)         [] end
      def obj.full_messages() [] end
      obj
    end
  end
end
