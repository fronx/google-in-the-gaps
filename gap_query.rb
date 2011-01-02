# encoding: UTF-8
require 'cgi'
require 'google-search'

Enumerable.module_eval do
  def with_index
    index = -1
    map { |item| [item, index += 1] }
  end
end

Array.class_eval do
  def uniq_by(&block)
    mapped = map { |item| block.call(item) }
    with_index.select do |item, index|
      (mapped.count(block.call(item)) == 1) ||
        mapped.index(block.call(item)) == index
    end.map { |item, _| item }
  end
end

class GapQuery
  attr_reader :query

  PLACEHOLDER = %q{[\w\s'"äüöÄÜÖß-]+[\W\.,;!\?]*?}

  def initialize(query)
    @query = query
  end

  def expr
    @expr ||= Regexp.new(
      "(#{query})".
        gsub(/\s*\*\s*/, ") (#{PLACEHOLDER}) ("). # google -> regexp placeholders
        gsub(/\s*\(\)\s*/, ''), # cleanup
      Regexp::IGNORECASE
    )
  end

  def groups
    @groups ||= expr.source.gsub(PLACEHOLDER, '*').split(/\s*\)\s*/).map do |group|
      group[1..-1]
    end
  end

  def results
    Google::Search::Web.new(:query => query)
  end

  class Placeholder < String
  end

  def matching_results(&block)
    results.map do |result|
      text = CGI.unescapeHTML(result.content.
        gsub(/<[\/]?b>/, '').
        gsub(/\s+/, ' ')
      )
      if text =~ expr
        $~.to_a[1..-1].with_index.map do |group, index|
          line = group.gsub(/<[^>]+>/, '')
          groups[index] == '*' ? Placeholder.new(line) : line
        end
      end
    end.compact.
      uniq_by { |ary| ary.to_s.downcase }.
      sort_by { |ary| ary.to_s.downcase }
  end
end
