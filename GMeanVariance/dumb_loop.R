library(PerformanceAnalytics)

library(DEoptim)

library(quantmod)



etflist = c("TLT","SPY","XLB","XLV","XLP","XLY","XLE","XLF","XLI","XLK","XLU")





getSymbols(etflist,from="2003-12-01", to = "2013-05-01")

tickers = etflist 
## Make matrix of Returns code stolen from vignette of deoptim
P<- NULL
seltickers<-NULL
for(ticker in tickers){
  tmp = Cl(to.monthly(eval(parse(text=ticker))))
  if(is.null(P)){timeP=time(tmp)}
  if(any(time(tmp)!=timeP)) next
  else P = cbind(P,as.numeric(tmp))
  seltickers = c(seltickers,ticker)
}
P = xts(P,order.by=timeP)
colnames(P) = seltickers
R = diff(log(P))
R = R[-1,]

initw = rep(1/ncol(R),ncol(R))
objectivefun = function(w){
	if(sum(w)==0){
		w = w + 1e-2 
	}
	w = w / sum(w)
targ = ES(weights=w,method="gaussian",portfolio_method="component",mu=mu,sigma=sigma)
tmp1 = targ$ES
tmp2 = max(targ$pct_contrib_ES-0.05,0)
out = tmp1 + 1e3 * tmp2
return(out)}

source('random_portfolios.R')
source('constraints.R')


N = ncol(R)
minw = 0
maxw = 1
lower = rep(minw,N)
upper = rep(maxw,N)

eps <- 0.025
weight_seq<-generatesequence(min=minw,max=maxw,by=.001,rounding=3)
rpconstraint<-constraint( assets=N, min_sum=(1-eps), max_sum=(1+eps), min=lower, max=upper, weight_seq=weight_seq)

rp = random_portfolios(rpconstraints=rpconstraint,permutations=N*10)
rp <-rp/rowSums(rp)
controlDE = list(reltol=0.00001,steptol=150,itermax=2000,trace=250,NP=as.numeric(nrow(rp)),initialpop=rp)
set.seed(1234)

preturn = R
for (p in 1:ncol(preturn)){
	
preturn[,p] = 0
}
optweights = R
for (z in 1:ncol(optweights)){
	
optweights[,z] = 0
}

for (i in 2:length(R)){
rollR = first(R,i)
mu = colMeans(rollR)
sigma = cov(rollR)

weightvec = DEoptim(fn=objectivefun,lower=lower,upper=upper,control=controlDE)
preturn[i+1,] = weightvec$optim$bestmem*R[i+1]
optweights[i+1,] = weightvec$optim$bestmem


}
portret = rowSums(preturn)
portret = xts(portret,order.by=index(preturn))
