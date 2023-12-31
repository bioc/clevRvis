dolphinPlot <- function(seaObject, shape = 'spline', borderCol = NULL,
                        pos='center', vlines=NULL, vlineCol="#6E6E66",
                        vlab=NULL, vlabSize = 3,
                        separateIndependentClones = FALSE,
                        showLegend = FALSE, markMeasuredTimepoints = NULL,
                        main = NULL, mainPos = 'middle', mainSize = 5,
                        xlab = NULL, ylab = NULL, pad.left = 0.005,
                        annotations = NULL, annotSize = 3){
    if(is(seaObject, "seaObject") == FALSE){
        stop('No seaObject provided as input.')
    }
    if(!is.null(borderCol) && is.null(.isColor(borderCol))){
        stop("No valid input for borderCol provided.")
    }
    if(!is.null(vlines) && !is.numeric(vlines)){
        stop("No valid input for vlines provided.")
    }
    if(is.null(.isColor(vlineCol))){
        stop("No valid input for vlineCol provided.")
    }
    if(!is.null(vlab) && !is.character(vlab) && !is.numeric(vlab)){
        stop("No valid input for vlab provided.")
    }
    if(!is.numeric(vlabSize)){
        stop("No valid input for vlabSize provided.")
    }
    if(separateIndependentClones != TRUE && separateIndependentClones != FALSE){
        stop("No valid input for separateIndependentClones provided.")
    }
    if(showLegend != TRUE && showLegend != FALSE){
        stop("No valid input for showLegend provided.")
    }
    if(!is.null(markMeasuredTimepoints) && !is.numeric(markMeasuredTimepoints)){
        stop("No valid input for markMeasuredTimepoints provided.")
    }
    if(!is.null(main) && !is.character(main)){
        stop("No valid input for main provided.")
    }
    if(!is.numeric(mainSize)){
        stop("No valid input for mainSize provided.")
    }
    if(!is.null(xlab) && !is.character(xlab)){
        stop("No valid input for xlab provided.")
    }
    if(!is.null(ylab) && !is.character(ylab)){
        stop("No valid input for ylab provided.")
    }
    if(!is.null(pad.left) && !is.numeric(pad.left)){
        stop("No valid input for pad.left provided.")
    }
    if(!is.null(annotations) && !is.data.frame(annotations)){
        stop("No valid input for annotations provided.")
    }
    if(!is.numeric(annotSize)){
        stop("No valid input for annotSize provided.")
    }
    if(nrow(fracTable(seaObject)) != length(parents(seaObject))){
        stop("Number of clones defined in the fractable does not match number
            of clones defined in parents (", nrow(fracTable(seaObject)), " vs ",
            length(parents(seaObject)), ").")
    }
    if(ncol(fracTable(seaObject)) != length(timepoints(seaObject))){
        stop("Number of time points defined in the fractable does not match 
            number of time points defined in timepoints (", 
            ncol(fracTable(seaObject)), " vs ", length(timepoints(seaObject)), 
            ").")
    }
    
    x<-NULL
    y<-NULL
    name<-NULL
    ymin<-NULL
    ymax<-NULL
    tp<-NULL
    lab<-NULL

    ##get x and y values
    if (pos == 'center'){
        seaObject <- .layoutSeaObjectClones(seaObject,
                        separateIndependentClones = separateIndependentClones)
    } else if(pos== 'bottom'){
        seaObject <- .bottomLayout(seaObject,
                        separateIndependentClones = separateIndependentClones)
    } else if (pos == 'top'){
        seaObject <-.topLayout(seaObject,
                        separateIndependentClones = separateIndependentClones)
    } else{
        stop('Position (pos) must be either "center" or "bottom".',
                    pos,'is not a valid position.')
    }


    if (shape == 'polygon'){
        coordsTbl <- .getCoordsTable(seaObject)

    }else{
        if(shape == 'spline'){
            coordsTbl <- .getSmoothCoordsTbl(seaObject=seaObject,
                                            pad.left=pad.left)
        } else{
            stop('Shape must be wither "spline" or "polygon"')
        }
    }

    if(!is.null(borderCol)){
        dolphPlot <- ggplot(coordsTbl, aes(x = x, y = y)) +
            geom_polygon_interactive(aes(fill = name, group = name,
                                        tooltip = name, data_id = name),
                                    show.legend = showLegend,
                                    color = borderCol, size = 0.25
            )
    }else{
        dolphPlot <- ggplot(coordsTbl, aes(x = x, y = y)) +
            geom_polygon_interactive(aes(fill = name, group = name,
                                        tooltip = name, data_id = name),
                                    show.legend = showLegend
            )
    }

    dolphPlot <- dolphPlot +
        scale_fill_manual(values = seaObject@col, name = "Clone labels") +
        theme_void() + theme(legend.position = "left")


    if(!is.null(vlines)){
        vlinesData <- data.frame(vlines = vlines, ymin = rep(0,length(vlines)),
                                ymax = rep(100,length(vlines)))

        dolphPlot <- dolphPlot + geom_segment(mapping = aes(x = vlines,
                                                            xend=vlines,
                                                            y = ymin,
                                                            yend = ymax),
                                            data = vlinesData,
                                            color = vlineCol,
                                            show.legend = FALSE)

        if(!is.null(vlab)){
            vlinesData <- vlinesData %>% add_column(vlab = vlab)
            dolphPlot <- dolphPlot + geom_text(mapping = aes(x = vlines,
                                                            y = 100,
                                                            label = vlab,
                                                            vjust = -1),
                                            size = vlabSize,
                                            data = vlinesData) +
                expand_limits(y=100+vlabSize)
        }
    }

    if(!is.null(markMeasuredTimepoints)){
        measuredTpData <- data.frame(tp = markMeasuredTimepoints,
                                    y = rep(-2,
                                            length(markMeasuredTimepoints)))
        dolphPlot <- dolphPlot + geom_point(mapping = aes(x = tp, y = y),
                                            data = measuredTpData,
                                            shape = 'triangle',
                                            size = 2)
    }

    if(!is.null(main)){
        if(mainPos == 'middle'){
            mainCoords <- (min(seaObject@timepoints) +
                            max(seaObject@timepoints))/2
        } else{
            if(mainPos == 'left'){
                mainCoords <- min(seaObject@timepoints)

            }else{
                if(mainPos == 'right'){
                    mainCoords <- max(seaObject@timepoints)
                }else{
                    stop('main position (mainPos) must be "left",
                        "middle", or "right"')
                }
            }
        }

        mainY <- mainSize*2 + 100

        if(mainY < 110 & !is.null(vlab)){
            mainY <- 110
        }

        mainLabel <- data.frame(lab = main, x = mainCoords, y = mainY)

        dolphPlot <- dolphPlot + geom_text(mapping = aes(x = x, y = y,
                                                        label = lab),
                                                        size = mainSize,
                                                        data = mainLabel)
    }

    if(!is.null(xlab)){

        axisLabelX <- data.frame(lab = xlab,
                                x = ((min(seaObject@timepoints) +
                                max(seaObject@timepoints))/2),
                                y = -6)

        dolphPlot <- dolphPlot + geom_text(mapping = aes(x = x, y = y,
                                                        label = lab),
                                            data = axisLabelX)
    }

    if(!is.null(ylab)){
        pad <- max(coordsTbl$x)-min(coordsTbl$x)
        axisLabelY <- data.frame(lab = ylab, x = min(coordsTbl$x) - pad*0.18,
                                y = 50)
        yLine <- data.frame(x = min(coordsTbl$x) - pad*0.05, ymin = 0,
                            ymax =100)
        percentages <- data.frame(lab = '100%', x = min(coordsTbl$x) - pad*0.08,
                                y = 50)

        dolphPlot <- dolphPlot +
            geom_text(mapping = aes(x = x,y = y,label = lab,angle = 90),
                    data = axisLabelY) +
            geom_segment(mapping = aes(x = x, xend=x, y = ymin, yend = ymax),
                        data = yLine, color = 'black',
                        show.legend = FALSE, size = 0.2) +
            geom_text(mapping = aes(x = x, y = y, label = lab, angle = 90),
                    data = percentages, size=3)

    }

    ##Annotations
    if(!is.null(annotations)){
        if(sum(annotations$col %in% c('black','Black')) == 0){
            colorsScale <- 'white'
        } else {
            colorsScale <- c('black','white')
        }
        dolphPlot <- dolphPlot + geom_text(mapping = aes(x = x, y = y,
                                                        label = lab,
                                                        color = col),
                                        size = annotSize,
                                        data = annotations) +
            guides(color = 'none') +
            scale_color_discrete(type = colorsScale)
    }


    return(dolphPlot)
}

