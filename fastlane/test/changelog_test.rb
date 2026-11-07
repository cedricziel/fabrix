require "minitest/autorun"
require_relative "../lib/changelog"

class ChangelogTest < Minitest::Test
  FIXTURE = <<~MD
    # Changelog

    ## [0.2.0](https://github.com/cedricziel/fabrix/compare/v0.1.0...v0.2.0) (2026-11-07)


    ### Features

    * **app:** sign in to factories from onboarding ([9116bb6](https://github.com/cedricziel/fabrix/commit/9116bb6110a8372fa5e72089fe4c63c92c812837))
    * **core:** add OIDC sign-in with discovery and PKCE ([17005fd](https://github.com/cedricziel/fabrix/commit/17005fdde04020c63fe10614c911c4bb48525c70))
    * public TestFlight beta with Beta App Review ([d7e260f](https://github.com/cedricziel/fabrix/commit/d7e260ff030405aacee21dc0e4a62202483d34cc))


    ### Bug Fixes

    * **core:** follow redirects only within the server's origin ([d82655e](https://github.com/cedricziel/fabrix/commit/d82655e34f214409df5ca7ea26c685cb41ede2cc))
    * **features:** size buttons to 44pt touch targets on iOS ([7086976](https://github.com/cedricziel/fabrix/commit/7086976b3a1c0f4f0a1f9d6d1d9a5d0c6b9e0f11))


    ### Miscellaneous Chores

    * **ci:** pin actions ([aaaaaaa](https://github.com/cedricziel/fabrix/commit/aaaaaaa0000000000000000000000000000000))

    ## [0.1.0](https://github.com/cedricziel/fabrix/compare/v0.0.1...v0.1.0) (2026-10-01)

    ### Features

    * **core:** older feature ([bbbbbbb](https://github.com/cedricziel/fabrix/commit/bbbbbbb0000000000000000000000000000000))
  MD

  EXPECTED = <<~TXT.chomp
    New

    - App: sign in to factories from onboarding
    - Core: add OIDC sign-in with discovery and PKCE
    - public TestFlight beta with Beta App Review

    Fixes

    - Core: follow redirects only within the server's origin
    - Features: size buttons to 44pt touch targets on iOS
  TXT

  def test_renders_a_release_please_section_as_plain_text
    body = Changelog.section(FIXTURE, "0.2.0")
    assert_equal EXPECTED, Changelog.format_groups(Changelog.groups_from_section(body))
  end

  def test_renders_the_real_0_2_0_section_within_the_limit
    markdown = File.read(File.join(__dir__, "fixtures", "changelog_0.2.0.md"))
    text = Changelog.for_release(markdown: markdown, version: "0.2.0", subjects: [], env: {})

    assert_operator text.length, :<=, Changelog::LIMIT
    assert text.start_with?("New\n\n- App: render the Fabrix mark as iOS and macOS app icons\n")
    assert_includes text, "\n\nFixes\n\n"
    refute_match(/[0-9a-f]{7}\]|https?:|\]\(|\*\*/, text)
  end

  def test_section_stops_at_the_next_release
    refute_includes Changelog.section(FIXTURE, "0.2.0"), "older feature"
  end

  def test_missing_section_is_nil
    assert_nil Changelog.section(FIXTURE, "9.9.9")
  end

  def test_drops_hashes_links_and_hidden_types
    text = Changelog.for_release(markdown: FIXTURE, version: "0.2.0", subjects: [], env: {})
    refute_match(/[0-9a-f]{7}|https?:|\]\(|\*\*|pin actions/, text)
  end

  def test_strips_markdown_links_inside_entries
    assert_equal "Core: see docs", Changelog.clean_entry("**core:** see [docs](https://x.y/z) ([abc1234](https://x.y/c/abc1234))")
  end

  def test_caps_at_an_entry_boundary
    entries = Array.new(200) { |i| "- Core: entry number #{i} " + "x" * 30 }
    markdown = "## [1.0.0](u) (d)\n\n### Features\n\n" + entries.map { |e| e.sub("- ", "* **core:** ").sub("Core: ", "") }.join("\n") + "\n"
    text = Changelog.for_release(markdown: markdown, version: "1.0.0", subjects: [], env: {})

    assert_operator text.length, :<=, Changelog::LIMIT
    lines = text.lines.map(&:chomp)
    assert_match(/\A\.\.\.and \d+ more changes\z/, lines.last)
    assert(lines[0..-3].all? { |l| l.empty? || l == "New" || l.match?(/\A- Core: entry number \d+ x{30}\z/) })
    kept = lines.count { |l| l.start_with?("- ") }
    assert_equal 200 - kept, lines.last[/\d+/].to_i
  end

  def test_missing_section_falls_back_to_user_facing_commits
    subjects = [
      "feat(core): add a thing (#12)",
      "fix: repair the other thing",
      "chore(deps): bump x",
      "ci: pin actions",
      "docs: readme",
      "Merge pull request #1 from a/b"
    ]
    text = Changelog.for_release(markdown: FIXTURE, version: "0.3.0", subjects: subjects, since: "v0.2.0", env: {})

    assert_equal <<~TXT.chomp, text
      Changes since v0.2.0

      New

      - Core: add a thing

      Fixes

      - repair the other thing
    TXT
  end

  def test_env_override_is_used_verbatim
    text = Changelog.for_release(markdown: FIXTURE, version: "0.2.0", subjects: [], env: { "FABRIX_CHANGELOG" => "  Hand-written\n\n- notes " })
    assert_equal "  Hand-written\n\n- notes ", text
  end

  def test_blank_env_override_is_ignored
    text = Changelog.for_release(markdown: FIXTURE, version: "0.2.0", subjects: [], env: { "FABRIX_CHANGELOG" => "  " })
    assert_equal EXPECTED, text
  end

  def test_nothing_user_facing_yields_empty_text
    assert_equal "", Changelog.for_release(markdown: "", version: "1.0.0", subjects: ["chore: x"], env: {})
  end
end
