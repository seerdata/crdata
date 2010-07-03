library("R2HTML")

target <- HTMLInitFile(getwd(), filename="index")
HTML("<br>Don't forget to use the CSS file in order to benefit from fixed-width font", file=target)
tmp <- as.data.frame(matrix(rnorm(100),ncol=10))
summary(tmp)
HTML(tmp,file=target)
graph1="graph1.png"
png(file.path(getwd(),graph1))
plot(tmp)
dev.off()

# Insert graph to the HTML output
HTMLInsertGraph(graph1,file=target,caption="Sample discrete distribution plot")

HTMLEndFile()

#tmp <- as.data.frame(matrix(rnorm(100),ncol=10))
#summary(tmp)
#plot(tmp)
