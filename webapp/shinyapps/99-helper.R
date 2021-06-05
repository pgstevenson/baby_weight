
new_var <- function(x, y, z, a) tibble(name = x, type = y, unit = z, description = a)

age_variables <- function(days, months) {

  # Weekly expected weight gain (grams)
  # NHMRC Infant-feeding-guidelines-info-for-health-workers.pdf

  if (months < 3) {
    growth <- c(min = 150, max = 200)
  } else if (months < 6) {
    growth <- c(min = 100, max = 150)
  } else if (months < 12) {
    growth <- c(min = 70, max = 90)
  } else {
    growth <- NA
  }

  # Approximate formula required for infants, mL/kg/day
  # NHMRC Infant-feeding-guidelines-info-for-health-workers.pdf

  if (days >= 5 & months < 3) {
    volume <- 150
  } else if (months < 6) {
    volume <- 120
  } else if (months < 12) {
    volume <- 100
  } else {
    volume <- NA
  }

  tibble(amt_growth_min = growth["min"],
         amt_growth_max = growth["max"],
         amt_volume = volume)

}

db_data <- function(api) {

  #### Import data ----

  dat <- list()

  dat$dat <- fromJSON(readLines(glue('{api}/api/v1/weight?child_id=1'))) %>% as_tibble()
  dat$meta <- fromJSON(readLines(glue('{api}/api/v1/child?id=1'))) %>% as_tibble()
  
  #### data cleaning ----

  dat$meta <- mutate(dat$meta,
                     across("male", ~as.logical(as.numeric(.))),
                     across("dob", dmy_hms))
  dat$dat <- mutate(dat$dat, across("weight_date", dmy_hms))

  dat

}

db_add_weight <- function(x, y, z, api) {

  GET(glue("{api}/api/v1/insert_weight?id={x}&weight={y}&date=\'{format(z, '%Y-%m-%d')}\'"))
  
  return()

}

fun_weight_change <- function(x, y, z) {

  ggplot(x, aes(x = weight_date, y = {{ y }}, fill = {{ y }} > 0)) +
    geom_col() +
    geom_text(aes(y = {{ y }} * 1.15, label = sprintf("%0.0f", {{ y }}))) +
    geom_hline(aes(yintercept = 0)) +
    labs(title = z,
         subtitle = "Weight change between measurements",
         x = "Date",
         y = "Weight change (g)") +
    theme(legend.position = "none")

}
