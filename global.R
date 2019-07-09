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
source(here::here("00_first-run.R"))

tweets_file_exist <- TWEETS_FILE %>% keep(file.exists)
if (!length(tweets_file_exist)) {
  stop("The TWEETS_FILE(s) do not exist: ", paste(TWEETS_FILE, collapse = ", "))
}
TWEETS_FILE <- tweets_file_exist[1]
message("Using tweets from: ", TWEETS_FILE)
