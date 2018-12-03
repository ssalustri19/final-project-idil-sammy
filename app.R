library(shiny)
library(readr)
library(DT)
library(twitteR)
library(dplyr)
library(lubridate)
library(tidytext)
library(tm)

politicians<-read_csv('https://raw.githubusercontent.com/ssalustri19/final-project-idil-sammy/master/politicians.csv')

setup_twitter_oauth(consumer_key ,consumer_secret,access_token ,access_secret)

ui<- fluidPage(
  titlePanel("Analyzing Politicans' Word Usage in Tweets"),
  sidebarLayout(
    sidebarPanel(
      selectInput(inputId = "politician",
                  label="Choose a politician",
                  choices= politicians$twitter_handle,
                  selectize = TRUE),
      numericInput(inputId = "numtweets",
                   label="Select number of most recent tweets to analyze. Max=3200",
                   value=100,
                   min=1,
                   max=3199,
                   step=100),
      actionButton(inputId="goButton",
                   label="Run Analysis")
  
    ),
    mainPanel(
      tabsetPanel(tabPanel("Raw Tweets Data Frame", DT::dataTableOutput(outputId = "tweetstable")),
                  tabPanel("Word Frequency Table", DT::dataTableOutput(outputId = "freqtable")),
                  tabPanel("Word Cloud", plotOutput(outputId="cloud"))
      )
              
    )
  )
)

  
  
  
  


server<- function(input,output){

  
  tweets_from_selected_politician<-eventReactive(input$goButton,
                                                 {userTimeline(input$politician, n = input$numtweets, includeRts = FALSE)%>%
                                                  twListToDF() %>% 
                                                  mutate(date=lubridate::date(created)) %>% 
                                                  select(text, date)
                                                  })
  
  output$freqtable <- DT::renderDataTable({
    raw<-tm::termFreq(tweets_from_selected_politician()$text, control = list(removePunctuation = TRUE, tolower = TRUE, stopwords = TRUE)) 
    df <- as.data.frame(melt(as.matrix(raw), varnames = c("word", "some"))) %>% select(-some)
    df$word <- as.character(df$word)
    df2<- df %>% arrange(desc(value)) 
    DT::datatable(data = df2, 
                options = list(pageLength = 10), 
                rownames = FALSE)
  })
    


  
  output$tweetstable<-DT::renderDataTable({
    DT::datatable(data = tweets_from_selected_politician(), 
                  options = list(pageLength = 10), 
                  rownames = FALSE)
  })
}
  
  


shinyApp(ui=ui, server=server)