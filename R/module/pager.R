pagerUI <- function(id, width = 6, ..., offset = 3) {
  ns <- NS(id)
  fluidRow(
    column(
      width = width, offset = offset, ...,
      # uiOutput(ns("pager_slider")),
      uiOutput(ns("pager_buttons"))
    )
  )
}

pagerNextButtonsUI <- function(id, width = 12, ..., offset = 0) {
  ns <- NS(id)
  fluidRow(
    column(
      width = width, offset = offset, ...,
      uiOutput(ns("pager_extra_buttons"))
    )
  )
}

shiny_page_button <- function(n, ns, s_page = 1) {
  tags$li(
    class = paste("page-item", if (n == s_page) "active"),
    actionLink(
      ns(sprintf("page_%03d", n)),
      n,
      class = "page-link"
    )
  )
}

prev_next_button <- function(goto = c("prev", "next"), ns, disabled = FALSE, id_suffix = NULL) {
  goto <- match.arg(goto)
  input_id <- if (goto == "prev") "page_prev" else "page_next"
  input_id <- paste0(input_id, id_suffix)
  input_label <- if (goto == "prev") "Previous" else "Next"

  tags$li(
    class = paste("page-item", if (disabled) "disabled"),
    actionLink(ns(input_id), input_label, class = "page-link")
  )
}

pagerSliderModule <- function(input, output, session, page_break = 20, n_items) {
  ns <- session$ns

  pages <- rep(0L, 999)

  s_page <- reactiveVal(1L)

  observe({
    pgs <- sort(names(input))
    if (!length(pgs)) return(NULL)
    pgs <- str_subset(pgs, "\\d")
    pg <- map_int(pgs, ~ input[[.]] %||% 0L)
    s_pg <- which(pages[1:length(pg)] != pg)
    if (!length(s_pg)) return(NULL)
    s_page(s_pg)
    cat(s_page())
    pages[s_pg] <- pg[s_pg]
  })

  output$pager_extra_buttons <- renderUI({
    req(n_items() > page_break)
    req(s_page())

    n_pages <- ceiling(n_items() / page_break)
    at_first <- s_page() == 1
    at_last <- s_page() == n_pages

    prev <- prev_next_button("prev", ns, at_first, "_extra")
    nxt  <- prev_next_button("next", ns, at_last, "_extra")

    tags$nav(
      "aria-label" = "...",
      tags$ul(
        class = "pagination",
        prev,
        nxt
      )
    )
  })

  output$pager_buttons <- renderUI({
    req(n_items() > page_break)
    req(s_page())

    n_pages <- ceiling(n_items() / page_break)
    at_first <- s_page() == 1
    at_last <- s_page() == n_pages

    page_start <- max(1L, s_page() - 2L)
    page_end <- min(n_pages, s_page() + 2L)

    bttns <- map(page_start:page_end, shiny_page_button, ns = ns, s_page = s_page())

    prev <- prev_next_button("prev", ns, at_first)
    nxt  <- prev_next_button("next", ns, at_last)

    tags$nav(
      "aria-label" = "...",
      tags$ul(
        class = "pagination",
        prev,
        bttns,
        nxt
      )
    )
  })

  observeEvent(input$page_prev, {
    s_page(s_page() - 1L)
  })

  observeEvent(input$page_next, {
    s_page(s_page() + 1L)
  })

  observeEvent(input$page_prev_extra, {
    s_page(s_page() - 1L)
  })

  observeEvent(input$page_next_extra, {
    s_page(s_page() + 1L)
  })

  return(reactive({s_page()}))
}
