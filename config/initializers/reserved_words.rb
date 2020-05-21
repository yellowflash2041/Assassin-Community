class ReservedWords
  BASE_WORDS = %w[
    1024
    404
    500
    about
    account
    additional_content_boxes
    admin
    administrate
    ads
    advertising
    amp
    anal
    async_info
    analysis
    analytics
    answers
    api
    app
    article
    articles
    binary
    bit
    bits
    blocks
    buffered_articles
    butt
    byte
    bytes
    cast
    challenge
    changelog
    chat
    chat_channels
    code
    code-of-conduct
    coffee
    comment
    comments
    computer
    connect
    contact
    csv_exports
    daily
    dash
    dashboard
    day
    deep
    delayed_job_admin
    delete
    design
    designer
    destroy
    dev
    developer
    developertea
    drole
    edit
    el
    email_subscriptions
    enter
    faq
    features
    feed
    feedback_messages
    flip
    followers
    following
    follows
    forloop
    fuck
    fun
    funnies
    funny
    future
    gag
    gags
    getting-started
    gigs
    github
    hack
    hackers
    haskell
    help
    history
    infinite
    infiniteloop
    internal
    iot
    java
    javascript
    job
    job_application
    job_applications
    job_listings
    jobs
    joke
    jokes
    journal
    ki
    kilo
    kilobyte
    kis
    latest
    leader
    leaderboard
    leaders
    legal
    libraries
    library
    links
    linux
    listen
    live
    live_articles
    loop
    mac
    machinelearning
    mag
    magazine
    me
    medium
    mega
    megabyte
    membership
    merch
    merchandise
    new
    new
    news
    night
    nightly
    notification_subscriptions
    notifications
    onboarding_checkbox_update
    onboarding_update
    one-of-us
    online
    ons
    opensource
    opps
    ops
    oreilly
    org
    organizations
    orgs
    orly
    orlybooks
    orlygenerator
    oss
    pc
    phishing
    pod
    podcast
    podcasts
    privacy
    programmer
    programming
    pulse
    pulses
    push_notification_subscriptions
    python
    questions
    rails
    reactions
    readinglist
    repo
    report-abuse
    reports
    repos
    retro
    rly
    rlygenerator
    rlyslack
    rlyweb
    robots
    rss
    ruby
    script
    search
    security
    sedaily
    settings
    shoutouts
    signout_confirm
    social
    social_previews
    software
    sounds
    start
    started
    startups
    swagnets
    tag
    tags
    tea
    tech
    terms
    things
    top
    tos
    track
    tv
    twilio_tokens
    twitter
    update
    user
    users
    video_states
    videos
    welcome
    work
    yes
  ].freeze

  class << self
    def all
      @all || BASE_WORDS
    end

    attr_writer :all
  end
end
