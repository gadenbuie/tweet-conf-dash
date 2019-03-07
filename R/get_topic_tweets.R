#! /usr/bin/env Rscript
'Get or update topic tweets

Usage:
  get_topic_tweets.R get [--out=<file>] [<topics>...]
  get_topic_tweets.R update [--file=<file>]

Options:
  -h --help     Show this screen.
  --out=<file>  Output filename for RDS file of tweets
  <topics>      Hashtags and search terms
  --file=<file> Filename containing tweets to update
' -> doc

library(docopt)
args <- docopt(doc, version = 'Get Topic Tweets 0.1')

if (!requireNamespace("here", quietly = TRUE)) install.packages('here')
library(here)
source(here("R", "zzz-deps.R"))
source(here("R", "initial_functions.R"))
library(dplyr)

logger <- function(..., file = here::here("log/get_topic_tweets.log")) {
  cat(strftime(Sys.time(), "\n[%F %T]\t"), ..., 
      sep = "", file = file, append = TRUE)
}

log_pipe <- function(.data, ..., file = here::here("log/get_topic_tweets.log")) {
  logger(glue::glue(...), file = file)
  invisible(.data)
}

if (isTRUE(args$get)) {
  if (length(args$topics)) {
    options("tweets.topic.query" = args$topics)
  } else {
    logger("Using default topic list", getOption("tweets.topic.query"))
  }
  if (!is.null(args$out)) {
    options("tweets.file" = args$out)
  } else {
    logger("Using default topic list", getOption("tweets.file"))
  }

  logger("Getting new topic tweets")
  x <- last_seen_tweet() %>%
    log_pipe("Starting from tweet: {.data}") %>%
    log_pipe("Topics: {paste(getOption('tweets.topic.query'), collapse = ', ')}") %>%
    get_topic_tweets(since_id = .) %>%
    log_pipe("Gathered {nrow(.data)} new tweets") %>%
    save_tweets()

  log_pipe(x, "Total tweets: {nrow(.data)}")  

} else if (isTRUE(args$update)) {
  if (!is.null(args$file)) {
    options("tweets.file" = args$file)
  } else {
    logger("Using default topic list", getOption("tweets.file"))
  }

  logger("Updating seen tweets")
  x <- update_seen_tweets()
}

logger("Tweet ", if(isTRUE(args$get)) "gathering" else "updating", " complete")
cat("\n")
