`%||%` <- function(x,y) if (is.null(x)) y else x

import_tweets <- function(
  file,
  tz_global = tz_global(),
  topic_terms = NULL,
  start_date = NULL,
  blocklist = NULL
) {
  tweets <-
    readRDS(file) %>%
    mutate(created_at = lubridate::with_tz(created_at, tz_global())) %>%
    tweets_since(TWEETS_START_DATE) %>%
    tweets_not_hashdump() %>%
    tweets_block(blocklist$status_id, blocklist$screen_name) %>%
    arrange(desc(created_at)) %>%
    is_topic_tweet(topic_terms)

  if (!"is_quote" %in% names(tweets)) tweets$is_quote <- FALSE
  if (!"is_retweet" %in% names(tweets)) tweets$is_retweet <- FALSE
  tweets
}

is_topic_tweet <- function(tweets, topics = NULL, var_name = "is_topic") {
  if (is.null(topics)) return(tweets)
  tweets %>%
    mutate(!!var_name := str_detect(tolower(text), paste0("(", topics, ")", collapse = "|")))
}

tweets_just <- function(tweets, ...) {
  vars <- rlang::enquos(...)
  if (!length(vars)) {
    tweets %>%
      select(user_id, status_id, created_at, screen_name, text)
  } else {
    tweets %>% select(!!!vars)
  }
}

tweets_by_time <- function(tweets, by = "1 hour") {
  tweets %>%
    mutate(by_time = lubridate::floor_date(created_at, by)) %>%
    group_by(by_time, add = TRUE)
}

tweets_volume <- function(tweets, by = "1 hour") {
  tweets %>%
    tweets_by_time(by) %>%
    count() %>%
    # drop by_time group
    {
      if (!is.null(groups(tweets))) {
        group_by(., !!!groups(tweets))
      } else ungroup(.)
    } %>%
    # fill missing time units
    complete(by_time = seq(min(by_time), max(by_time), by), fill = list(n = 0))
}

tweets_in_last <- function(tweets, d = 0, h = 0, m = 15, s = 0) {
  tweets %>%
    filter(created_at >= lubridate::now() - lubridate::hours(h + d * 24) -
             lubridate::minutes(m) - lubridate::seconds(s))
}

tweets_since <- function(tweets, since = "2019-01-01", tz = NULL) {
  if (is.null(since)) return(tweets)
  if (is.character(since)) since <- lubridate::ymd_hms(since, truncated = 3, tz = tz_global(tz))
  tweets %>%
    filter(created_at >= since)
}

tweets_today <- function(tweets, tz = NULL) {
  tweets_since(tweets, lubridate::today(tz_global(tz)))
}

tweets_not_hashdump <- function(tweets) {
  tweets %>%
    mutate(n_hash = map_int(hashtags, length)) %>%
    filter(n_hash <= 7) %>%
    select(-n_hash)
}

tweets_block <- function(tweets, status_id = NULL, screen_name = NULL) {
  if (!is.null(status_id)) {
    tweets <- tweets %>% filter(!status_id %in% !!status_id)
  }
  if (!is.null(screen_name)) {
    tweets <- tweets %>% filter(!screen_name %in% !!screen_name)
  }
  tweets
}

top_tweets <- function(tweets, top_n = 10, ..., descending = TRUE) {
  top_by <- rlang::enquos(...)
  x <- tweets %>%
    arrange(!!!top_by)
  if (descending) {
    x %>% tail(top_n) %>% slice(top_n:1)
  } else {
    x %>% head(top_n)
  }
}

tweets_by_engaged_users <- function(tweets, ...) {
  # Currently just a dummy function. If you want to apply filters to discard
  # tweets by spam or unrelated users when using a noisy search term, this
  # is the place to add those filters.
  tweets
}

simplify_tweets <- function(tweets, collapse_list = NULL) {
  library(dplyr)
  tweets <-
    tweets %>%
    select(
      1:5,
      starts_with("reply_"),
      starts_with("is_"),
      favorite_count,
      retweet_count,
      hashtags,
      ends_with("expanded_url"),
      quoted_status_id,
      retweet_status_id,
      mentions_user_id,
      mentions_screen_name,
      starts_with("place")
    )
  if (is.null(collapse_list)) return(tweets)
  tweets %>%
    mutate_if(is.list, ~ sapply(., paste0, collapse = collapse_list))
}

tz_global <- function(tz = NULL) {
  if (!is.null(tz)) return(tz)
  tz <- Sys.getenv("TZ")
  if (tz == "") "UTC" else tz
}

get_tweet_blockquote <- function(screen_name, status_id, ..., null_on_error = TRUE, theme = "light") {
  oembed <- list(...)$oembed
  if (!is.null(oembed) && !is.na(oembed)) return(unlist(oembed))
  oembed_url <- glue::glue("https://publish.twitter.com/oembed?url=https://twitter.com/{screen_name}/status/{status_id}&omit_script=1&dnt=1&theme={theme}")
  bq <- possibly(httr::GET, list(status_code = 999))(URLencode(oembed_url))
  if (bq$status_code >= 400) {
    if (null_on_error) return(NULL)
    '<blockquote style="font-size: 90%">Sorry, unable to get tweet ¯\\_(ツ)_/¯</blockquote>'
  } else {
    httr::content(bq, "parsed")$html
  }
}

cache_profile_image <- function(profile_image_url, location = "www", default = "twitter-default-profile.jpg") {
  file_serve <- str_replace(profile_image_url, ".+/profile", "profile")
  file_local <- fs::path(location, file_serve)
  if (fs::file_exists(file_local)) {
    x <- list(result = file_serve)
  } else {
    fs::dir_create(fs::path_dir(file_local))
    x <- safely(download.file)(profile_image_url, file_local)
    # On fist download, the image won't be ready for the UI, so show default
    if (is.null(x$error)) x$result <- default
  }
  if (is.null(x$error)) x$result else default
}

masonify_tweets <- function(tweets, id = NULL, class = NULL) {
  stopifnot("status_id" %in% names(tweets))

  t_embed <-
    tweets %>%
    pmap(get_tweet_blockquote) %>%
    map(HTML) %>%
    map(tags$div, class = "tweet-item")

  tagList(
    tags$div(id = id,
             class = paste("masonry text-left", class),
             t_embed
    )
  )
}

twemoji <- function(runes, width = "20px") {
  runes <- tolower(runes)
  runes <- gsub(" ", "-", runes)
  runes <- sub("-fe0f$", "", runes) # seems to cause problems with twemoji :shrug:
  emojis <- glue::glue("https://cdnjs.cloudflare.com/ajax/libs/twemoji/11.2.0/2/svg/{runes}.svg")
  emojis <- glue::glue('<img src="{emojis}" width = "{width}">')
  paste(emojis)
}

tweet_cache_oembed <- function(tweets, cache = "data/tweets_oembed.rds") {
  if (fs::file_exists(cache)) {
    oembed <- readRDS(cache)
    tweets <- left_join(tweets, oembed, by = "status_id")
  } else {
    oembed <- tibble(status_id = character(), oembed = character())
  }

  if (!"oembed" %in% names(tweets)) tweets$oembed <- map(seq_len(nrow(tweets)), ~ NULL)

  is_needed <- map_lgl(tweets$oembed, is.null)
  if (any(is_needed)) {
    tweets$oembed[is_needed] <- if (requireNamespace("furrr", quietly = TRUE)) {
      furrr::future_pmap(tweets[is_needed, ], get_tweet_blockquote, null_on_error = FALSE, .progress = TRUE)
    } else {
      pmap(tweets[is_needed, ], get_tweet_blockquote, null_on_error = FALSE)
    }
    oembed_new <- tweets %>% select(status_id, oembed)
    # oembed may be a superset of the oembed we got from these tweets
    # so the following keeps the old oembed not contained in oembed_new
    oembed <- bind_rows(
      semi_join(oembed_new, oembed, by = "status_id"),
      anti_join(oembed_new, oembed, by = "status_id")
    )
    saveRDS(oembed, cache)
  }
  return(tweets)
}
