require 'rubygems'
require 'rainbow'
require 'gap_query'

gap_query = GapQuery.new(ARGV.last).tap { |q| puts q.query }

gap_query.matching_results.each do |line|
  puts line.map { |part|
    case part
    when GapQuery::Placeholder: part.color(:green)
    else part
    end
  }.join(' ')
end
