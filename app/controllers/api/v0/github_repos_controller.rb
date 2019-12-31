module Api
  module V0
    class GithubReposController < ApiController
      def index
        client = create_octokit_client
        existing_user_repos = GithubRepo.
          where(user_id: current_user.id, featured: true).pluck(:github_id_code) #=> [1,2,3]
        existing_user_repos = Set.new(existing_user_repos)
        @repos = client.repositories.map do |repo|
          repo.selected = existing_user_repos.include?(repo.id)
          repo
        end
      rescue Octokit::Unauthorized => e
        render json: { error: "Github Unauthorized: #{e.message}", status: 401 }, status: :unauthorized
      end

      def update_or_create
        @client = create_octokit_client
        fetched_repo = fetch_repo
        unless fetched_repo
          render json: "error: Could not find Github repo", status: :not_found
          return
        end

        @repo = GithubRepo.find_or_create(fetched_repo_params(fetched_repo))
        current_user.touch(:github_repos_updated_at)
        if @repo.valid?
          render json: { featured: @repo.featured }
        else
          render json: "error: #{@repo.errors.full_messages}"
        end
      end

      private

      def create_octokit_client
        current_user_token = Identity.find_by(provider: "github", user_id: current_user.id).token
        Octokit::Client.new(access_token: current_user_token)
      end

      def fetched_repo_params(fetched_repo)
        {
          github_id_code: fetched_repo.id,
          user_id: current_user.id,
          name: fetched_repo.name,
          description: fetched_repo.description,
          language: fetched_repo.language,
          fork: fetched_repo.fork,
          url: fetched_repo.html_url,
          bytes_size: fetched_repo.size,
          watchers_count: fetched_repo.watchers,
          stargazers_count: fetched_repo.stargazers_count,
          featured: permitted_attributes(GithubRepo)[:featured],
          info_hash: fetched_repo.to_hash
        }
      end

      def fetch_repo
        params[:github_repo] = JSON.parse(params[:github_repo])
        @client.repositories.detect do |repo|
          repo.id == permitted_attributes(GithubRepo)[:github_id_code].to_i
        end
      end
    end
  end
end
