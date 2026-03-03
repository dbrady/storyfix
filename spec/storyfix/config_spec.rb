require "spec_helper"

RSpec.describe Storyfix::Config do
  let(:setting_store) { instance_double("Storyfix::Setting") }

  it "prioritizes CLI over ENV and Settings" do
    allow(setting_store).to receive(:get).with("my-key").and_return("db-val")
    env = { "STORYFIX_MY_KEY" => "env-val" }

    config1 = described_class.new(setting_store, env, {})
    expect(config1.get("my-key")).to eq("env-val")

    config2 = described_class.new(setting_store, env, { :"my-key" => "cli-val" })
    expect(config2.get("my-key")).to eq("cli-val")

    config3 = described_class.new(setting_store, {}, {})
    expect(config3.get("my-key")).to eq("db-val")
  end

  it "resolves api_key from OPENROUTER_API_KEY env" do
    allow(setting_store).to receive(:get).and_return(nil)
    config = described_class.new(setting_store, { "OPENROUTER_API_KEY" => "secret" })
    expect(config.api_key).to eq("secret")
  end

  it "resolves api_key from openrouter-api-key setting" do
    allow(setting_store).to receive(:get).with("openrouter-api-key").and_return("openrouter-key")
    config = described_class.new(setting_store, {}, {})
    expect(config.api_key).to eq("openrouter-key")
  end

  it "resolves api_key from api-key setting as fallback" do
    allow(setting_store).to receive(:get).with("openrouter-api-key").and_return(nil)
    allow(setting_store).to receive(:get).with("api-key").and_return("legacy-key")
    config = described_class.new(setting_store, {}, {})
    expect(config.api_key).to eq("legacy-key")
  end

  it "resolves model aliases" do
    allow(setting_store).to receive(:get).with("model-opus").and_return("anthropic/claude-3-opus")
    allow(setting_store).to receive(:get).with("model-custom").and_return(nil)

    config = described_class.new(setting_store)
    expect(config.model_for("opus")).to eq("anthropic/claude-3-opus")
    expect(config.model_for("custom")).to eq("custom")
  end

  it "returns nil for model_for(nil)" do
    config = described_class.new(setting_store)
    expect(config.model_for(nil)).to be_nil
  end

  it "returns system_prompt from settings" do
    allow(setting_store).to receive(:get).with("system-prompt-fix").and_return("You are helpful.")
    config = described_class.new(setting_store)
    expect(config.system_prompt).to eq("You are helpful.")
  end

  it "returns default_model from settings" do
    allow(setting_store).to receive(:get).with("default-model").and_return("gpt-4")
    config = described_class.new(setting_store)
    expect(config.default_model).to eq("gpt-4")
  end

  it "resolves model using CLI option first" do
    allow(setting_store).to receive(:get).with("model-fast").and_return("gpt-4-turbo")
    allow(setting_store).to receive(:get).with("default-model").and_return("gpt-3.5")

    config = described_class.new(setting_store, {}, { model: "fast" })
    expect(config.resolved_model).to eq("gpt-4-turbo")
  end

  it "falls back to default_model for resolved_model" do
    allow(setting_store).to receive(:get).with("model").and_return(nil)
    allow(setting_store).to receive(:get).with("default-model").and_return("gpt-3.5")
    allow(setting_store).to receive(:get).with("model-gpt-3.5").and_return(nil)

    config = described_class.new(setting_store, {}, {})
    expect(config.resolved_model).to eq("gpt-3.5")
  end
end
