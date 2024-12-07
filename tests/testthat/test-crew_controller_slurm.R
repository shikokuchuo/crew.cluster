test_that("crew_controller_slurm() script() nearly empty", {
  x <- crew_controller_slurm(slurm_time_minutes = NULL)
  lines <- c(
    "#!/bin/sh",
    "#SBATCH --job-name=name",
    "#SBATCH --output=/dev/null",
    "#SBATCH --error=/dev/null"
  )
  expect_equal(x$launcher$script(name = "name", attempt = 1L), lines)
})

test_that("crew_controller_slurm() script() all lines", {
  x <- crew_controller_slurm(
    options_cluster = crew_options_slurm(
      script_lines = c("module load R", "echo 'start'"),
      log_output = "log1",
      log_error = "log2",
      memory_gigabytes_required = 5.07,
      memory_gigabytes_per_cpu = 4.07,
      cpus_per_task = 2,
      time_minutes = 57
    )
  )
  out <- x$launcher$script(name = "my_name", attempt = 1L)
  exp <- c(
    "#!/bin/sh",
    "#SBATCH --job-name=my_name",
    "#SBATCH --output=log1",
    "#SBATCH --error=log2",
    "#SBATCH --mem=5192M",
    "#SBATCH --mem-per-cpu=4168M",
    "#SBATCH --cpus-per-task=2",
    "#SBATCH --time=57",
    "module load R",
    "echo 'start'"
  )
  expect_equal(out, exp)
})

test_that("crew_controller_slurm() script() retryable options", {
  x <- crew_controller_slurm(
    options_cluster = crew_options_slurm(
      script_lines = c("module load R", "echo 'start'"),
      log_output = "log1",
      log_error = "log2",
      memory_gigabytes_required = c(5.07, 2.11),
      memory_gigabytes_per_cpu = c(4.07, 3.73),
      cpus_per_task = c(2, 3),
      time_minutes = c(57, 11)
    )
  )
  out <- x$launcher$script(name = "my_name", attempt = 1L)
  exp <- c(
    "#!/bin/sh",
    "#SBATCH --job-name=my_name",
    "#SBATCH --output=log1",
    "#SBATCH --error=log2",
    "#SBATCH --mem=5192M",
    "#SBATCH --mem-per-cpu=4168M",
    "#SBATCH --cpus-per-task=2",
    "#SBATCH --time=57",
    "module load R",
    "echo 'start'"
  )
  expect_equal(out, exp)
  out <- x$launcher$script(name = "my_name", attempt = 2L)
  exp <- c(
    "#!/bin/sh",
    "#SBATCH --job-name=my_name",
    "#SBATCH --output=log1",
    "#SBATCH --error=log2",
    "#SBATCH --mem=2161M",
    "#SBATCH --mem-per-cpu=3820M",
    "#SBATCH --cpus-per-task=3",
    "#SBATCH --time=11",
    "module load R",
    "echo 'start'"
  )
  expect_equal(out, exp)
})
