module Github
  module Trending
    class User
      attr_accessor :name, :repo, :repo_description, :url

      def to_a
        [@name, @repo, @repo_description, @url]
      end
    end
  end
end
