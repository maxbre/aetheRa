#' Get all available sounding stations in dataset
#' @description Query the NOAA radiosonde database and create a data frame object that contains a current listing of all sounding stations for which data is available.
#' @export get_sounding_stations
#' @examples
#' \dontrun{
#' # Get the current listing of global soundings as a data frame
#' all_soundings <- get_sounding_stations()
#'}

get_sounding_stations <- function(){
  
  # Include require statements
  require(RCurl)
  require(stringr)
  
  # Obtain the HTML source from a URI containing a query
  URI <- getURL(paste("http://www.esrl.noaa.gov/raobs/intl/GetRaobs.cgi?",
                      "shour=All+Times&ltype=All+Levels&wunits=Tenths+of+Meters%2FSecond",
                      "&bdate=1990010100&edate=2013122523&access=All+Sites&view=YES&",
                      "osort=Station+Series+Sort&oformat=FSL+format+%28ASCII+text%29",
                      sep = ''))
  
  if(grepl("Service Temporarily Unavailable", URI) == TRUE) {
    stop("The NOAA DB server is reporting that it's temporarily unavailable.")
  }
  
  # Create a 'pattern' string object cdontaining the regex pattern for extracting
  # sounding data strings from the URI
  pattern <- paste("<OPTION> [0-9A-Z]*[ ]*[0-9]* [0-9]{5} [0-9/.-]*",
                   "[0-9/.-]* [0-9-]{5,6}  [.]*  [0-9A-Z]{2} [0-9A-Z]{2}",
                   sep = '')
  
  # Generate vector list of strings from URI page source
  lines <- gsub(pattern = pattern, replacement = "\\1", x = URI)
  lines <- gsub(pattern = ".*MULTIPLE SIZE=\"10\">\n", replacement = "", x = lines)
  lines <- gsub(pattern = "\n\n</SELECT>.*", replacement = "", x = lines)
  lines <- gsub(pattern = "<OPTION> ", replacement = "", x = lines)
  lines <- str_split(lines, "\n\n")
  lines <- unlist(lines)
  
  # Initialize the data objects
  # Loop through list of strings, extract and clean the substrings corresponding to data elements
  # Create a data frame with vector lists and coerce some objects into numeric objects
  for (i in 1:length(lines)){
    if (i == 1) {
      init <- mat.or.vec(nr = length(lines), nc = 1)
      wban <- mat.or.vec(nr = length(lines), nc = 1)
      wmo <- mat.or.vec(nr = length(lines), nc = 1)
      lat <- mat.or.vec(nr = length(lines), nc = 1)
      lon <- mat.or.vec(nr = length(lines), nc = 1)
      elev <- mat.or.vec(nr = length(lines), nc = 1)
      station_name <- mat.or.vec(nr = length(lines), nc = 1)
      prov_state <- mat.or.vec(nr = length(lines), nc = 1)
      country <- mat.or.vec(nr = length(lines), nc = 1)
    }
    init[i] <- 
      str_match(string = lines[i],
                pattern = "^([0-9A-Z]*)")[1,2]
    wban[i] <- 
      str_match(string = lines[i],
                pattern = "^[0-9A-Z]+[ ]+([0-9]*)")[1,2]
    wmo[i] <- 
      str_match(string = lines[i],
                pattern = "^[0-9A-Z]+[ ]+[0-9]* ([0-9]{5})")[1,2]
    lat[i] <- 
      as.numeric(str_match(string = lines[i],
                           pattern = paste("^[0-9A-Z]+[ ]+[0-9]* ",
                                           "[0-9]{5} ([0-9/.-]*)", sep = ''))[1,2])
    lon[i] <- 
      as.numeric(str_match(string = lines[i],
                           pattern = paste("^[0-9A-Z]+[ ]+[0-9]* [0-9]{5} ",
                                           "[0-9/.-]* ([0-9/.-]*)", sep = ''))[1,2])
    elev[i] <- 
      as.numeric(str_match(string = lines[i],
                           pattern = paste("^[0-9A-Z]+[ ]+[0-9]* ",
                                           "[0-9]{5} [0-9/.-]* [0-9/.-]* ",
                                           "([0-9-]{5,6})", sep = ''))[1,2])
    station_name[i] <- 
      str_trim(str_match(string = lines[i],
                         pattern = paste("^[0-9A-Z]+[ ]+[0-9]* ",
                                         "[0-9]{5} [0-9/.-]* [0-9/.-]* ",
                                         "[0-9-]{5,6}  (.+) [0-9A-Z]{2} ",
                                         "[0-9A-Z]{2}$", sep = ''))[1,2],
               side = "both")
    prov_state[i] <- 
      str_match(string = lines[i],
                pattern = paste("^[0-9A-Z]+[ ]+[0-9]* ",
                                "[0-9]{5} [0-9/.-]* [0-9/.-]* ",
                                "[0-9-]{5,6}  .+ ([0-9A-Z]{2}) ",
                                "[0-9A-Z]{2}$", sep = ''))[1,2]
    country[i] <- 
      str_match(string = lines[i],
                pattern = paste("^[0-9A-Z]+[ ]+[0-9]* ",
                                "[0-9]{5} [0-9/.-]* [0-9/.-]* ",
                                "[0-9-]{5,6}  .+ [0-9A-Z]{2} ",
                                "([0-9A-Z]{2})$", sep = ''))[1,2]
    
    if (i == length(lines)) {
      # Create data frame with vector objects of equal length 
      df_soundings <- as.data.frame(cbind(init, wban, wmo, lat, lon,
                                          elev, station_name, prov_state,
                                          country), stringsAsFactors = FALSE)
      
      # Change object class for lat, lon, and elev in 'df_soundings' data frame
      df_soundings[,4] <- as.numeric(df_soundings[,4])
      df_soundings[,5] <- as.numeric(df_soundings[,5])
      df_soundings[,6] <- as.numeric(df_soundings[,6])
      
      # Remove objects from global environment
      rm(i, init, wban, wmo, lat, lon, elev, station_name, prov_state,
         country, URI, pattern, lines)
    }
  }
  
  # Return object
  return(df_soundings)
  
}
