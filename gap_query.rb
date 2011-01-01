# encoding: UTF-8
require 'cgi'
require 'google-search'

Enumerable.module_eval do
  def with_index
    index = -1
    map { |item| [item, index += 1] }
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
    end.compact.uniq.sort_by { |ary| ary.to_s.downcase }
  end
end
