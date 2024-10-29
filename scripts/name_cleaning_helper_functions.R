library(stringi)
library(dplyr)

# a helper function that pre-processes the name
str_format_removal <- function(text){
  
  clean_text <- text %>% 
    as.character() %>% 
    stri_trans_general("Latin-ASCII") %>% # convert latin characters to ascii
    toupper() %>% # convert to uppercase
    str_replace_all("[^a-zA-Z ]"," ") %>% # keep only alphabet, space
    str_remove_all("\\b[A-Za-z]\\b\\s*") %>% # remove standalone characters
    str_squish() %>% # removing leading and trailing spaces
    ifelse(.=="",NA,.) 
  
  return(clean_text)
}