require "rails_helper"

vcr_option = {
  cassette_name: "github_issue_api",
  allow_playback_repeats: "true"
}

RSpec.describe GithubIssue, type: :model, vcr: vcr_option do
  let(:link) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/510#issue-354483683" }

  it "finds or fetches based on URL" do
    # NB: this approvals test is a little harder to update
    # because a legitimate github access token is required for octokit
    # which is then captured via vcr.
    # IF YOU DO PLAN TO UPDATE THIS: be sure to remove your access token
    # from the vcr cassette generated by this
    issue = described_class.find_or_fetch(link)
    Approvals.verify(issue.processed_html, name: "github_issue_test", format: :html)
  end
end
