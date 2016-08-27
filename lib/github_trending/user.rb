module Github
  module Trending
    class User
      attr_accessor :name, :full_name, :repo, :rank, :repo_description, :url

      def to_a
        [@name, @full_name, @repo, @rank, @repo_description, @url]
      end
    end
  end
end
