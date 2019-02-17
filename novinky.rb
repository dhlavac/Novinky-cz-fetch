#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'typhoeus'
require 'date'

require 'pry-byebug'
require 'benchmark'

HTML = "https://www.novinky.cz/archiv?id=966"
$number_of_articles = 5

class Article
	attr_accessor :url
	attr_reader :author, :date, :text, :comments_url

	def initialize(url)
		@comments_url = ""
		@text = ""
		@url = url
		@author = ""
		@date = ""
	end


	def extract_data(content)
		data = Nokogiri::HTML(content)
		@text = data.css("[class=articleBody]").text
		@author = data.css("[class=articleAuthors]").text
		@date = data.css("p#articleDate").text
		@comments_url = data.css("[data-dot=c_vase_nazory] a")[0]["href"]

		normalize_data
	end

	def normalize_data
		@date.sub! 'Dnes', (Date.today).strftime("%A %d. %B %Y,")
		@date.sub! 'Včera', (Date.today-1).strftime("%A %d. %B %Y,")
		@date.lstrip!
		@date.rstrip!
		@comments_url.prepend("https://www.novinky.cz")
		@author.lstrip!
		@author.rstrip!
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

	
	array_of_articles.each do |article|
		response = Typhoeus.get(article.url)
		article.extract_data(response.body)
	end
	array_of_articles.each do |article|
		puts article.text
		puts "\n"
		puts article.author
		puts "\n"
		puts article.date
		puts "\n"
		puts article.comments_url
		puts "\n"
	end
end


def bench
	time = Benchmark.measure {
		parse
	}
	puts "Benchmark"
	puts time.real  #or save it to logs
end

bench
