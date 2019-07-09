#
# Note About Credit
# =================
#
# You may, of course, decide to change this section of the dashboard.
# But PLEASE provide credit and link to my website: garrickadenbuie.com
# Something like this would be great:
#
# "This dashboard was built using a template provided by
# <a href="https://garrickadenbuie.com">Garrick Aden-Buie</a>."
#
# Thank you! -Garrick
fluidRow(
  # About - About Me - start ------------------------------------------------
  box(
    title = "About me",
    status = "danger",
    width = "6 col-lg-4",
    tags$p(
      class = "text-center",
      tags$img(class = "img-responsive img-rounded center-block", src = "grrrck.jpg", style = "max-width: 150px;")
    ),
    tags$p(
      class = "text-center",
      HTML(twemoji("1F44B")),
      tags$strong("Hi! I'm Garrick."),
      HTML(paste0("(", tags$a(href = "https://twitter.com/grrrck", "@grrrck"), ")"))
    ),
    tags$p(
      "I'm a data scientist from St. Petersburg, FL, where I focus on",
      "data visualization, interactive reporting, data structuring and cleaning,",
      "and statistical and machine learning. I enjoy building bespoke data tools,",
      "like this dashboard. You can find more of the things I like to build on my webpage",
      HTML(paste0(tags$a(href = "https://garrickadenbuie.com", "garrickadenbuie.com", target = "_blank"), "."))
    ),
    tags$p(
      "I also use data science to support cancer research with",
      tags$a(href = "https://gerkelab.com", "GerkeLab", target = "_blank"),
      "at", tags$a(href = "https://moffitt.org", "Moffitt Cancer Center", target = "_blank"),
      "in sunny Tampa, FL.",
      "I'm lucky to get to use R and RStudio tools on a daily basis to help others",
      "learn from patient, genetic and molecular data and to communicate their results",
      "through dashboards and interactive reports like this one."
    ),
    tags$p(
      "Get in touch with me on Twitter at",
      HTML(paste0("(", tags$a(href = "https://twitter.com/grrrck", "@grrrck", target = "_blank"), "),")),
      "online at",
      HTML(paste0(tags$a(href = "https://garrickadenbuie.com", "garrickadenbuie.com", target = "_blank"), ",")),
      "or by email at",
      HTML(paste0(tags$a(href = "mailto:garrick@adenbuie.com", "garrick@adenbuie.com"), "."))
    )
  ),
  # About - About Me - end --------------------------------------------------
  # About - About Dashboard - start -----------------------------------------
  box(
    title = "About this Dashboard",
    # status = "primary",
    width = "6 col-lg-4",
    tags$p(
      class = "text-center",
      tags$a(
        href = "https://www.r-project.org",
        target = "_blank",
        tags$img(class = "image-responsive",
                 src = "https://www.r-project.org/logo/Rlogo.svg",
                 style = "max-width: 150px;"
        )
      ),
      tags$a(
        href = "https://rstudio.com",
        target = "_blank",
        tags$img(class = "image-responsive",
                 src = "RStudio.svg",
                 style = "max-width: 150px; margin-left: 2em;"
        )
      ),
      tags$a(
        href = "https://rtweet.info",
        target = "_blank",
        tags$img(class = "image-responsive",
                 src = "rtweet.png",
                 style = "max-width: 150px; margin-left: 2em;"
        )
      )
    ),
    tags$p(
      "This dashboard was built in",
      tags$a(href = "https://r-project.org", target = "_blank", "R"),
      "and", tags$a(href = "https://rstudio.com", target = "_blank", "RStudio"), "with",
      tags$strong("shiny,"),
      tags$strong("shinydashboard,"),
      tags$strong("rtweet,"),
      tags$strong("plotly,"),
      "the", tags$strong("tidyverse,"),
      "and many more packages."
    )
  )
  # About - About Dashboard - end -----------------------------------------
)
