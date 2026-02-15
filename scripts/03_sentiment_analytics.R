# =============================================================================
# 03_sentiment_analytics.R
# Hotel Guest Satisfaction & Review Analytics - Sentiment & NPS Analysis
#
# Performs text-based sentiment analysis using tidytext, calculates NPS,
# extracts department-level satisfaction, and demonstrates pivot operations.
# =============================================================================

library(tidyverse)
library(lubridate)
library(tidytext)

cat("=" |> strrep(60), "\n")
cat("HOTEL GUEST ANALYTICS - SENTIMENT & NPS ANALYSIS\n")
cat("=" |> strrep(60), "\n\n")

# --- Load Cleaned Data -------------------------------------------------------

reviews <- read_csv("data/processed/reviews_cleaned.csv",
                     show_col_types = FALSE)

cat("Loaded", nrow(reviews), "cleaned reviews\n\n")

# =============================================================================
# 1. SENTIMENT ANALYSIS WITH TIDYTEXT
# =============================================================================

cat("--- SENTIMENT ANALYSIS ---\n")

# Tokenize review text into words
review_words <- reviews %>%
  select(review_id, rating_overall, review_text) %>%
  unnest_tokens(word, review_text) %>%
  # Remove stop words (the, a, is, etc.)
  anti_join(stop_words, by = "word")

cat("Total words after removing stop words:", nrow(review_words), "\n")

# Join with Bing sentiment lexicon (positive/negative)
bing_sentiments <- get_sentiments("bing")

word_sentiments <- review_words %>%
  inner_join(bing_sentiments, by = "word")

cat("Words matched to Bing lexicon:", nrow(word_sentiments), "\n")

# Sentiment score per review (positive count - negative count)
review_sentiment <- word_sentiments %>%
  group_by(review_id) %>%
  summarise(
    positive_words = sum(sentiment == "positive"),
    negative_words = sum(sentiment == "negative"),
    sentiment_score = positive_words - negative_words,
    .groups = "drop"
  )

# Join back to reviews
reviews <- reviews %>%
  left_join(review_sentiment, by = "review_id") %>%
  mutate(
    positive_words = replace_na(positive_words, 0),
    negative_words = replace_na(negative_words, 0),
    sentiment_score = replace_na(sentiment_score, 0),
    sentiment_label = case_when(
      sentiment_score > 1  ~ "Positive",
      sentiment_score < -1 ~ "Negative",
      TRUE                 ~ "Neutral"
    )
  )

cat("\nSentiment Distribution:\n")
reviews %>%
  count(sentiment_label) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  print()

# Top positive and negative words
cat("\nTop 15 Positive Words:\n")
top_positive <- word_sentiments %>%
  filter(sentiment == "positive") %>%
  count(word, sort = TRUE) %>%
  head(15)
print(top_positive)

cat("\nTop 15 Negative Words:\n")
top_negative <- word_sentiments %>%
  filter(sentiment == "negative") %>%
  count(word, sort = TRUE) %>%
  head(15)
print(top_negative)

# =============================================================================
# 2. DEPARTMENT-LEVEL SATISFACTION (Keyword Extraction)
# =============================================================================

cat("\n--- DEPARTMENT-LEVEL ANALYSIS ---\n")

# Define department keywords
dept_keywords <- tibble(
  department = c(rep("Front Desk", 5),
                 rep("Housekeeping", 5),
                 rep("Food & Beverage", 6),
                 rep("Amenities", 5),
                 rep("Location", 4)),
  keyword = c(
    # Front Desk
    "check-in", "front desk", "reception", "receptionist", "check-out",
    # Housekeeping
    "clean", "housekeeping", "towels", "bathroom", "spotless",
    # Food & Beverage
    "breakfast", "restaurant", "food", "bar", "dining", "room service",
    # Amenities
    "pool", "gym", "spa", "wifi", "business center",
    # Location
    "location", "metro", "walking distance", "nearby"
  )
)

# Search for department mentions in review text
dept_mentions <- reviews %>%
  select(review_id, review_text, rating_overall, sentiment_score) %>%
  crossing(dept_keywords) %>%
  filter(str_detect(str_to_lower(review_text), fixed(keyword))) %>%
  distinct(review_id, department, .keep_all = TRUE)

dept_satisfaction <- dept_mentions %>%
  group_by(department) %>%
  summarise(
    mentions = n(),
    avg_rating = round(mean(rating_overall), 2),
    avg_sentiment = round(mean(sentiment_score), 2),
    pct_positive = round(sum(sentiment_score > 0) / n() * 100, 1),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_rating))

cat("\nDepartment Satisfaction:\n")
print(dept_satisfaction)

# =============================================================================
# 3. NPS ANALYSIS
# =============================================================================

cat("\n--- NPS (NET PROMOTER SCORE) ANALYSIS ---\n")

# Overall NPS
nps_overall <- reviews %>%
  summarise(
    total = n(),
    promoters = sum(nps_category == "Promoter"),
    passives = sum(nps_category == "Passive"),
    detractors = sum(nps_category == "Detractor"),
    nps = round((promoters - detractors) / total * 100, 1)
  )

cat("\nOverall NPS:\n")
print(nps_overall)

# NPS by month
nps_monthly <- reviews %>%
  group_by(stay_month, stay_month_name) %>%
  summarise(
    total = n(),
    promoters = sum(nps_category == "Promoter"),
    passives = sum(nps_category == "Passive"),
    detractors = sum(nps_category == "Detractor"),
    nps = round((promoters - detractors) / total * 100, 1),
    .groups = "drop"
  )

cat("\nMonthly NPS:\n")
print(nps_monthly)

# NPS by trip type
nps_trip <- reviews %>%
  group_by(trip_type) %>%
  summarise(
    reviews = n(),
    nps = round(
      (sum(nps_category == "Promoter") - sum(nps_category == "Detractor")) /
        n() * 100, 1),
    avg_rating = round(mean(rating_overall), 2),
    .groups = "drop"
  ) %>%
  arrange(desc(nps))

cat("\nNPS by Trip Type:\n")
print(nps_trip)

# =============================================================================
# 4. RESPONSE TIME IMPACT
# =============================================================================

cat("\n--- RESPONSE TIME IMPACT ---\n")

response_impact <- reviews %>%
  group_by(response_category) %>%
  summarise(
    reviews = n(),
    avg_rating = round(mean(rating_overall), 2),
    avg_sentiment = round(mean(sentiment_score), 2),
    pct_promoter = round(sum(nps_category == "Promoter") / n() * 100, 1),
    .groups = "drop"
  )

cat("\nSatisfaction by Response Speed:\n")
print(response_impact)

# =============================================================================
# 5. PIVOT DEMONSTRATIONS
# =============================================================================

cat("\n--- PIVOT_WIDER: Average Rating by Room Type x Quarter ---\n")

rating_room_quarter <- reviews %>%
  group_by(room_type, stay_quarter) %>%
  summarise(avg_rating = round(mean(rating_overall), 2), .groups = "drop") %>%
  pivot_wider(
    names_from = stay_quarter,
    values_from = avg_rating,
    values_fill = 0
  )

print(rating_room_quarter)

cat("\n--- PIVOT_LONGER: Sub-Ratings for Faceted Plotting ---\n")

ratings_long <- reviews %>%
  select(review_id, stay_month, rating_cleanliness, rating_service,
         rating_location, rating_value, rating_food) %>%
  pivot_longer(
    cols = starts_with("rating_"),
    names_to = "rating_category",
    values_to = "score",
    names_prefix = "rating_"
  ) %>%
  mutate(
    rating_label = case_when(
      rating_category == "cleanliness" ~ "Cleanliness",
      rating_category == "service"     ~ "Service",
      rating_category == "location"    ~ "Location",
      rating_category == "value"       ~ "Value",
      rating_category == "food"        ~ "Food & Beverage"
    )
  )

cat("Pivoted to long format:", nrow(ratings_long), "rows\n")
cat("(5 rating categories x", nrow(reviews), "reviews)\n")

# =============================================================================
# SAVE ALL ANALYTICS
# =============================================================================

cat("\n\nSaving analytics results...\n")

write_csv(reviews, "data/processed/reviews_with_sentiment.csv")
write_csv(top_positive, "data/processed/top_positive_words.csv")
write_csv(top_negative, "data/processed/top_negative_words.csv")
write_csv(dept_satisfaction, "data/processed/dept_satisfaction.csv")
write_csv(nps_monthly, "data/processed/nps_monthly.csv")
write_csv(nps_trip, "data/processed/nps_by_trip_type.csv")
write_csv(response_impact, "data/processed/response_impact.csv")
write_csv(rating_room_quarter, "data/processed/rating_room_quarter.csv")
write_csv(ratings_long, "data/processed/ratings_long.csv")

cat("All analytics tables saved to data/processed/\n")
cat("\n")
cat("=" |> strrep(60), "\n")
cat("SENTIMENT & NPS ANALYSIS COMPLETE\n")
cat("=" |> strrep(60), "\n")
