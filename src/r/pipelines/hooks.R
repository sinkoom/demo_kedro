## This file define hooks for the Framework to execute.
## "hooks" is simply a named list containing pipelines.
## There must always be a hook named 'default'.
## Example:
## hooks <- list(default = my_pipeline,
##               engineering = data_engineering_pipeline,
##               science = data_science_pipeline)
##
## The pipelines are sourced from the pipeline.R files inside the pipelines folder.
## For example:
## source("pipelines/engineering/pipeline.R", chdir = TRUE)
## The 'chdir = TRUE' argument is necessary because we are using relative paths.
##
## If you source from multiple files and want to avoid name clashes, use an environment
## for each file.
## For example:
## eng <- base::new.env()
## source("pipelines/engineering/pipeline.R", chdir = TRUE, local = eng)
## Now the contents of the file are listed in 'eng'.
source(file.path("example", "pipeline.R"), chdir = TRUE)

hooks <- list(
  default = pipeline,
  greet = list(greeting_node), # pipeline with single node
  model = model_pipeline, # modeling pipeline loading and saving data
  estimate = model_pipeline[1:2]
) # stop after estimating the model
