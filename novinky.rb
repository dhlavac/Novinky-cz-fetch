#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'typhoeus'

require 'pry-byebug'
require 'benchmark'

HTML = "https://www.novinky.cz/archiv?id=966"
$number_of_articles = 4

class Article
	attr_accessor :url
	def initialize(url)
		@comments_urls = Array.new
		@text = ""
		@url = url
		@author = ""
		@date = ""
	end




end


def parse
	array_of_articles = Array.new
	# Fetch and parse HTML document
	doc = Nokogiri::HTML(open(HTML))
	doc.css('[class=item] h3 a').each_with_index { |link, i|
		array_of_articles << Article.new(link['href'])
		break if i == $number_of_articles
	}

	array_of_articles.each {|article| puts article.url}
end


def bench
	time = Benchmark.measure {
		parse
	}
	puts "Benchmark"
	puts time.real  #or save it to logs
end

bench
