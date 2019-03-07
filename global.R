library(shiny)
library(shinydashboard)
library(forcats)
library(ggplot2)
library(plotly)
library(lubridate)
library(stringr)
library(tidyr)
library(purrr)
library(dplyr)
library(shinycssloaders)

source(here::here("R/functions.R"))
source(here::here("R/progress_bar.R"))
# source(here::here("R/module/dropdownButton.R"))
source(here::here("R/module/tweetExplorer.R"))

# ---- Metadata ----
META <- list(
  name        = "rstudio::conf(\'tweets\')",
  description = "A Shiny Dashboard, rstudio::conf #FOMO reducer, tweet explorer by @grrrck",
  app_url     = "https://apps.garrickadenbuie.com/rstudioconf-2019/",
  app_icon    = "https://garrickadenbuie.com/images/2019/rstudioconf-2019-icon.png",
  conf_org    = "rstudio::conf",
  skin_color  = "blue-light",
  logo_mini   = "<em>rs</em><strong>c</strong>",
  logo_lg     = "<em>rstudio</em>::<strong>conf</strong>(2019)",
  topic_icon  = "comments",
  topic_icon_full = "r-project"
)

# ---- Global: Schedule ----
SCHEDULE <- list()
SCHEDULE$url <- "https://www.rstudio.com/conference/"
SCHEDULE$data <- readRDS(here::here("data/schedule.rds"))

# ----- Global: Tweet Most ----
TWEET_MOST <- list(
  hours   = 12,
  days    = 0,
  minutes = 0,
  text    = "12 hours"
)

# ---- Global: Topic Info ----
TOPIC <- list(
  name             = "rstudio::conf",
  full_community   = "#rstats",
  terms            = list("rstudioconf", "rstudio conf", "rstudio::conf", "rstudiconf", "rstduioconf"),
  hashtag_exclude  = "rstudio?conf|rstduioconf|rstats|rstudio conf",
  wordlist_exclude = "rstudio|conf|rstats"
)
GA_KEY <- if (file.exists("google_analytics_key.txt")) readLines("google_analytics_key.txt")
TWEETS_FILE <- paste0("data/", c("tweets_simplified.rds", "tweets.rds")) %>%
  keep(file.exists) %>% .[1]
message("Using tweets from: ", TWEETS_FILE)
TWEETS_START_DATE <- "2019-01-01"
TZ_GLOBAL <- "America/New_York"
Sys.setenv(TZ = TZ_GLOBAL)

TWEET_WALL_DATE_PRESETS <- c(
  "Today"     = "today",
  "Yesterday" = "yesterday",
  "Past week" = "past_week",
  "In 2019"   = "in_2019"
)

if (today(tz = tz_global()) > ymd("2019-01-15", tz = tz_global())) {
  TWEET_WALL_DATE_PRESETS <- c(TWEET_WALL_DATE_PRESETS, "Since Workshops" = "since_workshop")
}

if (today(tz = tz_global()) > ymd("2019-01-17", tz = tz_global())) {
  TWEET_WALL_DATE_PRESETS <- c(TWEET_WALL_DATE_PRESETS, "Conference Proper" = "conf_prop")
}

today_tz <- today(tz_global())

TWEET_DATE_RANGE_TEMPLATE <- function(inputId) {
  switch(
    inputId,
    "today"          = c(start = today_tz,          end = today_tz),
    "yesterday"      = c(start = today_tz - 1,      end = today_tz - 1),
    "past_week"      = c(start = today_tz - 7,      end = today_tz),
    "in_2019"        = c(start = ymd("2019-01-01"), end = today_tz),
    "since_workshop" = c(start = ymd("2019-01-15"), end = today_tz),
    "conf_prop"      = c(start = ymd("2019-01-17"), end = today_tz),
    "conf_and_after" = c(start = ymd("2019-01-15"), end = today_tz),
    NA
  )
}

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

BASIC_COLORS <- c("primary", "info", "success", "danger", "warning")

adminlte_pal <- function(direction = 1, color_other = "grey-lte") {
  colors <- unlist(unname(ADMINLTE_COLORS))
  function(n) {
    if (n > length(colors)) warning("Only ", length(colors), " colors available")
    x <- if (n == 2) {
      color_other <- if (!color_other %in% names(ADMINLTE_COLORS)) color_other else
        ADMINLTE_COLORS[[color_other]]
      c(colors[[1]], color_other)
    } else colors[1:n]
    if (direction < 0) rev(x) else x
  }
}

scale_color_adminlte <- function(direction = 1, color_other = "grey", ...) {
  ggplot2::discrete_scale("colour", "adminlte", adminlte_pal(direction, color_other))
}
scale_colour_adminlte <- scale_color_adminlte
scale_fill_adminlte <- function(direction = 1, color_other = "grey", ...) {
  ggplot2::discrete_scale("fill", "adminlte", adminlte_pal(direction, color_other))
}

if (!file.exists("www/twitter-default-profile.jpg")) {
  download.file("https://pbs.twimg.com/profile_images/453289910363906048/mybOhh4Z_400x400.jpeg", "www/twitter-default-profile.jpg")
}

# ---- Blocklist ----
BLOCKLIST <- list(
  status_id = list(
    "1087748087454535680"
  ),
  screen_name = list(
    "paukniccadi"
  )
)
