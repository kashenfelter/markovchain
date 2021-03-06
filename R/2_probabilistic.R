# given a markovchain object is it possible to reach goal state from 
# a given state

#' @name is.accessible
#' @title Verify if a state j is reachable from state i.
#' @description This function verifies if a state is reachable from another, i.e., 
#'              if there exists a path that leads to state j leaving from state i with 
#'              positive probability
#'              
#' @param object A \code{markovchain} object.
#' @param from The name of state "i" (beginning state).
#' @param to The name of state "j" (ending state).
#' 
#' @details It wraps an internal function named \code{.commStatesFinder}.
#' @return A boolean value.
#' 
#' @references James Montgomery, University of Madison
#' 
#' @author Giorgio Spedicato
#' @seealso \code{is.irreducible}
#' 
#' @examples 
#' statesNames <- c("a", "b", "c")
#' markovB <- new("markovchain", states = statesNames, 
#'                transitionMatrix = matrix(c(0.2, 0.5, 0.3,
#'                                              0,   1,   0,
#'                                            0.1, 0.8, 0.1), nrow = 3, byrow = TRUE, 
#'                                          dimnames = list(statesNames, statesNames)
#'                                         )
#'                )
#' is.accessible(markovB, "a", "c")
#' @export

is.accessible <- function(object, from, to) {
  # assume that it is not possible
  out <- FALSE
  
  # names of states
  statesNames <- states(object)
  
  # row number
  fromPos <- which(statesNames == from)
  
  # column number
  toPos<-which(statesNames == to)

  # a logical matrix which will tell the reachability of jth state from ith state
  R <- .commStatesFinderRcpp(object@transitionMatrix)
  
  if(R[fromPos, toPos] == TRUE) {
    out <- TRUE 
  }
  
  return(out)
}

# a markov chain is irreducible if it is composed of only one communicating class

#' @name is.irreducible
#' @title Function to check if a Markov chain is irreducible
#' @description This function verifies whether a \code{markovchain} object transition matrix 
#'              is composed by only one communicating class.
#' @param object A \code{markovchain} object
#' 
#' @details It is based on \code{.communicatingClasses} internal function.
#' @return A boolean values.
#' 
#' @references Feres, Matlab listings for Markov Chains.
#' @author Giorgio Spedicato
#' 
#' @seealso \code{\link{summary}}
#' 
#' @examples 
#' statesNames <- c("a", "b")
#' mcA <- new("markovchain", transitionMatrix = matrix(c(0.7,0.3,0.1,0.9),
#'                                              byrow = TRUE, nrow = 2, 
#'                                              dimnames = list(statesNames, statesNames)
#'            ))
#' is.irreducible(mcA)
#' @export

is.irreducible <- function(object) {
  # assuming markovchain chain has more than 1 communicating classes
  out <- FALSE

  # this function will return a list of communicating classes 
  tocheck <- .communicatingClassesRcpp(object)
  
  # only one class implies irreducible markovchain
  if(length(tocheck) == 1) {
    out<-TRUE  
  }
  
  return(out)
}

# what this function will do?
# It calculates the probability to go from given state
# to all other states in k steps
# k varies from 1 to n

#' @name firstPassage
#' @title First passage across states
#' @description This function compute the first passage probability in states
#' 
#' @param object A \code{markovchain} object
#' @param state Initial state
#' @param n Number of rows on which compute the distribution
#' 
#' @details Based on Feres' Matlab listings
#' @return A matrix of size 1:n x number of states showing the probability of the 
#'         first time of passage in states to be exactly the number in the row.
#'
#' @references Renaldo Feres, Notes for Math 450 Matlab listings for Markov chains
#' 
#' @author Giorgio Spedicato
#' @seealso \code{\link{conditionalDistribution}}
#' 
#' @examples 
#' simpleMc <- new("markovchain", states = c("a", "b"),
#'                  transitionMatrix = matrix(c(0.4, 0.6, .3, .7), 
#'                                     nrow = 2, byrow = TRUE))
#' firstPassage(simpleMc, "b", 20)
#'
#' @export

firstPassage <- function(object, state, n) {
  P <- object@transitionMatrix
  stateNames <- states(object)
  
  # row number
  i <- which(stateNames == state)

  
  outMatr <- .firstpassageKernelRcpp(P = P, i = i, n = n)
  colnames(outMatr) <- stateNames
  rownames(outMatr) <- 1:n
  return(outMatr)
}




#' function to calculate first passage probabilities
#' 
#' @description The function calculates first passage probability for a subset of
#' states given an initial state.
#' 
#' @param object a markovchain-class object
#' @param state intital state of the process (charactervector)
#' @param set set of states A, first passage of which is to be calculated
#' @param n Number of rows on which compute the distribution
#' 
#' @return A vector of size n showing the first time proabilities
#' @references
#' Renaldo Feres, Notes for Math 450 Matlab listings for Markov chains;
#' MIT OCW, course - 6.262, Discrete Stochastic Processes, course-notes, chap -05
#' 
#' @author Vandit Jain
#' 
#' @seealso \code{\link{firstPassage}}
#' @examples 
#' statesNames <- c("a", "b", "c")
#' markovB <- new("markovchain", states = statesNames, transitionMatrix =
#' matrix(c(0.2, 0.5, 0.3,
#'          0, 1, 0,
#'          0.1, 0.8, 0.1), nrow = 3, byrow = TRUE,
#'        dimnames = list(statesNames, statesNames)
#' ))
#' firstPassageMultiple(markovB,"a",c("b","c"),4)  
#' 
#' @export 
firstPassageMultiple <- function(object,state,set, n){
  
  # gets the transition matrix
  P <- object@transitionMatrix
  
  # character vector of states of the markovchain
  stateNames <- states(object)
  
  k <- -1
  k <- which(stateNames == state)
  if(k==-1)
    stop("please provide a valid initial state")
  
  # gets the set in numeric vector
  setno <- rep(0,length(set))
  for(i in 1:length(set))
  {
    setno[i] = which(set[i] == stateNames)
    if(setno[i] == 0)
      stop("please provide proper set of states")
  }
  
  # calls Rcpp implementation
  outMatr <- .firstPassageMultipleRCpp(P,k,setno,n)
  
  #sets column and row names of output
  colnames(outMatr) <- "set"
  rownames(outMatr) <- 1:n
  return(outMatr)
}




# return a list of communicating classes

#' @name communicatingClasses
#' @title Various function to perform structural analysis of DTMC
#' @description These functions return absorbing and transient states of the \code{markovchain} objects.
#' 
#' @param object A \code{markovchain} object.
#' 
#' @return vector, matrix or list
#' 
#' @references Feres, Matlab listing for markov chain.
#' 
#' @author Giorgio Alfredo Spedicato
#' 
#' @seealso \code{\linkS4class{markovchain}}
#' 
#' @examples 
#' statesNames <- c("a", "b", "c")
#' markovB <- new("markovchain", states = statesNames, transitionMatrix =
#'                    matrix(c(0.2, 0.5, 0.3,
#'                               0,   1,   0,
#'                             0.1, 0.8, 0.1), nrow = 3, byrow = TRUE, 
#'                             dimnames = list(statesNames, statesNames)
#'               ))
#'               
#' communicatingClasses(markovB)               
#' recurrentClasses(markovB)
#' absorbingStates(markovB)
#' transientStates(markovB)
#' canonicForm(markovB)
#' 
#' # periodicity analysis : 1
#' E <- matrix(c(0, 1, 0, 0, 0.5, 0, 0.5, 0, 0, 0.5, 0, 0.5, 0, 0, 1, 0), 
#'             nrow = 4, ncol = 4, byrow = TRUE)
#' mcE <- new("markovchain", states = c("a", "b", "c", "d"), 
#'           transitionMatrix = E, 
#'           name = "E")
#'
#' is.irreducible(mcE) #true
#' period(mcE) #2
#'
#' # periodicity analysis : 2
#' myMatr <- matrix(c(0, 0, 1/2, 1/4, 1/4, 0, 0,
#'                    0, 0, 1/3, 0, 2/3, 0, 0,
#'                    0, 0, 0, 0, 0, 1/3, 2/3,
#'                    0, 0, 0, 0, 0, 1/2, 1/2,
#'                    0, 0, 0, 0, 0, 3/4, 1/4,
#'                    1/2, 1/2, 0, 0, 0, 0, 0,
#'                    1/4, 3/4, 0, 0, 0, 0, 0), byrow = TRUE, ncol = 7)
#' myMc <- new("markovchain", transitionMatrix = myMatr)
#' period(myMc)
#' 
#' @rdname absorbingStates
#' @export

communicatingClasses <- function(object) {
  out <- .communicatingClassesRcpp(object)
  return(out)
}

# A communicating class will be a recurrent class if 
# there is no outgoing edge from this class
# Recurrent classes are subset of communicating classes

#' @rdname absorbingStates
#' 
#' @export

recurrentClasses <- function(object) {
  out <- .recurrentClassesRcpp(object)
  return(out)
}



#' @title Calculates committor of a markovchain object with respect to set A, B
#' 
#' @description Returns the probability of hitting states rom set A before set B 
#' with different initial states
#' 
#' @usage committorAB(object,A,B,p)
#' 
#' @param object a markovchain class object
#' @param A a set of states
#' @param B a set of states
#' @param p initial state (default value : 1)
#' 
#' @details The function solves a system of linear equations to calculate probaility that the process hits
#' a state from set A before any state from set B
#' 
#' @return Return a vector of probabilities in case initial state is not provided else returns a number
#' 
#' @examples 
#' transMatr <- matrix(c(0,0,0,1,0.5,
#'                       0.5,0,0,0,0,
#'                       0.5,0,0,0,0,
#'                       0,0.2,0.4,0,0,
#'                       0,0.8,0.6,0,0.5),
#'                       nrow = 5)
#' object <- new("markovchain", states=c("a","b","c","d","e"),transitionMatrix=transMatr)
#' committorAB(object,c(5),c(3))
#' 
#' @export
committorAB <- function(object,A,B,p=1) {
  
  if(!class(object) == "markovchain")
    stop("please provide a valid markovchain object")
  
  matrix <- object@transitionMatrix
  
  noofstates <- length(object@states)
  
  for(i in length(A))
  {
    if(A[i] <= 0 || A[i] > noofstates)
      stop("please provide a valid set A")
  }
  
  for(i in length(B))
  {
    if(B[i] <= 0 || B[i] > noofstates)
      stop("please provide a valid set B")
  }
  
  for(i in 1:noofstates)
  {
    if(i %in% A && i %in% B)
      stop("intersection of set A and B in not null")
  }
  
  if(p <=0 || p > noofstates)
    stop("please provide a valid initial state")
  
  I <- diag(noofstates)
  
  matrix <- matrix - I
  
  A_size = length(A)
  B_size = length(B)
  
  # sets the matrix according to the provided states
  for(i in 1:A_size)
  {
    for(j in 1:noofstates)
    {
      if(A[i]==j)
        matrix[A[i],j] = 1
      else
        matrix[A[i],j] = 0
    }
  }
  
  # sets the matrix according to the provided states
  for(i in 1:B_size)
  {
    for(j in 1:noofstates)
    {
      if(B[i]==j)
        matrix[B[i],j] = 1
      else
        matrix[B[i],j] = 0
    }
  }
  
  # initialises b in the equation the system of equation AX =b
  b <- rep(0,noofstates)
  
  
  for(i in 1:A_size)
  {
    b[A[i]] = 1
  }
  
  # solve AX = b according using solve function from base package
  out <- solve(matrix,b)
  
  
  if(missing(p))
    return(out)
  else
    return(out[p])
}


#' Expected Rewards for a markovchain
#' 
#' @description Given a markovchain object and reward values for every state,
#' function calculates expected reward value after n steps.
#' 
#' @usage expectedRewards(markovchain,n,rewards)
#' 
#' @param markovchain the markovchain-class object
#' @param n no of steps of the process
#' @param rewards vector depicting rewards coressponding to states
#' 
#' @details the function uses a dynamic programming approach to solve a 
#' recursive equation described in reference.
#' 
#' @return
#' returns a vector of expected rewards for different initial states
#' 
#' @author Vandit Jain
#' 
#' @references Stochastic Processes: Theory for Applications, Robert G. Gallager,
#' Cambridge University Press
#' 
#' @examples 
#' transMatr<-matrix(c(0.99,0.01,0.01,0.99),nrow=2,byrow=TRUE)
#' simpleMc<-new("markovchain", states=c("a","b"),
#'              transitionMatrix=transMatr)
#' expectedRewards(simpleMc,1,c(0,1))
#' @export
expectedRewards <- function(markovchain, n, rewards) {
  
  # gets the transition matrix
  matrix <- markovchain@transitionMatrix
  
  # Rcpp implementation of the function
  out <- .expectedRewardsRCpp(matrix,n, rewards)
  
  noofStates <- length(states(markovchain))
  
  result <- rep(0,noofStates)
  
  for(i in 1:noofStates)
    result[i] = out[i]
  
  #names(result) <- states(markovchain)
  return(result)
}

#' Expected first passage Rewards for a set of states in a markovchain
#' 
#' @description Given a markovchain object and reward values for every state,
#' function calculates expected reward value for a set A of states after n 
#' steps. 
#'  
#' @usage expectedRewardsBeforeHittingA(markovchain, A, state, rewards, n)
#'  
#' @param markovchain the markovchain-class object
#' @param A set of states for first passage expected reward
#' @param state initial state
#' @param rewards vector depicting rewards coressponding to states
#' @param n no of steps of the process
#'  
#' @details The function returns the value of expected first passage 
#' rewards given rewards coressponding to every state, an initial state
#' and number of steps.
#'  
#' @return returns a expected reward (numerical value) as described above
#'  
#' @author Sai Bhargav Yalamanchi, Vandit Jain
#'  
#' @export
expectedRewardsBeforeHittingA <- function(markovchain, A, state, rewards, n) {
  
  ## gets the markovchain matrix
  matrix <- markovchain@transitionMatrix
  
  # gets the names of states
  stateNames <- states(markovchain)
  
  # no of states
  S <- length(stateNames)
  
  # vectors for states in S-A
  SAno <- rep(0,S-length(A))
  rewardsSA <- rep(0,S-length(A))
  
  # for initialisation for set S-A 
  i=1
  ini = -1
  for(j in 1:length(stateNames))
  {
    if(!(stateNames[j] %in% A)){
      SAno[i] = j
      rewardsSA[i] = rewards[j]
      if(stateNames[j] == state)
        ini = i
      i = i+1
    }
  }
  
  ## get the matrix coressponding to S-A
  matrix <- matrix[SAno,SAno]
  
  ## cals the cpp implementation
  out <- .expectedRewardsBeforeHittingARCpp(matrix, ini, rewardsSA, n)
  
  return(out)
  
}



# @title Check if a DTMC is regular
# 
# @description Function to check wether a DTCM is regular
# 
# @details A regular Markov chain has $A^n$ strictly positive for some n. 
# So we check: if there is only one eigenvector; if the steadystate vector is striclty positive.
# 
# @param object a markovchain object
# 
# @return A boolean value
# 
# @examples 
# P=matrix(c(0.5,.25,.25,.5,0,.5,.25,.25,.5),nrow = 3)
# colnames(P)<-rownames(P)<-c("R","N","S")
# ciao<-as(P,"markovchain")
# is.regular(ciao)
# 
# @seealso \code{\link{is.irreducible}}


# is.regular<-function(object) {
#   eigenValues<-steadyStates(object = object)
#   minDim<-min(dim(eigenValues))
#   out <- minDim==1 & all(eigenValues>0)
#   return(out)
# }


