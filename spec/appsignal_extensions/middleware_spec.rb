require_relative "../spec_helper"
require "rack/test"

describe AppsignalExtensions::Middleware do
  include Rack::Test::Methods
  let(:app) { AppsignalExtensions::Middleware.new(@app) }

  describe AppsignalExtensions::Middleware::NullTransaction do
    it "supports all the methods we need on Transaction" do
      methods = %w[set_action set_metadata set_http_or_background_queue_start set_error close]
      methods.each do |m|
        expect(subject).to respond_to(m)
        expect(subject.method(m).arity).to eq(-1) # Should accept any args
      end
    end

    it "has a method set that matches the Appsignal method set" do
      methods = %w[set_action set_metadata set_http_or_background_queue_start set_error]
      methods.each do |m|
        expect(Appsignal::Transaction.public_instance_methods).to include(m.to_sym)
      end
    end
  end

  context "using a NullTransaction if Appsignal is disabled or not defined" do
    it "returns the app call result if no exceptions are raised" do
      expect(Appsignal).to receive(:active?).and_return(false)

      fake_transaction = double("NullTransaction")
      @app = lambda { |env|
        expect(env).to have_key("appsignal.transaction")
        expect(env["appsignal.transaction"]).to eq(fake_transaction)
        [200, {}, ["Good."]]
      }

      expect(described_class::NullTransaction).to receive(:new) { fake_transaction }

      expect(fake_transaction).to receive(:set_action) { |action_name|
        expect(action_name).to match(/call/)
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("path")
        expect(meta_value).to eq("/here")
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("method")
        expect(meta_value).to eq("GET")
      }
      expect(fake_transaction).to receive(:set_http_or_background_queue_start)
      expect(fake_transaction).to receive(:close)

      get "/here"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("Good.")
    end

    it "re-raises the exception raised in the app call and sets it in the transaction" do
      expect(Appsignal).to receive(:active?).and_return(false)

      fake_transaction = double("NullTransaction")
      @app = lambda { |env|
        expect(env).to have_key("appsignal.transaction")
        expect(env["appsignal.transaction"]).to eq(fake_transaction)
        raise "This failed"
      }

      expect(described_class::NullTransaction).to receive(:new) { fake_transaction }

      expect(fake_transaction).to receive(:set_action) { |action_name|
        expect(action_name).to match(/call/)
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("path")
        expect(meta_value).to eq("/here")
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("method")
        expect(meta_value).to eq("GET")
      }
      expect(fake_transaction).to receive(:set_http_or_background_queue_start)
      expect(fake_transaction).to receive(:set_error) { |e|
        expect(e).to be_kind_of(StandardError)
        expect(e.message).to match(/This failed/)
      }

      expect(fake_transaction).to receive(:close)

      expect do
        get "/here"
      end.to raise_error(/This failed/)
    end

    it "re-raises the exception raised in the response body and sets it in the transaction" do
      expect(Appsignal).to receive(:active?).and_return(false)

      fake_transaction = double("NullTransaction")
      raising_body = Class.new do
        def each
          raise "Failure in the body"
        end
      end

      @app = lambda { |env|
        expect(env).to have_key("appsignal.transaction")
        expect(env["appsignal.transaction"]).to eq(fake_transaction)
        [200, {}, raising_body.new]
      }

      expect(described_class::NullTransaction).to receive(:new) { fake_transaction }

      expect(fake_transaction).to receive(:set_action) { |action_name|
        expect(action_name).to match(/call/)
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("path")
        expect(meta_value).to eq("/here")
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("method")
        expect(meta_value).to eq("GET")
      }
      expect(fake_transaction).to receive(:set_http_or_background_queue_start)
      expect(fake_transaction).to receive(:set_error) { |e|
        expect(e).to be_kind_of(StandardError)
        expect(e.message).to match(/Failure in the body/)
      }

      expect(fake_transaction).to receive(:close)

      expect do
        get "/here"
      end.to raise_error(/Failure in the body/)
    end

    it "leaves the transaction open if appsignal.suspend header is passed in the response" do
      expect(Appsignal).to receive(:active?).and_return(false)

      fake_transaction = double("NullTransaction")

      @app = lambda { |env|
        expect(env).to have_key("appsignal.transaction")
        expect(env["appsignal.transaction"]).to eq(fake_transaction)
        [200, { "appsignal.suspend" => true }, ["Suspended long response"]]
      }

      expect(described_class::NullTransaction).to receive(:new) { fake_transaction }

      expect(fake_transaction).to receive(:set_action) { |action_name|
        expect(action_name).to match(/call/)
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("path")
        expect(meta_value).to eq("/here")
      }
      expect(fake_transaction).to receive(:set_metadata) { |meta_key, meta_value|
        expect(meta_key).to eq("method")
        expect(meta_value).to eq("GET")
      }
      expect(fake_transaction).to receive(:set_http_or_background_queue_start)

      expect(fake_transaction).not_to receive(:close)
      get "/here"
      expect(last_response.headers).not_to have_key("appsignal.suspend")
    end
  end

  context "using a real Appsignal::Transaction" do
    it "creates and closes the transaction, and ensures the transaction supports #close" do
      pending "No Appsignal to test with" unless defined?(Appsignal)

      allow(Appsignal).to receive(:active?).and_return(true)

      expect(Appsignal::Transaction).to receive(:complete_current!).and_call_original

      # Create the actual Transaction in advance
      request_id = SecureRandom.uuid
      req = double("Rack::Request", env: {})
      txn = Appsignal::Transaction.create(request_id, Appsignal::Transaction::HTTP_REQUEST, req)
      expect(Appsignal::Transaction).to receive(:create).and_return(txn)

      @app = lambda { |env|
        expect(env).to have_key("appsignal.transaction")
        expect(env["appsignal.transaction"]).to be_kind_of(described_class::Close) # the wrapper with the close() method
        expect(env["appsignal.transaction"]).to respond_to(:transaction_id)
        expect(env["appsignal.transaction"]).to respond_to(:close)
        [200, {}, ["Simple response"]]
      }
      get "/here"
    end

    it "logs the error to Appsignal from within the rack app call" do
      pending "No Appsignal to test with" unless defined?(Appsignal)

      mock_config = double("Appsignal::Config", :active? => true, :[] => [])
      allow(Appsignal).to receive(:config).and_return(mock_config)
      allow(Appsignal).to receive(:active?).and_return(true)

      expect(Appsignal::Transaction).to receive(:complete_current!).and_call_original
      expect_any_instance_of(Appsignal::Transaction).to receive(:set_error).and_call_original

      @app = lambda { |_env|
        raise "Nope!"
      }
      expect do
        get "/here"
      end.to raise_error(/Nope/)
    end

    it "handles a suspended transaction" do
      pending "No Appsignal to test with" unless defined?(Appsignal)

      mock_config = double("Appsignal::Config")
      allow(Appsignal).to receive(:config).and_return(mock_config)
      expect(Appsignal).to receive(:active?).and_return(true)
      expect(Appsignal::Transaction).not_to receive(:complete_current!)

      @app = lambda { |_env|
        [200, { "appsignal.suspend" => true }, ["Hello"]]
      }
      get "/here"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("Hello")
    end
  end
end
