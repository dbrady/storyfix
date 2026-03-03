require "spec_helper"

RSpec.describe Storyfix::StoryfixError do
  it "is a standard error" do
    expect(described_class.new).to be_a(StandardError)
  end
end

RSpec.describe Storyfix::MissingApiKeyError do
  it "has a helpful default message" do
    error = described_class.new
    expect(error.message).to include("OpenRouter API key is missing")
  end
end

RSpec.describe Storyfix::ApiError do
  it "stores status and body" do
    error = described_class.new("404", "Not Found")
    expect(error.status).to eq("404")
    expect(error.body).to eq("Not Found")
    expect(error.message).to eq("API Error (404): Not Found")
  end
end
