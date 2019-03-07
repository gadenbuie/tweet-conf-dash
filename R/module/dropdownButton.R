#' @param options A named vector of options and labels. The name is the label
#'   that will appear on the button and the value is the id of the input.
#' @param type One of `"dropdown"` or `"dropup"`
dropdownButtonUI <- function(id, options, label = "Options", type = "dropdown", buttonId = NULL, class = NULL) {
  if (is.null(buttonId)) {
    buttonId <- paste0(id, "-dropdown")
  }
  ns <- NS(id)
  tags$div(
    class = paste("btn-group", type, class),
    tags$button(
      class = "btn btn-default dropdown-toggle",
      role = "button",
      id = buttonId,
      "data-toggle" = "dropdown",
      "aria-haspopup" = "true",
      "aria-expanded" = "false",
      label , tags$span(class = "caret")
    ),
    tags$ul(
      class = "dropdown-menu box-shadow",
      "aria-labelledby" = buttonId,
      purrr::imap(options, dropdown_buttons, ns = ns)
    )
  )
}

dropdown_buttons <- function(input_id, text, ns) {
  tags$li(actionLink(ns(input_id), text), class = "dropdown-item")
}

dropdownButton <- function(input, output, session, options) {
  ns <- session$ns

  prev_state <- setNames(rep(0L, length(options)), names(options))

  this_state <- reactive({
    map_dbl(options, ~ input[[.]] %||% 0L)
  })

  clicked_button <- reactive({
    this_state <- this_state()
    updated_state <- which(prev_state != this_state)
    if (length(updated_state) > 1) {
      warning("More than one button state was updated!")
      cat(capture.output(str(this_state)), sep = "\n")
    }
    prev_state <<- this_state
    options[updated_state]
  })

  return(clicked_button)
}
