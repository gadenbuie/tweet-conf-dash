# ---- Library ----
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

# ---- tweet-conf-dash Functions ----
source(here::here("R/functions.R"))
source(here::here("R/progress_bar.R"))
source(here::here("R/module/tweetExplorer.R"))

# ---- Settings ----
source(here::here("00_settings.R"))

# ---- Color Helpers ----
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

# ---- Bootstrap App ----
if (!file.exists("www/twitter-default-profile.jpg")) {
  download.file("https://pbs.twimg.com/profile_images/453289910363906048/mybOhh4Z_400x400.jpeg", "www/twitter-default-profile.jpg")
}

if (!file.exists(here::here("data", "tweets_oembed.rds"))) {
  message("Getting Tweet oembed HTML, this may take a minute...")
  if (requireNamespace("furrr", quietly = TRUE)) {
    message("Using {furrr} to speed up the process")
    future::plan(future::multiprocess)
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
