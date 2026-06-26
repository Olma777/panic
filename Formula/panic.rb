class Panic < Formula
  desc "One-step hide-and-lock kill-switch for macOS"
  homepage "https://github.com/Di-kairos/panic"
  url "https://github.com/Di-kairos/panic/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "83d7cd9a2f6324108b2fa8185999751d48c17b29aa65da61ead8242117958168"
  license "MIT"

  def install
    bin.install "panic"
  end

  test do
    assert_match "panic", shell_output("#{bin}/panic version")
  end
end
