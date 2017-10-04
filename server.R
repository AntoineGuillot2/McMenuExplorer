require(shiny)
require(data.table)
require(DT)
require(D3partitionR)
require(magrittr)
require(shinyWidgets)
require(ggplot2)
require(stringr)


dataMc=fread('data/menu.csv')

shinyServer(function(input,output,session)
{
  vals<-reactiveValues(switch_origin_cal=F)
  ###First tab, menu selection
  output$dish_type_selection<-renderUI(
    selectizeInput('dish_type_selection','Select dish type',c('All',unique(dataMc[['Category']])),multiple=T,selected='All')
  )
  output$dish_selection<-renderUI(
    selectizeInput('dish_selection','Add a dish',split(dataMc[Category%in%input$dish_type_selection | input$dish_type_selection=='All']$Item,dataMc[Category%in%input$dish_type_selection | input$dish_type_selection=='All',Category]),
                   multiple=T,selected=dataMc[Category%in%input$dish_type_selection | input$dish_type_selection=='All']$Item[sample(1:260,5)])
  )
  output$selected_items<-renderDataTable(
    {
      dataMc[Item%in%input$dish_selection,colnames(dataMc)[which(!colnames(dataMc)%like%'Daily Value')],with=F]
    },options=list(scrollX=T,dom='t'),rownames= FALSE
    
  )
  
  observeEvent(input$switch_origin_cal,{vals$switch_origin_cal=!vals$switch_origin_cal})
  
  ##Second tab, explore calories
  output$viz_calories<-renderD3partitionR({
    ##dataframe in large format
    DT=melt(dataMc[Item%in%input$dish_selection],id.vars = input$variables_to_show_cal,measure.vars = c('Total Fat','Carbohydrates','Dietary Fiber','Protein'),variable.name = 'Origin',value.name = 'Cal')
    ##Computing the calories value from the weight of each nutrients
    DT[Origin=='Total Fat',Cal:=Cal*9]
    DT[Origin=='Carbohydrates',Cal:=Cal*4]
    DT[Origin=='Protein',Cal:=Cal*4]
    DT[Origin=='Dietary Fiber',Cal:=Cal*2]
    ##Implementing the possibility to swicth the nutrients and the categories
    if (vals$switch_origin_cal)
    {
      current_steps=c('Origin',input$variables_to_show_cal)
    }
    else
    {
      current_steps=c(input$variables_to_show_cal,'Origin')
    }
    ##Aggreagting the datatable by path
    DT=DT[,.(Cal=sum(Cal)),by=c(input$variables_to_show_cal,'Origin')]
    ##Plot
    D3partitionR()%>%add_data(DT,steps = current_steps,count = 'Cal',tooltip=c('name','Cal'))%>%
      set_chart_type(input$chart_type_cal)%>%
      set_legend_parameters(zoom_subset=T)%>%
      set_labels_parameters(cut_off=10)%>%
      add_title(text = 'Where are the calories from ?',style = 'font-size:20px;')%>%
      set_shiny_input(input_id=c('test_shiny_1'),enabled_inputs = list(leaves = T))%>%
      plot(d3_sv)
  })
  
  ##Bar chart with the calorie value of the leaves in the partitionchart
  
  output$current_menu_cal<-renderPlot(
    {
      ##Transformig the shiny input from a list to a usable dataframe
      DT_cal<-rbindlist(lapply(input$test_shiny_1$leaves,as.data.frame))[,color:=rgb(color.r,color.g,color.b,maxColorValue = 255)]
      ##Aggregation
      DT_cal<-unique(DT_cal[,.(Cal=sum(Cal),color=unique(color)),by=c('name')])
      ##Plot
      ggplot(DT_cal,aes(x=reorder(name, Cal),y=Cal,fill=name)) +
        geom_bar(stat="identity")+coord_flip()+xlab('')+
        scale_fill_manual(values = DT_cal$color,breaks=DT_cal$name)+
        scale_x_discrete(labels = function(x) str_wrap(x, width = 20))+ 
        theme(legend.position="none")
      
    }

    )
  output$nutrient_to_show_ui<-renderUI({selectizeInput('nutrient_to_show','Nutrients',
                                                 choices=colnames(dataMc)[which(!colnames(dataMc)%like%'Daily'&!colnames(dataMc)%like%'Calories')][-c(1:3)]
                                                 ,multiple=T,selected=colnames(dataMc)[which(!colnames(dataMc)%like%'Daily'&!colnames(dataMc)%like%'Calories')][-c(1:3)][1:3])})
  
  ##Third tab, explore nutrients
  output$viz_nutrients<-renderUI({
    ##Need to initialize a lit to be able to facet the html widget
    d3_list=list()
    
    ##Iterating over the nutrients, each nutrients will be shown in a different facet.
    for (current_nutrient_to_show in input$nutrient_to_show)
    {
      ##Weight unit selection
      if (current_nutrient_to_show%in%c('Cholesterol','Sodium'))
      {
        count_variable='Milligramms'
      }
      else
      {
        count_variable='Gramms'
      }
      ###Converting to wide format
      DT=melt(dataMc[Item%in%input$dish_selection],id.vars = input$variables_to_show_nutrients,measure.vars = current_nutrient_to_show,variable.name = 'Origin',value.name ='Cal')
      ##Adding a common origin (==common root)
      current_steps=c('Origin',input$variables_to_show_nutrients)
      ##Path aggregations
      DT=DT[,.(Cal=sum(Cal)),by=c(input$variables_to_show_nutrients,'Origin')]
      setnames(DT,old='Cal',new=count_variable)
      ##Creating the D3partitionR plot
      d3_tp=D3partitionR()%>%add_data(DT,steps = current_steps,count = count_variable,tooltip=c('name',count_variable))%>%
        set_chart_type(input$chart_type_nutrients)%>%
        set_legend_parameters(visible = F)%>%
        set_labels_parameters(cut_off=25)%>%
        set_trail(visible=F)%>%
        add_title(text = paste0(current_nutrient_to_show,': ',sum(DT[[count_variable]]),' ',count_variable ),style = 'font-size:16px;')
      d3_list=c(d3_list,list(d3_tp))
      
    }
    
    ##'Facetting', each plot is rendered in a width=4 column.
    fluidPage(lapply(d3_list,function(x){
      tags$div(column(4,renderD3partitionR(plot(x))))
      }))

  })
  
  
  ##Fourth tab, explore daily value
  output$daily_value_to_show_ui<-renderUI({selectizeInput('daily_value_to_show','Daily value',
                                                       choices=colnames(dataMc)[which(colnames(dataMc)%like%'Daily')],multiple=T,selected=colnames(dataMc)[which(colnames(dataMc)%like%'Daily')][1:3])})
  
  
  
  output$viz_daily_value<-renderUI({
    ##Need to initialize a lit to be able to facet the html widget
    d3_list=list()
    
    ##Iterating over the nutrients, each nutrients will be shown in a different facet.
    for (daily_value_to_show in input$daily_value_to_show)
    {
      count_variable='%'
      ###Very similar to tab 3
      DT=melt(dataMc[Item%in%input$dish_selection],id.vars = input$variables_to_show_daily_value,measure.vars = daily_value_to_show,variable.name = 'Origin',value.name ='Cal')
      current_steps=c('Origin',input$variables_to_show_daily_value)
      DT=DT[,.(Cal=sum(Cal)),by=c(input$variables_to_show_daily_value,'Origin')]
      setnames(DT,old='Cal',new=count_variable)
      ##Creation of the D3partitionR plot
      d3_tp=D3partitionR()%>%add_data(DT,steps = current_steps,count = count_variable,tooltip=c('name',count_variable))%>%
        set_chart_type(input$chart_type_daily_value)%>%
        set_legend_parameters(visible = F)%>%
        set_labels_parameters(cut_off=25)%>%
        set_trail(visible=F)%>%
        add_title(text = paste0(daily_value_to_show,': ',sum(DT[[count_variable]]),' ',count_variable ),style = 'font-size:16px;')
      d3_list=c(d3_list,list(d3_tp))
      
    }
    ##'Facetting', each plot is rendered in a width=4 column.
    fluidPage(lapply(d3_list,function(x){
      tags$div(column(4,renderD3partitionR(plot(x))))
    }))
    
  })
  
})