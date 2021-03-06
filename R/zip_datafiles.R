# zip_datafiles
#' Zip a set of data files
#'
#' Zip a set of data files (in format read by [read_cross2()]).
#'
#' @md
#'
#' @param control_file Character string with path to the control file
#' ([YAML](http://www.yaml.org) or [JSON](http://www.json.org/))
#' containing all of the control information.
#' @param zip_file Name of zip file to use. If NULL, we use the
#' stem of `control_file` but with a `.zip` extension.
#' @param quiet If `FALSE`, print progress messages.
#'
#' @return Character string with the file name of the zip file that
#' was created.
#'
#' @details The input `control_file` is the control file (in
#' [YAML](http://www.yaml.org) or [JSON](http://www.json.org/) format)
#' to be read by [read_cross2()].  (See the
#' [sample data files](http://kbroman.org/qtl2/pages/sampledata.html) and the
#' [vignette describing the input file format](http://kbroman.org/qtl2/assets/vignettes/input_files.html).)
#'
#' The [utils::zip()] function is used to do the zipping.
#'
#' The files should all be contained within the directory where the
#' `control_file` sits, or in a subdirectory of that directory.
#' If file paths use `..`, these get stripped by zip, and so the
#' resulting zip file may not work with [read_cross2()].
#'
#' @export
#' @keywords IO
#' @seealso [read_cross2()], sample data files at \url{http://kbroman.org/qtl2/pages/sampledata.html}
#' @examples
#' \dontrun{
#' control_file <- "~/grav2_data/grav2.yaml"
#' zip_datafiles(control_file, "grav2.zip")
#' }
zip_datafiles <-
function(control_file, zip_file=NULL, quiet=TRUE)
{
    control_file <- path.expand(control_file)
    if(!(file.exists(control_file)))
        stop("The control file (", control_file, ") doesn't exist.")

    dir <- dirname(control_file)

    if(is.null(zip_file))
        zip_file <- sub("\\.[a-z]+$", ".zip", control_file)

    # read control file
    control <-  read_control_file(control_file)

    # get all of the file names
    sections <- c("geno", "gmap", "pmap", "pheno", "covar", "phenocovar", "founder_geno")
    files <- basename(control_file)
    for(section in sections) {
        if(section %in% names(control))
            files <- c(files, control[[section]])
    }

    # sex and cross_info as files?
    sections <- c("sex", "cross_info")
    for(section in sections) {
        if(section %in% names(control)) {
            if("file" %in% names(control[[section]]))
                files <- c(files, control[[section]][["file"]])
        }
    }

    # flag for quiet
    zip_flags <- ifelse(quiet, "-q", "")

    # move to the directory with the files
    cwd <- getwd()
    on.exit(setwd(cwd)) # move back on exit
    setwd(dir)

    # check for ".." in file paths
    patterns <- c("^\\.\\.\\/", "\\/\\.\\.\\/")
    patterns <- gsub("/", .Platform$file.sep, patterns, fixed=TRUE)
    if(any(grepl(patterns[1], files) | grepl(patterns[2], files))) {
        warning('zip strips ".." from file paths, so ', zip_file,
                ' may not work with read_cross2().')
    }

    # do the zipping
    utils::zip(zip_file, files, flags=zip_flags)

    invisible(zip_file)
}
