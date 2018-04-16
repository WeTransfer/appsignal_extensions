require_relative '../spec_helper'
require 'rack/test'

describe AppsignalExtensions::Middleware do
  include Rack::Test::Methods
  let(:app) { AppsignalExtensions::Middleware.new(@app) }

  it 'creates and closes the transaction, and ensures the transaction supports #close' do
    pending "No Appsignal to test with" unless defined?(Appsignal)
    
    allow(described_class).to receive(:appsignal_defined_and_active?) { true }
    
    expect(Appsignal::Transaction).to receive(:complete_current!).and_call_original
    
    # Create the actual Transaction in advance
    request_id = SecureRandom.uuid
    req = double('Rack::Request', env: {})
    txn = Appsignal::Transaction.create(request_id, Appsignal::Transaction::HTTP_REQUEST, req)
    expect(Appsignal::Transaction).to receive(:create).and_return(txn)
    
    @app = ->(env) {
      expect(env).to have_key('appsignal.transaction')
      expect(env['appsignal.transaction']).to be_kind_of(described_class::Close) # the wrapper with the close() method
      expect(env['appsignal.transaction']).to respond_to(:transaction_id)
      expect(env['appsignal.transaction']).to respond_to(:close)
      [200, {}, ['Simple response']]
    }
    get '/here'
  end
  
  it 'logs the error to Appsignal from within the rack app call' do
    pending "No Appsignal to test with" unless defined?(Appsignal)
    
    mock_config = double('Appsignal::Config', :active? => true, :[] => [])
    allow(Appsignal).to receive(:config).and_return(mock_config)
    
    allow(described_class).to receive(:appsignal_defined_and_active?) { true }
    
    expect(Appsignal::Transaction).to receive(:complete_current!).and_call_original
    expect_any_instance_of(Appsignal::Transaction).to receive(:set_error).and_call_original
    
    @app = ->(env) {
      raise "Nope!"
    }
    expect { 
      get '/here'
    }.to raise_error(/Nope/)
  end
  
  it 'handles a suspended transaction' do
    pending "No Appsignal to test with" unless defined?(Appsignal)
    
    mock_config = double('Appsignal::Config')
    allow(Appsignal).to receive(:config).and_return(mock_config)
    allow(described_class).to receive(:appsignal_defined_and_active?) { true }
    expect(Appsignal::Transaction).not_to receive(:complete_current!)
    
    @app = ->(env) {
      [200, {'appsignal.suspend'=>true}, ['Hello']]
    }
    get '/here'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('Hello')
  end
end
