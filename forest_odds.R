#' Makes an ordered forest plot of adjusted odds ratios
#'
#' From the glm.output of GLM to a printed figure.
#' @param glm.output Output of multivariate logistic regression (glm, family=binomial)
#' @param labels.low, vector of strings describing reference level of all predictors
#' @param labels.high, vector of strings describing other level of all predictors
#' @param figure.filename, string for filename of saved figure; e.g., "demo.png"
#' @param width_cm [optional], width of figure in cm
#' @param height_cm [optional], height of figure in cm
#' @param myColors [optional], 2-element vector of strings for colors of figure elements that alternate across predictors
#' @param font.size.x [optional], size of numbers for odds ratio along x axis
#' @param font.size.y [optional], size of labels for predictor labels
#' @param  font.size.xlabel [optional], size of string that reads "Adjusted odds ratio"
#' @return Handle to ggplot figure
#' @export
#' @examples
#' forest_odds(glm.output, lowLab, highLab, "demo.png")

require(ggplot2)

forest_odds <- function(glm.output, labels.low, labels.high, figure.filename,
	width_cm=22, height_cm=12, myColors=c("blue","black"),
	font.size.x=14, font.size.y=12, font.size.xlabel=14) {

	# # set up
	# width_cm = 22
	# height_cm = 12
	# myColors <- c("blue","black")
	
# odds ratios (OR), confidence intervals (CI) and p-values (PV)
num_factors <- length(glm.output$coefficients)
OR <- exp(coef(glm.output)[2:num_factors])
CI <- exp(confint(glm.output))[2:num_factors,1:2]
PV <- coef(summary(glm.output))[2:num_factors,4]

# p-values to number of significance stars
# 	< 0.05 *
# 	< 0.01 **
# 	< 0.001 ***
num_stars <- as.numeric(PV < 0.05) + as.numeric(PV < 0.01) + as.numeric(PV < 0.001)

# package together for re-ordering
data <- data.frame(labels.low=labels.low, OR=OR, CIa=CI[,1], CIb=CI[,2],
	num_stars=num_stars, labels.high=labels.high)

# Flip each ratio so all are > 1.
#	Also flip labels and CI accordingly.
data$labels.low <- as.character(data$labels.low)
data$labels.high <- as.character(data$labels.high)
n_factors <- dim(data)[1]
for (i in 1:n_factors){
	if (data[i,]$OR < 1){
		data[i,]$OR <- 1 / data[i,]$OR
		a <- data[i,]$CIa
		b <- data[i,]$CIb
		data[i,]$CIa <- 1 / b
		data[i,]$CIb <- 1 / a
		labels.low <- data[i,]$labels.low
		labels.high <- data[i,]$labels.high
		data[i,]$labels.low <- labels.high
		data[i,]$labels.high <- labels.low
	}
}

# Ascending order from bottom.
ix <- sort(data$OR, index.return=TRUE)$ix
data <- data[ix,]

# Rearrange data as d with additional variables
#
#	NOTE:
#		y corresponds to abscissa, and x to ordinate
#		because of "+ coord_flip()"
#
#	GGPLOT automatically orders the levels of a factor alphabetically.
#	So plot factors by numerical index (label_index) and set labels manually.
#	Alternation of color across factors set by col_indices.
#
# 	d$x		factor labels, low risk
# 	d$x2 	factor labels, high risk
# 	d$y 	OR gives center point
# 	d$ylo 	OR lower limits
# 	d#yhi 	OR upper limits
label_index <- seq(n_factors)
col_indices <- as.factor(label_index%%2)

d <- data.frame(x = data$labels.low, x2 = data$labels.high,
	y = data$OR, ylo = data$CIa, yhi = data$CIb,
	c= col_indices, index=label_index, stars=data$num_stars)
	
locs <- num_stars>0
s <- c("*","**","***")
log_shift <- 0.25
loc_magnitude = 2^(log2(d$ylo[locs])-log_shift)
asterisks <- data.frame(loc_factor=seq(n_factors)[locs], num=num_stars[locs], loc_magnitude=loc_magnitude, lab=s[num_stars[locs]])

# plot it using ggplot
n_factors <- dim(d)[1]
p <- ggplot(d, aes(x=index, y=y, ymin=ylo, ymax=yhi, col=c)) +
geom_pointrange() +
scale_y_continuous(trans = "log2") +
scale_x_continuous(breaks=1:n_factors, labels=d$x,
	sec.axis=sec_axis(~., breaks=1:n_factors, labels=d$x2)) +
geom_hline(yintercept = 1, linetype = 2) +
coord_flip() +
xlab("") +
ylab("Adjusted odds ratio") +
theme(legend.position = "none") +
scale_color_manual(values=myColors) + 		
theme(axis.text.y = element_text(colour=myColors[d$c], size=font.size.y),
	axis.text.x = element_text(size=font.size.x),
	axis.title=element_text(size=font.size.xlabel)) +
# x is x here (abcissa)

annotate(geom = "text", x = asterisks$loc_factor,
	y = asterisks$loc_magnitude, label = asterisks$lab,
	size=5)
# x is y here (abcissa)
	
	# print to file
	ggsave(figure.filename, width=width_cm, height=height_cm, units="cm")
  	return(p)
}