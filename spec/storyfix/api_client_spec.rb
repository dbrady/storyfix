require "spec_helper"

RSpec.describe Storyfix::ApiClient do
  let(:api_key) { "sk-test-key" }
  let(:model) { "anthropic/claude-3-haiku" }
  let(:client) { described_class.new(api_key, model) }
  let(:endpoint) { described_class::ENDPOINT }

  it "raises MissingApiKeyError if API key is blank" do
    client = described_class.new("", model)
    expect { client.call("sys", "user") }.to raise_error(Storyfix::MissingApiKeyError)
  end

  it "makes a POST request to OpenRouter" do
    stub_request(:post, endpoint).to_return(
      status: 200,
      body: { choices: [{ message: { content: "Fixed text." } }] }.to_json
    )

    result = client.call("sys prompt", "user content")
    
    expect(result).to eq("Fixed text.")
    expect(a_request(:post, endpoint).with(
      headers: { "Authorization" => "Bearer sk-test-key" },
      body: hash_including(model: model, messages: [{role: "system", content: "sys prompt"}, {role: "user", content: "user content"}])
    )).to have_been_made
  end

  it "raises TimeoutError on timeout" do
    stub_request(:post, endpoint).to_timeout

    expect { client.call("sys", "user") }.to raise_error(Storyfix::TimeoutError)
  end

  it "raises ApiError on 4xx/5xx responses" do
    stub_request(:post, endpoint).to_return(status: 400, body: "Bad Request")

    expect { client.call("sys", "user") }.to raise_error(Storyfix::ApiError) do |error|
      expect(error.status).to eq("400")
      expect(error.body).to eq("Bad Request")
    end
  end

  it "raises EmptyResponseError if content is missing" do
    stub_request(:post, endpoint).to_return(
      status: 200,
      body: { choices: [] }.to_json
    )

    expect { client.call("sys", "user") }.to raise_error(Storyfix::EmptyResponseError)
  end
end
