class ClaudePager < Formula
  desc "Approve Claude Code permission prompts from your phone"
  homepage "https://github.com/FilipCondac/claude-pager"
  url "https://github.com/FilipCondac/claude-pager/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "13334f19e47c8ebd06dcee90173c9b0935274ac600c24abd56b688b52c05f80c"
  license "MIT"

  depends_on "tmux"
  depends_on "python@3.12"

  def install
    bin.install "bin/claude-pager-hook"
    bin.install "bin/claude-pager-daemon"
    bin.install "bin/claude-pager-setup"
    bin.install "bin/claude-pager-status"
    bin.install "bin/claude-pager-test"
    (pkgshare/"launchd").install "launchd/com.claudepager.daemon.plist.template"
  end

  def caveats
    <<~EOS
      Finish the per-user setup (generates topics + HMAC secret, installs the
      LaunchAgent into your account, and wires the Claude Code hook):

        CLAUDE_PAGER_PLIST_TEMPLATE="#{pkgshare}/launchd/com.claudepager.daemon.plist.template" \\
          claude-pager-setup

      Then subscribe to the printed topic in the ntfy iOS app and start Claude
      inside a tmux session:

        tmux new -s claude
        claude
    EOS
  end

  test do
    assert_predicate bin/"claude-pager-daemon", :executable?
    assert_predicate bin/"claude-pager-hook", :executable?
    assert_predicate bin/"claude-pager-setup", :executable?
  end
end
