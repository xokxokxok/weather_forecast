module Google
  class BaseError < StandardError
    attr_reader :status
  
    def initialize(message, status: :bad_gateway, back_trace: nil)
      super(message)
      @status = status
      set_backtrace(back_trace)
    end
  end
end