#' @title `r lifecycle::badge("experimental")` Create a launcher with
#'   PBS or TORQUE workers.
#' @export
#' @family pbs
#' @description Create an `R6` object to launch and maintain
#'   workers as jobs on a PBS or TORQUE cluster.
#' @details WARNING: the `crew.cluster` PBS plugin is experimental
#'   and has not actually been tested on a PBS cluster. Please proceed
#'   with caution and report bugs to
#'   <https://github.com/wlandau/crew.cluster>.
#'
#'   To launch a PBS/TORQUE worker, this launcher
#'   creates a temporary job script with a call to `crew::crew_worker()`
#'   and submits it as an PBS job with `qsub`. To see most of the lines
#'   of the job script in advance, use the `script()` method of the launcher.
#'   It has all the lines except for the job name and the
#'   call to `crew::crew_worker()`, both of
#'   which will be inserted at the last minute when it is time
#'   to actually launch a worker.
#' @inheritSection crew.cluster-package Attribution
#' @inheritParams crew_launcher_cluster
#' @param pbs_cwd Logical of length 1, whether to set the working directory
#'   of the worker to the working directory it was launched from.
#'   `pbs_cwd = TRUE` is translates to a line of `cd "$PBS_O_WORKDIR"`
#'   in the job script. This line is inserted after the content of
#'   `script_lines` to make sure the `#PBS` directives are above
#'   system commands. `pbs_cwd = FALSE` omits this line.
#' @param pbs_log_output Character of length 1, file or directory path to PBS
#'   worker log files for standard output.
#'   `pbs_log_output = "VALUE"` translates to a line of
#'   `#PBS -o VALUE` in the PBS job script. The default is `/dev/null` to omit
#'   the logs. If you do supply a non-`/dev/null` value,
#'   it is recommended to supply a
#'   directory path with a trailing slash so that each worker gets its own set
#'   of log files.
#' @param pbs_log_error Character of length 1, file or directory path to PBS
#'   worker log files for standard error.
#'   `pbs_log_error = "VALUE"` translates to a line of
#'   `#PBS -e VALUE` in the PBS job script.
#'   The default of `NULL` omits this line.
#'   If you do supply a non-`/dev/null` value, it is recommended to supply a
#'   directory path with a trailing slash so that each worker gets its own set
#'   of log files.
#' @param pbs_log_join Logical, whether to join the stdout and stderr log
#'   files together into one file. `pbs_log_join = TRUE` translates to a line
#'   of `#PBS -j oe` in the PBS job script, while `pbs_log_join = FALSE` is
#'   equivalent to `#PBS -j n`. If `pbs_log_join = TRUE`, then `pbs_log_error`
#'   should be `NULL`.
#' @param pbs_memory_gigabytes_required Optional positive numeric of length 1
#'   with the gigabytes of memory required to run the worker.
#'   `pbs_memory_gigabytes_required = 2.4`
#'   translates to a line of `#PBS -l mem=2.4gb` in the PBS job script.
#'   `pbs_memory_gigabytes_required = NULL` omits this line.
#' @param pbs_cores Optional positive integer of length 1,
#'   number of cores per worker ("slots" in PBS lingo).
#'   `pbs_cores = 4` translates
#'   to a line of `#PBS -l ppn=4` in the PBS job script.
#'   `pbs_cores = NULL` omits this line.
#' @param pbs_walltime_hours Numeric of length 1 with the hours of wall time
#'   to request for the job. `pbs_walltime_hours = 23` translates to
#'   a line of `#PBS -l walltime=23:00:00` in the job script.
#'   `pbs_walltime_hours = NULL` omits this line.
crew_launcher_pbs <- function(
  name = NULL,
  seconds_interval = 0.5,
  seconds_timeout = 60,
  seconds_launch = 86400,
  seconds_idle = Inf,
  seconds_wall = Inf,
  tasks_max = Inf,
  tasks_timers = 0L,
  reset_globals = TRUE,
  reset_packages = FALSE,
  reset_options = FALSE,
  garbage_collection = FALSE,
  launch_max = 5L,
  tls = crew::crew_tls(mode = "automatic"),
  r_arguments = c("--no-save", "--no-restore"),
  verbose = FALSE,
  command_submit = as.character(Sys.which("qsub")),
  command_terminate = as.character(Sys.which("qdel")),
  command_delete = NULL,
  script_directory = tempdir(),
  script_lines = character(0L),
  pbs_cwd = TRUE,
  pbs_log_output = "/dev/null",
  pbs_log_error = NULL,
  pbs_log_join = TRUE,
  pbs_memory_gigabytes_required = NULL,
  pbs_cores = NULL,
  pbs_walltime_hours = 12
) {
  name <- as.character(name %|||% crew::crew_random_name())
  if (!is.null(command_delete)) {
    crew::crew_deprecate(
      name = "command_delete",
      date = "2023-01-08",
      version = "0.1.4.9001",
      alternative = "command_terminate"
    )
    command_terminate <- command_delete
  }
  launcher <- crew_class_launcher_pbs$new(
    name = name,
    seconds_interval = seconds_interval,
    seconds_timeout = seconds_timeout,
    seconds_launch = seconds_launch,
    seconds_idle = seconds_idle,
    seconds_wall = seconds_wall,
    tasks_max = tasks_max,
    tasks_timers = tasks_timers,
    reset_globals = reset_globals,
    reset_packages = reset_packages,
    reset_options = reset_options,
    garbage_collection = garbage_collection,
    launch_max = launch_max,
    tls = tls,
    r_arguments = r_arguments,
    verbose = verbose,
    command_submit = command_submit,
    command_terminate = command_terminate,
    script_directory = script_directory,
    script_lines = script_lines,
    pbs_cwd = pbs_cwd,
    pbs_log_output = pbs_log_output,
    pbs_log_error = pbs_log_error,
    pbs_log_join = pbs_log_join,
    pbs_memory_gigabytes_required = pbs_memory_gigabytes_required,
    pbs_cores = pbs_cores,
    pbs_walltime_hours = pbs_walltime_hours
  )
  launcher$validate()
  launcher
}

#' @title `r lifecycle::badge("maturing")` PBS/TORQUE launcher class
#' @export
#' @family pbs
#' @description `R6` class to launch and manage PBS/TORQUE workers.
#' @details See [crew_launcher_pbs()].
#' @inheritSection crew.cluster-package Attribution
crew_class_launcher_pbs <- R6::R6Class(
  classname = "crew_class_launcher_pbs",
  inherit = crew_class_launcher_cluster,
  cloneable = FALSE,
  private = list(
    .pbs_cwd = NULL,
    .pbs_log_output = NULL,
    .pbs_log_error = NULL,
    .pbs_log_join = NULL,
    .pbs_memory_gigabytes_required = NULL,
    .pbs_cores = NULL,
    .pbs_walltime_hours = NULL
  ),
  active = list(
    #' @field pbs_cwd See [crew_launcher_pbs()].
    pbs_cwd = function() {
      .subset2(private, ".pbs_cwd")
    },
    #' @field pbs_log_output See [crew_launcher_pbs()].
    pbs_log_output = function() {
      .subset2(private, ".pbs_log_output")
    },
    #' @field pbs_log_error See [crew_launcher_pbs()].
    pbs_log_error = function() {
      .subset2(private, ".pbs_log_error")
    },
    #' @field pbs_log_join See [crew_launcher_pbs()].
    pbs_log_join = function() {
      .subset2(private, ".pbs_log_join")
    },
    #' @field pbs_memory_gigabytes_required See [crew_launcher_pbs()].
    pbs_memory_gigabytes_required = function() {
      .subset2(private, ".pbs_memory_gigabytes_required")
    },
    #' @field pbs_cores See [crew_launcher_pbs()].
    pbs_cores = function() {
      .subset2(private, ".pbs_cores")
    },
    #' @field pbs_walltime_hours See [crew_launcher_pbs()].
    pbs_walltime_hours = function() {
      .subset2(private, ".pbs_walltime_hours")
    }
  ),
  public = list(
    #' @description PBS/TORQUE launcher constructor.
    #' @return an PBS/TORQUE launcher object.
    #' @param name See [crew_launcher_pbs()].
    #' @param seconds_interval See [crew_launcher_slurm()].
    #' @param seconds_timeout See [crew_launcher_slurm()].
    #' @param seconds_launch See [crew_launcher_pbs()].
    #' @param seconds_idle See [crew_launcher_pbs()].
    #' @param seconds_wall See [crew_launcher_pbs()].
    #' @param tasks_max See [crew_launcher_pbs()].
    #' @param tasks_timers See [crew_launcher_pbs()].
    #' @param reset_globals See [crew_launcher_pbs()].
    #' @param reset_packages See [crew_launcher_pbs()].
    #' @param reset_options See [crew_launcher_pbs()].
    #' @param garbage_collection See [crew_launcher_pbs()].
    #' @param launch_max See [crew_launcher_pbs()].
    #' @param tls See [crew_launcher_pbs()].
    #' @param r_arguments See [crew_launcher_pbs()].
    #' @param verbose See [crew_launcher_pbs()].
    #' @param command_submit See [crew_launcher_pbs()].
    #' @param command_terminate See [crew_launcher_pbs()].
    #' @param script_directory See [crew_launcher_pbs()].
    #' @param script_lines See [crew_launcher_pbs()].
    #' @param pbs_cwd See [crew_launcher_sge()].
    #' @param pbs_log_output See [crew_launcher_pbs()].
    #' @param pbs_log_error See [crew_launcher_pbs()].
    #' @param pbs_log_join See [crew_launcher_pbs()].
    #' @param pbs_memory_gigabytes_required See [crew_launcher_pbs()].
    #' @param pbs_cores See [crew_launcher_pbs()].
    #' @param pbs_walltime_hours See [crew_launcher_pbs()].
    initialize = function(
      name = NULL,
      seconds_interval = NULL,
      seconds_timeout = NULL,
      seconds_launch = NULL,
      seconds_idle = NULL,
      seconds_wall = NULL,
      tasks_max = NULL,
      tasks_timers = NULL,
      reset_globals = NULL,
      reset_packages = NULL,
      reset_options = NULL,
      garbage_collection = NULL,
      launch_max = NULL,
      tls = NULL,
      r_arguments = NULL,
      verbose = NULL,
      command_submit = NULL,
      command_terminate = NULL,
      script_directory = NULL,
      script_lines = NULL,
      pbs_cwd = NULL,
      pbs_log_output = NULL,
      pbs_log_error = NULL,
      pbs_log_join = NULL,
      pbs_memory_gigabytes_required = NULL,
      pbs_cores = NULL,
      pbs_walltime_hours = NULL
    ) {
      super$initialize(
        name = name,
        seconds_interval = seconds_interval,
        seconds_timeout = seconds_timeout,
        seconds_launch = seconds_launch,
        seconds_idle = seconds_idle,
        seconds_wall = seconds_wall,
        tasks_max = tasks_max,
        tasks_timers = tasks_timers,
        reset_globals = reset_globals,
        reset_packages = reset_packages,
        reset_options = reset_options,
        garbage_collection = garbage_collection,
        launch_max = launch_max,
        tls = tls,
        r_arguments = r_arguments,
        verbose = verbose,
        command_submit = command_submit,
        command_terminate = command_terminate,
        script_directory = script_directory,
        script_lines = script_lines
      )
      private$.pbs_cwd <- pbs_cwd
      private$.pbs_log_output <- pbs_log_output
      private$.pbs_log_error <- pbs_log_error
      private$.pbs_log_join <- pbs_log_join
      private$.pbs_memory_gigabytes_required <- pbs_memory_gigabytes_required
      private$.pbs_cores <- pbs_cores
      private$.pbs_walltime_hours <- pbs_walltime_hours
    },
    #' @description Validate the launcher.
    #' @return `NULL` (invisibly). Throws an error if a field is invalid.
    validate = function() {
      super$validate()
      crew::crew_assert(
        private$.pbs_log_output,
        is.character(.),
        length(.) == 1L,
        !anyNA(.),
        nzchar(.),
        message = "pbs_log_output must be a nonempty length-1 character string."
      )
      if (!is.null(private$.pbs_log_error)) {
        crew::crew_assert(
          private$.pbs_log_error,
          is.character(.),
          length(.) == 1L,
          !anyNA(.),
          nzchar(.),
          message = paste(
            "pbs_log_error must be a nonempty",
            "length-1 character string."
          )
        )
      }
      fields <- c(
        "pbs_cwd",
        "pbs_log_join"
      )
      for (field in fields) {
        crew::crew_assert(
          self[[field]],
          isTRUE(.) || isFALSE(.),
          message = paste(field, "must be a length-1 logical.")
        )
      }
      fields <- c(
        "pbs_memory_gigabytes_required",
        "pbs_cores",
        "pbs_walltime_hours"
      )
      for (field in fields) {
        if (!is.null(self[[field]])) {
          crew::crew_assert(
            self[[field]],
            is.numeric(.),
            length(.) == 1L,
            !anyNA(.),
            . > 0L,
            message = paste("invalid", field, "field")
          )
        }
      }
      invisible()
    },
    #' @description Generate the job script.
    #' @details Includes everything except the worker-instance-specific
    #'   job name and the worker-instance-specific
    #'   call to `crew::crew_worker()`, both of which get inserted at
    #'   the bottom of the script at launch time.
    #' @return Character vector of the lines of the job script.
    #' @param name Character of length 1, name of the job. For inspection
    #'   purposes, you can supply a mock job name.
    #' @examples
    #' if (identical(Sys.getenv("CREW_EXAMPLES"), "true")) {
    #' launcher <- crew_launcher_pbs(
    #'   pbs_cores = 2,
    #'   pbs_memory_gigabytes_required = 4
    #' )
    #' launcher$script(name = "my_job_name")
    #' }
    script = function(name) {
      c(
        paste("#PBS -N", name),
        paste("#PBS -o", private$.pbs_log_output),
        if_any(
          is.null(private$.pbs_log_error),
          character(0L),
          paste("#PBS -e", private$.pbs_log_error)
        ),
        if_any(private$.pbs_log_join, "#PBS -j oe", "#PBS -j n"),
        if_any(
          is.null(private$.pbs_memory_gigabytes_required),
          character(0L),
          sprintf(
            "#PBS -l mem=%sgb",
            private$.pbs_memory_gigabytes_required
          )
        ),
        if_any(
          is.null(private$.pbs_cores),
          character(0L),
          paste0("#PBS -l ppn=", as.character(private$.pbs_cores))
        ),
        if_any(
          is.null(private$.pbs_walltime_hours),
          character(0L),
          sprintf(
            "#PBS -l walltime=%s:00:00",
            as.character(private$.pbs_walltime_hours)
          )
        ),
        private$.script_lines,
        if_any(private$.pbs_cwd, "cd \"$PBS_O_WORKDIR\"", character(0L))
      )
    }
  )
)
