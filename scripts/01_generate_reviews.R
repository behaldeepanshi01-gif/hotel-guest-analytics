# =============================================================================
# 01_generate_reviews.R
# Hotel Guest Satisfaction & Review Analytics - Dataset Generation
#
# Generates ~2,000 simulated guest reviews for a 250-room DC hotel.
# Reviews include numeric ratings, free-text comments mentioning specific
# hotel departments, and NPS-style recommendation data.
# Includes deliberate data quality issues for ETL demonstration.
# =============================================================================

library(tidyverse)
library(lubridate)

set.seed(515)

# --- Configuration -----------------------------------------------------------

n_reviews <- 2000

# Room types
room_types <- c("Standard Queen", "King Room", "Double Queen",
                "Junior Suite", "Executive Suite")

# Trip types
trip_types <- c("Business", "Leisure", "Family", "Couple", "Solo")
trip_weights <- c(0.30, 0.25, 0.20, 0.15, 0.10)

# Booking channels
channels <- c("Direct Website", "Expedia", "Booking.com", "TripAdvisor",
              "Phone", "Travel Agent", "Group")
channel_weights <- c(0.22, 0.18, 0.16, 0.10, 0.12, 0.10, 0.12)

# Loyalty tiers
loyalty_tiers <- c("Diamond", "Gold", "Silver", "Blue", "None")
loyalty_weights <- c(0.08, 0.15, 0.20, 0.25, 0.32)

# --- Review Text Templates ----------------------------------------------------

# Positive department mentions
positive_front_desk <- c(
  "Check-in was smooth and the front desk staff were very welcoming.",
  "The receptionist upgraded our room which was a lovely surprise.",
  "Front desk handled our late check-out request perfectly.",
  "Staff at the front desk were friendly and professional.",
  "Excellent service at reception, they remembered our name."
)

positive_housekeeping <- c(
  "Room was spotless and housekeeping did an outstanding job.",
  "Loved the turn-down service, towels were always fresh.",
  "The room was impeccably clean every single day.",
  "Housekeeping was prompt and thorough throughout our stay.",
  "Bathroom was sparkling clean, great attention to detail."
)

positive_fnb <- c(
  "Breakfast buffet was excellent with a great variety.",
  "The restaurant served amazing food, especially the brunch.",
  "Room service was quick and the food was delicious.",
  "Loved the lobby bar, cocktails were fantastic.",
  "Great dining options, the chef really knows what they're doing."
)

positive_amenities <- c(
  "The pool area was beautiful and well maintained.",
  "Gym was well equipped and open 24 hours which was perfect.",
  "Spa experience was world class, highly recommend.",
  "The business center had everything I needed for work.",
  "WiFi was fast and reliable throughout the hotel."
)

positive_location <- c(
  "Perfect location, walking distance to the National Mall.",
  "Great location near Metro, very convenient for sightseeing.",
  "Loved being so close to all the DC attractions.",
  "Location was unbeatable, right in the heart of the city.",
  "Easy access to restaurants and shops nearby."
)

# Negative department mentions
negative_front_desk <- c(
  "Long wait at check-in, only one person at the front desk.",
  "Front desk staff seemed uninterested and unhelpful.",
  "Had issues with our reservation and nobody could resolve it.",
  "The check-in process took over 30 minutes which was frustrating.",
  "Front desk gave us wrong room keys twice."
)

negative_housekeeping <- c(
  "Room wasn't cleaned properly, found hair in the bathroom.",
  "Housekeeping skipped our room two days in a row.",
  "Stains on the bedsheets that were clearly not fresh.",
  "Bathroom wasn't cleaned and trash was overflowing.",
  "Towels were not replaced despite putting them on the floor."
)

negative_fnb <- c(
  "Breakfast was disappointing, very limited options.",
  "Restaurant was overpriced for the quality of food.",
  "Room service took over an hour to arrive and food was cold.",
  "The bar closed too early and drink selection was poor.",
  "Food quality at the restaurant was below average."
)

negative_amenities <- c(
  "Pool was closed for maintenance during our entire stay.",
  "Gym equipment was outdated and some machines were broken.",
  "WiFi kept dropping which was very inconvenient for work.",
  "No spa services available on weekends which was surprising.",
  "Business center computers were extremely slow."
)

negative_location <- c(
  "Area around the hotel felt unsafe at night.",
  "Street noise made it hard to sleep even with windows closed.",
  "Far from the main attractions, had to take taxis everywhere.",
  "Parking was very expensive and limited.",
  "Construction nearby created constant noise during the day."
)

# Neutral/mixed
neutral_comments <- c(
  "Overall an average stay, nothing special but nothing terrible.",
  "It was okay for the price. Met expectations but didn't exceed them.",
  "Decent hotel for a short stay. Would consider returning.",
  "Standard hotel experience, room was adequate.",
  "Fine for a business trip but wouldn't choose it for vacation."
)

# --- Generate Reviews ---------------------------------------------------------

cat("Generating", n_reviews, "hotel guest reviews...\n")

# Stay dates across 2025
stay_months <- sample(1:12, n_reviews, replace = TRUE,
                      prob = c(0.06, 0.07, 0.09, 0.11, 0.10, 0.08,
                               0.07, 0.08, 0.09, 0.10, 0.09, 0.06))
stay_days <- sapply(stay_months, function(m) {
  max_day <- days_in_month(ymd(paste0("2025-", m, "-01")))
  sample(1:max_day, 1)
})
stay_dates <- ymd(paste("2025", stay_months, stay_days, sep = "-"))

# Review is posted 1-14 days after stay
review_lag <- sample(1:14, n_reviews, replace = TRUE,
                     prob = c(0.20, 0.15, 0.12, 0.10, 0.08, 0.07,
                              0.06, 0.05, 0.04, 0.03, 0.03, 0.03,
                              0.02, 0.02))
review_dates <- stay_dates + days(review_lag)

# Overall rating (1-10, skewed toward 7-9 as typical for hotels)
overall_base <- sample(1:10, n_reviews, replace = TRUE,
                       prob = c(0.02, 0.03, 0.04, 0.06, 0.08, 0.10,
                                0.15, 0.22, 0.18, 0.12))

# Sub-ratings correlated with overall but with noise
add_noise <- function(base, sd = 1.2) {
  noisy <- round(base + rnorm(length(base), 0, sd))
  pmin(pmax(noisy, 1), 10)  # clamp to 1-10
}

rating_cleanliness <- add_noise(overall_base)
rating_service     <- add_noise(overall_base)
rating_location    <- add_noise(overall_base, sd = 0.8)  # less variable
rating_value       <- add_noise(overall_base, sd = 1.0)
rating_food        <- add_noise(overall_base, sd = 1.3)

# Generate review text based on rating
generate_review <- function(rating) {
  parts <- c()

  if (rating >= 8) {
    # Mostly positive, pick 2-3 positive department mentions
    n_pos <- sample(2:3, 1)
    pos_pools <- list(positive_front_desk, positive_housekeeping,
                      positive_fnb, positive_amenities, positive_location)
    chosen <- sample(1:5, n_pos)
    for (i in chosen) {
      parts <- c(parts, sample(pos_pools[[i]], 1))
    }
  } else if (rating >= 5) {
    # Mixed - 1 positive, 1 negative, maybe 1 neutral
    pos_pools <- list(positive_front_desk, positive_housekeeping,
                      positive_fnb, positive_amenities, positive_location)
    neg_pools <- list(negative_front_desk, negative_housekeeping,
                      negative_fnb, negative_amenities, negative_location)
    pos_dept <- sample(1:5, 1)
    neg_dept <- sample(setdiff(1:5, pos_dept), 1)
    parts <- c(parts, sample(pos_pools[[pos_dept]], 1))
    parts <- c(parts, sample(neg_pools[[neg_dept]], 1))
    if (runif(1) > 0.5) parts <- c(parts, sample(neutral_comments, 1))
  } else {
    # Mostly negative, pick 2-3 negative department mentions
    n_neg <- sample(2:3, 1)
    neg_pools <- list(negative_front_desk, negative_housekeeping,
                      negative_fnb, negative_amenities, negative_location)
    chosen <- sample(1:5, n_neg)
    for (i in chosen) {
      parts <- c(parts, sample(neg_pools[[i]], 1))
    }
  }

  paste(parts, collapse = " ")
}

review_texts <- sapply(overall_base, generate_review)

# Would recommend (NPS style)
would_recommend <- case_when(
  overall_base >= 9  ~ "Definitely",
  overall_base >= 7  ~ "Probably",
  overall_base >= 5  ~ "Maybe",
  overall_base >= 3  ~ "Probably Not",
  TRUE               ~ "Definitely Not"
)

# Response time (hours for hotel to respond to review)
response_time <- round(rexp(n_reviews, rate = 0.05) + 2, 1)
# Some reviews get no response (~15%)
no_response_idx <- sample(n_reviews, round(n_reviews * 0.15))
response_time[no_response_idx] <- NA

# Length of stay
nights_stayed <- sample(1:7, n_reviews, replace = TRUE,
                        prob = c(0.22, 0.30, 0.20, 0.12, 0.08, 0.05, 0.03))

# Guest names
first_names <- c("James", "Mary", "Robert", "Patricia", "John", "Jennifer",
                 "Michael", "Linda", "David", "Elizabeth", "William", "Barbara",
                 "Deepanshi", "Priya", "Raj", "Carlos", "Maria", "Wei",
                 "Yuki", "Ahmed", "Sofia", "Pierre", "Liam", "Emma",
                 "Noah", "Olivia", "Ava", "Ethan", "Sophia", "Mason",
                 "Aisha", "Kenji", "Lucia", "Henrik", "Fatima", "Dmitri")
last_names <- c("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia",
                "Miller", "Davis", "Patel", "Sharma", "Chen", "Kim",
                "Tanaka", "Muller", "Dubois", "Ali", "Khan", "Park",
                "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Lee")

guest_names <- paste(
  sample(first_names, n_reviews, replace = TRUE),
  sample(last_names, n_reviews, replace = TRUE)
)

# Review IDs
review_ids <- paste0("RV", sprintf("%06d", 1:n_reviews))

# --- Introduce Messiness ------------------------------------------------------

cat("Introducing data quality issues...\n")

# 1. Mixed date formats
fmt_mask <- sample(c(TRUE, FALSE), n_reviews, replace = TRUE, prob = c(0.65, 0.35))
stay_date_str <- ifelse(fmt_mask,
                        format(stay_dates, "%Y-%m-%d"),
                        format(stay_dates, "%m/%d/%Y"))
review_date_str <- ifelse(fmt_mask,
                          format(review_dates, "%Y-%m-%d"),
                          format(review_dates, "%m/%d/%Y"))

# 2. Inconsistent guest name casing
name_case <- sample(1:3, n_reviews, replace = TRUE, prob = c(0.55, 0.25, 0.20))
guest_names_messy <- case_when(
  name_case == 1 ~ guest_names,
  name_case == 2 ~ toupper(guest_names),
  name_case == 3 ~ tolower(guest_names)
)

# 3. Inconsistent room type casing/naming
room_sample <- sample(room_types, n_reviews, replace = TRUE,
                      prob = c(0.30, 0.25, 0.25, 0.12, 0.08))
room_case <- sample(1:3, n_reviews, replace = TRUE, prob = c(0.60, 0.20, 0.20))
room_messy <- case_when(
  room_case == 1 ~ room_sample,
  room_case == 2 ~ toupper(room_sample),
  room_case == 3 ~ tolower(room_sample)
)

# 4. Mixed would_recommend encoding
rec_case <- sample(1:3, n_reviews, replace = TRUE, prob = c(0.50, 0.30, 0.20))
recommend_messy <- case_when(
  rec_case == 1 ~ would_recommend,
  rec_case == 2 ~ toupper(would_recommend),
  rec_case == 3 ~ tolower(would_recommend)
)

# 5. Missing values
rating_clean_messy <- rating_cleanliness
rating_clean_messy[sample(n_reviews, round(n_reviews * 0.04))] <- NA

rating_food_messy <- rating_food
rating_food_messy[sample(n_reviews, round(n_reviews * 0.05))] <- NA

rating_value_messy <- rating_value
rating_value_messy[sample(n_reviews, round(n_reviews * 0.03))] <- NA

loyalty_sample <- sample(loyalty_tiers, n_reviews, replace = TRUE,
                         prob = loyalty_weights)
loyalty_messy <- loyalty_sample
loyalty_messy[sample(n_reviews, round(n_reviews * 0.06))] <- NA

# 6. Whitespace in channels
channel_sample <- sample(channels, n_reviews, replace = TRUE,
                         prob = channel_weights)
channel_messy <- channel_sample
ws_idx <- sample(n_reviews, round(n_reviews * 0.12))
channel_messy[ws_idx] <- paste0("  ", channel_messy[ws_idx], "  ")

# 7. Trip type with whitespace issues
trip_sample <- sample(trip_types, n_reviews, replace = TRUE, prob = trip_weights)
trip_messy <- trip_sample
trip_ws <- sample(n_reviews, round(n_reviews * 0.08))
trip_messy[trip_ws] <- paste0(" ", trip_messy[trip_ws], " ")

# --- Assemble DataFrame -------------------------------------------------------

reviews_raw <- tibble(
  review_id = review_ids,
  guest_name = guest_names_messy,
  loyalty_tier = loyalty_messy,
  room_type = room_messy,
  trip_type = trip_messy,
  booking_channel = channel_messy,
  stay_date = stay_date_str,
  review_date = review_date_str,
  nights_stayed = nights_stayed,
  rating_overall = overall_base,
  rating_cleanliness = rating_clean_messy,
  rating_service = rating_service,
  rating_location = rating_location,
  rating_value = rating_value_messy,
  rating_food = rating_food_messy,
  review_text = review_texts,
  would_recommend = recommend_messy,
  response_time_hours = response_time
)

# Add ~35 duplicate rows
dup_idx <- sample(n_reviews, 35)
reviews_with_dups <- bind_rows(reviews_raw, reviews_raw[dup_idx, ])
reviews_final <- reviews_with_dups[sample(nrow(reviews_with_dups)), ]

# --- Export -------------------------------------------------------------------

output_path <- "data/raw/hotel_reviews_raw.csv"
write_csv(reviews_final, output_path)

cat("\nDataset generated successfully!\n")
cat("Total rows (with duplicates):", nrow(reviews_final), "\n")
cat("Unique reviews:", n_reviews, "\n")
cat("Duplicate rows added: 35\n")
cat("Output:", output_path, "\n")

cat("\n--- Data Quality Issues ---\n")
cat("1. Mixed date formats (YYYY-MM-DD and MM/DD/YYYY)\n")
cat("2. Inconsistent guest name casing (Title, UPPER, lower)\n")
cat("3. Inconsistent room type casing\n")
cat("4. Mixed would_recommend casing\n")
cat("5. Missing values in cleanliness, food, value ratings and loyalty_tier\n")
cat("6. Leading/trailing whitespace in booking_channel and trip_type\n")
cat("7. 35 duplicate rows\n")
cat("8. ~15% of reviews have no hotel response time (NA)\n")
