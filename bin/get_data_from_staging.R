#!/usr/bin/env Rscript
  
  suppressMessages( library(  S4Vectors ) )
  suppressMessages( library(  SummarizedExperiment ) )

  # getAtlasExperiment
  #   - Download and return the SimpleList object representing a single
  #   Expression Atlas experiment.
  getAtlasExperiment <- function( experimentAccession ) {
    
    # Make sure the experiment accession is in the correct format.
    if( ! .isValidExperimentAccession( experimentAccession ) ) {
      
      stop( "Experiment accession not valid. Cannot continue." )
    }
    
    # $ATLAS_EXPS to load Atlas data from.
    ATLAS_EXPS <- Sys.getenv("ATLAS_EXPS")
    
    # Create filename for R data file.
    atlasExperimentSummaryFile <- paste( 
      experimentAccession,
      "-atlasExperimentSummary.Rdata", 
      sep = "" 
    )
    
    # Create full path to download R data from.
    fullPath <- paste( 
      ATLAS_EXPS, 
      experimentAccession, 
      atlasExperimentSummaryFile, 
      sep = "/" 
    )
    
    message( 
      paste( 
        "Getting Expression Atlas experiment summary from:\n", 
        fullPath
      ) 
    )
  
  # Try download, catching any errors
  loadResult <- try( load( fullPath ), silent = TRUE )
  
  # Quit if we got an error.
  if( class( loadResult ) == "try-error" ) {
    msg <- geterrmessage()
    
    warning( 
      paste( 
        paste( 
          "Error encountered while trying to load experiment summary for",
          experimentAccession,
          ":"
        ),
        msg,
      )
    )
      return( )
  }
  
  # Make sure experiment summary object exists before trying to return it.
  getResult <- try( get( "experimentSummary" ) )
  
  if( class( getResult ) == "try-error" ) {
    
    stop( 
      "ERROR - Loading appeared successful but no experiment summary object was found." 
    )
  }
  
  # If we're still here, things must have worked ok.
  message( 
    paste( 
      "Successfully loaded experiment summary object for", 
      experimentAccession
    ) 
  )
  
  # Return the experiment summary.
  expSum <- get( "experimentSummary" )
  
  return( expSum )
}
  
# .isValidExperimentAccession
#   - Return TRUE if experiment accession matches expected ArrayExpress
#   experiment accession pattern. Return FALSE otherwise.
.isValidExperimentAccession <- function( experimentAccession ) {
  
  if( missing( experimentAccession ) ) {
    
    warning( "Accession missing. Cannot validate." )
    
    return( FALSE )
  }
  
  if( !grepl( "^E-\\w{4}-\\d+$", experimentAccession ) ) {
    
    warning( 
      paste( 
        "\"", 
        experimentAccession, 
        "\" does not look like an ArrayExpress experiment accession. Please check.", 
        sep="" 
      ) 
    )
    
    return( FALSE )
    
  } else {
    
    return( TRUE )
  }
}


# getAtlasData
#   - Download SimpleList objects for one or more Expression Atlas experiments
#   and return then in a list.
getAtlasData <- function( experimentAccessions ) {
  
  if( missing( experimentAccessions ) ) {
    
    stop( "Please provide a vector of experiment accessions to download." )
  }
  
  # Make sure experimentAccessions is a vector.
  if( ! is.vector( experimentAccessions ) ) {
    
    stop( "Please provide experiment accessions as a vector." )
  }
  
  # Only use valid accessions to download.
  experimentAccessions <- experimentAccessions[ 
    which( 
      sapply( 
        experimentAccessions, function( accession ) {
          .isValidExperimentAccession( accession )
        }
      )
    )
    ]
  
  # The experimentAccessions vector is empty if none of the accessions are
  # valid. Just quit here if so.
  if( length( experimentAccessions ) == 0 ) {
    stop( "None of the accessions passed are valid ArrayExpress accessions. Cannot continue." )
  }
  
  # Go through each one and download it, creating a list.
  # So that the list has the experiment accessions as the names, use them as
  # names for the vector before starting to create the list.
  names( experimentAccessions ) <- experimentAccessions
  
  experimentSummaryList <- SimpleList( 
    
    lapply( experimentAccessions, function( experimentAccession ) {
      
      experimentSummary <- getAtlasExperiment( experimentAccession )
    } 
    ) )
  
  # Remove any null entries, i.e. experiments without R data files available.
  experimentSummaryList <- experimentSummaryList[ ! sapply( experimentSummaryList, is.null ) ]
  
  return( experimentSummaryList )
}