require(shiny)
require(shinydashboard)
require(data.table)
require(D3partitionR)
require(shinyWidgets)
require(DT)

###Building UI
navbarPage(
  title='McExplorer',
  ##Menu Selecton tab: Where thenuser selects which items will be shown in next tabs
  tabPanel("Menu selection",
           column(3,
                  uiOutput('dish_type_selection')),
           column(5,
                  uiOutput('dish_selection')),
           column(12,dataTableOutput('selected_items'))
           ),
  ##Calories exlorer tab: explore number of calories
  tabPanel("Calories explorer",
           column(3,
                  h4(strong('Chart options and info'),align='center'),
                  column(4,circleButton('switch_origin_cal',icon=icon('level-up'),status ='primary')),
                  column(4,dropdownButton(label = 'Plot options',
                    awesomeCheckboxGroup('variables_to_show_cal',label = 'Show',choices = c('Category','Item'),selected =  c('Category','Item')),
                    awesomeRadio('chart_type_cal', 'Chart type', c('sunburst','circle_treemap','treemap','icicle','partition_chart'),selected = 'treemap'),
                  icon=icon('gear'),status='primary')),
                  column(4,circleButton('help_cal',icon=icon('question-circle'),status ='primary')),
                  ###Bar chart showing the calories in the leaf of the partition chart
                  column(12,hr(),plotOutput('current_menu_cal'))
                  ),
                  
           column(9,D3partitionROutput('viz_calories',height=500))),
  ##Nutrients explorer tab
  tabPanel("Nutrients explorer",
           column(3,
                  h4(strong('Chart options and info'),align='center'),
                  column(4,offset=2,dropdownButton(label = 'Plot options',
                                          awesomeCheckboxGroup('variables_to_show_nutrients',label = 'Show',choices = c('Category','Item'),selected =  c('Category','Item')),
                                          awesomeRadio('chart_type_nutrients', 'Chart type', c('sunburst','circle_treemap','treemap','icicle','partition_chart'),selected = 'treemap'),
                                          icon=icon('gear'),status='primary')),
                  column(4,circleButton('help_nutrients',icon=icon('question-circle'),status ='primary')),

                  column(12,
                         br(),
                         hr(),
                         uiOutput('nutrient_to_show_ui'))
           ),
           
           column(9,uiOutput('viz_nutrients'))),
  ##Daily value explorer tab
  tabPanel("Daily value explorer",
           column(3,
                  h4(strong('Chart options and info'),align='center'),
                  column(4,offset=2,dropdownButton(label = 'Plot options',
                                          awesomeCheckboxGroup('variables_to_show_daily_value',label = 'Show',choices = c('Category','Item'),selected =  c('Category','Item')),
                                          awesomeRadio('chart_type_daily_value', 'Chart type', c('sunburst','circle_treemap','treemap','icicle','partition_chart'),selected = 'treemap'),
                                          icon=icon('gear'),status='primary')),
                  column(4,circleButton('help_daily_value',icon=icon('question-circle'),status ='primary')),
                  column(12,br(),
                         hr(),
                         uiOutput('daily_value_to_show_ui'))
           ),
           
           column(9,uiOutput('viz_daily_value')))
  
  
)