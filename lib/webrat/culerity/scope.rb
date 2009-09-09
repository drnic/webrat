module Webrat
  class CulerityScope
    attr_reader :container

    def initialize(container)
      @container = container
    end

    def check(id_or_name_or_label, value = true)
      elem = element_locator(id_or_name_or_label, :check_box)
      elem.set(value)
    end

    webrat_deprecate :checks, :check

    def choose(id_or_name_or_label)
      elem = element_locator(id_or_name_or_label, :radio)
      elem.set
    end

    webrat_deprecate :chooses, :choose

    def click_button(value_or_id_or_alt = nil, options = {})
      options = value_or_id_or_alt if value_or_id_or_alt.is_a?(Hash)

      with_handler options.delete(:confirm) do
        if value_or_id_or_alt
          elem = element_locator(value_or_id_or_alt, :button, :value, :id, :text, :alt)
        else
          elem = container.buttons[0] # celerity should really include Enumerable here
        end
        elem.click
      end
    end

    webrat_deprecate :clicks_button, :click_button

    def click_link(text_or_title_or_id, options = {})
      with_handler options.delete(:confirm) do
        elem = element_locator(text_or_title_or_id, :link, :text, :title, :id)
        elem.click
      end
    end

    webrat_deprecate :clicks_link, :click_link

    def field_by_xpath(xpath)
      element_locator(xpath, :generic_field, :xpath)
    end

    def field_labeled(label)
      element_locator(label, :generic_field, :label)
    end

    def field_with_id(id)
      element_locator(id, :generic_field, :id)
    end

    def fill_in(id_or_name_or_label, options = {})
      elem = element_locator(id_or_name_or_label, :text_field)
      elem.set(options[:with])
    end

    webrat_deprecate :fills_in, :fill_in
    
    def attach_file(id_or_name_or_label, path)
      elem = element_locator(id_or_name_or_label, :file_field)
      elem.set(path)
    end

    def response_body
      container.html
    end

    def select(option_text, options = {})
      elem = element_locator(options[:from], :select_list)
      elem.select(option_text)
    end

    webrat_deprecate :selects, :select

    DATE_TIME_SUFFIXES = {
      :year   => '1i',
      :month  => '2i',
      :day    => '3i',
      :hour   => '4i',
      :minute => '5i'
    }

    # FIXME duplication with webrat/core/scope
    def select_date(date_to_select, options ={})
      date = date_to_select.is_a?(Date) || date_to_select.is_a?(Time) ?
                date_to_select : Date.parse(date_to_select)

      id_prefix = locate_id_prefix(options) do
        raise NotImplementedError.new("select_date without :from key is not implemented yet.")
      end

      select date.year, :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:year]}"
      select date.strftime('%B'), :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:month]}"
      select date.day, :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:day]}"
    end

    webrat_deprecate :selects_date, :select_date

    def uncheck(id_or_name_or_label)
      check(id_or_name_or_label, false)
    end

    webrat_deprecate :unchecks, :uncheck

  protected

    # Returns a +Culerity::Element+
    def element_locator(locator, element, *how)
      CulerityLocator.new(container, locator, element, *how).locate!
    end

    def with_handler(proc, &block)
      p proc, block
      # old_handler = container.browser.webclient.confirm_handler
      # puts "OLD HANDLER"
      # p old_handler
      # p old_handler.class
      # container.browser.webclient.confirm_handler = proc
      # block.call
      # container.browser.webclient.confirm_handler = old_handler
      
      # self.send_remote(:add_listener, :confirm) { blk }
      # block.call
      # self.send_remote(:remove_listener, :confirm) { blk }
      
      container.browser.add_listener :confirm, &proc
      block.call if block_given?
      # container.browser.remove_listener :confirm, &proc
    end

    # FIXME duplication with webrat/core/scop
    def locate_id_prefix(options, &location_strategy) #:nodoc:
      return options[:id_prefix] if options[:id_prefix]

      if options[:from]
        if (label = element_locator(options[:from], :label))
          label.for
        else
          raise NotFoundError.new("Could not find the label with text #{options[:from]}")
        end
      else
        yield
      end
    end

  end
end
