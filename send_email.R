send_email <- function(sender, recipients, subject, message, ..., attachmentpaths = NULL) {
  library(mailR)

  # SMTP server configuration for CATS
  server <- "smtp.messaging.svc"
  port <- 1025
  smtp_username <- ""
  smtp_password <- "" # Use an App Password for security
  attachmentpaths <- c(...)

  lines <- readLines(message)

  # Combine the lines into a single string using paste()
  content <- paste(lines, collapse = "\n")

  # Check if the content contains HTML tags
  contains_html <- grepl("<[a-zA-Z!][^>]*>", content)

  # Split recipients into a vector
  recipient_list <- unlist(strsplit(recipients, ",\\s*"))

  # Create and Send the email
  tryCatch(
    {
      if (!is.null(attachmentpaths)) {
        send.mail(
          from = sender,
          to = recipient_list,
          subject = subject,
          body = content,
          html = contains_html,
          smtp = list(host.name = server, port = port, user.name = "", passwd = "", ssl = FALSE),
          authenticate = FALSE,
          send = TRUE,
          attach.files = attachmentpaths
        )
      } else {
        send.mail(
          from = sender,
          to = recipient_list,
          subject = subject,
          body = content,
          html = contains_html,
          smtp = list(host.name = server, port = port, user.name = "", passwd = "", ssl = FALSE),
          authenticate = FALSE,
          send = TRUE
        )
      }

      cat("Email sent successfully.\n")
    },
    error = function(e) {
      cat("Error sending email:", e$message, "\n")
    }
  )
}
