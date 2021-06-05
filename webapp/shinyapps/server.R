
#### Server ----

server <- function(input, output, session) {
    
    config <- config::get()
    
    dat_raw <- reactive({
        
        a <- input$refresher
        
        db_data(config$api)
    })
    
    dat <- reactive({
        
        req(dat_raw())
        
        left_join(dat_raw()$dat,
                  select(dat_raw()$meta, id, dob, male),
                  by = c("child_id" = "id")) %>%
            mutate(amt_age_days = 1 + as.numeric(as.duration(interval(dob, weight_date)), "days"),
                   amt_age_months = as.numeric(as.duration(interval(dob, weight_date)), "months"),
                   amt_age_years = as.numeric(as.duration(interval(dob, weight_date)), "years"),
                   amt_weight_kg = weight / 1000,
                   amt_weight_percentile = 100 * sds(amt_weight_kg,
                                               amt_age_years,
                                               ifelse(male, "male", "female"),
                                               "weight",
                                               who.ref,
                                               type = "perc"),
                   projected = FALSE)
    })
    
    amt_age_today <- reactive({
        
        req(dat_raw())

        1 + as.numeric(as.duration(interval(dat_raw()$meta$dob, Sys.Date())), "days")
        
    })
    
    last_measure <- reactive({
        
        req(dat())

        slice_max(dat(), order_by = weight_date, n = 1) # values of the last weight measurement

    })
    
    proj <- reactive({
        
        req(dat_raw(), dat(), last_measure())
        
        m <- lm(weight ~ amt_age_days,
                data = slice_max(dat(), order_by = weight_date, n = 3))
        
        a <- tibble(amt_age_days = last_measure()$amt_age_days:(last_measure()$amt_age_days + 7))
        
        bind_cols(a,
                  as_tibble(predict(m, a, interval = "prediction"))) %>%
            rename("weight" = "fit") %>%
            mutate(projected = TRUE) %>%
            mutate(amt_age_months = interval(dat_raw()$meta$dob, dat_raw()$meta$dob + days(amt_age_days) - 1) %>%
                       as.duration() %>%
                       as.numeric("months"))
        
    })
    
    ptab <- reactive({
        
        make_percentile_tab(ref = who.ref,
                            item = "weight",
                            perc = c(3, 10, 50, 85, 97),
                            stack = TRUE) %>%
            filter(sex == ifelse(dat_raw()$meta$male, "male", "female")) %>%
            mutate(age = age * 365) %>%
            pivot_wider(names_from = variable, values_from = value) %>%
            mutate(across("age", ~floor(0.5 + .)),
                   across(starts_with("perc_"), ~.*1000))
        
    })
    
    observeEvent(input$add_weight, {
        
        req(dat_raw(), last_measure(), Sys.Date())
        
        showModal(modalDialog(
            title = "Enter weight",
            
            dateInput(
                "dt_new_weight",
                "Date",
                value = Sys.Date()),
            
            numericInput(
                "amt_new_weight",
                "Weight (g)",
                last_measure()$weight,
                min = 0,
                max = 99999
            ),
            
            footer = fluidRow(
                column(12,
                       actionButton("ok_weight", "Save"),
                       modalButton("Cancel")
                )
            )
            
        ))
        
    })
    
    observeEvent(input$ok_weight, {
        
        req(dat_raw())
        
        db_add_weight(dat_raw()$meta$id, input$amt_new_weight, input$dt_new_weight, config$api)
        
        removeModal()
        
        updateNumericInput(session, "refresher", value = input$refresher + 1)
        
    })
    
    output$name <- renderUI({
        h1(glue('{dat_raw()$meta$firstname} {dat_raw()$meta$surname}'))
    })
    
    output$age <- renderUI({
        
        age <- as.numeric(as.duration(interval(dat_raw()$meta$dob, Sys.Date())), "months")
        
        h2(glue('{round(age, 1)} months old'))
    })
    
    output$weight_gain <- renderValueBox({
        
        req(dat_raw(), dat())
        
        #### Weekly average weight gain from the last 4 weeks (from last measure) ----
        
        last_4_weeks <- dat()[dat()$weight_date > last_measure()$weight_date - weeks(4) & !is.na(dat()$weight_date),]
        
        d <- last_4_weeks %>%
            mutate(across("amt_age_days", ~ . - min(amt_age_days)))
        
        m <- lm(weight ~  amt_age_days, data = d)
        
        o <- predict(m, tibble(amt_age_days = c(0, 7)))

        valueBox(
            paste(sprintf("%0.0f", o[[2]] - o[[1]]), "g"),
            "Mean weekly weight increase.",
            color = "yellow"
        )
    })
    
    output$perc <- renderValueBox({
        
        req(ptab(), last_measure())
        
        a <- filter(ptab(), age == last_measure()$amt_age_days)
        
        valueBox(
            paste(formatC(last_measure()$weight, format = "f", big.mark = ",", digits = 0), "g"),
            glue('This weight is at the {ordinal(round(last_measure()$amt_weight_percentile))} percentile',
                 ' per UK-WHO growth charts for a {round(last_measure()$amt_age_months,1)}',
                 ' month old {ifelse(last_measure()$male, "male", "female")}.'),
            color = "orange"
        )
    })
    
    output$perc50 <- renderValueBox({
        
        req(last_measure(), ptab(), dat_raw())
        
        a <- filter(ptab(), age == amt_age_today())
        b <- age_variables(last_measure()$amt_age_days, last_measure()$amt_age_months)
        
        valueBox(
            glue('{formatC(b$amt_volume * last_measure()$weight / 1000, format = "f", big.mark = ",", digits = 0)} mL'),
            glue("Suggested formula volume for {dat_raw()$meta$firstname}'s most recently recorded weight calculated",
                 ' as {b$amt_volume} mL/kg/day. The volume for a UK-WHO 50th percentile weight',
                 ' {round(last_measure()$amt_age_months, 1)} month old {ifelse(last_measure()$male, "male", "female")}',
                 ' ({formatC(a$perc_50_0, format = "f", big.mark = ",", digits = 0)} g) is',
                 ' {formatC(b$amt_volume * a$perc_50_0 / 1000, format = "f", big.mark = ",", digits = 0)} mL'),
            color = "green")
    })
    
    output$plot1 <- renderPlot({
        
        req(dat_raw(), dat(), proj(), ptab())
        
        bind_rows(dat(), proj()) %>%
            left_join(ptab(), by = c("amt_age_days" = "age")) %>%
            select(amt_age_days, weight, projected, lwr, upr, starts_with("perc_")) %>%
            filter(amt_age_days > max(.$amt_age_days) - 92) %>% # ~3 months
            ggplot(aes(x = amt_age_days, y = weight)) +
            geom_line(aes(y = perc_50_0), size = 0.5, linetype = "dashed") +
            geom_ribbon(aes(ymin = perc_03_0, ymax = perc_97_0), alpha = 0.1, fill = ifelse(dat_raw()$meta$male, "blue", "red")) +
            geom_ribbon(aes(ymin = perc_10_0, ymax = perc_85_0), alpha = 0.1, fill = ifelse(dat_raw()$meta$male, "blue", "red")) +
            geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.2, fill = "black") +
            geom_line(aes(color = projected), size = 1.5) +
            geom_vline(xintercept = amt_age_today()) +
            labs(title = paste0(dat_raw()$meta$firstname, "'s Weight"),
                 subtitle = "Measured (red) and predicted (blue) weight", x = "Age (days)", y = "Weight (g)") +
            scale_y_continuous(labels = function(x) format(x, big.mark = ",", scientific = FALSE)) +
            theme(legend.position = "none")
        
    })
    
    output$plot_change <- renderUI({
        
        tagList(
            plotOutput("plot2", height = 300),
            radioButtons("dat_type", "Change scale:",
                         c("7-Day Mean Change" = "amt_weekly_change",
                           "Raw Change" = "weight_change"))
        )
        
    })
    
    output$tab_weights <- renderDataTable({
        
        a <- dat_raw()$meta %>%
            select(dob, birth_weight) %>%
            rename("weight_date" = "dob",
                   "weight" = "birth_weight")
        
        o <- select(dat(), weight_date, weight) %>%
            bind_rows(a) %>%
            arrange(desc(weight_date)) %>%
            mutate(across("weight_date", ~ . + seconds(1)),
                   across("weight_date", format, "%Y-%m-%d")) %>%
            setNames(c("Date", "Weight (g)"))
        
        datatable(o, options = list(lengthMenu = c(5, 30, 50), pageLength = 5))
        
    })
    
    output$plot2 <- renderPlot({
        
        req(dat())
        
        d <- dat() %>%
            select(weight_date, amt_age_days, weight) %>%
            mutate(weight_change = weight - lag(weight, 1),
                   amt_days_between = amt_age_days - lag(amt_age_days, 1),
                   amt_weekly_change = 7 * weight_change / amt_days_between) %>%
            na.omit()
        
        if (input$dat_type == "amt_weekly_change") {
            fun_weight_change(d, amt_weekly_change, "7-Day Mean Weight Change")
        } else {
            fun_weight_change(d, weight_change, "Weight Change")
        }
        
    })
}
