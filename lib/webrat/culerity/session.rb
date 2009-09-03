require "culerity"
require "forwardable"
require "webrat/core/save_and_open_page"

module Webrat #:nodoc:
  class CulerityResponse
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  class CuleritySession #:nodoc:
    include Webrat::SaveAndOpenPage
    extend Forwardable

    def initialize(*args) # :nodoc:
    end

    def response
      CulerityResponse.new(response_body)
    end

    def current_url
      container.url
    end

    def visit(url = nil, http_method = :get, data = {})
      reset
      # TODO querify data
      container.goto(absolute_url(url))
    end

    webrat_deprecate :visits, :visit

    def click_link_within(selector, text_or_title_or_id)
      within(selector) do
        click_link(text_or_title_or_id)
      end
    end

    webrat_deprecate :clicks_link_within, :click_link_within

    def reload
      reset
      container.refresh
    end

    webrat_deprecate :reloads, :reload

    def clear_cookies
      container.clear_cookies
    end

    def execute_script(source)
      container.execute_script(source)
    end

    def current_scope
      scopes.last || base_scope
    end

    def scopes
      @_scopes ||= []
    end

    def base_scope
      @_base_scope ||= CulerityScope.new(container)
    end

    def within(selector)
      xpath = Webrat::XML.css_to_xpath(selector).first
      scope = CulerityScope.new(container.element_by_xpath(xpath))
      scopes.push(scope)
      ret = yield
      scopes.pop
      return ret
    end

    def within_frame(name)
      scope = CulerityScope.new(container.frame(:name => name))
      scopes.push(scope)
      if block_given?
        ret = yield
        scopes.pop
        return ret
      end
      scope
    end

    def self.delegate_and_wait(*methods)
      for method in methods
        module_eval(<<-RUBY, __FILE__, __LINE__+1)
          def #{method}(*args, &block)
            result = current_scope.__send__(:#{method}, *args, &block)
            container.wait
            result
          end
        RUBY
      end
    end

    delegate_and_wait :check, :checks
    delegate_and_wait :choose, :chooses
    delegate_and_wait :click_button, :clicks_button
    delegate_and_wait :click_link, :clicks_link
    delegate_and_wait :fill_in, :fills_in
    delegate_and_wait :attach_file
    delegate_and_wait :field_by_xpath
    delegate_and_wait :field_labeled
    delegate_and_wait :field_with_id
    delegate_and_wait :response_body
    delegate_and_wait :select, :selects
    delegate_and_wait :select_date, :selects_date
    delegate_and_wait :uncheck, :unchecks

  protected

    def container
      setup unless $setup_done
      browser
    end

    def browser
      @_browser ||= begin
        $browser ||= ::Culerity::RemoteBrowserProxy.new(server, {:browser => :firefox, :log_level => :off})
        $browser.clear_cookies
        $browser
      end
    end

    def server
      $server ||= ::Culerity::run_server
    end

    def absolute_url(url) #:nodoc:
      if url =~ Regexp.new('^https?://')
        url
      elsif url =~ Regexp.new('^/')
        "#{current_host}#{url}"
      else
        "#{current_host}/#{url}"
      end
    end

    def current_host
      @_current_host ||= [Webrat.configuration.application_address, Webrat.configuration.application_port].join(":")
    end

    def setup #:nodoc:
      silence_stream(STDOUT) do
        Webrat.start_app_server
      end
      teardown_at_exit
      $setup_done = true
    end

    def teardown_at_exit #:nodoc:
      at_exit do
        silence_stream(STDOUT) do
          Webrat.stop_app_server
        end
        $browser.exit if $browser
        $server.close if $server
      end
    end

  private

    def reset
      @_scopes     = nil
      @_base_scope = nil
    end

  end
end
