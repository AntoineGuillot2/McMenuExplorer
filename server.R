require(shiny)
require(data.table)
require(DT)
require(D3partitionR)
require(magrittr)
require(shinyWidgets)

dataMc=fread('data/menu.csv')

shinyServer(function(input,output,session)
{
  vals<-reactiveValues(switch_origin_cal=F)
  ###First tab, menu selection
  output$dish_type_selection<-renderUI(
    selectizeInput('dish_type_selection','Select dish type',c('All',unique(dataMc[['Category']])),multiple=T,selected='All')
  )
  output$dish_selection<-renderUI(
    selectizeInput('dish_selection','Add a dish',split(dataMc[Category%in%input$dish_type_selection | input$dish_type_selection=='All']$Item,dataMc[Category%in%input$dish_type_selection | input$dish_type_selection=='All',Category]),multiple=T)
  )
  output$selected_items<-renderDataTable(
    {
      dataMc[Item%in%input$dish_selection,colnames(dataMc)[which(!colnames(dataMc)%like%'Daily Value')],with=F]
    },options=list(scrollX=T,dom='t'),rownames= FALSE
    
  )
  
  observeEvent(input$switch_origin_cal,{vals$switch_origin_cal=!vals$switch_origin_cal})
  
  ##Second tab, explore calories
  output$viz_calories<-renderD3partitionR({
    DT=melt(dataMc[Item%in%input$dish_selection],id.vars = input$variables_to_show_cal,measure.vars = c('Total Fat','Carbohydrates','Dietary Fiber','Protein'),variable.name = 'Origin',value.name = 'Cal')
    DT[Origin=='Total Fat',Cal:=Cal*9]
    DT[Origin=='Carbohydrates',Cal:=Cal*4]
    DT[Origin=='Protein',Cal:=Cal*4]
    DT[Origin=='Dietary Fiber',Cal:=Cal*2]
    if (vals$switch_origin_cal)
    {
      current_steps=c('Origin',input$variables_to_show_cal)
    }
    else
    {
      current_steps=c(input$variables_to_show_cal,'Origin')
    }
    DT=DT[,.(Cal=sum(Cal)),by=c(input$variables_to_show_cal,'Origin')]
    D3partitionR()%>%add_data(DT,steps = current_steps,count = 'Cal',tooltip=c('name','Cal'))%>%
      set_chart_type(input$chart_type_cal)%>%
      set_legend_parameters(zoom_subset=T)%>%
      set_labels_parameters(cut_off=10)%>%
      add_title(text = 'Where are the calories from ?',style = 'font-size:20px;')%>%
      plot()
  })
  
  output$current_menu_cal<-renderUI(
    fluidPage(
      hr(),
      h4(strong('Selected Items:'),align='center'),
      
    
    lapply(dataMc[Item%in%input$dish_selection,Item],tags$li))
    )
  
  
  ##Third tab, explore nutrients
  output$viz_nutrients<-renderUI({

    
    if (input$variables_to_show_nutrients[1]%like%'% Daily')
    {
      count_variable='% Daily Value'
    }
    else
    {
      count_variable='Grammes'
    }
    DT=melt(dataMc[Item%in%input$dish_selection],id.vars = input$variables_to_show_nutrients,measure.vars = input$nutrient_to_show,variable.name = 'Origin',value.name ='Cal')
    current_steps=c('Origin',input$variables_to_show_nutrients)
    DT=DT[,.(Cal=sum(Cal)),by=c(input$variables_to_show_nutrients,'Origin')]
    setnames(DT,old='Cal',new=count_variable)
    d3_tp=D3partitionR()%>%add_data(DT,steps = current_steps,count = count_variable,tooltip=c('name',count_variable))%>%
      set_chart_type(input$chart_type_nutrients)%>%
      set_legend_parameters(zoom_subset=T)%>%
      set_labels_parameters(cut_off=10)%>%
      add_title(text = 'Where are the nutrients from ?',style = 'font-size:20px;')
    fluidPage(renderD3partitionR({plot(d3_tp)}))
  })
  
})