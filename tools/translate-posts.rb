#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'pathname'
require 'time'
require 'uri'

require 'kramdown'
require 'kramdown-parser-gfm'

POSTS_DIR = File.expand_path('../_posts', __dir__)
OUTPUT_DIR = File.expand_path('../assets/translations', __dir__)
GAS_URL = ENV['GOOGLE_APPS_SCRIPT_URL']
GAS_TOKEN = ENV['GOOGLE_APPS_SCRIPT_TOKEN']

SLEEP_BETWEEN_POSTS = 3
HISTORY_DRIP_LIMIT = 10
NEW_PRIORITY_LIMIT = 15
MAX_REDIRECTS = 5

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

exit(0) unless GAS_URL

FileUtils.mkdir_p(OUTPUT_DIR)

def hash_content(content)
  Digest::SHA256.hexdigest(content)
end

def sleep_between_posts
  sleep(SLEEP_BETWEEN_POSTS)
end

def translate_atomic(text_array, target)
  response = post_json_with_redirects(
    GAS_URL,
    {
      q: text_array,
      target: target,
      token: GAS_TOKEN
    }
  )

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

def post_json_with_redirects(url, payload, limit = MAX_REDIRECTS)
  raise 'too many translation proxy redirects' if limit <= 0

  uri = URI(url)
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Accept'] = 'application/json'
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  return response unless response.is_a?(Net::HTTPRedirection)

  location = response['location']
  raise 'translation proxy redirect missing Location header' if location.to_s.empty?

  redirected_url = URI.join(url, location).to_s
  post_json_with_redirects(redirected_url, payload, limit - 1)
end

def parse_post(content)
  fm_match = content.match(/\A---([\s\S]*?)---/)
  front_matter = fm_match ? fm_match[1] : ''
  body = fm_match ? content[fm_match[0].length..] : content
  title = front_matter[/^title:\s*(.*)$/, 1]&.gsub(/['"]/, '')&.strip || ''
  desc = front_matter[/^description:\s*(.*)$/, 1]&.gsub(/['"]/, '')&.strip || ''
  { title: title, desc: desc, body: body.to_s.strip }
end

def parse_markdown(markdown)
  Kramdown::Document.new(markdown, input: 'GFM')
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
  document = parse_markdown(parsed[:body])
  text_nodes = collect_text_nodes(document.root)
  to_translate = [parsed[:title], parsed[:desc], *text_nodes.map(&:value)]
  translated = translate_atomic(to_translate, 'en')

  text_nodes.each_with_index do |node, index|
    node.value = translated[index + 2] || node.value
  end

  result = {
    title: translated[0],
    description: translated[1],
    content: document.to_html,
    format: 'html',
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

main
