## Boostrap App ----
if (!exists("META")) {
  # IF RUNNING MANUALLY, RUN FROM A NEW, CLEAN SESSION!
  source(here::here("R", "packages.R"))
  source(here::here("R", "functions.R"))
  source(here::here("R", "custom", "00_settings.R"))
}

# This script initializes the app and may take a while to complete,
# so it's best to run this before deploying the app.

# Get default twitter profile image
if (!file.exists("www/twitter-default-profile.jpg")) {
  download.file("https://pbs.twimg.com/profile_images/453289910363906048/mybOhh4Z_400x400.jpeg", "www/twitter-default-profile.jpg")
}

# First run of tweet gathering if not already collected
if (TWEETS_MANAGE_UPDATES &&
    TWEETS_FILE %>% map_lgl(negate(file.exists)) %>% any()) {
  message("Collecting initial round of tweets...")
  callr::r(gathertweet_auto, args = list(TOPIC = TOPIC), show = TRUE)
}


# Gather and cache OEMBED codes first tweets
# (This processes happens incrementally for new tweets)
if (!file.exists(here::here("data", "tweets_oembed.rds"))) {
  message("Getting Tweet oembed HTML, this may take a minute...")

  TWEETS_FILE <- TWEETS_FILE %>% keep(file.exists) %>% .[1]
  message("Using tweets from: ", TWEETS_FILE)

  if (requireNamespace("furrr", quietly = TRUE)) {
    message("Using {furrr} to speed up the process")
    future::plan(future::multisession)
  }
  tweets <- import_tweets(
    TWEETS_FILE,
    tz_global   = tz_global(),
    topic_terms = TOPIC$terms,
    start_date  = TWEETS_START_DATE,
    blocklist   = BLOCKLIST
  ) %>%
    filter(is_topic) %>%
    tweet_cache_oembed()

  rm(tweets)
}

# Cache profile images for top 50 screen_names
message("Getting Twitter profile images for current top 50 users")
TWEETS_FILE %>%
  keep(file.exists) %>%
  .[1] %>%
  import_tweets(
    tz_global   = tz_global(),
    topic_terms = TOPIC$terms,
    start_date  = TWEETS_START_DATE,
    blocklist   = BLOCKLIST
  ) %>%
  group_by(screen_name, profile_url, profile_image_url) %>%
  summarize(engagement = (sum(retweet_count) * 2 + sum(favorite_count))) %>%
  arrange(desc(engagement)) %>%
  ungroup() %>%
  slice(1:50) %>%
  pull(profile_image_url) %>%
  walk(cache_profile_image)
