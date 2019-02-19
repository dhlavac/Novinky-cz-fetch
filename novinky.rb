#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'typhoeus'
require 'date'
require 'json'

require 'pry-byebug'
require 'benchmark'

URL = "https://www.novinky.cz/archiv?id=966"
$number_of_articles = 100

class Article
	attr_accessor :url
	attr_reader :author, :date, :text, :comments_url, :images_urls

	def initialize(url)
		@url = url
		@title = ""
		@text = ""
		@comments_url = ""
		@author = ""
		@date = ""
		@images_urls = Array.new
	end

	#Extract data from article
	def extract_data(content)
		begin
			data = Nokogiri::HTML(content)
		rescue
			puts "ERROR:Cannot open HTML file"
		end
		begin
			@text = data.xpath("//div[@id='articleBody']/p[not(@id) and not(@class)]").text
			@title =  data.css("div#articleHeaderBig h1").text
			@author = data.css("[class=articleAuthors]").text
			@date = data.css("p#articleDate").text
			@comments_url = data.css("[data-dot=c_vase_nazory] a")[0]["href"]
			data.css("div#articleBody [class=articlePhotos] a").each do |image|
				@images_urls << image['href']
			end
		rescue
			puts "ERROR:Cannot extract data from website"
		end

		normalize_data
	end

	# Normalize extracted data to required format
	def normalize_data
		@date.sub! 'Dnes', (Date.today).strftime("%A %d. %B %Y,")
		@date.sub! 'Včera', (Date.today-1).strftime("%A %d. %B %Y,")
		@date.lstrip!
		@date.rstrip!
		@comments_url.prepend("https://www.novinky.cz")
		@author.lstrip!
		@author.rstrip!
	end

	# Return data in JSON format
	def to_json
		{:url => @url, :author => @author, :title => @title, :text => @text,
		 :date => @date, :comments_url => @comments_url,
		 :image_urls => @images_urls }.to_json
	end
end

# Fetch and parse HTML document
def parse
	hydra = Typhoeus::Hydra.new
	array_of_articles = Array.new
	begin
		doc = Nokogiri::HTML(open(URL))
	rescue
		puts "ERROR:Cannot open HTML file"
	end
	doc.css('[class=item] h3 a').each_with_index { |link, i|
		array_of_articles << Article.new(link['href'])
		break if i == $number_of_articles
	}

	array_of_articles.each do |article|
		request = Typhoeus::Request.new(article.url)
		hydra.queue(request)
		request.on_complete do |response|
			article.extract_data(response.body)
		end
	end
	hydra.run

	array_of_articles.each do |article|
		puts article.to_json
		puts "\n"
	end
end


def bench
	time = Benchmark.measure {
		parse
	}
	puts "Benchmark"
	puts time.real
end

bench
