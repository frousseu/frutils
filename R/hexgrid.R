
hexgrid<-function(
	
	x,
	width=NULL,
	n=NULL,
	buffer=NULL,
	convex=TRUE,
	seed=1
	
){
	
	if(is.null(width) && is.null(n)){
		stop("One of \"width\" or \"n\" has to be provided")
	}
	if(!is.null(width) && !is.null(n)){
		warning("Only \"width\" will be used")
	}
	prjini<-NULL
	if(!is.projected(x)){
		prjini<-proj4string(x)
		prj<-paste0("+proj=laea +lat_0=",mean(coordinates(x)[,2])," +lon_0=",mean(coordinates(x)[,2]))
		
		x<-spTransform(x,CRS(prj))
	}
	
	if(convex){
	  region<-gConvexHull(x)
	}else{
	  region<-FRutils:::bbox2pol(x) # gConvexHull is too slow
	}
	
	if(!is.null(buffer)){
		region<-gBuffer(region,width=buffer)
	}
 b<-bbox(region)
 if(!is.null(width)){
   s<-width
 }else{
 	 s<-round(abs(b[1,2]-b[1,1])/n,0)
 }
 g<-GridTopology(c(b[1,1]-(1*s),b[2,1]-(1*s)),c(s,s),c(ceiling((b[1,2]-b[1,1])/s)+2,ceiling((b[2,2] -b[2,1])/s)+2)) # les +1 et +2 c'est pour s,assurer de couvrir tous les points de données
 g<-SpatialGrid(g)
 grid<-g
 grid<-as(grid,"SpatialPolygons")
 set.seed(seed)
 grid2<-spsample(grid,type="hexagonal",cellsize=s)
 grid<-HexPoints2SpatialPolygons(grid2)
 grid<-SpatialPolygonsDataFrame(grid,data=data.frame(id=1:length(grid)),match.ID=FALSE)
 proj4string(grid)<-CRS(proj4string(x))
 if(convex){
   o<-!is.na(over(grid,region))
 }else{
 	 o<-over(grid,x)
 	 if(!is.null(dim(o))){
 	   o<-apply(o,1,function(i){!all(is.na(i))})
 	 }else{
 	   o<-!is.na(o)	
 	 }
 }
 grid<-grid[o,]
 if(!is.null(prjini)){
   grid<-spTransform(grid,CRS(prjini))
 }
 grid<-spChFIDs(grid,as.character(seq_along(grid)))
 grid@data[,"id"]<-as.character(seq_along(grid))
 grid

}


