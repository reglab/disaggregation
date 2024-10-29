library(tidyverse)

name_weighting <- function(name_table, 
                           type,
                           fractional = F,
                           min_n=2,
                           us_weight=T){
  
  name_prior <- 
    name_table %>% 
    select(-subgroup) %>% 
    distinct() %>%
    group_by(name) %>% 
    count() 
  
  if (type == "surname"){
    
    name_set1 <- name_prior %>% 
      inner_join(L2_p_race_given_surname, by=c("name"))
    
  } else {
    
    name_set1 <- name_prior %>% 
      inner_join(L2_p_race_given_firstname, by=c("name"))
    
  }
  
  # filter out names that with total frequency <= 2 (across all groups)
  name_set2 <- 
    name_prior %>% 
    anti_join(name_set1, by="name") %>% 
    filter(n >= min_n, name != "") %>% 
    select(name)

  name_prior <- bind_rows(name_set1 %>% select(name), name_set2)
  
  name_prior_clean <- 
    name_table %>% 
    inner_join(name_prior, by="name") %>% 
    distinct()
  
  if(fractional){
    
    name_prior_clean <- 
      name_prior_clean %>% 
      group_by(fullname) %>% 
      mutate(weight = 1/n()) %>% 
      group_by(name, subgroup) %>% 
      summarize(n = sum(weight)) 
    
  } else {
    
    name_prior_clean <- 
      name_prior_clean %>% 
      group_by(subgroup) %>% 
      mutate(
        person_count = length(unique(fullname))
      ) %>% 
      group_by(name, subgroup) %>% 
      summarize(
        n = n()/first(person_count)
      ) %>% 
      ungroup()
    
  }
  
  if (us_weight){
    name_prior_clean <- 
      name_prior_clean %>% 
      left_join(asian_pop_rescale, by="subgroup") %>% 
      mutate(n = n * share)
  }
  
  final_results <- name_prior_clean %>% 
    pivot_wider(
      id_cols = name, 
      names_from = subgroup, 
      values_from = n
    ) %>% 
    ungroup() %>% 
    mutate(
      across(-name, ~replace_na(.x, 0))
    ) %>% 
    select(name, order(colnames(.)))
  
  return(final_results)
}

name_weighting_ipums <- function(name_table, 
                           type,
                           fractional = F,
                           min_n=2,
                           us_weight=T){
  
  name_prior <- 
    name_table %>% 
    select(-subgroup) %>% 
    distinct() %>%
    group_by(name) %>% 
    count() 
  
  if (type == "surname"){
    
    name_set1 <- name_prior %>% 
      inner_join(L2_p_race_given_surname, by=c("name"))
    
  } else {
    
    name_set1 <- name_prior %>% 
      inner_join(L2_p_race_given_firstname, by=c("name"))
    
  }
  
  # filter out names that with total frequency <= 2 (across all groups)
  name_set2 <- 
    name_prior %>% 
    anti_join(name_set1, by="name") %>% 
    filter(n >= min_n, name != "") %>% 
    select(name)
  
  name_prior <- bind_rows(name_set1 %>% select(name), name_set2)
  
  name_prior_clean <- 
    name_table %>% 
    inner_join(name_prior, by="name") %>% 
    distinct()
  
  name_prior_clean <- 
    name_prior_clean %>% 
    group_by(name, subgroup) %>% 
    summarize(n = sum(PERWT)) 
  
  final_results <- name_prior_clean %>% 
    pivot_wider(
      id_cols = name, 
      names_from = subgroup, 
      values_from = n
    ) %>% 
    ungroup() %>% 
    mutate(
      across(-name, ~replace_na(.x, 0))
    ) %>% 
    select(name, order(colnames(.)))
  
  return(final_results)
}