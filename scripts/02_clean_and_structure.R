# =============================================================================
# 02_clean_and_structure.R
# Hotel Guest Satisfaction & Review Analytics - Data Cleaning & Structuring
#
# Reads the messy review export, cleans and transforms the data,
# then exports structured tables for analysis.
# =============================================================================

library(tidyverse)
library(lubridate)

cat("=" |> strrep(60), "\n")
cat("HOTEL GUEST ANALYTICS - DATA CLEANING\n")
cat("=" |> strrep(60), "\n\n")

# =============================================================================
# EXTRACT
# =============================================================================

cat("PHASE 1: EXTRACT\n")
cat("-" |> strrep(40), "\n")

raw_data <- read_csv("data/raw/hotel_reviews_raw.csv",
                      show_col_types = FALSE)

cat("Raw records loaded:", nrow(raw_data), "\n")
cat("Columns:", ncol(raw_data), "\n\n")

# =============================================================================
# TRANSFORM
# =============================================================================

cat("PHASE 2: TRANSFORM\n")
cat("-" |> strrep(40), "\n")

# --- Step 1: Remove duplicates -----------------------------------------------
n_before <- nrow(raw_data)
clean_data <- raw_data %>% distinct()
n_after <- nrow(clean_data)
cat("Duplicates removed:", n_before - n_after, "\n")

# --- Step 2: Clean text fields -----------------------------------------------

clean_data <- clean_data %>%
  mutate(
    across(where(is.character), str_trim),
    guest_name = str_to_title(guest_name),
    room_type = str_to_title(room_type),
    trip_type = str_to_title(trip_type),
    would_recommend = str_to_title(would_recommend)
  )

cat("Text fields cleaned (trimmed, standardized casing)\n")

# --- Step 3: Parse dates ------------------------------------------------------

parse_mixed_date <- function(date_str) {
  parsed <- parse_date_time(date_str, orders = c("ymd", "mdy"), quiet = TRUE)
  as.Date(parsed)
}

clean_data <- clean_data %>%
  mutate(
    stay_date = parse_mixed_date(stay_date),
    review_date = parse_mixed_date(review_date)
  )

cat("Dates parsed (handled YYYY-MM-DD and MM/DD/YYYY formats)\n")

# --- Step 4: Handle missing values --------------------------------------------

# Missing loyalty_tier -> "None"
n_loyalty_na <- sum(is.na(clean_data$loyalty_tier))
clean_data <- clean_data %>%
  mutate(loyalty_tier = replace_na(loyalty_tier, "None"))
cat("Missing loyalty_tier replaced with 'None':", n_loyalty_na, "values\n")

# Missing sub-ratings -> impute from overall rating
n_clean_na <- sum(is.na(clean_data$rating_cleanliness))
n_food_na <- sum(is.na(clean_data$rating_food))
n_value_na <- sum(is.na(clean_data$rating_value))

clean_data <- clean_data %>%
  mutate(
    rating_cleanliness = if_else(is.na(rating_cleanliness),
                                 rating_overall, rating_cleanliness),
    rating_food = if_else(is.na(rating_food),
                          rating_overall, rating_food),
    rating_value = if_else(is.na(rating_value),
                           rating_overall, rating_value)
  )

cat("Missing sub-ratings imputed from overall:",
    n_clean_na + n_food_na + n_value_na, "total values\n")

# --- Step 5: Add derived columns ----------------------------------------------

clean_data <- clean_data %>%
  mutate(
    # Month and quarter from stay date
    stay_month = month(stay_date),
    stay_month_name = month(stay_date, label = TRUE, abbr = FALSE),
    stay_quarter = paste0("Q", quarter(stay_date)),
    season = case_when(
      stay_month %in% c(12, 1, 2)  ~ "Winter",
      stay_month %in% c(3, 4, 5)   ~ "Spring",
      stay_month %in% c(6, 7, 8)   ~ "Summer",
      stay_month %in% c(9, 10, 11) ~ "Fall"
    ),
    # Is weekend stay
    is_weekend = wday(stay_date) %in% c(1, 7),
    # Average sub-rating
    avg_sub_rating = round((rating_cleanliness + rating_service +
                             rating_location + rating_value + rating_food) / 5, 2),
    # NPS category based on overall rating (1-10 scale)
    nps_category = case_when(
      rating_overall >= 9  ~ "Promoter",
      rating_overall >= 7  ~ "Passive",
      TRUE                 ~ "Detractor"
    ),
    # Response speed category
    response_category = case_when(
      is.na(response_time_hours) ~ "No Response",
      response_time_hours <= 6   ~ "Fast (0-6h)",
      response_time_hours <= 24  ~ "Same Day (6-24h)",
      response_time_hours <= 48  ~ "Next Day (24-48h)",
      TRUE                       ~ "Slow (48h+)"
    ),
    # Days between stay and review
    review_lag_days = as.integer(review_date - stay_date)
  )

cat("Derived columns added (month, quarter, season, NPS category, etc.)\n")

# --- Step 6: Validate ---------------------------------------------------------

clean_data <- clean_data %>%
  filter(
    rating_overall >= 1, rating_overall <= 10,
    nights_stayed >= 1,
    !is.na(stay_date)
  )

cat("\nCleaned records:", nrow(clean_data), "\n")

# =============================================================================
# EXPORT
# =============================================================================

cat("\nPHASE 3: EXPORT\n")
cat("-" |> strrep(40), "\n")

write_csv(clean_data, "data/processed/reviews_cleaned.csv")
cat("Cleaned reviews exported to data/processed/reviews_cleaned.csv\n")

# Summary table by month
monthly_summary <- clean_data %>%
  group_by(stay_month, stay_month_name) %>%
  summarise(
    total_reviews = n(),
    avg_overall = round(mean(rating_overall), 2),
    avg_cleanliness = round(mean(rating_cleanliness), 2),
    avg_service = round(mean(rating_service), 2),
    avg_location = round(mean(rating_location), 2),
    avg_value = round(mean(rating_value), 2),
    avg_food = round(mean(rating_food), 2),
    pct_promoter = round(sum(nps_category == "Promoter") / n() * 100, 1),
    pct_detractor = round(sum(nps_category == "Detractor") / n() * 100, 1),
    nps_score = round(pct_promoter - pct_detractor, 1),
    .groups = "drop"
  )

write_csv(monthly_summary, "data/processed/monthly_summary.csv")
cat("Monthly summary exported\n")

# Summary by channel
channel_summary <- clean_data %>%
  group_by(booking_channel) %>%
  summarise(
    reviews = n(),
    avg_rating = round(mean(rating_overall), 2),
    pct_promoter = round(sum(nps_category == "Promoter") / n() * 100, 1),
    pct_detractor = round(sum(nps_category == "Detractor") / n() * 100, 1),
    nps_score = round(pct_promoter - pct_detractor, 1),
    avg_response_hrs = round(mean(response_time_hours, na.rm = TRUE), 1),
    .groups = "drop"
  )

write_csv(channel_summary, "data/processed/channel_summary.csv")
cat("Channel summary exported\n")

# Summary by loyalty tier
loyalty_summary <- clean_data %>%
  group_by(loyalty_tier) %>%
  summarise(
    reviews = n(),
    avg_rating = round(mean(rating_overall), 2),
    avg_nights = round(mean(nights_stayed), 2),
    pct_promoter = round(sum(nps_category == "Promoter") / n() * 100, 1),
    nps_score = round(
      sum(nps_category == "Promoter") / n() * 100 -
      sum(nps_category == "Detractor") / n() * 100, 1),
    .groups = "drop"
  )

write_csv(loyalty_summary, "data/processed/loyalty_summary.csv")
cat("Loyalty summary exported\n")

# --- Final Summary -----------------------------------------------------------

cat("\n")
cat("=" |> strrep(60), "\n")
cat("DATA CLEANING COMPLETE\n")
cat("=" |> strrep(60), "\n")
cat("\nRecords: ", nrow(clean_data), "\n")
cat("Date range:", as.character(min(clean_data$stay_date)),
    "to", as.character(max(clean_data$stay_date)), "\n")
cat("Avg overall rating:", round(mean(clean_data$rating_overall), 2), "\n")
cat("NPS Score:", round(
  sum(clean_data$nps_category == "Promoter") / nrow(clean_data) * 100 -
  sum(clean_data$nps_category == "Detractor") / nrow(clean_data) * 100, 1), "\n")
