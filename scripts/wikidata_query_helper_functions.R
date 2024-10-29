library(WikidataQueryServiceR)
library(stringr)
library(dplyr)

run_wiki_pipeline <- function(subgroup, data_path){
  label <- subgroup[["subgroup_label"]]
  query <- subgroup[["query"]] %>% 
    paste(collapse="\n") 
  
  filename <- paste0(label, ".rds")
  save_path <- paste(data_path, "raw_wikidata", filename, sep = "/")
  
  year_range <- seq(1800, 2020, 5)
  
  results <- map_dfr(.x=year_range, ~run_wqs_api(label, query, .x), 
                     .progress=T) %>% 
    mutate(subgroup = label) %>% 
    distinct()
  
  saveRDS(results, save_path)
}

run_wqs_api <- function(label, query, start){
  end <- start + 4
  wqs_query <- create_query(query, start, end)
  
  result <- tryCatch(
    query_wikidata(wqs_query),
    error = function(e){
      message(paste("Query failed for ", start, " to ", end))
      message("Query year by year")
      map_dfr(
        start:end, function(year){
          wqs_query <- create_query(query, year, year)
          result <- query_wikidata(wqs_query) %>%
            mutate(dobLabel = as.Date(dobLabel))
          return(wqs_query)
        }
      )
    }
  )
  
  result <- result %>% mutate(dobLabel = as.Date(dobLabel))
  return(result)
}

create_query <- function(query, start, end){
  
  full_query <- 
    paste0(
      'SELECT DISTINCT ?fullname ?fullnameLabel ?surnameLabel ?firstnameLabel ?dobLabel ?citizenshipLabel ?birthplaceLabel ?raceLabel ?article
WHERE {
  ?fullname wdt:P31 wd:Q5 .
  ?fullname wdt:P569 ?dob .
  FILTER(YEAR(?dob) >= ', start,' && YEAR(?dob) <= ',end,')
  ', query, '
  OPTIONAL { ?fullname wdt:P734 ?surname }
  OPTIONAL { ?fullname wdt:P735 ?firstname }
  OPTIONAL { ?fullname wdt:P569 ?dob }
  OPTIONAL { ?fullname wdt:P27 $citizenship }
  OPTIONAL { ?fullname wdt:P19/wdt:P17 $birthplace }
  OPTIONAL { ?fullname wdt:P172 ?race }
  OPTIONAL {
    ?article schema:about ?fullname .
    ?article schema:inLanguage "en" .
    ?article schema:isPartOf <https://en.wikipedia.org/> .
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" . }
}'
    )
  
  return(full_query)
}