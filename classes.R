
library("tictoc")

# limits
setClass (Class="Limits", slots=c(channel="character", min="numeric", max="numeric"))

# creation function
mkLimits <- function(channel, vs)
{
  minvs <- min (vs)
  maxvs <- max (vs)
  return(new("Limits", channel=channel, min=minvs, max=maxvs))
}

limitsC <- function(l)
{
  return (c(l@min,l@max))
}



# a data object, including its limits
setClass (Class="FlowDataObject", slots=c(flowFrame="flowFrame", data="matrix", xChannel="character", yChannel="character", x="Limits", y="Limits"))
mkFlowDataObject <- function(frame, xChannel, yChannel)
{
  data <- exprs(frame)
  xs <- data[,xChannel]
  ys <- data[,yChannel]
  return(new("FlowDataObject", flowFrame=frame, data=data, xChannel=xChannel, yChannel=yChannel
             , x=mkLimits(channel=xChannel,xs), y=mkLimits(channel=yChannel,ys)))
}



# input parameters, as a class
validFlowData <- function(object)
{
  #TODO we should check certain things
  TRUE
}
setClass (Class="FlowData", slots=c(data="FlowDataObject", sampled="matrix", fraction="numeric"), validity=validFlowData)

# create flow data object, including correct subsampling, etc
# fraction is the subsampling parameter, 0 < fraction <= 1
# note that the "sampled" structure retains only two dimensions

# TODO move denoised in own function, used by mkFlowDataObject

mkFractionedFlowData <- function(fdo, fraction=1.0, xMin, xMax, yMin, yMax)
{
  tic(msg="mkFractionedFlowData")
  # prepare subset extraction without border machine noise
  border <- list(c(xMin,xMax+fdo@x@min), c(yMin,yMax+fdo@y@min)) # define subset area
  names(border) <- c(fdo@xChannel, fdo@yChannel)
  denoised <- rectangleGate(filterId="Noise",  .gate = border) # filter noise
  denoised.subset <- Subset(fdo@flowFrame, denoised)
  denoisedData<-mkFlowDataObject(frame=denoised.subset, xChannel=fdo@xChannel, yChannel=fdo@yChannel)
  # subsample every nth element
  vs<-cbind(denoisedData@data[,fdo@xChannel],denoisedData@data[,fdo@yChannel]) #both dimensions as matrix
  subsampled<-vs[sample(nrow(vs),size=nrow(vs) * fraction,replace=FALSE),]
  colnames(subsampled) <- list(fdo@xChannel, fdo@yChannel)
  toc()

  return (new("FlowData"
              , data=denoisedData
              , sampled=subsampled
              , fraction=fraction
              ))
}



# a single run of the EM algorithm with a given number of clusters
setClass (Class="EMRun", slots=c(mu="matrix", sigma="list", weight="matrix", clusterProbs="numeric", logL="numeric"
                                 ))
mkEMRun <- function ()
{
  return (new("EMRun"
              , mu=matrix()
              , sigma=list()
              , weight=matrix()
              , clusterProbs=0
              , logL=Inf
              ))
}



# include the newest mu, sigma, logL values in the EMRun
updateEMRun <- function (em, mu, sigma, weight, clusterProbs, logL)
{
#  n <- 1 + length (em@mu)
#  # store old data
#  em@mus[n] <- mu
#  em@sigmas[n] <- sigma
#  em@weights[n] <- w
#  em@logLs[n] <- logL
  # setup new
  em@mu <- mu
  em@sigma <- sigma
  em@weight <- weight
  em@clusterProbs <- clusterProbs
  em@logL <- logL
  return (em)
}
