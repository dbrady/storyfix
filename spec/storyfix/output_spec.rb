require "spec_helper"

RSpec.describe Storyfix::Output do
  it "prints error in red" do
    expect { described_class.error("msg") }.to output(/storyfix: error: msg/).to_stderr
  end

  it "prints success in green" do
    expect { described_class.success("msg") }.to output(/storyfix: success: msg/).to_stderr
  end

  it "prints warning in yellow" do
    expect { described_class.warn("msg") }.to output(/storyfix: warning: msg/).to_stderr
  end

  it "prints info in cyan" do
    expect { described_class.info("msg") }.to output(/storyfix: msg/).to_stderr
  end

  it "prints debug in light black" do
    expect { described_class.debug("msg") }.to output(/storyfix: debug: msg/).to_stderr
  end
end
