pois.envMU <- function(X, Y, u, initial = NULL){
  X <- as.matrix(X)
  Y <- as.matrix(Y)
  a <- dim(Y)
  n <- a[1]
  r <- a[2]
  p <- ncol(X)
  if (a[1] != nrow(X)) 
    stop("X and Y should have the same number of observations.")
  if (u > p || u < 0) 
    stop("u must be an integer between 0 and r.")
  if (sum(duplicated(cbind(X, Y), MARGIN = 2)) > 0) 
    stop("Some responses also appear in the predictors, or there maybe duplicated columns in X or Y.")
  
  options(warn = -1) 
  fit <- stats::glm(Y ~ X, family = stats::poisson)
  mu <- as.vector(fit$coefficients[1])
  beta <- as.vector(fit$coefficients[2 : (p + 1)])
  theta <- matrix(1, n, 1) %*% mu + X %*% beta
  c.theta <- - exp(theta)
  c.theta.mean <- mean(c.theta)
  weight <- c.theta / c.theta.mean
  V <- theta + ((Y - c.theta) / weight)
  W <- diag(as.vector(weight))
  wx <- W %*% X
  mean.wx <- apply(wx, 2, mean)
  wxx <- X - matrix(1, nrow = n) %*% mean.wx
  sigwx <- crossprod(wxx, W) %*% wxx / n
  wv <- W %*% V
  mean.wv <- mean(wv)
  wvv <- V - matrix(1, nrow = n) %*% mean.wv
  sigwxv <- crossprod(wxx, W) %*% wvv / n
  inv.sigwx <- chol2inv(chol(sigwx))

  M.init <- inv.sigwx / (- c.theta.mean)
  U.init <- tcrossprod(beta)
  tmp1 <- envMU(M.init, U.init, u, initial = initial)
  gamma.init <- tmp1$Gammahat
  gamma0.init <- tmp1$Gamma0hat


  sigX <- stats::cov(X) * (n - 1) / n
  invsigX <- chol2inv(chol(sigX))

  if (u == 0) {
    Gammahat <- NULL
    Gamma0hat <- diag(r)
    tmp.M <- eigen(sigX)
    mu <- log(mean(Y))
    muh <- matrix(1, n, 1) %*% mu
    Cn1 <- t(Y) %*% muh - colSums(exp(muh))
    eta <- NULL
    var <- NULL
    weight <- rep(1, n)
    V <- Y
    objfun <- Cn1 - n/2 * sum(log(tmp.M$values))
  } else if (u == p) {
    Gammahat <- diag(r)
    Gamma0hat <- NULL
    tmp.M <- eigen(sigX)
    eta <- beta
    var <- inv.sigwx / (- c.theta.mean)
    Cn1 <- t(Y) %*% theta - colSums(exp(theta))
    objfun <- Cn1 - n/2 * sum(log(tmp.M$values))
  } else if (u == p - 1) {
    maxiter = 10000
    ftol = 0.0001
    
    M <- sigX
    MU <- sigX
    tmp.MU <- eigen(MU)
    invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1/tmp.MU$values, "*") %*% t(tmp.MU$vectors)
    
    Cn1 <- t(Y) %*% theta - colSums(exp(theta))
    e1 <- eigen(crossprod(gamma.init, M) %*% gamma.init)
    e2 <- eigen(crossprod(gamma.init, invMU) %*% gamma.init)
    e3 <- eigen(sigX)
    temp1 <- sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))
    obj1 <- Cn1 - (n / 2) * temp1

    GiX <- X %*% gamma.init
    fit <- stats::glm(Y ~ GiX, family = stats::poisson)
    eta <- as.matrix(fit$coefficients[2 : (u + 1)])
  
    init <- gamma.init
    GEidx <- GE(init)
    Ginit <- init %*% solve(init[GEidx[1:u], ])
    j <- GEidx[p]
    g <- as.matrix(Ginit[j, ])
    g1 <- Ginit[-j, ]
    t2 <- crossprod(g1, as.matrix(M[-j, j]))/M[j, j]
    t3 <- crossprod(g1, as.matrix(invMU[-j, j]))/invMU[j, j]
    GUGt2 <- g + t2
    GUG <- crossprod(Ginit, (M %*% Ginit)) - tcrossprod(GUGt2, GUGt2) * M[j, j]
    GVGt2 <- g + t3
    GVG <- crossprod(Ginit, (invMU %*% Ginit)) - tcrossprod(GVGt2, GVGt2) * invMU[j, j]
    invC1 <- chol2inv(chol(GUG))
    invC2 <- chol2inv(chol(GVG))
  
    X1 <- X[ , j]
    X2 <- X[ , -j]
    t5 <- X1 %*% t(g) %*% eta
    t6 <- matrix(1, n, 1) %*% mu + X2 %*% g1 %*% eta
    t7 <- t6 + t5
    t8 <- t(Y) %*% t7
    et6 <- exp(t7)
    t9 <- colSums(et6)

      fobj <- function(x) {
        tmp2 <- x + t2
        tmp3 <- x + t3
        tmp4 <- X1 %*% t(x) %*% eta + t6
        T2 <- invC1 %*% tmp2
        T3 <- invC2 %*% tmp3 
        T4 <- exp(tmp4)
        n /2 * (- 2 * log(1 + sum(x^2)) + log(1 + M[j, j] * 
        crossprod(tmp2,T2)) + log(1 + invMU[j, j] * 
        crossprod(tmp3,T3))) - t(Y) %*% tmp4 + colSums(T4)
      }
    
      gobj <- function(x) {
        tmp2 <- x + t2
        tmp3 <- x + t3
        tmp4 <- X1 %*% t(x) %*% eta + t6
        Cn <- Y - exp(tmp4)
        T2 <- invC1 %*% tmp2
        T3 <- invC2 %*% tmp3 
        A1 <- crossprod(g1, sigwx[-j, -j]) %*% g1 + as.matrix(x) %*% sigwx[j, -j] %*% g1 + crossprod(g1, sigwx[-j, j]) %*% t(x) + tcrossprod(x) * sigwx[j , j]
        invC3 <- chol2inv(chol(A1))
        T5 <- crossprod(X, Cn) %*% t(eta) 
        tmp5 <- X1 %*% t(x) + X2 %*% g1
        T6 <- tcrossprod(sigwxv, Cn) %*% tmp5 %*% invC3
        tmp6 <- as.matrix(sigwx[ , -j]) %*% g1 + tcrossprod(sigwx[ , j], x)
        T7 <- tmp6 %*% invC3 %*% crossprod(tmp5, Cn) %*% t(eta)
        T8 <- tmp6 %*% eta %*% crossprod(Cn, tmp5) %*% invC3
        r1 <- rep(0, p)
        r1[j] <- 1
        T9 <- t(r1) %*% (T5 + T6 - T7 - T8) 
        - t(T9) + n * (- 4 * x %*% solve(1 + sum(x^2)) + 2 * T2/as.numeric(1/M[j, j] + 
        crossprod(tmp2, T2)) + 2 * T3/as.numeric(1/invMU[j, j] + crossprod(tmp3, T3)))
      }
    
      i <- 1
      while (i < maxiter) {
        res <- stats::optim(Ginit[j, ], fobj, gobj, method = "BFGS")
        Ginit[j, ] <- res$par
      
        GX <- X %*% Ginit
        fit <- stats::glm(Y ~ GX, family = stats::poisson)
        mu <- as.vector(fit$coefficients[1])
        eta <- as.matrix(fit$coefficients[2 : (u + 1)])
        beta <- Ginit %*% eta
        theta <- matrix(1, n, 1) %*% mu + X %*% beta
        c.theta <- - exp(theta)
        c.theta.mean <- mean(c.theta)
        weight <- c.theta / c.theta.mean
        V <- theta + ((Y - c.theta) / weight)
        W <- diag(as.vector(weight))
        wx <- W %*% X
        mean.wx <- apply(wx, 2, mean)
        wxx <- X - matrix(1, nrow = n) %*% mean.wx
        sigwx <- crossprod(wxx, W) %*% wxx / n
        wv <- W %*% V
        mean.wv <- mean(wv)
        wvv <- V - matrix(1, nrow = n) %*% mean.wv
        sigwxv <- crossprod(wxx, W) %*% wvv / n

      
        e1 <- eigen(t(Ginit) %*% M %*% Ginit)
        e2 <- eigen(t(Ginit) %*% invMU %*% Ginit)
        e3 <- eigen(crossprod(Ginit))
        e4 <- matrix(1, n, 1) %*% mu + X %*% beta
        e5 <- crossprod(Y, e4) - colSums(exp(e4))
        obj2 <- - n/2 * (sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))) + e5
        if (abs(obj1 - obj2) < ftol) {
          break
        }
        else {
          obj1 <- obj2
          i <- i + 1
        }
      }
      a <- qr(Ginit)
      Gammahat <- qr.Q(a)
      GX <- X %*% Gammahat
      fit <- stats::glm(Y ~ GX, family = stats::poisson)
      mu <- as.vector(fit$coefficients[1])
      eta <- matrix(fit$coefficients[2 : (u + 1)])
      beta <- Gammahat %*% eta
      theta <- matrix(1, n, 1) %*% mu + X %*% beta
      theta <- matrix(1, n, 1) %*% mu + X %*% beta
      c.theta <- - exp(theta)
      c.theta.mean <- mean(c.theta)
      weight <- c.theta / c.theta.mean
      V <- theta + ((Y - c.theta) / weight)
      W <- diag(as.vector(weight))
      wx <- W %*% X
      mean.wx <- apply(wx, 2, mean)
      wxx <- X - matrix(1, nrow = n) %*% mean.wx
      sigwx <- crossprod(wxx, W) %*% wxx / n
      inv.sigwx <- chol2inv(chol(sigwx))
      var <- inv.sigwx / (- c.theta.mean)
      e1 <- eigen(t(Gammahat) %*% M %*% Gammahat)
      e2 <- eigen(t(Gammahat) %*% invMU %*% Gammahat)
      e3 <- eigen(M)
      e4 <- matrix(1, n, 1) %*% mu + X %*% Gammahat %*% eta
      e5 <- crossprod(Y, e4) - colSums(exp(e4))
      Gamma0hat <- qr.Q(a, complete = TRUE)[, (u + 1):r, drop = FALSE]
      objfun <- - n/2 * (sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))) + e5
      Gammahat <- as.matrix(Gammahat)
      Gamma0hat <- as.matrix(Gamma0hat)
  
    } else {
      maxiter = 10000
      ftol = 0.0001
      
      M <- sigX
      MU <- sigX
      tmp.MU <- eigen(MU)
      invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1/tmp.MU$values, "*") %*% t(tmp.MU$vectors)
      
      Cn1 <- t(Y) %*% theta - colSums(exp(theta))
      e1 <- eigen(crossprod(gamma.init, M) %*% gamma.init)
      e2 <- eigen(crossprod(gamma.init, invMU) %*% gamma.init)
      e3 <- eigen(sigX)
      temp1 <- sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))
      obj1 <- Cn1 - (n / 2) * temp1
    
      GiX <- X %*% gamma.init
      fit <- stats::glm(Y ~ GiX, family = stats::poisson)
      eta <- as.matrix(fit$coefficients[2 : (u + 1)])
    
      init <- gamma.init
      GEidx <- GE(init)
      Ginit <- init %*% solve(init[GEidx[1:u], ])
      GUG <- crossprod(Ginit, (M %*% Ginit))
      GVG <- crossprod(Ginit, (invMU %*% Ginit))
      t4 <- crossprod(Ginit[GEidx[(u + 1):p], ], Ginit[GEidx[(u + 1):p], ]) + diag(u)
      i <- 1
      while (i < maxiter) {
        for (j in GEidx[(u + 1):p]) {
          g <- as.matrix(Ginit[j, ])  
          g1 <- as.matrix(Ginit[-j, ])
          t2 <- crossprod(g1, as.matrix(M[-j, j]))/M[j, j]
          t3 <- crossprod(g1, as.matrix(invMU[-j, j]))/invMU[j, j]
          GUGt2 <- g + t2
          GUG <- GUG - tcrossprod(GUGt2, GUGt2) * M[j, j]
          GVGt2 <- g + t3
          GVG <- GVG - tcrossprod(GVGt2, GVGt2) * invMU[j, j]
          t4 <- t4 - tcrossprod(g, g)
          invC1 <- chol2inv(chol(GUG))
          invC2 <- chol2inv(chol(GVG))
          invt4 <- chol2inv(chol(t4))
        
          X1 <- X[ , j]
          X2 <- X[ , -j]
          t5 <- X1 %*% t(g) %*% eta
          t6 <- matrix(1, n, 1) %*% mu + X2 %*% g1 %*% eta
          t7 <- t5 + t6
          t8 <- t(Y) %*% t7
          et7 <- exp(t7)
          t9 <- colSums(et7)
        
          fobj <- function(x) {
            tmp2 <- x + t2
            tmp3 <- x + t3
            tmp4 <- X1 %*% t(x) %*% eta + t6
            T1 <- invt4 %*% x
            T2 <- invC1 %*% tmp2
            T3 <- invC2 %*% tmp3
            T4 <- exp(tmp4)
            n /2 * (-2 * log(1 + x %*% T1) + log(1 + M[j, j] * 
            crossprod(tmp2, T2)) + log(1 + invMU[j, j] *
            crossprod(tmp3, T3))) - t(Y) %*% tmp4 + colSums(T4)
          }
        
          gobj <- function(x) {
            tmp2 <- x + t2
            tmp3 <- x + t3
            tmp4 <- X1 %*% t(x) %*% eta + t6
            Cn <- Y - exp(tmp4)
            T1 <- invt4 %*% x
            T2 <- invC1 %*% tmp2
            T3 <- invC2 %*% tmp3 
            A1 <- crossprod(g1, sigwx[-j, -j]) %*% g1 + as.matrix(x) %*% sigwx[j, -j] %*% g1 + crossprod(g1, sigwx[-j, j]) %*% t(x) + tcrossprod(x) * sigwx[j , j]
            invC3 <- chol2inv(chol(A1))
            T5 <- crossprod(X, Cn) %*% t(eta) 
            tmp5 <- X1 %*% t(x) + X2 %*% g1
            T6 <- tcrossprod(sigwxv, Cn) %*% tmp5 %*% invC3
            tmp6 <- as.matrix(sigwx[ , -j]) %*% g1 + tcrossprod(sigwx[ , j], x)
            T7 <- tmp6 %*% invC3 %*% crossprod(tmp5, Cn) %*% t(eta)
            T8 <- tmp6 %*% eta %*% crossprod(Cn, tmp5) %*% invC3
            r1 <- rep(0, p)
            r1[j] <- 1
            T9 <- t(r1) %*% (T5 + T6 - T7 - T8)
            - t(T9) + n * (- 4 * T1/as.numeric(1 + x %*% T1) + 2 * T2/as.numeric(1/M[j, j] + 
            crossprod(tmp2, T2)) + 2 * T3/as.numeric(1/invMU[j, j] + crossprod(tmp3, T3)))
          }
          res <- stats::optim(Ginit[j, ], fobj, gobj, method = "BFGS")
          Ginit[j, ] <- res$par
          g <- as.matrix(Ginit[j, ])
          t4 <- t4 + tcrossprod(g, g)
          GUGt2 <- g + t2
          GUG <- GUG + tcrossprod(GUGt2, GUGt2) * M[j, j]
          GVGt2 <- g + t3
          GVG <- GVG + tcrossprod(GVGt2, GVGt2) * invMU[j, j]
        }
      
        GX <- X %*% Ginit
        fit <- stats::glm(Y ~ GX, family = stats::poisson)
        mu <- as.vector(fit$coefficients[1])
        eta <- as.matrix(fit$coefficients[2 : (u + 1)])
        beta <- Ginit %*% eta
        theta <- matrix(1, n, 1) %*% mu + X %*% beta
        c.theta <- - exp(theta)
        c.theta.mean <- mean(c.theta)
        weight <- c.theta / c.theta.mean
        V <- theta + ((Y - c.theta) / weight)
        W <- diag(as.vector(weight))
        wx <- W %*% X
        mean.wx <- apply(wx, 2, mean)
        wxx <- X - matrix(1, nrow = n) %*% mean.wx
        sigwx <- crossprod(wxx, W) %*% wxx / n
        wv <- W %*% V
        mean.wv <- mean(wv)
        wvv <- V - matrix(1, nrow = n) %*% mean.wv
        sigwxv <- crossprod(wxx, W) %*% wvv / n

      
        e1 <- eigen(t(Ginit) %*% M %*% Ginit)
        e2 <- eigen(t(Ginit) %*% invMU %*% Ginit)
        e3 <- eigen(crossprod(Ginit))
        e4 <- matrix(1, n, 1) %*% mu + X %*% beta
        e5 <- crossprod(Y, e4) - colSums(exp(e4))
        obj2 <- - n/2 * (sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))) + e5
        if (abs(obj1 - obj2) < ftol) {
          break
        }
        else {
          obj1 <- obj2
          i <- i + 1
        }
      }
      a <- qr(Ginit)
      Gammahat <- qr.Q(a)
      GX <- X %*% Gammahat
      fit <- stats::glm(Y ~ GX, family = stats::poisson)
      mu <- as.vector(fit$coefficients[1])
      eta <- matrix(fit$coefficients[2 : (u + 1)])
      beta <- Gammahat %*% eta
      theta <- matrix(1, n, 1) %*% mu + X %*% beta
      c.theta <- - exp(theta)
      c.theta.mean <- mean(c.theta)
      weight <- c.theta / c.theta.mean
      V <- theta + ((Y - c.theta) / weight)
      W <- diag(as.vector(weight))
      wx <- W %*% X
      mean.wx <- apply(wx, 2, mean)
      wxx <- X - matrix(1, nrow = n) %*% mean.wx
      sigwx <- crossprod(wxx, W) %*% wxx / n
      
      inv.sigwx <- chol2inv(chol(sigwx))
      var <- inv.sigwx / (- c.theta.mean)
      e1 <- eigen(t(Gammahat) %*% M %*% Gammahat)
      e2 <- eigen(t(Gammahat) %*% invMU %*% Gammahat)
      e3 <- eigen(M)
      e4 <- matrix(1, n, 1) %*% mu + X %*% Gammahat %*% eta
      e5 <- crossprod(Y, e4) - colSums(exp(e4))
      Gamma0hat <- qr.Q(a, complete = TRUE)[, (u + 1):p]
      objfun <- - n/2 * (sum(log(e1$values)) + sum(log(e2$values)) + sum(log(e3$values))) + e5
      Gammahat <- as.matrix(Gammahat)
      Gamma0hat <- as.matrix(Gamma0hat)
    
    }
    return(list(Gammahat = Gammahat, Gamma0hat = Gamma0hat, muhat = mu,
              etahat = eta, weighthat = weight, Vhat = V, 
              avar = var, objfun = objfun))
}
