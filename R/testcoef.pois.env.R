testcoef.pois.env <- function(m, L, A) {
  if (is.null(m$Gamma)) 
    stop("beta is a zero matrix, no test is interesting.")
  a <- dim(m$beta)
  p <- a[1]
  r <- a[2]
  R <- diag(1)
  if (ncol(L) != p) 
    stop("The size of L is not supported")
  if (nrow(L) != nrow(A)) 
    stop("The size of A is not supported")
  tmp1 <- kronecker(t(R), L)
  Sigma <- tmp1 %*% tcrossprod(m$covMatrix, tmp1)/m$n
  tmp2 <- matrix(c(L %*% m$beta - A), nrow = 1)
  chisqStatistic <- tmp2 %*% tcrossprod(chol2inv(chol(Sigma)), 
                                        tmp2)
  dof <- nrow(L)
  pValue <- stats::pchisq(chisqStatistic, dof, lower.tail = F)
  covMatrix <- Sigma
  return(list(chisqStatistic = chisqStatistic, dof = dof, pValue = pValue, 
              covMatrix = covMatrix))
}