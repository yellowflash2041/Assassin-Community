json.type_of            "user"
json.username           @user.username
json.name               @user.name
json.summary            @user.summary
json.twitter_username   @user.twitter_username
json.github_username    @user.github_username
json.website_url        @user.name
json.name               @user.name
json.name               @user.name
json.name               @user.name
json.profile_image      ProfileImage.new(@user).get(320)