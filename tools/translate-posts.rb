#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'nokogiri'
require 'pathname'
require 'time'
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

TRANSLATABLE_TEXT_CONTAINERS = %i[
  p
  header
  li
  blockquote
  em
  strong
  a
].freeze

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
    front_matter = YAML.safe_load(match[1], aliases: true) || {}
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

def translatable_text_node?(element, parent_types)
  return false unless element.type == :text
  return false if element.value.to_s.strip.empty?
  return false if parent_types.any? { |type| SKIPPED_TYPES.include?(type) }

  (parent_types & TRANSLATABLE_TEXT_CONTAINERS).any?
end

def collect_text_nodes(element, parent_types = [], result = [])
  current_parent_types = parent_types + [element.type]

  if translatable_text_node?(element, parent_types)
    result << element
  end

  return result if SKIPPED_TYPES.include?(element.type)

  element.children.each do |child|
    collect_text_nodes(child, current_parent_types, result)
  end

  result
end

def process_file(filename)
  file_path = File.join(POSTS_DIR, filename)
  slug = filename.sub(/^\d{4}-\d{2}-\d{2}-/, '').sub(/\.md$/, '')
  out_path = File.join(OUTPUT_DIR, "#{slug}.json")
  raw_content = File.read(file_path)
  current_hash = hash_content(raw_content)

  puts "🌐 [Translating] #{filename}"

  parsed = parse_post(raw_content)
  source_document = parse_markdown(parsed[:body])
  translated_document = parse_markdown(parsed[:body])
  text_nodes = collect_text_nodes(translated_document.root)
  to_translate = [parsed[:title], parsed[:desc], *text_nodes.map(&:value)]
  translated = translate_atomic(to_translate, 'en')

  text_nodes.each_with_index do |node, index|
    node.value = translated[index + 2] || node.value
  end

  result = {
    format: TRANSLATION_FORMAT,
    schema_version: 2,
    source_lang: 'zh-CN',
    target_lang: 'en',
    translations: {
      'zh-CN' => {
        title: parsed[:title],
        description: parsed[:desc],
        content: render_document(source_document, lang: 'zh-CN')
      },
      'en' => {
        title: translated[0],
        description: translated[1],
        content: render_document(translated_document, lang: 'en')
      }
    },
    hash: current_hash,
    timestamp: Time.now.utc.iso8601
  }

  File.write(out_path, JSON.pretty_generate(result))
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
