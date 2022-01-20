require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe "AppsignalExtensions" do
  it "has a version" do
    expect(AppsignalExtensions::VERSION).to be_kind_of(String)
  end

  it "has a Middleware constant" do
    expect(AppsignalExtensions::Middleware).to respond_to(:new)
    expect(AppsignalExtensions::Middleware.instance_method(:initialize).arity).to eq(1)
  end
end
