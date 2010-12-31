# encoding: UTF-8
require 'rubygems'
gem 'google-search'
gem 'rainbow'

require 'cgi'
require 'google-search'
require 'rainbow'

class GapQuery
  attr_reader :query, :marker

  PLACEHOLDER = %q{[\w\s'"äüöÄÜÖß-]+[\W\.,;!\?]*?}

  def initialize(query, marker)
    @query = query
    @marker = marker
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

  def placeholder?(index)
    groups[index] == '*'
  end

  def to_s
    query
  end

  def results
    Google::Search::Web.new(:query => to_s)
  end

  def matching_results(&block)
    results.map do |result|
      text = CGI.unescapeHTML(result.content.
        gsub(/<[\/]?b>/, '').
        gsub(/\s+/, ' ')
      )
      if text =~ expr
        line = []
        $~.to_a[1..-1].map do |group|
          group.gsub(/<[^>]+>/, '')
        end.each_with_index do |group, index|
          line << (placeholder?(index) ? marker.call(group) : group)
        end
        block.call if block
        line.join(' ') unless line.empty?
      end
    end.compact.sort.uniq
  end
end

query = GapQuery.new(ARGV.last, Proc.new { |s| s.color(:green) })
puts query.to_s

query.matching_results.each do |line|
  puts line
end
