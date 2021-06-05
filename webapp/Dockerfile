FROM rocker/shiny-verse:4.0.4

MAINTAINER Paul Stevenson "pstevenson6@gmail.com"

RUN apt-get update && apt-get install libcurl4-openssl-dev libnode-dev -y
RUN mkdir -p /var/lib/shiny-server/bookmarks/shiny

# Download and install library
RUN R -e "install.packages(c('lubridate', 'shinydashboard', 'shinyjs', 'V8', 'childsds', 'DT', 'jsonlite', 'httr', 'glue', 'config', 'scales'))"

# copy the app to the image
COPY webapp/shinyapps /root/app
COPY config.yml /root/app
COPY webapp/Rprofile.site /usr/local/lib/R/etc/Rprofile.site

# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN chmod -R 755 /root/app
RUN chmod -R 755 /usr/local/lib/R/etc

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/app')"]
