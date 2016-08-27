module Github
  module Trending
    class User
      attr_accessor :name, :repo, :rank, :repo_description, :url

      def to_a
        [@name, @repo, @rank, @repo_description, @url]
      end
    end
  end
end
