#' @title `r lifecycle::badge("experimental")` Create a controller with a
#'   PBS launcher.
#' @export
#' @family controllers
#' @description Create an `R6` object to submit tasks and
#'   launch workers on PBS workers.
#' @inheritParams crew::crew_router
#' @inheritParams crew_launcher_pbs
#' @inheritParams crew::crew_controller
#' @examples
#' if (identical(Sys.getenv("CREW_EXAMPLES"), "true")) {
#' controller <- crew_controller_pbs()
#' controller$start()
#' controller$push(name = "task", command = sqrt(4))
#' controller$wait()
#' controller$pop()$result
#' controller$terminate()
#' }
crew_controller_pbs <- function(
  name = NULL,
  workers = 1L,
  host = NULL,
  port = NULL,
  seconds_launch = 60,
  seconds_interval = 0.01,
  seconds_timeout = 5,
  seconds_idle = Inf,
  seconds_wall = Inf,
  seconds_exit = 0.1,
  tasks_max = Inf,
  tasks_timers = 0L,
  reset_globals = TRUE,
  reset_packages = FALSE,
  reset_options = FALSE,
  garbage_collection = FALSE,
  verbose = FALSE,
  command_submit = as.character(Sys.which("qsub")),
  command_delete = as.character(Sys.which("qdel")),
  script_directory = tempdir(),
  script_lines = character(0L),
  pbs_log_output = "/dev/null",
  pbs_log_error = NULL,
  pbs_log_join = TRUE,
  pbs_memory_gigabytes_required = NULL,
  pbs_cores = NULL,
  pbs_walltime_hours = 12,
  auto_scale = "demand"
) {
  router <- crew::crew_router(
    name = name,
    workers = workers,
    host = host,
    port = port,
    seconds_interval = seconds_interval,
    seconds_timeout = seconds_timeout
  )
  launcher <- crew_launcher_pbs(
    name = name,
    seconds_launch = seconds_launch,
    seconds_interval = seconds_interval,
    seconds_timeout = seconds_timeout,
    seconds_idle = seconds_idle,
    seconds_wall = seconds_wall,
    seconds_exit = seconds_exit,
    tasks_max = tasks_max,
    tasks_timers = tasks_timers,
    reset_globals = reset_globals,
    reset_packages = reset_packages,
    reset_options = reset_options,
    garbage_collection = garbage_collection,
    verbose = verbose,
    command_submit = command_submit,
    command_delete = command_delete,
    script_directory = script_directory,
    script_lines = script_lines,
    pbs_log_output = pbs_log_output,
    pbs_log_error = pbs_log_error,
    pbs_log_join = pbs_log_join,
    pbs_memory_gigabytes_required = pbs_memory_gigabytes_required,
    pbs_cores = pbs_cores,
    pbs_walltime_hours = pbs_walltime_hours
  )
  controller <- crew::crew_controller(
    router = router,
    launcher = launcher,
    auto_scale = auto_scale
  )
  controller$validate()
  controller
}