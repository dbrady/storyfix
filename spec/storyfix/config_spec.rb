require "spec_helper"

RSpec.describe Storyfix::Config do
  let(:setting_store) { instance_double("Storyfix::Setting") }

  describe "#get" do
    context "with CLI option set" do
      it "returns the CLI value" do
        allow(setting_store).to receive(:get).with("my-key").and_return("db-val")
        env = { "STORYFIX_MY_KEY" => "env-val" }

        config = Storyfix::Config.new(setting_store, env, { :"my-key" => "cli-val" })

        expect(config.get("my-key")).to eq("cli-val")
      end
    end

    context "with ENV variable set" do
      it "returns the ENV value" do
        allow(setting_store).to receive(:get).with("my-key").and_return("db-val")
        env = { "STORYFIX_MY_KEY" => "env-val" }

        config = Storyfix::Config.new(setting_store, env, {})

        expect(config.get("my-key")).to eq("env-val")
      end
    end

    context "with only settings value" do
      it "returns the settings value" do
        allow(setting_store).to receive(:get).with("my-key").and_return("db-val")

        config = Storyfix::Config.new(setting_store, {}, {})

        expect(config.get("my-key")).to eq("db-val")
      end
    end
  end

  describe "#api_key" do
    context "with OPENROUTER_API_KEY env variable" do
      it "returns the env value" do
        allow(setting_store).to receive(:get).and_return(nil)

        config = Storyfix::Config.new(setting_store, { "OPENROUTER_API_KEY" => "secret" })

        expect(config.api_key).to eq("secret")
      end
    end

    context "with openrouter-api-key setting" do
      it "returns the setting value" do
        allow(setting_store).to receive(:get).with("openrouter-api-key").and_return("openrouter-key")

        config = Storyfix::Config.new(setting_store, {}, {})

        expect(config.api_key).to eq("openrouter-key")
      end
    end

    context "with api-key setting as fallback" do
      it "returns the legacy setting value" do
        allow(setting_store).to receive(:get).with("openrouter-api-key").and_return(nil)
        allow(setting_store).to receive(:get).with("api-key").and_return("legacy-key")

        config = Storyfix::Config.new(setting_store, {}, {})

        expect(config.api_key).to eq("legacy-key")
      end
    end
  end

  describe "#model_for" do
    context "with a model alias defined" do
      it "returns the aliased model" do
        allow(setting_store).to receive(:get).with("model-opus").and_return("anthropic/claude-3-opus")

        config = Storyfix::Config.new(setting_store)

        expect(config.model_for("opus")).to eq("anthropic/claude-3-opus")
      end
    end

    context "without a model alias defined" do
      it "returns the input unchanged" do
        allow(setting_store).to receive(:get).with("model-custom").and_return(nil)

        config = Storyfix::Config.new(setting_store)

        expect(config.model_for("custom")).to eq("custom")
      end
    end

    context "with nil input" do
      it "returns nil" do
        config = Storyfix::Config.new(setting_store)

        expect(config.model_for(nil)).to be_nil
      end
    end
  end

  describe "#system_prompt" do
    it "returns the system-prompt-fix setting" do
      allow(setting_store).to receive(:get).with("system-prompt-fix").and_return("You are helpful.")

      config = Storyfix::Config.new(setting_store)

      expect(config.system_prompt).to eq("You are helpful.")
    end
  end

  describe "#default_model" do
    it "returns the default-model setting" do
      allow(setting_store).to receive(:get).with("default-model").and_return("gpt-4")

      config = Storyfix::Config.new(setting_store)

      expect(config.default_model).to eq("gpt-4")
    end
  end

  describe "#resolved_model" do
    context "with CLI model option" do
      it "resolves the CLI model through aliases" do
        allow(setting_store).to receive(:get).with("model-fast").and_return("gpt-4-turbo")
        allow(setting_store).to receive(:get).with("default-model").and_return("gpt-3.5")

        config = Storyfix::Config.new(setting_store, {}, { model: "fast" })

        expect(config.resolved_model).to eq("gpt-4-turbo")
      end
    end

    context "without CLI model option" do
      it "falls back to default_model" do
        allow(setting_store).to receive(:get).with("model").and_return(nil)
        allow(setting_store).to receive(:get).with("default-model").and_return("gpt-3.5")
        allow(setting_store).to receive(:get).with("model-gpt-3.5").and_return(nil)

        config = Storyfix::Config.new(setting_store, {}, {})

        expect(config.resolved_model).to eq("gpt-3.5")
      end
    end
  end
end
