library(dplyr)
library(stringr)
library(mltest)
library(tidymodels)
library(probably)
library(ggplot2)

predict_disagg_race <- function(df, firstname=F, ssa=F, geo = "county"){
  
  if(ssa){
    p_race_given_surname <- ssa_p_race_given_surname
  }
  
  race_var <- p_race_given_surname %>% select(-name) %>% names()
  
  if(geo == "tract"){
    p_race_given_geo <- geo_race_table_lst$p_race_given_tract %>% 
      bind_rows(geo_race_table_lst$p_race_given_us)
    p_geo_given_race <- geo_race_table_lst$p_tract_given_race %>% 
      bind_rows(geo_race_table_lst$p_us_given_race)
    
    df <- df %>% 
      mutate(
        GEOID = ifelse(
          tract %in% p_geo_given_race$GEOID,
          tract,
          "1"
        )
      ) %>% 
      select(-state,-county,-zip,-tract)
  }
  if(geo == "zip"){
    p_race_given_geo <- geo_race_table_lst$p_race_given_zcta %>% 
      bind_rows(geo_race_table_lst$p_race_given_us)
    p_geo_given_race <- geo_race_table_lst$p_zcta_given_race %>% 
      bind_rows(geo_race_table_lst$p_us_given_race)
    
    df <- df %>% 
      mutate(
        GEOID = ifelse(
          zip %in% p_geo_given_race$GEOID,
          zip,
          "1"
        )
      ) %>% 
      select(-state,-county,-zip,-tract)
  }
  if(geo == "county"){
    p_race_given_geo <- geo_race_table_lst$p_race_given_county %>% 
      bind_rows(geo_race_table_lst$p_race_given_us)
    p_geo_given_race <- geo_race_table_lst$p_county_given_race %>% 
      bind_rows(geo_race_table_lst$p_us_given_race)
    
    df <- df %>% 
      mutate(
        GEOID = ifelse(
          county %in% p_geo_given_race$GEOID,
          county,
          "1"
        )
      ) %>% 
      select(-state,-county,-zip,-tract)
  }
  if(geo == "state"){
    p_race_given_geo <- geo_race_table_lst$p_race_given_state %>% 
      bind_rows(geo_race_table_lst$p_race_given_us)
    p_geo_given_race <- geo_race_table_lst$p_state_given_race %>% 
      bind_rows(geo_race_table_lst$p_us_given_race)
    
    df <- df %>% 
      mutate(
        GEOID = ifelse(
          state %in% p_geo_given_race$GEOID,
          state,
          "1"
        )
      ) %>% 
      select(-state,-county,-zip,-tract)
  }

  df1 <- df %>%
    inner_join(p_race_given_surname, by=c("surname"="name"))
  
  df1_posteriors <- NULL
  
  if (nrow(df1) > 0){
    priors <- df1 %>%
      select(all_of(race_var))
    
    update <- df1 %>% 
      select(GEOID) %>% 
      left_join(p_geo_given_race, by="GEOID") %>%
      mutate(across(
        everything(),
        ~replace_na(.,1)
      )) %>% 
      select(all_of(race_var))
    post <- priors * update
    
    df1_posteriors <- cbind(
      df1 %>% select(patientuid),
      post
    ) 
  }
  
  if (firstname & ssa){
    df3 <- df %>%
      anti_join(p_race_given_surname, by=c("surname"="name")) %>% 
      inner_join(ssa_p_race_given_surname, by=c("firstname"="name"))
    
    if (nrow(df3) > 0){
      df1_posteriors <- df1_posteriors %>% 
        rbind(df3 %>% select(patientuid,all_of(race_var)))
      
      df2 <- df %>% 
        filter(!patientuid %in% df1_posteriors$patientuid)
    }
  } else {
    df2 <- df %>%
      anti_join(p_race_given_surname, by=c("surname"="name"))
  }
  
  df2_posteriors <- NULL
  if (nrow(df2) > 0){
    priors <- df2 %>%
      select(GEOID) %>% 
      left_join(p_race_given_geo, by="GEOID") %>%
      select(all_of(race_var))
    
    df2_posteriors <- cbind(
      df2 %>% select(patientuid),
      priors
    )
  }
  
  post_combined <- rbind(df1_posteriors, df2_posteriors) 
  
  if (firstname & !ssa){
    
    firstname_update <- df %>% 
      left_join(p_firstname_given_race,
                by=c("firstname"="name")) %>%
      distinct() %>% 
      left_join(post_combined %>% select(patientuid), ., 
                 by="patientuid") %>% 
      select(all_of(race_var)) %>%
      mutate(
        across(everything(), ~replace_na(.,1))
      )
    
    total_prior <- select(post_combined, all_of(race_var))
    
    post_firstname <- total_prior * firstname_update
    post_firstname_normalized <- post_firstname / rowSums(post_firstname)
    
    temp <- cbind(
      post_combined %>% select(patientuid),
      post_firstname_normalized
    )
    
    temp1 <- temp %>% 
      filter(across(all_of(race_var), ~!is.na(.)))
    
    post_combined <- rbind(
      post_combined %>% filter(!patientuid %in% temp1$patientuid),
      temp1
    )
  }
  
  df_posteriors <- post_combined %>%
    mutate(sum_to_adjust = rowSums(select(., -c(patientuid)))) %>%
    mutate(across(-c(patientuid,-sum_to_adjust), ~./sum_to_adjust)) %>%
    select(-sum_to_adjust) %>% 
    mutate(across(-patientuid,~replace_na(.,0)))
  
  return(df_posteriors)
}

calculate_pr <- function(df, method){
  
  race_vars <- unique(df$raceeth)
  
  df_pr <- df %>%
    mutate(raceeth = raceeth %>% factor(levels = race_vars)) %>%
    pr_curve(raceeth, all_of(race_vars)) %>%
    mutate(Method=method) %>%
    rename(race=.level)
  
  df_pr_custom <- race_vars %>% 
    map_dfr(function(raceeth){
      
      seq(0.01,1,0.01) %>% 
        map_dfr(function(budget){
          
          temp <- df_pr %>% 
            filter(race == raceeth) %>% 
            filter(recall >= budget) %>% 
            head(1)
          
          result <- df %>% 
            filter(get({{raceeth}}) >= temp$`.threshold`) %>% 
            slice_sample(n = round(nrow(df)*budget), replace = F)
          
          data.frame(
            race = raceeth,
            recall = budget,
            precision = sum(result$raceeth == raceeth, na.rm=T)/nrow(result),
            Method = method
          )
          
        })
      
    })
  
  return(df_pr_custom)
}

bootstrap_afc <- function(patient_df, seed, geography = "county"){
  
  set.seed(seed) 
  b_patient_df <- patient_df %>% 
    slice_sample(n = nrow(.), replace = T)
  
  method_lst <- c("SSA","BISG","Hybrid")
  
  ssa_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = F, ssa = T, geo = geography) %>% 
    left_join(
      patients_categorized %>% 
        select(patientuid, raceeth, category),
      by="patientuid"
    )
  
  bisg_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = F, geo = geography) %>% 
    left_join(
      patients_categorized %>% 
        select(patientuid, raceeth, category),
      by="patientuid"
    )
  
  hybrid_post <- ssa_post %>% 
    filter(category %in% c("ssa only","wiki only")) %>% 
    rbind(
      bisg_post %>% 
        filter(!category %in% c("ssa only","wiki only"))
    )
  
  prob_result_lst <- list(
    "ssa_post" = ssa_post,
    "bisg_post" = bisg_post,
    "hybrid_post" = hybrid_post
  )
  
  pr_lst <- map2_dfr(
    prob_result_lst,
    method_lst, 
    calculate_pr
  ) %>% 
    mutate(sample = seed) %>% 
    rename(x = recall, y = precision) %>% 
    mutate(race = recode(race, !!!unlist(clean_group_names)))
  
  return(pr_lst)
}

bootstrap_afc_bisg <- function(patient_df, seed, geography = "county"){
  
  set.seed(seed) 
  b_patient_df <- patient_df %>% 
    slice_sample(n = nrow(.), replace = T)
  
  method_lst <- c("BISG")
  
  bisg_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = F, geo = geography) %>% 
    left_join(
      asian_patients %>% 
        select(patientuid, raceeth),
      by="patientuid"
    )
  
  prob_result_lst <- list(
    "bisg_post" = bisg_post
  )
  
  pr_lst <- map2_dfr(
    prob_result_lst,
    method_lst, 
    calculate_pr
  ) %>% 
    mutate(sample = seed) %>% 
    rename(x = recall, y = precision) %>% 
    mutate(race = recode(race, !!!unlist(clean_group_names)))
  
  return(pr_lst)
}

bootstrap_afc_bifsg <- function(patient_df, seed, geography = "county"){
  
  set.seed(seed) 
  b_patient_df <- patient_df %>% 
    slice_sample(n = nrow(.), replace = T)
  
  method_lst <- c("SSA with firstname","BIFSG")
  
  ssaf_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = T, ssa = T, geo = geography) %>% 
    left_join(
      asian_patients %>% 
        select(patientuid, raceeth),
      by="patientuid"
    )
  
  bifsg_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = T, geo = geography) %>% 
    left_join(
      asian_patients %>% 
        select(patientuid, raceeth),
      by="patientuid"
    )
  
  prob_result_lst <- list(
    "ssaf_post" = ssaf_post,
    "bifsg_post" = bifsg_post
  )
  
  pr_lst <- map2_dfr(
    prob_result_lst,
    method_lst, 
    calculate_pr
  ) %>% 
    mutate(sample = seed) %>% 
    rename(x = recall, y = precision) %>% 
    mutate(race = recode(race, !!!unlist(clean_group_names)))
  
  return(pr_lst)
}

bootstrap_afc_balanced <- function(patient_df, seed, geography = "county"){
  
  set.seed(seed) 
  b_patient_df <- rbind(
    patient_df %>% 
      filter(raceeth == "asian_indian") %>% 
      slice_sample(n = 5490, replace = T),
    patient_df %>% 
      filter(raceeth == "chinese") %>% 
      slice_sample(n = 5619, replace = T),
    patient_df %>% 
      filter(raceeth == "filipino") %>% 
      slice_sample(n = 3706, replace = T),
    patient_df %>% 
      filter(raceeth == "japanese") %>% 
      slice_sample(n = 958, replace = T),
    patient_df %>% 
      filter(raceeth == "korean") %>% 
      slice_sample(n = 1860, replace = T),
    patient_df %>% 
      filter(raceeth == "vietnamese") %>% 
      slice_sample(n = 2367, replace = T)
  )
  
  method_lst <- c("SSA","BISG","Hybrid")
  
  ssa_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = F, ssa = T, geo = geography) %>% 
    left_join(
      patients_categorized %>% 
        select(patientuid, raceeth, category),
      by="patientuid"
    )
  
  bisg_post <- b_patient_df %>% 
    select(patientuid, firstname, surname, state, county, zip, tract) %>% 
    predict_disagg_race(firstname = F, geo = geography) %>% 
    left_join(
      patients_categorized %>% 
        select(patientuid, raceeth, category),
      by="patientuid"
    )
  
  hybrid_post <- ssa_post %>% 
    filter(category %in% c("ssa only","wiki only")) %>% 
    rbind(
      bisg_post %>% 
        filter(!category %in% c("ssa only","wiki only"))
    )
  
  prob_result_lst <- list(
    "ssa_post" = ssa_post,
    "bisg_post" = bisg_post,
    "hybrid_post" = hybrid_post
  )
  
  pr_lst <- map2_dfr(
    prob_result_lst,
    method_lst, 
    calculate_pr
  ) %>% 
    mutate(sample = seed) %>% 
    rename(x = recall, y = precision) %>% 
    mutate(race = recode(race, !!!unlist(clean_group_names)))
  
  return(pr_lst)
}