## This file defines a pipeline (or many of them).
## A pipeline is a list of nodes (functions with explicit inputs and outputs) that can be
## executed sequentially.
## Example:
## pipeline <- list(
##     list(func = process_data,
##          inputs = c('parameters', 'raw_data'),
##          outputs = 'processed_data',
##          name = 'Process raw data'),
##     list(func = add_features,
##          inputs = c('parameters', 'processed_data'),
##          outputs = 'data_with_features',
##          name = 'Add new features to the processed data'))
##
## The example above is a pipeline with two nodes.
## When running this pipeline, the Framework will load the parameters.yml file and
## pass its values in the variable 'parameters'. Then, the framework will search
## catalog.yml for an entry named 'raw_data' and then load that data in a variable with the same name.
## The framework will then call the function 'process_data' with the specified inputs.

## ==============
## === PART 1 ===
## ==============
greeting <- function(params) {
  message <- paste0(toupper(params$message), "!!!!!!")
  print(message)
  return(message)
}

greeting_node <- list(
  func = greeting,
  inputs = "parameters",
  outputs = "greet",
  name = "greeting"
)

question <- function(msg) {
  q <- paste0(msg, "How are you?")
  print(q)
  return(q)
}

question_node <- list(
  func = question,
  inputs = "greet",
  outputs = "proper_greet",
  name = "question"
)

pipeline <- list(greeting_node, question_node)

## ==============
## === PART 2 ===
## ==============
summarize_and_clean <- function(df) {
  print(base::summary(df))
  clean <- tidyr::drop_na(df)
  return(clean)
}

linear_reg <- function(df) {
  model <- stats::lm(y ~ x, df)
  return(model)
}

print_predictions <- function(df, model) {
  predictions <- stats::predict(model, newdata = list(x = c(0, 10)))
  print(predictions)
  return(predictions)
}

model_pipeline <- list(
  list(
    func = summarize_and_clean,
    inputs = "data",
    outputs = "clean_data",
    name = "summarize_and_clean"
  ),
  list(
    func = linear_reg,
    inputs = "clean_data",
    outputs = "model",
    name = "linear_reg"
  ),
  list(
    func = print_predictions,
    inputs = c("clean_data", "model"),
    outputs = NULL,
    name = "print_predictions"
  )
)

## This file defines a pipeline (or many of them).
## A pipeline is a list of nodes (functions with explicit inputs and outputs) that can be
## executed sequentially.
## Example:
## pipeline <- list(
##     list(func = process_data,
##          inputs = c('parameters', 'raw_data'),
##          outputs = 'processed_data',
##          name = 'Process raw data'),
##     list(func = add_features,
##          inputs = c('parameters', 'processed_data'),
##          outputs = 'data_with_features',
##          name = 'Add new features to the processed data'))
##
## The example above is a pipeline with two nodes.
## When running this pipeline, the Framework will load the parameters.yml file and
## pass its values in the variable 'parameters'. Then, the framework will search
## catalog.yml for an entry named 'raw_data' and then load that data in a variable with the same name.
## The framework will then call the function 'process_data' with the specified inputs.

## ==============
## === PART 1 ===
## ==============
greeting <- function(params) {
  message <- paste0(toupper(params$message), "!!!!!!")
  print(message)
  return(message)
}

greeting_node <- list(
  func = greeting,
  inputs = "parameters",
  outputs = "greet",
  name = "greeting"
)

question <- function(msg) {
  q <- paste0(msg, "How are you?")
  print(q)
  return(q)
}

question_node <- list(
  func = question,
  inputs = "greet",
  outputs = "proper_greet",
  name = "question"
)

pipeline <- list(greeting_node, question_node)

## ==============
## === PART 2 ===
## ==============
summarize_and_clean <- function(df) {
  print(base::summary(df))
  clean <- tidyr::drop_na(df)
  return(clean)
}

linear_reg <- function(df) {
  model <- stats::lm(y ~ x, df)
  return(model)
}

print_predictions <- function(df, model) {
  predictions <- stats::predict(model, newdata = list(x = c(0, 10)))
  print(predictions)
  return(predictions)
}

model_pipeline <- list(
  list(
    func = summarize_and_clean,
    inputs = "data",
    outputs = "clean_data",
    name = "summarize_and_clean"
  ),
  list(
    func = linear_reg,
    inputs = "clean_data",
    outputs = "model",
    name = "linear_reg"
  ),
  list(
    func = print_predictions,
    inputs = c("clean_data", "model"),
    outputs = NULL,
    name = "print_predictions"
  )
)
