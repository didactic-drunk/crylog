module Crylog
  # Logging levels as defined by [RFC 5424](https://tools.ietf.org/html/rfc5424#section-6.2.1).
  enum Severity
    # Detailed debugging information.
    Debug = 100

    # Interesting events.
    #
    # Examples: User logs in, SQL logs.
    Info = 200

    # Uncommon events.
    Notice = 250

    # Exceptional occurrences that are not errors.
    #
    # Examples: Use of deprecated APIs, poor use of an API, undesirable things that are not necessarily wrong.
    Warning = 300

    # Runtime errors.
    Error = 400

    # Critical conditions.
    #
    # Example: Application component unavailable, unexpected exception.
    Critical = 500

    # Action must be taken immediately.
    #
    # Example: Entire website down, database unavailable, etc.
    # This should trigger the SMS alerts and wake you up.
    Alert = 550

    # Urgent alert.
    Emergency = 600
  end

  # A logger instance.
  struct Logger
    # The handlers registered on `self`.
    getter handlers : Array(Crylog::Handlers::LogHandler) = [] of Crylog::Handlers::LogHandler

    # Processors registered on `self`.
    getter processors : Array(Crylog::Processors::LogProcessors) = [] of Crylog::Processors::LogProcessors

    # The channel `self` belongs to.
    getter channel : String

    # Sets the handlers to use for `self`.
    def handlers=(handlers : Array(Crylog::Handlers::LogHandler)) : self
      @handlers = handlers
      self
    end

    # Sets the processors to use for `self`.
    def processors=(processors : Array(Crylog::Processors::LogProcessors)) : self
      @processors = processors
      self
    end

    # Creates a new `Logger` with the provided *channel*.
    def initialize(@channel : String); end

    # Closes each handler defined on `self`.
    def close
      @handlers.each &.close
    end

    {% for name in Crylog::Severity.constants %}
      # Logs *message* and optionally *context* with `Crylog::Severity::{{name}}` severity.
      def {{name.id.downcase}}(message, context : Crylog::LogContext = Hash(String, Crylog::Context).new) : Nil
        log Crylog::Severity::{{name.id}}, message.to_s, context
      end
    {% end %}

    # :nodoc:
    private def log(severity : Crylog::Severity, message : String?, context : Crylog::LogContext = Hash(String, Crylog::Context).new) : Nil
      msg = Crylog::Message.new message || "", context, severity, @channel, Time.utc, Hash(String, Crylog::Context).new

      # Return early if no handlers handle this message.
      return if @handlers.none?(&.handles?(msg))

      # Run the logger's processors
      @processors.each &.call msg

      # Run the logger's handlers.  Returning early is *bubble* was set to false.
      @handlers.each do |handler|
        break if handler.handle msg
      end
    end
  end
end
