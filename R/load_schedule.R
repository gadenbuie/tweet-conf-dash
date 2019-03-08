library(readxl)
library(purrr)
library(dplyr)
library(tidyr)
library(lubridate)

schedule <-
  map_dfr(
    paste0("session_", 1:5),
    read_xlsx,
    col_types = "text",
    path = here::here("data-raw/rstudio_conf_schedule_2019.xlsx")
  ) %>%
  filter(!is.na(start_time)) %>%
  mutate_at(vars(start_time, stop_time), as.numeric) %>%
  mutate_at(vars(session), as.integer) %>%
  gather(track, description, interop:shiny, na.rm = TRUE) %>%
  mutate(
    day = if_else(session < 4, ymd("2019-01-17"), ymd("2019-01-18")),
    day = wday(day, label = TRUE, abbr = FALSE),
    start_time = hms::hms(days = start_time),
    stop_time = hms::hms(days = stop_time)
  ) %>%
  spread(type, description) %>%
  # count(start_time) %>%
  arrange(session, start_time, session, track) %>%
  mutate(
    start_time = paste(start_time),
    stop_time = paste(stop_time)
  ) %>%
  select(session, day, start_time, stop_time, track, title, speaker, description)

saveRDS(schedule, here::here("data/schedule.rds"))
