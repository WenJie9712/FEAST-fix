# Internal helper: build the fill scale used by all FEAST plots.
# palette = NULL              -> ggthemes economist palette (default)
# palette = "Set2" (length 1)-> any RColorBrewer palette name
# palette = c("#a6cee3", ...) -> user supplied colours (needs >= n sources)
FEAST_fill_scale <- function(palette = NULL){

  if(is.null(palette))
    return(scale_fill_economist())

  # a single string without "#" is treated as an RColorBrewer palette name
  if(length(palette) == 1 && !grepl("^#", palette))
    return(scale_fill_brewer(palette = palette))

  scale_fill_manual(values = palette)
}

#' Plot source contribution per sink
#'
#' Draw the source composition of a single sink sample, either as a stacked
#' barplot (default) or as a pie chart.
#'
#' @param SourceNames A vector with the names of the sources of this sink.
#' @param source_contribution A vector with the sources' contributions (summing to 1).
#' @param sink_name Name of the sink sample, used as axis label / pie title.
#' @param dir_path A path to an output .png file.
#' @param save_plot 1 to save the plot, 0 to only return the ggplot object.
#' @param plot_type "bar" for a stacked barplot, "pie" for a pie chart.
#' @param palette Colours used to fill the sources. NULL (default) uses the
#' ggthemes economist palette, a single string (e.g. "Set2") uses the matching
#' RColorBrewer palette, a character vector of colours is used as is.
#' @export
PlotPerSinkSourceContribution  <- function(SourceNames, source_contribution,
                                           sink_name = "Example", dir_path, save_plot,
                                           plot_type = c("bar", "pie"),
                                           palette = NULL){

  plot_type <- match.arg(plot_type)
  fill_scale <- FEAST_fill_scale(palette)

  FEAST_per_sink <- data.frame(c(SourceNames),round(source_contribution*100,1))
  names(FEAST_per_sink) <- c("Source","Proportion")
  rownames(FEAST_per_sink) <- c(1:dim(FEAST_per_sink)[1])


  FEAST_per_sink$label <- FEAST_per_sink$Proportion
  FEAST_per_sink$label[FEAST_per_sink$label < 1] <- NA

  FEAST_per_sink <- FEAST_per_sink %>%
    mutate(Sink = sink_name)

  if(plot_type == "pie"){

    FEAST_per_sink$Source <- factor(FEAST_per_sink$Source,
                                    levels = unique(FEAST_per_sink$Source))

    my_plot <- ggplot(FEAST_per_sink, aes(x = "", y = Proportion, fill = Source)) +
      geom_col(width = 1, colour = "white") +
      geom_text(aes(label = label),
                position = position_stack(vjust = 0.5), color = "white", size = 3) +
      coord_polar(theta = "y") +
      fill_scale +
      labs(fill = "Sources", x = NULL, y = NULL, title = sink_name) +
      theme_void(base_size = 9) +
      theme(legend.position = "right",
            legend.title = element_text(color = "black", size = 9),
            legend.text = element_text(size = 9),
            plot.title = element_text(size = 10, hjust = 0.5))

  } else {

    my_plot <-ggplot(FEAST_per_sink, aes(x = Sink, y = Proportion, fill = Source)) +
      geom_col() +
      geom_text(aes(label = label),
                position = position_stack(vjust = 0.5), color = "white") +
      theme_economist(base_size = 9) +
      fill_scale +
      labs(fill = "Sources") +
      theme(legend.position = "right",
            legend.title = element_text(color = "black", size = 9)) +
      theme(axis.title.y = element_text(margin = margin(r = 12)), legend.text=element_text(size=9)) +
      ylab("Source proportions") +
      xlab(NULL)
  }

  #save
  if(save_plot == 1){

    setwd(dir_path)
    ggsave(filename=paste0(sink_name, if(plot_type == "pie") "_pie" else "", "_FEAST.png"),
           plot = my_plot ,
           dpi = 600, width = 6.1, height = 6.1, units = "in")
  }


  return(my_plot)


}

#' PlotMultipleSinks with different sources - use this plotting option to plot multiple sinks
#' each with a different set of sources.
#' @export
PlotMultipleSinks<- function(Filename,figures, dir_path){

  comb_plot <- do.call(grid.arrange,figures)
  setwd(dir_path)
  ggsave(filename=paste0(Filename ,"_FEAST.png"), plot = comb_plot ,
         dpi = 600, width = 9.75, height = 6.1, units = "in")

}

#' PlotSourceContribution
#'
#' Save a stacked barplot of source contributions to a group of pre-defined sink samples,
#' sharing the same sources.
#'
#' @param SinkNames A vector with the sink names to plot.
#' @param SourceNames A vector with all the sources' names.
#' @param Same_sources_flag  A boolian value indicating the source-sink plotting assignment.
#' Same_sources_flag = 1 if the same sources are assigned to the pre-defined sink samples , otherwise = 0.
#' @param mixing_proportions A list of vectors, where entry i corresponds to the vector of source
#' contributions (summing to 1) to sink i.
#' @param dir_path A path to an output .png file.
#' @param Plot_title Plot's title and output .png file's name.
#' @param N Number of plots in each output .png file.
#' @param plot_type "bar" for stacked barplots (default), "pie" for pie charts.
#' @param palette Colours used to fill the sources. NULL (default) uses the
#' ggthemes economist palette, a single string (e.g. "Set2") uses the matching
#' RColorBrewer palette, a character vector of colours is used as is.
#'
#'
#' @examples
#' \donttest{
#'
#' #Load metadata table
#'
#' #Load count matrix
#'
#' #Calculate the sources' contributions to
#' #each sink sample in the data
#'FEAST_output <- FEAST(count_matrix = otus, metadata = metadata,
#'                      different_sources_flag = 1)
#'
#' #Plot and save a stacked barplot of source contributions
#' #to the first four sink samples
#'PlotSourceContribution(SinkNames, SourceNames, Same_sources_flag,
#'                       mixing_proportions, dir_path, Plot_title = "Example",N)
#'
#' }
#'
#' @export
PlotSourceContribution <- function(SinkNames,
                                   SourceNames,
                                   Same_sources_flag,
                                   mixing_proportions,
                                   dir_path,
                                   Plot_title = "Example",
                                   N,
                                   plot_type = c("bar", "pie"),
                                   palette = NULL){

  plot_type <- match.arg(plot_type)
  fill_scale <- FEAST_fill_scale(palette)

  if(Same_sources_flag == 1){

    #remove NA's
    mixing_proportions[is.na(mixing_proportions)] <- 999

    my_sinks <- Plot_title
    my_sink_frame <- mixing_proportions[which(rownames(mixing_proportions) %in% SinkNames),]
    my_sink_frame <- data.frame(my_sink_frame)
    my_sink_frame <- t(my_sink_frame)

    for(j in 1:dim(my_sink_frame)[1]){

      rownames(my_sink_frame)[j] <- SourceNames[j]
      if(j == dim(my_sink_frame)[1])
        rownames(my_sink_frame)[j] <- "Unknown"
    }
    my_melt <- melt(my_sink_frame)
    my_melt$value[my_melt$value == 999] <- NA
    my_melt$Var2 <- as.factor(my_melt$Var2)


    if(plot_type == "pie"){

      #one pie per sink, all sinks sharing the same sources
      my_plot <- ggplot(my_melt, aes(x = "", y = value, fill = Var1)) +
        geom_col(width = 1, colour = "white") +
        coord_polar(theta = "y") +
        facet_wrap(~ Var2) +
        fill_scale +
        guides(fill=guide_legend(title="Source")) +
        labs(x = NULL, y = NULL) +
        theme_void() +
        theme(legend.position = "right",
              strip.text = element_text(size = 8),
              plot.title = element_text(hjust = 0.5)) +
        ggtitle(my_sinks)

    } else {

      my_plot <- ggplot(my_melt, aes(x=Var2,y=value,group=Var2,fill=Var1)) +
        geom_bar(stat="identity") +
        fill_scale +
        guides(fill=guide_legend(title="Source")) +
        xlab("") + theme_bw() +
        ylab("Source proportions") +
        theme(plot.title = element_text(hjust=1),
              axis.text.x = element_text(angle = 90, hjust = 1, size=8)) +
        ggtitle(my_sinks)
    }

    setwd(dir_path)
    ggsave(filename=paste0(my_sinks, if(plot_type == "pie") "_pie" else "", "_FEAST.png"), plot = my_plot ,
           dpi = 600, width = 8.75, height = 6.1, units = "in")

  }

  if(Same_sources_flag == 0){

    if(N > length(SinkNames))
        N = length(SinkNames)

    mixing_proportions <- mixing_proportions[which(rownames(mixing_proportions) %in% SinkNames),]



    j <- 1
    k <- 1
    while(j <= dim(mixing_proportions)[1]){

      Sink_plot_list <- list()

      for(i in 1:N){

        if(length( na.omit(colnames(mixing_proportions)[!is.na(mixing_proportions[(j+i-1),])] > 0)) & (j+i-1) <= dim(mixing_proportions)[1])
          Sink_plot_list[[i]] =   PlotPerSinkSourceContribution(SourceNames = colnames(mixing_proportions)[!is.na(mixing_proportions[(j+i-1),])],
                                                                source_contribution = mixing_proportions[(j+i-1),][!is.na(mixing_proportions[(j+i-1),])],
                                                                sink_name = SinkNames[(j+i-1)], save_plot = 0, dir_path = dir_path,
                                                                plot_type = plot_type, palette = palette)

      }

      figures <- Sink_plot_list
      PlotMultipleSinks(figures = figures, dir_path = dir_path,
                        Filename = paste0(Plot_title, if(plot_type == "pie") "_pie" else "", k))
      k <- k+1
      j <- j+N

    }



  }

}


