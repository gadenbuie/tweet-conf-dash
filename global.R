# ---- Library ----
source(here::here("R", "packages.R"))

# ---- tweet-conf-dash Functions ----
source(here::here("R", "functions.R"))
source(here::here("R", "progress_bar.R"))
source(here::here("R", "module", "tweetExplorer.R"))

# ---- Settings ----
# Everything configurable is in R/custom/
source(here::here("R", "custom", "00_settings.R"))

# ---- Color Helpers ----
BASIC_COLORS <- c("primary", "info", "success", "danger", "warning")

# ---- Bootstrap App ----
source(here::here("00_first-run.R"))

tweets_file_exist <- TWEETS_FILE %>% keep(file.exists)
if (!length(tweets_file_exist)) {
  stop("The TWEETS_FILE(s) do not exist: ", paste(TWEETS_FILE, collapse = ", "))
}
TWEETS_FILE <- tweets_file_exist[1]
message("Using tweets from: ", TWEETS_FILE)
