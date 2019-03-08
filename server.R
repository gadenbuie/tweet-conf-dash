# debug
# .tweets_all <- readRDS(here::here("data/tweets.rds")) %>%
#       mutate(created_at = lubridate::with_tz(created_at, tz_global())) %>%
#       tweets_since(TWEETS_START_DATE) %>%
#       tweets_not_hashdump() %>%
#       is_topic_tweet(rlang::splice(TOPIC$terms))
# tweets <- function() .tweets_all %>% filter(is_topic)

function(session, input, output) {
  # ---- Demo Modal ----
  if (exists("DEMO") && !is.null(DEMO$relive_date)) {
    showModal(
      modalDialog(
        title = strftime(DEMO$relive_date, "Welcome to %A, %B %e!", tz = tz_global()),
        easyClose = TRUE,
        footer = modalButton("Welcome to the Past"),
        tags$p(
          "No, you're not stuck in a", tags$em("Russian Doll"), "time-loop scenario!"
        ),
        tags$p(
          "It's just that this dashboard is more fun when a conference is going on",
          "than after the fact. So we're going to pretend that",
          tags$strong(META$conf_org), "is going on right now, as if today were",
          strftime(DEMO$relive_dat, "%A, %B %e!", tz = tz_global())
        ),
        tags$p(
          "The dates in tweet previews will be correct, but everywhere else in the app:"
        ),
        tags$ul(
          tags$li(
            strftime(now(), "%b %e"), "is really", strftime(DEMO$relive_date, "%b %e")
          ),
          tags$li(
            strftime(now() - days(), "%b %e"), "is really", strftime(DEMO$relive_date - days(), "%b %e")
          ),
          tags$li(
            strftime(now() - days(2), "%b %e"), "is really", strftime(DEMO$relive_date - days(2), "%b %e")
          ),
          tags$li("and so on...")
        ),
        tags$p("Come back tomorrow and relive it all over again!"),
        tags$p(HTML("&mdash; Garrick"),
               HTML('(<a href="https://twitter.com/grrrck" target="_blank">&commat;grrrck</a>)'))
      )
    )
  }

  # Global Reactives --------------------------------------------------------
  tweets_all <- reactiveFileReader(1 * 60 * 1000, session, TWEETS_FILE, function(file) {
    x <- import_tweets(
      file,
      tz_global   = tz_global(),
      topic_terms = TOPIC$terms,
      start_date  = TWEETS_START_DATE,
      blocklist   = BLOCKLIST
    ) %>%
      tweets_by_engaged_users() # dummy function that can be used to filter out noise

    if (exists("DEMO") && !is.null(DEMO$relive_date)) {
      x <- x %>%
        mutate(created_at = created_at + days(DEMO$adjust_days)) %>%
        filter(created_at <= now(tz_global()))
      invalidateLater(1000 * 60 * 5) # "update" in 5 minutes
    }
    x
  })

  tweets <- reactive({
    req(tweets_all())
    tweets_all() %>%
      filter(is_topic) %>%
      tweet_cache_oembed()
  })

  tweets_hourly_topic_count <- reactive({
    req(tweets())
    tweets() %>%
      tweets_just(created_at, status_id, is_topic) %>%
      tweets_by_time() %>%
      count(is_topic)
  })

  tweets_simple <- reactive({
    req(tweets())
    tweets() %>%
      filter(is_topic) %>%
      tweets_just(user_id, status_id, created_at, screen_name, text, is_topic)
  })

  tweets_simple_today <- reactive({
    req(tweets_simple())
    tweets_simple() %>%
      tweets_today()
  })


  # Dashboard Boxes ---------------------------------------------------------
  observe({
    tweets_in_last <- tweets() %>%
      tweets_in_last(d = 1)

    if (!nrow(tweets_in_last)) {
      updateBoxValue(session, "rate", 0)
      return()
    }

    rate <-
      tweets_in_last %>%
      tweets_volume(by = "1 hour") %>%
      pull(n) %>%
      mean()
    updateBoxValue(session, "rate", round(rate, 2))
  })

  observe({
    n_topic_tweets <-
      tweets_simple() %>%
      count() %>%
      pull(n) %>%
      format(big.mark = ",", digits = 0)

    updateBoxValue(session, "total_topic", n_topic_tweets)
  })

  observe({
    n_tweeters_today <-
      tweets_simple() %>%
      tweets_since(lubridate::today(tz_global())) %>%
      distinct(screen_name) %>%
      count() %>%
      pull(n) %>%
      format(big.mark = ",", digits = 0)

    updateBoxValue(session, "tweeters_today", n_tweeters_today)
  })

  observe({
    n_favorites <-
      tweets() %>%
      pull(favorite_count) %>%
      sum() %>%
      format(big.mark = ",", digits = 0)

    updateBoxValue(session, "total_favorites", n_favorites)
  })

  observe({
    n_topic_tweets_today <-
      tweets() %>%
      tweets_just(created_at) %>%
      filter(created_at >= lubridate::today()) %>%
      count() %>%
      pull(n) %>%
      format(big.mark = ",", digits = 0)

    updateBoxValue(session, "total_today", n_topic_tweets_today)
  })

  observe({
    n_all_tweets <-
      tweets_all() %>%
      nrow() %>%
      format(big.mark = ",", digits = 0)

    updateBoxValue(session, "total_all", n_all_tweets)
  })


  # Dashboard Plots ---------------------------------------------------------
  output$plot_hourly_tweet_volume <- renderPlotly({
    tweets_all() %>%
      tweets_just(created_at, is_topic) %>%
      group_by(is_topic) %>%
      tweets_volume() %>%
      mutate(topic = if_else(is_topic, "topic", "all")) %>%
      ungroup() %>%
      rename(Date = by_time) %>%
      select(-is_topic) %>%
      spread(topic, n, fill = 0) %>%
      plot_ly(x = ~ Date) %>%
      add_lines(y = ~topic, name = TOPIC$name, color = I(ADMINLTE_COLORS$teal)) %>%
      {
        if (!is.null(TOPIC$full_community)) {
          add_lines(., y = ~all, name = TOPIC$full_community, color = I(ADMINLTE_COLORS$purple))
        } else .
      }%>%
      config(displayModeBar = FALSE) %>%
      layout(
        xaxis = list(
          range = c(now(tz_global()) - days(7), now(tz_global())),
          rangeselector = list(
            buttons = list(
              list(
                count = 1,
                label = "Today",
                step = "day",
                stepmode = "todate"),
              list(
                count = 1,
                label = "Yesterday",
                step = "day",
                stepmode = "backward"),
              list(
                count = 7,
                label = "Week",
                step = "day",
                stepmode = "backward"),
              list(step = "all", label = "All"))),
          rangeslider = list(type = "date")),
        yaxis = list(title = "Tweets"),
        legend = list(orientation = 'h', x = 0.05, y = 0.9),
        hovermode = "compare" # thanks: https://stackoverflow.com/a/46733461/2022615
      ) %>%
      config(collaborate = FALSE, cloud = FALSE, mathjax = NULL)
  })

  output$plot_tweets_by_hour <- renderPlotly({
    tweets() %>%
      tweets_just(created_at, is_topic) %>%
      tweets_by_time(by = "1 hour") %>%
      mutate(hour = hour(by_time)) %>%
      group_by(hour, is_topic) %>%
      count() %>%
      ungroup() %>%
      mutate(topic = if_else(is_topic, "topic", "all")) %>%
      select(-is_topic) %>%
      spread(topic, n, fill = 0) %>%
      plot_ly(x = ~hour) %>%
      add_bars(y = ~topic, name = TOPIC$name, color = I(ADMINLTE_COLORS$teal)) %>%
      config(displayModeBar = FALSE) %>%
      layout(
        yaxis = list(title = "Tweets"),
        xaxis = list(title = glue::glue("Hour of the Day ({TZ_GLOBAL})")),
        hovermode = "compare" # thanks: https://stackoverflow.com/a/46733461/2022615
      )
  })


  # Dashboard Tweets --------------------------------------------------------
  tweets_most <- reactive({
    tweets() %>%
      tweets_in_last(d = TWEET_MOST$days,
                     h = TWEET_MOST$hours,
                     m = TWEET_MOST$minutes)
  })
  output$dash_most_liked <- renderUI({
    validate(
      need(nrow(tweets_most()) > 0,
      paste("No tweets in", TWEET_MOST$text)
    ))

    tweets_most() %>%
      arrange(desc(favorite_count)) %>%
      slice(1) %>%
      pmap(get_tweet_blockquote) %>%
      .[[1]] %>%
      HTML()
  })

  output$dash_most_rt <- renderUI({
    validate(
      need(nrow(tweets_most()) > 0,
      paste("No tweets in", TWEET_MOST$text)
    ))

    tweets_most() %>%
      arrange(desc(retweet_count)) %>%
      slice(1) %>%
      pmap(get_tweet_blockquote) %>%
      .[[1]] %>%
      HTML()
  })

  output$dash_most_recent <- renderUI({
    tweets() %>%
      slice(1) %>%
      pmap(get_tweet_blockquote) %>%
      .[[1]] %>%
      HTML()
  })


  # High Score --------------------------------------------------------------
  output$top_emojis <- renderUI({
    emoji_regex <- "[\\uD83C-\\uDBFF\\uDC00-\\uDFFF\u2600-\u27ff]+"

    twe <- tweets() %>%
      select(text) %>%
      tidytext::unnest_tokens(text, text, token = "tweets") %>%
      filter(str_detect(text, emoji_regex)) %>%
      mutate(text = str_remove_all(text, "\\w")) %>%
      tidytext::unnest_tokens(text, text, token = "characters") %>%
      count(text, sort = TRUE) %>%
      inner_join(emo::jis %>% select(runes, emoji, name), by = c("text" = "emoji")) %>%
      filter(!str_detect(runes, "^1F3F[B-F]$")) %>%
      slice(1:10) %>%
      mutate(
        b = n,
        # use twemoji
        runes = str_replace(tolower(runes), " ", "-"),
        runes = twemoji(runes)
      )

    colors <- rep(BASIC_COLORS[1:5], 2)

    tags$div(
      map(seq_len(min(10, nrow(twe))), ~ {
        progressGroup(HTML(twe$runes[[.x]]), twe$n[[.x]], max = max(twe$n), color = colors[.x])
      })
    )
  })

  output$top_hashtags <- renderUI({
    twh <-
      tweets() %>%
      select(hashtags) %>%
      unnest() %>%
      count(hashtags, sort = TRUE) %>%
      filter(!is.na(hashtags)) %>%
      filter(!str_detect(tolower(hashtags), TOPIC$hashtag_exclude)) %>%
      mutate(hashtags = paste0("#", hashtags))

    colors <- rep(BASIC_COLORS[1:5], 2)

    tags$div(
      map(seq_len(min(10, nrow(twh))), ~ {
        progressGroup(twh$hashtags[[.]], twh$n[[.]], max = max(twh$n), color = colors[.])
      })
    )
  })

  output$top_tweeters <- renderUI({
    tweets() %>%
      group_by(screen_name, profile_url, profile_image_url) %>%
      summarize(engagement = (sum(retweet_count) * 2 + sum(favorite_count)) / n()) %>%
      arrange(desc(engagement)) %>%
      ungroup() %>%
      slice(1:10) %>%
      mutate(
        engagement = scale(engagement, center = FALSE),
        engagement = engagement / max(engagement) * 100,
        profile_image = map_chr(profile_image_url, cache_profile_image),
        profile_image_url = glue::glue('<div class="center-block"><img class="img-responsive img-circle" src="{profile_image}" alt={screen_name} style="max-height: 25px; min-width: 20px;"></div>'),
        profile_url = if_else(is.na(profile_url), glue::glue("https://twitter.com/{screen_name}"), profile_url),
        screen_name = glue::glue('<a href="{profile_url}" target="_blank">@{screen_name}</a>'),
        engagement = progressBar_v(engagement, rep(BASIC_COLORS[1:5], 2))
      ) %>%
      select(profile_image_url, screen_name, engagement) %>%
      knitr::kable(
        format = "html",
        escape = FALSE,
        align = "cll",
        col.names = c("", "Screen Name", "Engagement/Tweet "),
        table.attr = 'class = "table"'
      ) %>%
      HTML()
  })

  output$top_tweet_words <- renderUI({
    tw <- tweets() %>%
      select(text) %>%
      mutate(
        text = str_remove_all(text, "@[[:alnum:]_]+\\b"),
        text = str_remove_all(text, "&\\w+;")
      ) %>%
      tidytext::unnest_tokens(word, text) %>%
      filter(
        !word %in% c("http", "https", "t.co"),
        !str_detect(word, TOPIC$wordlist_exclude),
        nchar(word) >= 3
      ) %>%
      anti_join(tidytext::stop_words, by = "word") %>%
      count(word, sort = TRUE) %>%
      slice(1:10)

    colors <- rep(BASIC_COLORS[1:5], 2)

    tags$div(
      map(seq_len(min(10, nrow(tw))), ~ {
        progressGroup(tw$word[[.]], tw$n[[.]], max = max(tw$n), color = colors[.])
      })
    )
  })

  # Tweet Wall --------------------------------------------------------------
  tweets_wall <- reactive({
    tweets_simple() %>%
      filter(
        created_at >= input$tweet_wall_daterange[1],
        created_at < input$tweet_wall_daterange[2] + 1
      )
  })

  tweet_wall_page_break = 20
  tweet_wall_n_items <- reactive({ nrow(tweets_wall()) })
  tweet_wall_page <- shinyThings::pager("tweet_wall_pager",
                                        n_items = tweet_wall_n_items,
                                        page_break = tweet_wall_page_break)

  output$tweet_wall_tweets <- renderUI({
    s_page_items <- tweet_wall_page() %||% 1L

    validate(need(
     nrow(tweets_wall()) > 0,
     "No tweets in selected date range. Try another set of dates."
    ))

    tweets_wall() %>%
      slice(s_page_items) %>%
      masonify_tweets()
  })

  tweet_wall_date_preset <- shinyThings::dropdownButton("tweet_wall_date_presets",
                                                        options = TWEET_WALL_DATE_INPUTS)

  observe({
    req(tweet_wall_date_preset())
    update_dates <- TWEET_WALL_DATE_RANGE(tweet_wall_date_preset())
    if (any(is.na(update_dates))) return(NULL)
    update_dates <- strftime(update_dates, "%F", tz = tz_global(), usetz = TRUE) %>% unname()
    updateDateRangeInput(session, "tweet_wall_daterange", start = update_dates[1], end = update_dates[2], max = now(tz_global()))
  })

  # Picture Tweet Wall ------------------------------------------------------
  pic_tweets_page_break <- 20
  tweets_pictures <- reactive({
    tweets() %>%
      select(created_at, status_id, screen_name, media_url) %>%
      filter(!map_lgl(media_url, ~ length(.) > 1 || is.na(.)))
  })

  pic_tweets_n_items <- reactive({ nrow(tweets_pictures()) })
  pic_tweets_page <- shinyThings::pager("pic_tweets", pic_tweets_n_items, pic_tweets_page_break)

  output$pic_tweets_wall <- renderUI({
    s_page_items <- pic_tweets_page() %||% 1L

    validate(need(
      nrow(tweets_pictures()) > 0,
      "No media tweets yet. Check back again soon."
    ))

    tweets_pictures() %>%
      slice(s_page_items) %>%
      masonify_tweets()
  })

  # Schdeule ---------------------------------------------------------------
  output$table_schedule <- DT::renderDataTable({
    if (is.null(SCHEDULE$data)) return(NULL)
    SCHEDULE$data %>%
      DT::datatable(
        rownames = FALSE,
        filter = "top",
        style = "bootstrap",
        autoHideNavigation = TRUE,
        selection = "none",
        extensions = "Responsive",
        options = list(searchHighlight = TRUE),
        colnames = c("Session", "Day", "Start", "End", "Track", "Title", "Speaker", "Description")
      )
  })

  # TweetExplorer -----------------------------------------------------------
  callModule(tweetExplorer, "tweet_table", reactive({ tweets() }), tzone = tz_global())

}
