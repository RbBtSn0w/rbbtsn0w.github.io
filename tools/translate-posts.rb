#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'date'
require 'fileutils'
require 'json'
require 'net/http'
require 'nokogiri'
require 'pathname'
require 'time'
require 'tempfile'
require 'uri'
require 'yaml'

require 'kramdown'
require 'kramdown-parser-gfm'

POSTS_DIR = File.expand_path('../_posts', __dir__)
OUTPUT_DIR = File.expand_path('../assets/translations', __dir__)
SITE_CONFIG_PATH = File.expand_path('../_config.yml', __dir__)
GAS_URL = ENV['GOOGLE_APPS_SCRIPT_URL']
GAS_TOKEN = ENV['GOOGLE_APPS_SCRIPT_TOKEN']

SLEEP_BETWEEN_POSTS = 3
HISTORY_DRIP_LIMIT = 10
NEW_PRIORITY_LIMIT = 15
MAX_REDIRECTS = 5
COPY_CODE_SUCCEED_TEXT = 'Copied!'.freeze

SKIPPED_TYPES = %i[
  codeblock
  codespan
  html_element
  xml_comment
  math
  blank
].freeze

SITE_CONFIG = YAML.safe_load(File.read(SITE_CONFIG_PATH), aliases: true) || {}
KRAMDOWN_OPTIONS = (SITE_CONFIG['kramdown'] || {}).merge('input' => 'GFM').freeze
HEADING_SELECTOR = 'h2[id], h3[id], h4[id], h5[id]'.freeze
TRANSLATION_FORMAT = 'bilingual_html'.freeze

LANGUAGE_LABELS = {
  'bash' => 'Shell',
  'shell' => 'Shell',
  'sh' => 'Shell',
  'zsh' => 'Shell',
  'console' => 'Console',
  'plaintext' => 'Text',
  'text' => 'Text',
  'objc' => 'Objective-C',
  'objective-c' => 'Objective-C',
  'obj-c' => 'Objective-C',
  'js' => 'JavaScript',
  'ts' => 'TypeScript',
  'yml' => 'YAML',
  'md' => 'Markdown'
}.freeze

FileUtils.mkdir_p(OUTPUT_DIR)

def safe_yaml_load(yaml)
  YAML.safe_load(
    yaml,
    permitted_classes: [Date, Time],
    aliases: true
  ) || {}
end

def hash_content(content)
  Digest::SHA256.hexdigest(content)
end

def sleep_between_posts
  sleep(SLEEP_BETWEEN_POSTS)
end

def translate_atomic(text_array, target)
  payload = {
    q: text_array,
    target: target,
    token: GAS_TOKEN
  }
  response = request_with_redirects(GAS_URL, method: :post, payload: payload)

  unless response.is_a?(Net::HTTPSuccess)
    raise "translation proxy returned HTTP #{response.code}"
  end

  content_type = response['content-type'].to_s
  unless content_type.include?('application/json')
    preview = response.body.to_s.strip[0, 120]
    raise "translation proxy returned non-JSON content-type=#{content_type.inspect} body=#{preview.inspect}"
  end

  data = JSON.parse(response.body)
  raise(data['error']) if data['error']

  data.fetch('data').fetch('translations').map { |item| item.fetch('translatedText') }
end

def request_with_redirects(url, method:, payload: nil, limit: MAX_REDIRECTS)
  raise 'too many translation proxy redirects' if limit <= 0

  uri = URI(url)
  request = if method == :get
              Net::HTTP::Get.new(uri)
            else
              Net::HTTP::Post.new(uri)
            end

  request['Accept'] = 'application/json'
  if method == :post
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload)
  end

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  return response unless response.is_a?(Net::HTTPRedirection)

  location = response['location']
  raise 'translation proxy redirect missing Location header' if location.to_s.empty?

  redirected_url = URI.join(url, location).to_s
  next_method = if response.is_a?(Net::HTTPTemporaryRedirect) || response.is_a?(Net::HTTPPermanentRedirect)
                  method
                elsif method == :post
                  :get
                else
                  method
                end
  next_payload = next_method == :post ? payload : nil

  request_with_redirects(redirected_url, method: next_method, payload: next_payload, limit: limit - 1)
end

def parse_post(content)
  front_matter = {}
  body = content

  if (match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m))
    front_matter = safe_yaml_load(match[1])
    body = content[match[0].length..]
  end

  {
    title: front_matter.fetch('title', '').to_s.strip,
    desc: front_matter.fetch('description', '').to_s.strip,
    body: body.to_s.strip
  }
end

def parse_markdown(markdown)
  Kramdown::Document.new(markdown, KRAMDOWN_OPTIONS)
end

def render_document(document, lang:)
  postprocess_content_html(document.to_html, lang: lang)
end

def postprocess_content_html(html, lang:)
  normalized_html = html
    .gsub('<div class="highlight"><pre class="highlight"><code', '<div class="highlight"><code')
    .gsub('</code></pre></div>', '</code></div>')

  fragment = Nokogiri::HTML::DocumentFragment.parse(normalized_html)
  wrap_tables(fragment)
  replace_task_list_checkboxes(fragment)
  add_code_headers(fragment, lang: lang)
  add_heading_anchors(fragment)
  fragment.to_html
end

def wrap_tables(fragment)
  fragment.css('table').each do |table|
    next if table.ancestors('code').any?
    next if table.parent&.name == 'div' && table.parent['class'].to_s.split.include?('table-wrapper')

    wrapper = Nokogiri::XML::Node.new('div', fragment)
    wrapper['class'] = 'table-wrapper'
    table.replace(wrapper)
    wrapper.add_child(table)
  end
end

def replace_task_list_checkboxes(fragment)
  fragment.css('input.task-list-item-checkbox[type="checkbox"]').each do |input|
    icon = Nokogiri::XML::Node.new('i', fragment)
    icon['class'] = input['checked'] ? 'fas fa-check-circle fa-fw checked' : 'far fa-circle fa-fw'
    input.replace(icon)
  end
end

def add_code_headers(fragment, lang:)
  fragment.css('div.highlight > code').each do |code_node|
    highlight = code_node.parent
    next if highlight.previous_element&.[]('class').to_s.split.include?('code-header')

    header = Nokogiri::XML::Node.new('div', fragment)
    header['class'] = 'code-header'

    label = Nokogiri::XML::Node.new('span', fragment)
    label['data-label-text'] = code_label_for(highlight)

    icon = Nokogiri::XML::Node.new('i', fragment)
    icon['class'] = code_icon_class_for(highlight, lang: lang)
    label.add_child(icon)

    button = Nokogiri::XML::Node.new('button', fragment)
    button['aria-label'] = 'copy'
    button['data-title-succeed'] = COPY_CODE_SUCCEED_TEXT

    button_icon = Nokogiri::XML::Node.new('i', fragment)
    button_icon['class'] = 'far fa-clipboard'
    button.add_child(button_icon)

    header.add_child(label)
    header.add_child(button)
    highlight.add_previous_sibling(header)
  end
end

def code_label_for(highlight)
  wrapper = highlight.ancestors.find { |node| node['class'].to_s.include?('language-') }
  file_name = wrapper&.[]('file').to_s.strip
  return file_name unless file_name.empty?

  language = wrapper&.[]('class').to_s[/language-([A-Za-z0-9_+\-.]+)/, 1].to_s.downcase
  return 'Code' if language.empty?

  LANGUAGE_LABELS.fetch(language, language.split(/[-_+]/).map(&:capitalize).join(' '))
end

def code_icon_class_for(highlight, lang: nil)
  wrapper = highlight.ancestors.find { |node| node['class'].to_s.include?('language-') }
  if wrapper&.[]('file').to_s.strip.empty?
    'fas fa-code fa-fw small'
  else
    'far fa-file-code fa-fw'
  end
end

def add_heading_anchors(fragment)
  fragment.css(HEADING_SELECTOR).each do |heading|
    next if heading.at_css('a.anchor')

    wrapper = Nokogiri::XML::Node.new('span', fragment)
    wrapper['class'] = 'me-2'
    heading.children.to_a.each do |child|
      wrapper.add_child(child.unlink)
    end

    anchor = Nokogiri::XML::Node.new('a', fragment)
    anchor['href'] = "##{heading['id']}"
    anchor['class'] = 'anchor text-muted'

    icon = Nokogiri::XML::Node.new('i', fragment)
    icon['class'] = 'fas fa-hashtag'
    anchor.add_child(icon)

    heading.add_child(wrapper)
    heading.add_child(anchor)
  end
end

def validate_translations!(translations, count, sources: nil)
  unless translations.is_a?(Array) && translations.length == count &&
         translations.all? { |text| text.is_a?(String) && !text.strip.empty? }
    raise ArgumentError, 'translation response count or text is invalid'
  end
  missing_value = /\[\s*value\s+missing\s*\]/i
  if translations.each_with_index.any? { |text, index| text.match?(missing_value) && !sources&.fetch(index)&.match?(missing_value) }
    raise ArgumentError, 'translation contains a missing-value placeholder'
  end
end

# Translate a complete inline context, not disconnected text nodes. Markers
# describe the existing AST; returned markup/attributes are never trusted.
class TranslationUnit
  TOKEN = /\[\[\[(\/?)(\d+)\]\]\]/
  INLINE_CONTAINERS = %i[strong em a].freeze
  attr_reader :element, :source

  def initialize(element)
    @element = element
    @nodes = []
    @source = element.children.map { |child| serialize(child) }.join
    @tokens = @source.scan(TOKEN)
  end

  def serialize(node)
    if node.type == :text
      raise ArgumentError, 'reserved translation marker in source' if node.value.include?('[[[')

      return node.value
    end
    id = @nodes.length
    @nodes << node
    text = if INLINE_CONTAINERS.include?(node.type)
             node.children.map { |child| serialize(child) }.join
           else
             literal(node)
           end
    "[[[#{id}]]]#{text}[[[/#{id}]]]"
  end

  def literal(node)
    return node.value if node.type == :codespan

    root = Kramdown::Element.new(:root, nil, nil, encoding: Encoding::UTF_8)
    root.children << node
    html, = Kramdown::Converter::Html.convert(root, KRAMDOWN_OPTIONS)
    Nokogiri::HTML.fragment(html).text
  end

  def apply(text)
    validate_translations!([text], 1, sources: [@source])
    raise ArgumentError, 'translation changed inline markers' unless text.scan(TOKEN) == @tokens

    validate_spacing!(text)
    root = Kramdown::Element.new(:root)
    stack = [root]
    offset = 0
    text.to_enum(:scan, TOKEN).each do
      match = Regexp.last_match
      append_text(stack.last, text[offset...match.begin(0)])
      node = @nodes.fetch(match[2].to_i)
      if match[1].empty?
        copy = Kramdown::Element.new(node.type, node.value, node.attr.dup, node.options.dup)
        stack.last.children << copy
        stack << copy
      else
        copy = stack.pop
        unless INLINE_CONTAINERS.include?(node.type)
          actual = copy.children.map(&:value).join
          raise ArgumentError, 'translation changed a protected literal' unless actual == literal(node)

          # Restore the entire original node, including raw HTML/math options.
          stack.last.children[-1] = node
        end
      end
      offset = match.end(0)
    end
    append_text(root, text[offset..])
    @element.children = root.children
  end

  def append_text(parent, text)
    raise ArgumentError, 'unknown translation marker' if text.include?('[[[')
    parent.children << Kramdown::Element.new(:text, text) unless text.empty?
  end

  def boundary_pairs(text)
    text.enum_for(:scan, TOKEN).map do
      match = Regexp.last_match
      [text[0...match.begin(0)].gsub(TOKEN, '')[-1], text[match.end(0)..].gsub(TOKEN, '')[0]]
    end
  end

  def joined_words?(pair)
    pair[0]&.match?(/[A-Za-z0-9)%\]]/) && pair[1]&.match?(/[A-Za-z0-9]/)
  end

  def validate_spacing!(text)
    boundary_pairs(@source).zip(boundary_pairs(text)).each do |original, translated|
      # Preserve intentional intra-word formatting already present in English.
      if joined_words?(translated) && !joined_words?(original)
        raise ArgumentError, 'translation joined words across an inline boundary'
      end
    end
  end
end

def translation_units(element, result = [])
  return result if SKIPPED_TYPES.include?(element.type)

  if %i[p header td th].include?(element.type)
    result << TranslationUnit.new(element) unless element.children.empty?
  else
    element.children.each { |child| translation_units(child, result) }
  end
  result
end

def build_translation(raw_content, translator: method(:translate_atomic))
  parsed = parse_post(raw_content)
  source_document = parse_markdown(parsed[:body])
  translated_document = parse_markdown(parsed[:body])
  units = translation_units(translated_document.root)
  queries = [parsed[:title], parsed[:desc], *units.map(&:source)]
  indices = queries.each_index.reject { |index| queries[index].strip.empty? }
  inputs = indices.map { |index| queries[index] }
  responses = inputs.empty? ? [] : translator.call(inputs, 'en')
  validate_translations!(responses, inputs.length, sources: inputs)
  translated = Array.new(queries.length, '')
  indices.zip(responses).each { |index, text| translated[index] = text }
  units.zip(translated.drop(2)).each { |unit, text| unit.apply(text) }

  {
    format: TRANSLATION_FORMAT,
    schema_version: 2,
    source_lang: 'zh-CN',
    target_lang: 'en',
    translations: {
      'zh-CN' => { title: parsed[:title], description: parsed[:desc], content: render_document(source_document, lang: 'zh-CN') },
      'en' => { title: translated[0], description: translated[1], content: render_document(translated_document, lang: 'en') }
    },
    hash: hash_content(raw_content),
    timestamp: Time.now.utc.iso8601
  }
end

def write_translation(out_path, raw_content, translator: method(:translate_atomic))
  result = build_translation(raw_content, translator: translator)
  Tempfile.create(['.translation-', '.json'], File.dirname(out_path)) do |file|
    file.write(JSON.pretty_generate(result))
    file.chmod(File.exist?(out_path) ? File.stat(out_path).mode & 0o777 : 0o644)
    file.close
    File.rename(file.path, out_path)
  end
end

def process_file(filename)
  file_path = File.join(POSTS_DIR, filename)
  slug = filename.sub(/^\d{4}-\d{2}-\d{2}-/, '').sub(/\.md$/, '')
  out_path = File.join(OUTPUT_DIR, "#{slug}.json")
  raw_content = File.read(file_path)
  puts "🌐 [Translating] #{filename}"
  write_translation(out_path, raw_content)
  true
rescue StandardError => e
  warn "✗ [Fail] #{filename}: #{e.message}"
  false
end

def queues_for(files)
  modified_queue = []
  untranslated_queue = []

  files.each do |file|
    file_path = File.join(POSTS_DIR, file)
    slug = file.sub(/^\d{4}-\d{2}-\d{2}-/, '').sub(/\.md$/, '')
    out_path = File.join(OUTPUT_DIR, "#{slug}.json")
    raw_content = File.read(file_path)
    current_hash = hash_content(raw_content)

    if !File.exist?(out_path)
      untranslated_queue << file
      next
    end

    existing = JSON.parse(File.read(out_path))
    modified_queue << file if existing['hash'] != current_hash
  end

  [modified_queue, untranslated_queue]
end

def main
  unless GAS_URL
    puts 'GOOGLE_APPS_SCRIPT_URL is not set, skipping translation generation.'
    return
  end

  files = Dir.children(POSTS_DIR).select { |name| name.end_with?('.md') }
  modified_queue, untranslated_queue = queues_for(files)

  puts "Found: #{modified_queue.length} modified, #{untranslated_queue.length} untranslated history."

  total_processed = 0

  modified_queue.first(NEW_PRIORITY_LIMIT).each do |file|
    if process_file(file)
      total_processed += 1
      sleep_between_posts
    end
  end

  if total_processed < NEW_PRIORITY_LIMIT
    budget_left = [HISTORY_DRIP_LIMIT, NEW_PRIORITY_LIMIT - total_processed].min
    puts "Backfilling history (Budget: #{budget_left})..."

    untranslated_queue.first(budget_left).each do |file|
      if process_file(file)
        total_processed += 1
        sleep_between_posts
      end
    end
  end

  puts "Total translated this run: #{total_processed}"
end

main if __FILE__ == $PROGRAM_NAME
