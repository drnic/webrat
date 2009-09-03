require "webrat/culerity"

if defined?(ActionController::IntegrationTest)
  module ActionController #:nodoc:
    IntegrationTest.class_eval do
      include Webrat::Methods
      include Webrat::Matchers
      include Webrat::HaveTagMatcher
      include Webrat::Culerity::Methods
    end
  end
end
