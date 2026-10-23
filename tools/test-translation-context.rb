#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'translate-posts'
require 'tmpdir'

def assert(condition, message)
  raise message unless condition
end

def reject_translation(source, response)
  unit = TranslationUnit.new(parse_markdown(source).root.children.first)
  begin
    unit.apply(response)
  rescue ArgumentError
    return
  end
  raise "Accepted invalid translation: #{response}"
end

document = parse_markdown("**下潜**：目标 `12%`，通常 `0.15s`。\n\n```mermaid\nA-->B\n```\n\n```swift\nlet s = \"<ID> & \\\"quoted\\\"\"\n```\n")
units = translation_units(document.root)
assert(units.length == 1, 'Only the prose paragraph should be submitted')
assert(units.first.source == '[[[0]]]下潜[[[/0]]]：目标 [[[1]]]12%[[[/1]]]，通常 [[[2]]]0.15s[[[/2]]]。', 'Inline values must remain in paragraph context')
before = document.root.children.select { |n| n.type == :codeblock }.map(&:value)
units.first.apply('[[[0]]]Attack fast[[[/0]]]: reduce the volume to [[[1]]]12%[[[/1]]] over [[[2]]]0.15s[[[/2]]].')
html = document.to_html
assert(html.include?('<strong>Attack fast</strong>: reduce'), 'Inline spacing was lost')
assert(html.include?('<code>0.15s</code>.'), 'Inline code changed')
assert(before == document.root.children.select { |n| n.type == :codeblock }.map(&:value), 'Code or Mermaid changed')

reject_translation('时间 `0.15s`。', 'Time [[[0]]]0.25s[[[/0]]].')
reject_translation('时间 `0.15s`。', 'Time [value missing] [[[0]]]0.15s[[[/0]]].')
reject_translation('时间 `0.15s`。', 'Time 0.15s.')
reject_translation('**标签**正文', '[[[0]]]Label[[[/0]]]Body')
reject_translation('**标签**正文', '[[[0]]]Label[[[/0]]][[[0]]]Again[[[/0]]]')

table = parse_markdown("| 维度 | 检查 |\n| --- | --- |\n| 代码 | 使用 `x < y` |\n")
assert(translation_units(table.root).length == 4, 'Table cells must be translated')
link = TranslationUnit.new(parse_markdown('[指南](/posts/example/){:target="_blank" rel="noopener"} & `a < b`').root.children.first)
link.apply('[[[0]]]Guide[[[/0]]] & [[[1]]]a < b[[[/1]]]')
assert(link.element.children.first.attr['href'] == '/posts/example/', 'Link destination changed')
assert(link.element.children.first.attr['rel'] == 'noopener', 'Link attributes changed')
entity = TranslationUnit.new(parse_markdown('尺寸 6.7"、6.5" &amp; `a < b`').root.children.first)
entity.apply(entity.source)
assert(entity.element.children.any? { |n| n.type == :entity }, 'Entity nodes were lost')
literal_placeholder = TranslationUnit.new(parse_markdown('原样保留 `[value missing]`。').root.children.first)
literal_placeholder.apply('Keep [[[0]]][value missing][[[/0]]] literally.')

Dir[File.join(__dir__, 'fixtures/translation-context/*.json')].each do |path|
  fixture = JSON.parse(File.read(path))
  slug = File.basename(path, '.json')
  source = File.read(File.join(POSTS_DIR, "2026-10-19-#{slug}.md"))
  assert(hash_content(source) == fixture.fetch('source_sha256'), "Reviewed fixture is stale: #{slug}")
  result = build_translation(source, translator: lambda { |queries, target|
    assert(target == 'en', 'Unexpected target language')
    assert(queries.length == fixture.fetch('translations').length, 'Translation unit coverage changed')
    fixture.fetch('translations')
  })
  original = Nokogiri::HTML.fragment(result[:translations]['zh-CN'][:content])
  translated = Nokogiri::HTML.fragment(result[:translations]['en'][:content])
  %w[code pre].each do |selector|
    assert(original.css(selector).map(&:to_html) == translated.css(selector).map(&:to_html), "#{slug}: #{selector} changed during regeneration")
  end
  assert(original.css('a').map { |a| a['href'] } == translated.css('a').map { |a| a['href'] }, 'Link targets changed')
  assert(!translated.text.include?('[value missing]'), 'Missing-value placeholder remains')
  cached = JSON.parse(File.read(File.join(OUTPUT_DIR, "#{slug}.json")))
  cached_html = Nokogiri::HTML.fragment(cached['translations']['en']['content'])
  prose = ->(html) { html.css('p,h2,h3,li,td,th').reject { |n| n.ancestors('code,pre').any? }.map(&:text) }
  assert(prose.call(cached_html) == prose.call(translated), "#{slug}: cached prose differs from reviewed regeneration")
  assert(translated.css('td,th').reject { |n| n.ancestors('code,pre').any? }.none? { |n| n.text.match?(/\p{Han}/) }, 'Table prose was not translated')
end

%w[missing_count missing_value].each do |failure|
  begin
    build_translation("---\ntitle: Test\ndescription: Test\n---\n正文", translator: ->(_q, _t) { failure == 'missing_count' ? ['Test'] : ['Test', 'Test', '[value missing]'] })
  rescue ArgumentError
    next
  end
  raise "Accepted invalid batch: #{failure}"
end
Dir.mktmpdir('translation-context-test') do |directory|
  path = File.join(directory, 'cached.json')
  File.write(path, 'previous valid cache')
  begin
    write_translation(path, "---\ntitle: Test\ndescription: Test\n---\n正文", translator: ->(_q, _t) { ['Test', 'Test', '[value missing]'] })
  rescue ArgumentError
    assert(File.read(path) == 'previous valid cache', 'Invalid output overwrote the cache')
  else
    raise 'Invalid output was accepted for writing'
  end
  write_translation(path, "---\ntitle: Test\ndescription: Test\n---\n正文", translator: ->(_q, _t) { ['Test', 'Test', 'Body'] })
  assert(JSON.parse(File.read(path))['translations']['en']['content'].include?('Body'), 'Valid cache was not written')
end
posts = Dir[File.join(POSTS_DIR, '*.md')]
without_description = build_translation("---\ntitle: Test\n---\n正文", translator: lambda { |queries, _target|
  assert(queries == ['Test', '正文'], 'Empty optional metadata must not be sent for translation')
  ['Test', 'Body']
})
assert(without_description[:translations]['en'][:description].empty?, 'Missing description should stay empty')
posts.each do |path|
  markdown = parse_post(File.read(path))[:body]
  original = parse_markdown(markdown)
  round_trip = parse_markdown(markdown)
  translation_units(round_trip.root).each { |unit| unit.apply(unit.source) }
  assert(original.to_html == round_trip.to_html, "Identity round trip changed #{File.basename(path)}")
  result = build_translation(File.read(path), translator: ->(queries, _target) { queries })
  assert(result[:translations]['zh-CN'] == result[:translations]['en'], "Identity generation changed #{File.basename(path)}")
end
puts 'PASS: paragraph context, spacing, table coverage, protected literals, and invalid-response rejection'
puts "PASS: #{posts.length} source documents preserve their rendered HTML in identity round trips"
