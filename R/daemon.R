daemon <- local({
  pid <- NULL
  ipfs_start <- function(background = TRUE, silent = FALSE){
    ipfs_stop()
    if(identical(background, FALSE)){
      message("Running ipfs in foreground. Press ESC or CTRL+C to stop")
      return(sys::exec_wait("ipfs", c("daemon", "--init"), std_out = !silent, std_err = !silent))
    }
    message("Starting IPFS. Give it a few seconds...")
    pid <<- sys::exec_background("ipfs", c("daemon", "--init"), std_out = !silent, std_err = !silent)
    reg.finalizer(environment(.onAttach), function(x){
      ipfs_stop()
    }, onexit = TRUE)
    while(!ipfs_is_online()){
      Sys.sleep(1)
    }
    cat("OK!\n")
    invisible()
  }

  ipfs_stop <- function(){
    if(!is.null(pid)){
      cat("stopping ipfs...\n")
      tools::pskill(pid)
      pid <<- NULL
    }
  }
  environment()
})


has_ipfs <- function(){
  out <- try(sys::exec_wait('ipfs', '--version', std_out = FALSE), silent = TRUE)
  !inherits(out, "try-error")
}

ipfs_is_online <- function(){
  url <- ipfs_api("version")
  handle <- curl::new_handle(TIMEOUT = 1, CONNECTTIMEOUT = 1)
  out <- try(curl::curl_fetch_memory(url), silent = TRUE)
  !inherits(out, "try-error")
}


#' IPFS daemon
#'
#' Start and stop the ipfs server. This is automatically done when attaching
#' the package.
#'
#' @export
#' @rdname daemon
#' @param background run the daemon as a background process (default). If set
#' to `FALSE`, the server will block the current R session and print server
#' output to the console. In this case you should use the client from a
#' separate R sesssion. Useful for debugging.
#' @param silent suppress server output
ipfs_daemon <- daemon$ipfs_start
