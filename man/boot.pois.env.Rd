\name{boot.pois.env}
\alias{boot.pois.env}
\title{Bootstrap for pois.env}
\description{
 Compute bootstrap standard error for the envelope estimator in poisson regression.
}
\usage{
boot.pois.env(X, Y, u, B)
}
\arguments{
  \item{X}{Predictors. An n by p matrix, p is the number of predictors and n is number of observations.  The predictors must be continuous variables.}
  \item{Y}{Response. An n by 1 matrix. The univariate response must be counts.}
  \item{u}{Dimension of the envelope. An integer between 0 and p.}
  \item{B}{Number of bootstrap samples. A positive integer.}
}
\details{
 This function computes the bootstrap standard errors for the coefficients in the poisson regression envelope by the paired bootstrap.
}
\value{The output is a p by 1 matrix.
\item{bootse}{The standard error for elements in beta computed by bootstrap.} 
}

\examples{
data(horseshoecrab)
X1 <- as.numeric(horseshoecrab[ , 1] == 2)
X2 <- as.numeric(horseshoecrab[ , 1] == 3)
X3 <- as.numeric(horseshoecrab[ , 1] == 4)
X4 <- as.numeric(horseshoecrab[ , 2] == 2)
X5 <- as.numeric(horseshoecrab[ , 2] == 3)
X6 <- horseshoecrab[ , 3]
X7 <- horseshoecrab[ , 5]
X <- cbind(X1, X2, X3, X4, X5, X6, X7)
Y <- horseshoecrab[ , 4]

B <- 100
\dontrun{bootse <- boot.pois.env(X, Y, 1, B)}
\dontrun{bootse}
}

