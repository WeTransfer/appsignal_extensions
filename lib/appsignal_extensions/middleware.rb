require "delegate"

# Used to open an Appsignal transaction, but to let the callee close
# it when it is done. The standard Rack middleware for Appsignal
# closes the transaction as soon as the response triplet gets returned,
# we need to keep the transaction open as long as the response is being read.
module AppsignalExtensions
  class Middleware
    # Appsignal::Transaction has no #close method, you have to use a global
    # function call instead. We wrap it with a simple proxy that provides
    # close
    class Close < SimpleDelegator
      # Closes the current Appsignal transaction
      def close
        Appsignal::Transaction.complete_current! if Appsignal.active?
      end
    end

    # Acts as a null-object replacement for the Appsignal transaction if there is no
    # transaction to provide (when Appsignal is not defined under jRuby or when
    # Appsignal is not configured or disabled). Supports the basic method set
    # that is important for us.
    class NullTransaction
      # @return [void]
      def set_action(*); end

      # @return [void]
      def set_metadata(*); end

      # @return [void]
      def set_http_or_background_queue_start(*); end

      # @return [void]
      def set_error(*); end

      # @return [void]
      def close(*); end
    end

    # Acts as a wrapper for Rack response bodies. Ensures that the transaction attached to
    # the request gets closed after the body #each returns or raises
    class TransactionClosingBody
      def initialize(body, transaction)
        @body = body
        @transaction = transaction
      end

      def each(&block)
        @body.each(&block)
      rescue Exception => e
        @transaction.set_error(e)
        raise e
      ensure
        @transaction.close
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    # Creates a new Appsignal middleware handler with the given Rack app as a callee
    #
    # @param app[#call] the Rack app
    def initialize(app)
      @app = app
    end

    # Calls the application, captures errors, sets up wrappers and so forth
    #
    # @param env[Hash] the Rack env
    # @return [Array] the Rack response triplet from upstream
    def call(env)
      request = ::Rack::Request.new(env)
      env["action_dispatch.request_id"] ||= SecureRandom.uuid
      if Appsignal.active?
        call_with_appsignal(env, request)
      else
        call_with_null_transaction(env, request)
      end
    end

    private

    def call_and_capture(env, transaction, request)
      env["appsignal.transaction"] = transaction
      app_name = @app.is_a?(Module) ? @app.to_s : @app.class.to_s # Set the class name properly
      transaction.set_action(format("%s#%s", app_name, "call"))
      transaction.set_metadata("path", request.path)
      transaction.set_metadata("method", request.request_method)
      transaction.set_http_or_background_queue_start
      s, h, b = @app.call(env)

      # If the app we called wants to close the transaction on it's own, return the response. This
      # is useful if the app will clean up or close the transaction within an async.callback block,
      # or within the long response body, or within a hijack proc.
      return [s, h, b] if h.delete("appsignal.suspend")

      # If the app didn't ask for the explicit suspend, Wrap the response in a self-closing wrapper
      # so that the transaction is closed once the response is read in full. This wrapper only works
      # with response bodies that support #each().
      closing_wrapper = TransactionClosingBody.new(b, transaction)
      [s, h, closing_wrapper]
    rescue Exception => e
      # If the raise happens immediately (not in the response read cycle)
      # set the error and close the transaction so that the data gets sent
      # to Appsignal right away, and ensure it gets closed
      transaction.set_error(e)
      transaction.close
      raise e
    end

    def call_with_null_transaction(env, request)
      # Supply the app with a null transaction
      call_and_capture(env, NullTransaction.new, request)
    end

    def call_with_appsignal(env, request)
      bare_transaction = Appsignal::Transaction.create(
        env.fetch("action_dispatch.request_id"),
        Appsignal::Transaction::HTTP_REQUEST,
        request
      )

      # Let the app do something to the appsignal transaction if it wants to
      # Instrument a `process_action`, to set params/action name
      transaction = Close.new(bare_transaction)
      status, headers, body = Appsignal.instrument("process_action.rack") do
        call_and_capture(env, transaction, request)
      end

      [status, headers, body]
    end
  end
end
