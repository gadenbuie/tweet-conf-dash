library(shiny)
library(shinydashboard)

dashboard_box_size <- if (is.null(TOPIC$full_community)) "3" else "4 col-lg-2"

dashboardPage(
  # Dashboard Page Setup ----------------------------------------------------
  title = META$name,
  skin  = META$skin_color,
  theme = c(META$theme_css, "custom.css"),
  sidebar_mini = TRUE,
  dashboardHeader(
    title = HTML(glue::glue(
      '<span class="logo-mini">{META$logo_mini}</span>
      <span class="logo-lg">{META$logo_lg}</span>'
    ))
  ),

  # Dashboard Sidebar -------------------------------------------------------
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "tab_dashboard", icon = icon("dashboard")),
      menuItem("High Score", tabName = "tab_high_score", icon = icon("trophy")),
      menuItem("Tweet Wall", tabName = "tab_tweet_wall", icon = icon("stream")),
      menuItem("Media Tweets", tabName = "tab_pic_tweets", icon = icon("images")),
      menuItem("Explore", tabName = "tab_explore", icon = icon("compass")),
      if (!is.null(SCHEDULE$data)) {
        menuItem("Schedule", tabName = "tab_schedule", icon = icon("calendar"))
      } else if (!is.null(SCHEDULE$url)) {
        menuItem(HTML("Schedule <span class='fa fa-external-link-alt' style='padding-left: 0.5em; font-size: 90%'></span>"),
                 href = SCHEDULE$url, icon = icon("calendar"))
      },
      menuItem("About", tabName = "tab_about", icon = icon("info"))
    )
  ),

  # Dashboard Body ----------------------------------------------------------
  dashboardBody(
    tabItems(

      # Frontpage - tab_dashboard -----------------------------------------------
      tabItem(
        "tab_dashboard",
        tags$head(
          # Metadata <head> ---------------------------------------------------------
          HTML(glue::glue(
            '<meta property="og:title" content="{META$name}">
            <meta property="og:description" content="{META$description}">
            <meta property="og:url" content="{META$app_url}">
            <meta property="og:image" content="{META$app_icon}">
            <meta name="twitter:card" content="{META$app_twitter_card_style}">
            <meta name="twitter:creator" content="{META$twitter_creator}">
            <meta name="twitter:site" content="META$twitter_site">
            <link rel="apple-touch-icon" sizes="57x57" href="apple-icon-57x57.png">
            <link rel="apple-touch-icon" sizes="60x60" href="apple-icon-60x60.png">
            <link rel="apple-touch-icon" sizes="72x72" href="apple-icon-72x72.png">
            <link rel="apple-touch-icon" sizes="76x76" href="apple-icon-76x76.png">
            <link rel="apple-touch-icon" sizes="114x114" href="apple-icon-114x114.png">
            <link rel="apple-touch-icon" sizes="120x120" href="apple-icon-120x120.png">
            <link rel="apple-touch-icon" sizes="144x144" href="apple-icon-144x144.png">
            <link rel="apple-touch-icon" sizes="152x152" href="apple-icon-152x152.png">
            <link rel="apple-touch-icon" sizes="180x180" href="apple-icon-180x180.png">
            <link rel="icon" type="image/png" sizes="192x192"  href="android-icon-192x192.png">
            <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
            <link rel="icon" type="image/png" sizes="96x96" href="favicon-96x96.png">
            <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
            <link rel="manifest" href="manifest.json">
            <meta name="msapplication-TileColor" content="#6699CC">
            <meta name="msapplication-TileImage" content="ms-icon-144x144.png">
            <meta name="theme-color" content="#6699CC">
            '
          )),
          if (!is.null(GA_KEY)) HTML(
            glue::glue(
              '
              <!-- Global site tag (gtag.js) - Google Analytics -->
              <script async src="https://www.googletagmanager.com/gtag/js?id={GA_KEY}"></script>
              <script>
                window.dataLayer = window.dataLayer || [];
                function gtag(){{dataLayer.push(arguments);}}
                  gtag(\'js\', new Date());
                  gtag(\'config\', \'{GA_KEY}\');
               </script>
              ')
          )
          # Metadata <head> end -----------------------------------------------------
        ),
        fluidRow(
          # Frontpage - boxes - start -----------------------------------------------
          valueBox(
            inputId = "total_today",
            "—", "Tweets Today",
            color = "purple",
            icon = icon("comment-dots"),
            width = dashboard_box_size),
          valueBox(
            inputId = "tweeters_today",
            "—", "Tweeters Today",
            color = "orange",
            icon = icon("user-circle"),
            width = dashboard_box_size),
          valueBox(
            inputId = "rate",
            "—", "Tweets/hr Today",
            color = "green",
            icon = icon("hourglass-half"),
            width = dashboard_box_size),
          if (!is.null(TOPIC$full_community)) valueBox(
            inputId = "total_favorites",
            "—", paste(TOPIC$name, "Likes"),
            color = "red",
            icon = icon("heart"),
            width = dashboard_box_size),
          valueBox(
            inputId = "total_topic",
            "—", paste(TOPIC$name, "Tweets"),
            color = "teal",
            icon = icon(META$topic_icon),
            width = dashboard_box_size),
          if (!is.null(TOPIC$full_community)) valueBox(
            inputId = "total_all",
            "—", paste(TOPIC$full_community, "Tweets"),
            color = "fuchsia",
            icon = icon(META$topic_icon_full),
            width = dashboard_box_size)
          # Frontpage - boxes - end -------------------------------------------------
        ),
        fluidRow(
          # Frontpage - tweet volume plots - start ----------------------------------
          tabBox(
            width = 12,
            tabPanel(
              status = "primary",
              title = "Tweet Volume",
              withSpinner(plotlyOutput("plot_hourly_tweet_volume", height = "250px"))
            ),
            tabPanel(
              status = "success",
              title = "Tweets by Hour of Day",
              withSpinner(plotlyOutput("plot_tweets_by_hour", height = "250px"))
            )
          )
          # Frontpage - tweet volume plots - end ------------------------------------
        ),
        fluidRow(
          # Frontpage - Most XX Tweets - start --------------------------------------
          column(
            width = 8,
            offset = 2,
            class = "col-md-6 col-md-offset-0 col-lg-4",
            class = "text-center",
            tags$h4(HTML(twemoji("2764"), "Most Liked in", TWEET_MOST$text)),
            withSpinner(uiOutput("dash_most_liked"), proxy.height = "200px")
          ),
          column(
            width = 8,
            offset = 2,
            class = "col-md-6 col-md-offset-0 col-lg-4",
            class = "text-center",
            tags$h4(HTML(twemoji("1F31F"), "Most RT in", TWEET_MOST$text)),
            withSpinner(uiOutput("dash_most_rt"), proxy.height = "200px")
          ),
          column(
            width = 8,
            offset = 2,
            class = "col-md-6 col-md-offset-0 col-lg-4",
            class = "text-center",
            tags$h4(HTML(twemoji("1F389"), "Most Recent")),
            withSpinner(uiOutput("dash_most_recent"), proxy.height = "200px")
          )
          # Frontpage - Most XX Tweets - end ----------------------------------------
        )
      ),

      # High Score - tab_high_score ---------------------------------------------
      tabItem(
        "tab_high_score",
        fluidRow(
          box(
            width = "6 col-lg-3",
            status = "info",
            title = "Top Tweeters",
            tags$div(
              class = "scroll-overflow-x",
              withSpinner(uiOutput("top_tweeters"))
            ),
            helpText(HTML("Total &#x1F504; RT (x2) and &#x2764; Favorites per user"))
          ),
          box(
            width = "6 col-lg-3",
            status = "danger",
            title = "Top Hashtags",
            withSpinner(uiOutput("top_hashtags")),
            helpText("Times hashtag was used relative to most popular hashtag, excludes",
                     tags$code(TOPIC$name),
                     if (!is.null(TOPIC$full_community)) HTML(paste(
                       "and", tags$code(TOPIC$full_community))
                     ))
          ),
          box(
            width = "6 col-lg-3",
            status = "warning",
            title = "Top Words",
            withSpinner(uiOutput("top_tweet_words")),
            helpText("Times word was used relative to most popular word")
          ),
          box(
            width = "6 col-lg-3",
            status = "success",
            title = "Top Emoji",
            withSpinner(uiOutput("top_emojis")),
            helpText("Times emoji was used relative to most used emoji")
          )
        )
      ),

      # Tweet Wall - tab_tweet_wall ---------------------------------------------
      tabItem(
        "tab_tweet_wall",
        class = "text-center",
        tags$h1("Tweets about", TOPIC$name),
        # Tweet Wall - twitter.js and masonry.css - start --------------------
        # twitter.js has to be loaded after the page is loaded (divs exist and jquery is loaded)
        tags$head(HTML(
        '
        <script>
        document.addEventListener("DOMContentLoaded", function(event) {
          var script = document.createElement("script");
          script.type = "text/javascript";
          script.src  = "twitter.js";
          document.getElementsByTagName("head")[0].appendChild(script);
        });
        </script>
        ')),
        tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "masonry.css")),
        # Tweet Wall - twitter.js and masonry.css - end ----------------------
        fluidRow(
          column(
            # Tweet Wall - Controls - start -------------------------------------------
            12,
            class = "col-md-8 col-md-offset-2 col-lg-6 col-lg-offset-3",
            tags$form(
              class = "form-inline",
              tags$div(
                class = "form-group",
                tags$div(
                  class = "btn-toolbar btn-group-sm",
                  dateRangeInput("tweet_wall_daterange", "",
                                 start = today(tz_global()), end = today(tz_global()),
                                 min = "2019-01-01", max = today(tz_global()),
                                 weekstart = 1, separator = " to "),
                  shinyThings::dropdownButtonUI("tweet_wall_date_presets",
                                                TWEET_WALL_DATE_INPUTS,
                                                class = "btn-default")
                )
              )
            )
            # Tweet Wall - Controls - end ---------------------------------------------
          ),
          shinyThings::paginationUI("tweet_wall_pager", width = 12, offset = 0)
        ),
        withSpinner(uiOutput("tweet_wall_tweets"), type = 3),
        shinyThings::pagerUI("tweet_wall_pager", centered = TRUE)
      ),

      # Pictures - tab_pic_tweets -----------------------------------------------
      tabItem(
        "tab_pic_tweets",
        class = "text-center",
        tags$h1(HTML("Tweets with", twemoji("1F5BC", width = "42px"))),
        shinyThings::paginationUI("pic_tweets", width = 12, offset = 0),
        withSpinner(uiOutput("pic_tweets_wall"), type = 3),
        shinyThings::pagerUI("pic_tweets", centered = TRUE)
      ),

      # Explore - tab_explore ---------------------------------------------------
      tabItem(
        "tab_explore",
        fluidRow(
          tweetExplorerUI("tweet_table", collapsed = TRUE, status = "success")
        )
      ),

      # Schedule - tab_schedule -------------------------------------------------
      if (!is.null(SCHEDULE$data)) tabItem(
        "tab_schedule",
        fluidRow(
          box(
            width = 12,
            status = "success",
            DT::dataTableOutput("table_schedule"),
            helpText(
              "This is an unofficial schdeule. Please refer to the",
              tags$a(href = SCHEDULE$url, "official", META$conf_org, "website"),
              "for the up-to-date schedule."
            )
          )
        )
      ) else tags$div(class = "tab-pane"),

      # About - tab_about -------------------------------------------------------
      tabItem(
        "tab_about",
        source(here::here("R", "custom", "about_page.R"))$value
      )
    )
  )
)


