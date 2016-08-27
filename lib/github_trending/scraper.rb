# -*- coding: utf-8 -*-
require 'mechanize'
require 'addressable/uri'

module Github
  module Trending
    def self.get_projects(language = nil, since = nil)
      scraper = Github::Trending::Scraper.new
      scraper.get_projects(language, since)
    end

    def self.get_users(language = nil, since = nil)
      scraper = Github::Trending::Scraper.new
      scraper.get_users(language, since)
    end

    def self.languages
      scraper = Github::Trending::Scraper.new
      scraper.list_languages
    end

    class << self
      alias_method :all_languages,  :languages
      alias_method :get_languages,  :languages
      alias_method :list_languages, :languages
    end

    class Scraper
      BASE_HOST = 'https://github.com'
      BASE_URL = "#{BASE_HOST}/trending"
      DEV_URL = "#{BASE_URL}/developers"

      def initialize
        @agent = Mechanize.new
        @agent.user_agent = "github-trending #{VERSION}"
        proxy = URI.parse(ENV['http_proxy']) if ENV['http_proxy']
        @agent.set_proxy(proxy.host, proxy.port, proxy.user, proxy.password) if proxy
      end

      def get_projects(language = nil, since = nil)
        projects = []
        page = @agent.get(generate_url_for_get_project(language, since))

        page.search('.repo-list-item').each do |content|
          project = Project.new
          meta_data = content.search('.repo-list-meta').text
          project.lang, project.star_count = extract_lang_and_star_from_meta(meta_data)
          project.name        = content.search('.repo-list-name a').text.split.join
          project.url         = BASE_HOST + content.search('.repo-list-name a').first.attributes["href"].value
          project.description = content.search('.repo-list-description').text.gsub("\n", '').strip
          projects << project
        end
        fail ScrapeException if projects.empty?
        projects
      end

      def get_users(language = nil, since = nil)
        users = []
        page = @agent.get(generate_url_for_get_user(language, since))

        page.search('.user-leaderboard-list-item').each do |content|
          user = User.new

          _user = content.children[3]
          _project = content.css(".repo")
          _rank = content.css(".leaderboard-list-rank")

          user.full_name   = content.children[7].css(".user-leaderboard-list-name").text.gsub("\n", '').strip
          user.name        = _user.attr("href").split("/").last
          user.url         = BASE_HOST + "/#{user.name}"

          user.repo = _project.attr("title").text
          user.repo_description = content.css(".repo-snipit-description").text.gsub("\n", '').strip
          user.rank = _rank.text.strip

          users << user
        end
        fail ScrapeException if users.empty?
        users
      end

      def list_languages
        languages = []
        page = @agent.get(BASE_URL)
        page.search('ul.language-filter-list a').each do |content|
          href = content.attributes['href'].value
          # objective-c++ =>
          language = href.match(/github.com\/trending\?l=(.+)/).to_a[1]
          languages << CGI.unescape(language) if language
        end
        languages
      end

      private

      def generate_url_for_get_project(language, since)
        language = language.to_s.gsub('_', '-') if language

        if since
          since =
            case since.to_sym
              when :d, :day,   :daily   then 'daily'
              when :w, :week,  :weekly  then 'weekly'
              when :m, :month, :monthly then 'monthly'
              else nil
            end
        end

        uri = Addressable::URI.parse(BASE_URL)
        if language || since
          uri.query_values = { l: language, since: since }.delete_if { |_k, v| v.nil? }
        end
        uri.to_s
      end

      def generate_url_for_get_user(language, since)
        language = language.to_s.gsub('_', '-') if language

        if since
          since =
            case since.to_sym
              when :d, :day,   :daily   then 'daily'
              when :w, :week,  :weekly  then 'weekly'
              when :m, :month, :monthly then 'monthly'
              else nil
            end
        end

        uri = Addressable::URI.parse(DEV_URL)
        if language || since
          uri.query_values = { l: language, since: since }.delete_if { |_k, v| v.nil? }
        end
        uri.to_s
      end

      def extract_lang_and_star_from_meta(text)
        meta_data = text.split('•').map { |x| x.gsub("\n", '').strip }
        if meta_data.size == 3
          lang = meta_data[0]
          star_count = meta_data[1].gsub(',', '').to_i
          [lang, star_count]
        else
          star_count = meta_data[0].gsub(',', '').to_i
          ['', star_count]
        end
      end
    end
  end
end
