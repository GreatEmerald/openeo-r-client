#' OpenEO client class
#'
#' A R6Class that interacts with an openEO-conformant backend.
#'
#' @include ClientListProduct-class.R
#' @importFrom R6 R6Class
#' @import httr
#' @export
OpenEOClient <- R6Class(
  "OpenEOClient",
  public = list(
    disableAuth = FALSE,
    general_auth_type = "bearer",
    user_id = NULL,
    products = list(),
    processes = list(),

    initialize = function() {

    },

    connect = function(url) {
      if (!missing(url)) {
        if (endsWith(url,"/")) {
          url = substr(url,1,nchar(url)-1)
        }
        private$host = url
        invisible(self)
      } else {
        stop("Host-URL is missing")
      }

    },

    login = function(user, password, auth_type="basic") {
      endpoint = "api/auth/login"

      if (missing(user) || missing(password)) {
        stop("Username or password is missing.")
      }
      if (!private$isConnected()) {
        stop("No host selected")
      }
      private$user = user
      private$password = password

      url = paste(private$host, endpoint, sep="/")
      res = POST(url=url,
                 config = authenticate(user=user,
                                       password = password,
                                       type = auth_type)
      )

      if (res$status_code == 200) {
        cont = content(res,type="application/json")

        private$login_token = cont$token
        self$user_id = cont$user_id

        cat("Login successful." )
        invisible(self)
      } else {
        stop("Login failed.")
      }
    },
    listData = function() {
      endpoint = "api/data/"
      # private$checkLogin()
      listOfProducts = private$callListing(endpoint=endpoint,
                          Template=ClientListProduct)
      lapply(listOfProducts, function(product) {
        product$print()
        self$register(product)
      })
      invisible(self)

    },
    listProcesses = function() {
      endpoint = "api/processes/"
      listOfProcesses = private$callListing(endpoint,ClientListProcess)

      lapply(listOfProcesses, function(process) {
        process$print()
        self$register(process)
      })
      invisible(self)
    },

    register = function(obj) {
      # TODO don't add already existing list stuff
      listName = NULL
      newObj = NULL

      if (isProcess(obj) || isClientListProcess(obj)) {
        if (is.null(self$processes)) {
          self$processes = list()
        }
        listName = "processes"

        newObj = list(obj)
        names(newObj) = obj$process_id

      } else if (isProduct(obj) || isClientListProduct(obj)) {
        if (is.null(self$products)) {
          self$products = list()
        }
        listName = "products"

        newObj = list(obj)
        names(newObj) = c(obj$product_id)

      } else {
        warning("Cannot register object. It is neither Process nor Product")
        return()
      }

      #add if not exists
      lapply(
        self[[listName]],
        function(obj) {
          if (listName == "products") {
            id = obj$process_id
          } else if (listName == "processes") {
            id = obj$product_id
          } else {
            stop("Trying to add something else than products or processes")
          }

          #TODO skip already existing objects
          # if it is incomplete (listElement) and obj is more complete
        }
      )
      self[[listName]] = append(self[[listName]],newObj)

    },
    describeProcess = function(pid) {
      endpoint = paste(private$host ,"api/processes",pid,sep="/")
      response = GET(url=endpoint)

      info = content(response,type="application/json", auto_unbox = TRUE)

      return(info)
    },

    executeTask = function (task,evaluation) {
      endpoint = paste(private$host, "api/jobs/",sep="/")

      header = list()
      if (self$general_auth_type == "bearer") {
        header = append(header,add_headers(
          Authorization=paste("Bearer",private$login_token, sep =" ")
        ))
      } else {
        header = append(header,authenticate(private$user,private$password,type = self$general_auth_type))
      }

      header = append(header,content_type("application/json"))
      return(POST(
        url= endpoint,
        config = header,
        query = list(
          evaluation = evaluation
        ),
        body = taskToJSON(task),
        encode = "raw"
      ))
    }


  ),
  private = list(
    login_token = NULL,
    user = NULL,
    password = NULL,
    host = NULL,

    isConnected = function() {
      return(!is.null(private$host))
    },

    isLoggedIn = function() {

      hasToken = !is.null(private$login_token)
      return(hasToken || self$disableAuth)
    },
    checkLogin = function() {
      if (!private$isLoggedIn()) {
        stop("You are not logged in.")
      }
    },
    callListing = function(endpoint, Template) {
      url = paste(private$host,endpoint, sep ="/")
      response = GET(url=url)

      if (response$status_code == 200) {
        info = content(response,type="application/json")

        return(lapply(info, function(product) {
          obj = Template$new()$fromJSON(product)
          return(obj)
        }))

      } else {
        stop("Cannot access data endpoint")
      }
    }


  )

)


# openeo <- OpenEOClient$new()
