# ---- Metadata ----
META <- list(
  # Name of the app, used in the browser/tab title
  name        = "useR!2019",
  # A description of the app, used in social media cards
  description = "A Shiny Dashboard, useR!2019 #FOMO reducer, tweet explorer by @grrrck",
  # Link to the app, used in social media cards
  app_url     = "https://apps.garrickadenbuie.com/user-2019/",
  # Link to app icon image, used in social media cards
  app_icon    = "https://garrickadenbuie.com/images/2019/rstudioconf-2019-icon.png",
  # The name of the conference or organization
  conf_org    = "UseR2019",
  # App title, long, shown when sidebar is open, HTML is valid
  logo_lg     = "use<strong>R</strong>!2019",
  # App title, short, shown when sidebar is collapsed, HTML is valid
  logo_mini   = "use<strong>R</strong>",
  # Icon for box with count of conference-related tweets
  topic_icon  = "r-project",
  # Icon for box with count of "community"-related tweets
  topic_icon_full = "comments",
  # AdminLTE skin color for the dashboard
  skin_color  = "red",
  # AdminLTE theme CSS files
  theme_css   = c("ocean-next/AdminLTE.css", "ocean-next/_all-skins.css")
)

# ---- Topics Settings ----
# The dashboard is designed to show tweets related to a conference, using
# specific terms to locate conference tweets. If the conference tweets are part
# of a broader Twitter community, you can also show stats about the full
# community (see also `topic_icon_full` above).
#
# Note that currently, this app expects tweet gathering to be conducted by an
# external script or process. The terms below should then match or extend the
# terms used in the gathering process.
#
# See https://github.com/gadenbuie/gathertweet for a utility for tweet
# gathering.
TOPIC <- list(
  # Name of the conference or topic, for use in descriptive text
  name = "useR!2019",
  # Name of the full Twitter community, for use in descriptive text
  full_community   = "#rstats",
  # Terms related to the topic that must be included in topical tweet text
  # Note that these are used internally and are compared with the lowercase
  # tweet text (so that case doesn't matter). Terms are evaluated invidividually
  # using str_detect(tweet_text, term), so you may use regular expressions. A
  # tweet is considered "topical" if _any_ term matches.
  terms = c("user2019", "user19", "user2019conf", "user 2019", "user conf"),
  # Search string as would be entered at https://twitter.com/search
  search_terms = paste0(
    "#user2019 OR #useR2019 OR #UseR2019 OR #useR2019_conf OR #UseR2019Conf OR ",
    "#UseR2019_Conf OR #user2019conf OR #user2019conf OR @UseR2019_conf"
  ),
  # Hashtags to exclude from the Top 10 Hashtags list (because they're implied by the topic)
  hashtag_exclude  = "user|user2019conf|user2019|rstats",
  # Words to exclude from the Top 10 Words list (because they're implied by the topic)
  wordlist_exclude = "user|conf|rstats"
)

# ---- Tweet Storage Location ----
# The tweets should be stored in data/tweets.rds or data/tweets_simplified.rds.
# The latter is preferred and should contain only the columns needed for the
# app, which reduced start-up loading time. You do not need to make any changes
# to this section if the app is managing the tweet gathering, but I'm "exposing"
# the global argument just in case you have a very particular setup. Note that
# the app will look for the following files in the order they appear.
TWEETS_FILE <- file.path("data", paste0(c("tweets_simplified", "tweets"), ".rds"))

# Should the app manage tweet updating? If FALSE, assumes that tweets are
# updated by an external process
TWEETS_MANAGE_UPDATES <- TRUE

# ----- Tweets With Most XX Time Window ----
# Sets the time window for the "Top RT" and "Top Liked" tweets on the front
# page. Shows the top tweet from the last `hours + days + minutes`, and the text
# is displayed like "in the last {text}".
TWEET_MOST <- list(
  hours   = 12,
  days    = 0,
  minutes = 0,
  text    = "12 hours"
)

# ---- Dates and Times ----
TWEETS_START_DATE <- "2019-07-01"  # Don't show tweets before this date
TZ_GLOBAL <- "Europe/Paris"        # Time zone where conference is taking place
Sys.setenv(TZ = TZ_GLOBAL)

# A helper to get today() in the app's timezone
# * Note that tz_global() returns the system timezone,
#   or can be overwritten with tz_global("other/timezone")
today_tz <- function() today(tz_global())

# TWEET_WALL_DATE_INPUTS:
# A character vector containing the Shiny input IDs and button labels (names)
# for the Tweet Wall date presets. The input IDs link to TWEET_DATE_RANGE and
# need to be defined there.
TWEET_WALL_DATE_INPUTS <- c(
  "Today"     = "today",
  "Yesterday" = "yesterday",
  "Past week" = "past_week",
  "In 2019"   = "in_2019"
)

# Conference-related dates, used only for the rest of this section
.tutorial_start   <- ymd("2019-07-09", tz = tz_global())
.conference_start <- ymd("2019-07-08", tz = tz_global())

# Only show "Since Workshop" button _after_ workshops have started
if (today_tz() > .tutorial_start) {
  TWEET_WALL_DATE_INPUTS <- c(
    TWEET_WALL_DATE_INPUTS, "Tutorials" = "from_tutorials")
}

# Only show "Conference Proper" button _after_ conference has started
if (today_tz() > .conference_start) {
  TWEET_WALL_DATE_INPUTS <- c(
    TWEET_WALL_DATE_INPUTS, "Conference" = "conf_prop")
}

# TWEET_WALL_DATE_RANGE:
# A function that returns a date range as c(start, end) for each inputId defined
# in TWEET_WALL_DATE_INPUTS. You can use specific dates or define the date range
# relative to the current date by using the today_tz() helper.
TWEET_WALL_DATE_RANGE <- function(inputId) {
  switch(
    inputId,
    "today"          = c(start = today_tz(),        end = today_tz()),
    "yesterday"      = c(start = today_tz() - 1,    end = today_tz() - 1),
    "past_week"      = c(start = today_tz() - 7,    end = today_tz()),
    "in_2019"        = c(start = ymd("2019-01-01"), end = today_tz()),
    "from_tutorials" = c(start = .tutorial_start,   end = today_tz()),
    "conf_prop"      = c(start = .conference_start, end = today_tz()),
    NA
  )
}

# ---- Schedule ----
# If you would like to include an interactive table of the conference schedule,
# then provide a named list to schedule. Use only `SCHEDULE$url` to have the
# sidebar button link directly to the conference schedule. Or also provide
# `SCHEDULE$data` to display an interactive dataTable of the schedule.
SCHEDULE <- list()
SCHEDULE$url <- "https://user2019.r-project.org/talk_schedule/"
SCHEDULE$data <- readRDS(here::here("data/schedule.rds"))

# ---- Google Analytics Key ----
# If you would like to use Google Analytics, save your GA key in a file called
# `google_analytics_key.txt` in the project directory. This file is ignored by
# git so that you don't check it into version control.
GA_KEY <- if (file.exists("google_analytics_key.txt")) readLines("google_analytics_key.txt")


# ---- Colors ----
# Set these colors to match your AdminLTE styles. Note that this does not
# update the CSS, just makes it possible to use the colors in the plots
# displayed in the dashboard.
#
# See https://github.com/gadenbuie/AdminLTE/tree/ocean-next for an example.
ADMINLTE_COLORS <- list(
  "light-blue" = "#6699CC",
  "green"      = "#99C794",
  "red"        = "#EC5f67",
  "purple"     = "#C594C5",
  "aqua"       = "#a3c1e0",
  "yellow"     = "#FAC863",
  "navy"       = "#343D46",
  "olive"      = "#588b8b",
  "blue"       = "#4080bf",
  "orange"     = "#F99157",
  "teal"       = "#5FB3B3",
  "fuchsia"    = "#aa62aa",
  "lime"       = "#b0d4b0",
  "maroon"     = "#AB7967",
  "black"      = "#1B2B34",
  "gray-lte"   = "#D8DEE9",
  "primary"    = "#6699CC",
  "success"    = "#99C794",
  "danger"     = "#EC5f67",
  "info"       = "#a3c1e0",
  "warning"    = "#FAC863"
)
options("spinner.color" = ADMINLTE_COLORS$`gray-lte`)
options("spinner.color.background" = "#F9FAFB")

# ---- Blocklist ----
# A list with named list elements `status_id` and `screen_name`. Block specific
# tweets by adding the status id of the tweet to the `status_id` list, or block
# specific people by adding their screen name to the `screen_name` list.
BLOCKLIST <- list(
  # status_id = list(),
  screen_name = list(
    "WorldSilverNews",
    "rootforum_org"
  )
)


# Demo Settings -----------------------------------------------------------
DEMO <- list(
  # relive_date = ymd("2019-01-18", tz = tz_global())
)

if (exists("DEMO") && !is.null(DEMO$relive_date)) {
  DEMO$adjust_days <-
    difftime(today_tz(), DEMO$relive_date, unit = "day") %>%
    as.numeric() %>%
    ceiling()

  .workshop_start   <<- as_date(.workshop_start + days(DEMO$adjust_days))
  .conference_start <<- as_date(.conference_start + days(DEMO$adjust_days))
}
