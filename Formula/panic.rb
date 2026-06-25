class Panic < Formula
  desc "One-step hide-and-lock kill-switch for macOS"
  homepage "https://github.com/Di-kairos/panic"
  url "https://github.com/Di-kairos/panic/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "7e5e9891cb3c0e61cb0a263c9dc0c0dcf0f78d0f1d514ab8ab16dd2e8fb2e7cb"
  license "MIT"

  def install
    bin.install "panic"
  end

  test do
    assert_match "panic", shell_output("#{bin}/panic version")
  end
end
