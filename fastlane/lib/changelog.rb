# Turns release-please changelog markdown into the plain "What to Test" text
# TestFlight shows. Pure functions only, so it runs under plain Ruby.
module Changelog
  # App Store Connect rejects What to Test longer than this.
  LIMIT = 4000

  HEADINGS = {
    "Features" => "New",
    "Bug Fixes" => "Fixes",
    "Performance Improvements" => "Performance",
    "Reverts" => "Reverts",
    "⚠ BREAKING CHANGES" => "Breaking changes"
  }.freeze

  # Commit types testers have no use for, and the changelog sections they land in.
  HIDDEN_TYPES = %w[chore build ci docs style test refactor].freeze
  HIDDEN_HEADINGS = [
    "Miscellaneous Chores", "Build System", "Continuous Integration",
    "Documentation", "Styles", "Tests", "Code Refactoring"
  ].freeze

  COMMIT_TYPES = { "feat" => "New", "fix" => "Fixes", "perf" => "Performance" }.freeze

  module_function

  # Body of the `## [version]` section, without its own heading line.
  def section(markdown, version)
    lines = markdown.lines
    start = lines.index { |l| l.match?(/\A## \[#{Regexp.escape(version)}\]/) }
    return nil unless start

    rest = lines[(start + 1)..]
    stop = rest.index { |l| l.start_with?("## ") } || rest.length
    rest.first(stop).join
  end

  # Groups of [heading, entries] from a release-please section body.
  def groups_from_section(body)
    groups = []
    hidden = false
    body.each_line do |raw|
      line = raw.strip
      if (m = line.match(/\A###\s+(.+)\z/))
        hidden = HIDDEN_HEADINGS.include?(m[1])
        groups << [HEADINGS.fetch(m[1], m[1]), []] unless hidden
      elsif (m = line.match(/\A[*-]\s+(.+)\z/)) && !hidden && !groups.empty?
        entry = clean_entry(m[1])
        groups.last[1] << entry if entry
      end
    end
    groups
  end

  # Groups from `git log --pretty=%s` subjects; only user-facing types survive.
  def groups_from_subjects(subjects)
    groups = COMMIT_TYPES.values.uniq.to_h { |title| [title, []] }
    subjects.each do |subject|
      m = subject.strip.match(/\A(\w+)(?:\(([^)]*)\))?!?:\s+(.+)\z/)
      next unless m && (title = COMMIT_TYPES[m[1]])

      entry = clean_entry(m[2] ? "**#{m[2]}:** #{m[3]}" : m[3])
      groups[title] << entry if entry
    end
    groups.to_a
  end

  # Plain text, cut at an entry boundary to fit the limit and noting what was left out.
  def format_groups(groups, limit = LIMIT)
    groups = groups.map { |title, entries| [title, entries.uniq] }.reject { |_, entries| entries.empty? }
    flat = groups.flat_map { |title, entries| entries.map { |e| [title, e] } }
    full = join_groups(flat)
    return full if full.length <= limit

    flat.length.downto(0) do |keep|
      note = "...and #{flat.length - keep} more changes"
      text = [join_groups(flat.first(keep)), note].reject(&:empty?).join("\n\n")
      return text if text.length <= limit
    end
  end

  def join_groups(flat)
    flat.group_by(&:first)
        .map { |title, rows| ([title, ""] + rows.map { |_, e| "- #{e}" }).join("\n") }
        .join("\n\n")
  end

  # `curated` is the hand-written metadata/beta/whats_new/<version>.txt, when it exists.
  def for_release(markdown:, version:, subjects:, since: nil, curated: nil, env: ENV)
    override = env["FABRIX_CHANGELOG"].to_s
    return override unless override.strip.empty?

    return curated.strip unless curated.to_s.strip.empty?

    body = section(markdown, version)
    text = body ? format_groups(groups_from_section(body)) : ""
    return text unless text.empty?

    header = since ? "Changes since #{since}" : "Changes"
    text = format_groups(groups_from_subjects(subjects), LIMIT - header.length - 2)
    text.empty? ? text : "#{header}\n\n#{text}"
  end

  # "**scope:** text ([abc1234](url))" -> "Scope: text"
  def clean_entry(entry)
    scope = nil
    text = entry.sub(/\A\*\*([^*]+?):\*\*\s*/) { scope = Regexp.last_match(1); "" }
    return nil if HIDDEN_TYPES.include?(scope)

    text = text.gsub(/\s*\(\[[0-9a-f]{7,40}\]\([^)]*\)\)/, "")
               .gsub(/\s*\(#\d+\)\s*\z/, "")
               .gsub(/\[([^\]]+)\]\([^)]*\)/, '\1')
               .gsub(/\s+/, " ")
               .strip
    return nil if text.empty?

    scope ? "#{scope.capitalize}: #{text}" : text
  end
end
