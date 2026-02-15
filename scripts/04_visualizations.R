# =============================================================================
# 04_visualizations.R
# Hotel Guest Satisfaction & Review Analytics - Visualizations
#
# Creates 8 ggplot2 charts for the guest satisfaction dashboard.
# All plots are saved as PNG files to output/plots/.
# =============================================================================

library(tidyverse)
library(lubridate)
library(scales)

cat("=" |> strrep(60), "\n")
cat("HOTEL GUEST ANALYTICS - VISUALIZATIONS\n")
cat("=" |> strrep(60), "\n\n")

# --- Load Data ----------------------------------------------------------------

reviews         <- read_csv("data/processed/reviews_with_sentiment.csv",
                             show_col_types = FALSE)
nps_monthly     <- read_csv("data/processed/nps_monthly.csv",
                             show_col_types = FALSE)
dept_satis      <- read_csv("data/processed/dept_satisfaction.csv",
                             show_col_types = FALSE)
top_pos         <- read_csv("data/processed/top_positive_words.csv",
                             show_col_types = FALSE)
top_neg         <- read_csv("data/processed/top_negative_words.csv",
                             show_col_types = FALSE)
nps_trip        <- read_csv("data/processed/nps_by_trip_type.csv",
                             show_col_types = FALSE)
response_impact <- read_csv("data/processed/response_impact.csv",
                             show_col_types = FALSE)
ratings_long    <- read_csv("data/processed/ratings_long.csv",
                             show_col_types = FALSE)

# Custom theme
theme_guest <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0),
    plot.subtitle = element_text(color = "gray40", size = 11),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# Color palettes
brand_colors <- c("#0D3B66", "#2E86AB", "#A23B72", "#F18F01",
                  "#C73E1D", "#44BBA4", "#3B1F2B")
nps_colors <- c("Promoter" = "#44BBA4", "Passive" = "#F4D35E",
                "Detractor" = "#C73E1D")
sentiment_colors <- c("Positive" = "#44BBA4", "Neutral" = "#F4D35E",
                       "Negative" = "#C73E1D")

cat("Data loaded. Generating 8 visualizations...\n\n")

# =============================================================================
# Plot 1: Monthly Satisfaction Trend
# =============================================================================

cat("1/8 - Monthly Satisfaction Trend...\n")

monthly_avg <- reviews %>%
  group_by(stay_month, stay_month_name) %>%
  summarise(avg_rating = round(mean(rating_overall), 2),
            reviews = n(), .groups = "drop")

p1 <- ggplot(monthly_avg, aes(x = stay_month, y = avg_rating)) +
  geom_line(color = "#0D3B66", linewidth = 1.2) +
  geom_point(aes(size = reviews), color = "#2E86AB", alpha = 0.8) +
  geom_text(aes(label = avg_rating), vjust = -1.3, size = 3.5,
            color = "gray30") +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  scale_size_continuous(range = c(3, 8), name = "# Reviews") +
  labs(
    title = "Monthly Guest Satisfaction Trend - 2025",
    subtitle = "Average overall rating (1-10) | Point size = review volume",
    x = NULL, y = "Average Rating"
  ) +
  theme_guest +
  coord_cartesian(ylim = c(
    min(monthly_avg$avg_rating) - 0.5,
    max(monthly_avg$avg_rating) + 0.5
  ))

ggsave("output/plots/01_satisfaction_trend.png", p1,
       width = 10, height = 6, dpi = 300, bg = "white")

# =============================================================================
# Plot 2: NPS Score by Month (Stacked Bar)
# =============================================================================

cat("2/8 - NPS by Month...\n")

nps_stacked <- reviews %>%
  group_by(stay_month, nps_category) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(stay_month) %>%
  mutate(pct = round(count / sum(count) * 100, 1)) %>%
  ungroup() %>%
  mutate(nps_category = factor(nps_category,
                               levels = c("Promoter", "Passive", "Detractor")))

p2 <- ggplot(nps_stacked, aes(x = factor(stay_month), y = pct,
                               fill = nps_category)) +
  geom_col(position = "stack", width = 0.7) +
  geom_text(data = nps_monthly,
            aes(x = factor(stay_month), y = 102,
                label = paste0("NPS: ", nps),
                fill = NULL),
            size = 3.2, fontface = "bold", color = "gray30") +
  scale_fill_manual(values = nps_colors) +
  scale_x_discrete(labels = month.abb) +
  labs(
    title = "Net Promoter Score by Month",
    subtitle = "Promoters (9-10) vs Passives (7-8) vs Detractors (1-6)",
    x = NULL, y = "Percentage (%)", fill = "NPS Category"
  ) +
  theme_guest +
  coord_cartesian(ylim = c(0, 110))

ggsave("output/plots/02_nps_by_month.png", p2,
       width = 10, height = 6, dpi = 300, bg = "white")

# =============================================================================
# Plot 3: Department Satisfaction Scores
# =============================================================================

cat("3/8 - Department Satisfaction...\n")

dept_plot <- dept_satis %>%
  mutate(department = fct_reorder(department, avg_rating))

p3 <- ggplot(dept_plot, aes(x = department, y = avg_rating, fill = department)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = paste0(avg_rating, " (", mentions, " mentions)")),
            hjust = -0.1, size = 3.8, fontface = "bold") +
  scale_fill_manual(values = brand_colors[1:5]) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.3))) +
  labs(
    title = "Guest Satisfaction by Department",
    subtitle = "Average rating from reviews mentioning each department",
    x = NULL, y = "Average Rating (1-10)"
  ) +
  theme_guest

ggsave("output/plots/03_dept_satisfaction.png", p3,
       width = 10, height = 6, dpi = 300, bg = "white")

# =============================================================================
# Plot 4: Top Positive & Negative Keywords
# =============================================================================

cat("4/8 - Sentiment Keywords...\n")

# Combine top words
top_words <- bind_rows(
  top_pos %>% head(10) %>% mutate(sentiment = "Positive"),
  top_neg %>% head(10) %>% mutate(sentiment = "Negative")
) %>%
  mutate(
    word = fct_reorder(word, n),
    n_signed = if_else(sentiment == "Negative", -n, n)
  )

p4 <- ggplot(top_words, aes(x = word, y = n_signed, fill = sentiment)) +
  geom_col(width = 0.7, show.legend = TRUE) +
  geom_text(aes(label = n,
                hjust = if_else(sentiment == "Negative", 1.2, -0.2)),
            size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Positive" = "#44BBA4",
                                "Negative" = "#C73E1D")) +
  coord_flip() +
  labs(
    title = "Top Guest Review Keywords by Sentiment",
    subtitle = "Most frequent positive and negative words in review text (Bing lexicon)",
    x = NULL, y = "Frequency", fill = "Sentiment"
  ) +
  theme_guest +
  theme(panel.grid.major.y = element_blank())

ggsave("output/plots/04_sentiment_keywords.png", p4,
       width = 10, height = 7, dpi = 300, bg = "white")

# =============================================================================
# Plot 5: Rating Distribution (Histogram)
# =============================================================================

cat("5/8 - Rating Distribution...\n")

p5 <- ggplot(reviews, aes(x = rating_overall, fill = nps_category)) +
  geom_histogram(binwidth = 1, color = "white", boundary = 0.5) +
  scale_fill_manual(values = nps_colors) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "Overall Rating Distribution",
    subtitle = "Guest ratings on a 1-10 scale | Colored by NPS category",
    x = "Overall Rating", y = "Number of Reviews", fill = "NPS Category"
  ) +
  theme_guest

ggsave("output/plots/05_rating_distribution.png", p5,
       width = 10, height = 6, dpi = 300, bg = "white")

# =============================================================================
# Plot 6: Satisfaction by Trip Type (Boxplot)
# =============================================================================

cat("6/8 - Satisfaction by Trip Type...\n")

trip_order <- reviews %>%
  group_by(trip_type) %>%
  summarise(med = median(rating_overall), .groups = "drop") %>%
  arrange(med) %>%
  pull(trip_type)

trip_plot <- reviews %>%
  mutate(trip_type = factor(trip_type, levels = trip_order))

p6 <- ggplot(trip_plot, aes(x = trip_type, y = rating_overall,
                             fill = trip_type)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.4, show.legend = FALSE) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 3.5,
               color = "red", show.legend = FALSE) +
  scale_fill_manual(values = brand_colors[1:5]) +
  labs(
    title = "Guest Satisfaction by Trip Type",
    subtitle = "Boxplot with median (line) and mean (red diamond)",
    x = "Trip Type", y = "Overall Rating (1-10)"
  ) +
  theme_guest

ggsave("output/plots/06_satisfaction_by_trip.png", p6,
       width = 10, height = 6, dpi = 300, bg = "white")

# =============================================================================
# Plot 7: Sub-Rating Comparison (Faceted - uses pivot_longer)
# =============================================================================

cat("7/8 - Sub-Rating Dashboard (Faceted)...\n")

monthly_sub_ratings <- ratings_long %>%
  group_by(stay_month, rating_label) %>%
  summarise(avg_score = round(mean(score), 2), .groups = "drop")

p7 <- ggplot(monthly_sub_ratings, aes(x = stay_month, y = avg_score)) +
  geom_line(color = "#0D3B66", linewidth = 1) +
  geom_point(color = "#2E86AB", size = 2.5) +
  facet_wrap(~ rating_label, ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = seq(2, 12, 2),
                     labels = month.abb[seq(2, 12, 2)]) +
  labs(
    title = "Monthly Sub-Rating Dashboard - 2025",
    subtitle = "5 rating categories tracked monthly (pivot_longer output)",
    x = NULL, y = "Average Score (1-10)"
  ) +
  theme_guest +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    strip.background = element_rect(fill = "gray95", color = NA)
  )

ggsave("output/plots/07_sub_rating_dashboard.png", p7,
       width = 12, height = 7, dpi = 300, bg = "white")

# =============================================================================
# Plot 8: Correlation Heatmap of Rating Categories
# =============================================================================

cat("8/8 - Rating Correlation Heatmap...\n")

rating_cols <- reviews %>%
  select(rating_overall, rating_cleanliness, rating_service,
         rating_location, rating_value, rating_food)

cor_matrix <- cor(rating_cols, use = "complete.obs") %>%
  as.data.frame() %>%
  rownames_to_column("var1") %>%
  pivot_longer(-var1, names_to = "var2", values_to = "correlation") %>%
  mutate(
    var1 = str_replace(var1, "rating_", "") %>% str_to_title(),
    var2 = str_replace(var2, "rating_", "") %>% str_to_title(),
    label = round(correlation, 2)
  )

p8 <- ggplot(cor_matrix, aes(x = var1, y = var2, fill = correlation)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = label), size = 4, fontface = "bold") +
  scale_fill_gradient2(low = "#C73E1D", mid = "#F4D35E", high = "#44BBA4",
                       midpoint = 0.5, limits = c(0, 1)) +
  labs(
    title = "Rating Category Correlation Heatmap",
    subtitle = "How strongly are different satisfaction dimensions related?",
    x = NULL, y = NULL, fill = "Correlation"
  ) +
  theme_guest +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

ggsave("output/plots/08_correlation_heatmap.png", p8,
       width = 9, height = 7, dpi = 300, bg = "white")

# =============================================================================
# Summary
# =============================================================================

cat("\n")
cat("=" |> strrep(60), "\n")
cat("ALL 8 VISUALIZATIONS SAVED TO output/plots/\n")
cat("=" |> strrep(60), "\n")
cat("\nPlots generated:\n")
cat("  1. 01_satisfaction_trend.png     - Monthly satisfaction trend\n")
cat("  2. 02_nps_by_month.png           - NPS score stacked by month\n")
cat("  3. 03_dept_satisfaction.png       - Department satisfaction scores\n")
cat("  4. 04_sentiment_keywords.png     - Top positive/negative keywords\n")
cat("  5. 05_rating_distribution.png    - Rating histogram by NPS category\n")
cat("  6. 06_satisfaction_by_trip.png    - Satisfaction by trip type boxplot\n")
cat("  7. 07_sub_rating_dashboard.png   - Sub-rating faceted dashboard\n")
cat("  8. 08_correlation_heatmap.png    - Rating correlation heatmap\n")
