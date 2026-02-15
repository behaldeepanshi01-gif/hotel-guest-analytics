# Hotel Guest Satisfaction & Review Analytics

A text analytics and NPS pipeline that processes 2,000 simulated hotel guest reviews, performs sentiment analysis, calculates Net Promoter Scores, and identifies department-level satisfaction patterns -- built with R, tidyverse, and tidytext.

## Project Overview

This project takes messy guest review data (simulating exports from platforms like TripAdvisor, Medallia, or Revinate), cleans it through an ETL pipeline, then applies text-based sentiment analysis and NPS calculations to surface actionable insights for hotel operations teams.

### Skills Demonstrated
- **Text Analytics**: Sentiment analysis with tidytext and the Bing lexicon
- **NPS Calculation**: Promoter/Passive/Detractor segmentation on a 1-10 scale
- **ETL Pipeline**: Data cleaning, standardization, and structuring
- **Data Wrangling**: tidyverse (dplyr, tidyr, stringr, lubridate)
- **Pivoting**: `pivot_wider` (ratings by room type x quarter) and `pivot_longer` (sub-ratings for faceted plots)
- **Data Visualization**: 8 ggplot2 charts with custom theming
- **Domain Knowledge**: Hotel guest experience terminology (NPS, department satisfaction, response time SLAs)

## Data Pipeline Architecture

```mermaid
flowchart LR
    A["Raw Reviews\n2,035 rows\n8 data quality issues"] -->|01 Generate| B["hotel_reviews_raw.csv"]
    B -->|02 Clean| C{"ETL Pipeline"}
    C --> D["Remove 35 dupes"]
    C --> E["Standardize text"]
    C --> F["Parse mixed dates"]
    C --> G["Impute missing ratings"]
    D & E & F & G --> H["Clean Dataset\n2,000 rows"]
    H -->|03 Analyze| I["Sentiment + NPS"]
    I -->|04 Visualize| J["8 ggplot2 Charts"]

    style A fill:#C73E1D,color:#fff
    style H fill:#F18F01,color:#fff
    style I fill:#2E86AB,color:#fff
    style J fill:#44BBA4,color:#fff
```

## Data Model

```mermaid
erDiagram
    reviews_cleaned ||--o{ ratings_long : review_id
    reviews_cleaned ||--o{ review_sentiment : review_id
    reviews_cleaned ||--o{ dept_mentions : review_id

    reviews_cleaned {
        string review_id PK
        string guest_name
        string loyalty_tier
        string room_type
        string trip_type
        string booking_channel
        date stay_date
        date review_date
        int nights_stayed
        int rating_overall
        int rating_cleanliness
        int rating_service
        int rating_location
        int rating_value
        int rating_food
        string review_text
        string would_recommend
        float response_time_hours
        string nps_category
        string season
    }

    ratings_long {
        string review_id FK
        int stay_month
        string rating_category
        int score
        string rating_label
    }

    review_sentiment {
        string review_id FK
        int positive_words
        int negative_words
        int sentiment_score
        string sentiment_label
    }

    dept_mentions {
        string review_id FK
        string department
        string keyword
        int rating_overall
        int sentiment_score
    }
```

## Analytics Methodology Flow

```mermaid
flowchart TD
    A["Cleaned Reviews\n2,000 rows"] --> B["Text Tokenization\nunnest_tokens()"]
    A --> C["Numeric Ratings\n6 categories"]
    A --> D["NPS Segmentation"]

    B --> B1["Remove Stop Words\nanti_join(stop_words)"]
    B1 --> B2["Bing Lexicon Match\npositive / negative"]
    B2 --> B3["Sentiment Score\nper review"]
    B2 --> B4["Top Keywords\nby frequency"]

    A --> E["Department Extraction\nkeyword search in text"]
    E --> E1["Front Desk"]
    E --> E2["Housekeeping"]
    E --> E3["Food & Beverage"]
    E --> E4["Amenities"]
    E --> E5["Location"]

    D --> D1["Promoter\nrating 9-10"]
    D --> D2["Passive\nrating 7-8"]
    D --> D3["Detractor\nrating 1-6"]
    D1 & D2 & D3 --> D4["NPS = %Promoters - %Detractors"]

    C --> F["pivot_wider\nRatings by Room x Quarter"]
    C --> G["pivot_longer\nSub-ratings for faceting"]

    B3 & B4 & E1 & E2 & E3 & E4 & E5 & D4 & F & G --> H["8 ggplot2\nVisualizations"]

    style A fill:#2E86AB,color:#fff
    style B2 fill:#F18F01,color:#fff
    style D4 fill:#44BBA4,color:#fff
    style H fill:#0D3B66,color:#fff
```

## Key Findings

- **OTA guests rate lower** than direct booking guests -- aligning with industry trends around expectation management
- **Housekeeping and Front Desk** are the most frequently mentioned departments in reviews
- **Fast response times** (under 6 hours) correlate with higher guest satisfaction scores
- **Business travelers** and **couples** tend to give higher ratings than family travelers
- **Spring and Fall** show highest satisfaction, matching DC's peak tourism seasons

## Analytics Methodology

### Net Promoter Score (NPS)
| Category | Rating Range | Meaning |
|----------|-------------|---------|
| Promoter | 9 - 10 | Loyal guests who will recommend |
| Passive | 7 - 8 | Satisfied but not enthusiastic |
| Detractor | 1 - 6 | Unhappy guests who may leave negative reviews |

**NPS = % Promoters - % Detractors** (ranges from -100 to +100)

### Sentiment Analysis
- Reviews are tokenized into individual words using `unnest_tokens()`
- Stop words removed (the, a, is, etc.)
- Each word scored using the **Bing sentiment lexicon** (positive/negative)
- Review-level sentiment = positive word count - negative word count

### Department-Level Analysis
Reviews are scanned for keyword mentions of 5 hotel departments:
| Department | Keywords Tracked |
|-----------|-----------------|
| Front Desk | check-in, reception, receptionist, check-out |
| Housekeeping | clean, towels, bathroom, spotless |
| Food & Beverage | breakfast, restaurant, food, bar, dining, room service |
| Amenities | pool, gym, spa, wifi, business center |
| Location | location, metro, walking distance, nearby |

## Dataset Details

The raw dataset simulates a guest review export with deliberate data quality issues:

| Issue | Description |
|-------|-------------|
| Mixed date formats | `YYYY-MM-DD` and `MM/DD/YYYY` in same column |
| Inconsistent casing | Guest names and room types in mixed case |
| Missing values | ~3-6% NAs across sub-ratings and loyalty tier |
| Whitespace | Leading/trailing spaces in channels and trip types |
| Duplicates | 35 exact duplicate rows |
| Missing responses | ~15% of reviews have no hotel response time |

### Rating Categories (1-10 scale)
- **Overall** - General satisfaction
- **Cleanliness** - Room and property cleanliness
- **Service** - Staff friendliness and responsiveness
- **Location** - Convenience and surroundings
- **Value** - Price-to-quality perception
- **Food & Beverage** - Dining and bar quality

## Visualizations

Eight ggplot2 charts saved to `output/plots/`:

| # | Chart | Description |
|---|-------|-------------|
| 1 | Monthly Satisfaction Trend | Line chart tracking average rating over 12 months |
| 2 | NPS by Month | Stacked bar showing Promoter/Passive/Detractor mix |
| 3 | Department Satisfaction | Horizontal bar of avg rating by department |
| 4 | Sentiment Keywords | Diverging bar of top positive/negative review words |
| 5 | Rating Distribution | Histogram colored by NPS category |
| 6 | Satisfaction by Trip Type | Boxplot comparing Business/Leisure/Family/Couple/Solo |
| 7 | Sub-Rating Dashboard | Faceted line charts using `pivot_longer` output |
| 8 | Correlation Heatmap | How rating categories relate to each other |

### Sample Outputs

<p align="center">
  <img src="output/plots/02_nps_by_month.png" width="48%" />
  <img src="output/plots/04_sentiment_keywords.png" width="48%" />
</p>
<p align="center">
  <img src="output/plots/05_rating_distribution.png" width="48%" />
  <img src="output/plots/08_correlation_heatmap.png" width="48%" />
</p>

## Project Structure

```
hotel-guest-analytics/
├── data/
│   ├── raw/hotel_reviews_raw.csv           # 2,000+ rows, messy raw data
│   └── processed/                          # Cleaned + analytics CSVs
│       ├── reviews_cleaned.csv
│       ├── reviews_with_sentiment.csv
│       ├── monthly_summary.csv
│       ├── channel_summary.csv
│       ├── loyalty_summary.csv
│       ├── dept_satisfaction.csv
│       ├── nps_monthly.csv
│       ├── nps_by_trip_type.csv
│       ├── top_positive_words.csv
│       ├── top_negative_words.csv
│       ├── response_impact.csv
│       ├── rating_room_quarter.csv
│       └── ratings_long.csv
├── scripts/
│   ├── 01_generate_reviews.R              # Review dataset generation
│   ├── 02_clean_and_structure.R           # ETL cleaning & structuring
│   ├── 03_sentiment_analytics.R           # Sentiment, NPS & department analysis
│   └── 04_visualizations.R               # 8 ggplot2 charts
├── output/plots/                          # Saved PNG charts
└── README.md
```

## How to Run

### Prerequisites
- R (>= 4.0)
- RStudio (recommended)

```r
install.packages(c("tidyverse", "lubridate", "scales", "tidytext"))
```

### Execution Order

```r
setwd("path/to/hotel-guest-analytics")

source("scripts/01_generate_reviews.R")       # Generate raw review data
source("scripts/02_clean_and_structure.R")     # Clean and structure
source("scripts/03_sentiment_analytics.R")     # Sentiment + NPS analysis
source("scripts/04_visualizations.R")          # Create all 8 charts
```

## Related Project

**[Hotel Revenue Analytics Pipeline](https://github.com/behaldeepanshi01-gif/hotel-revenue-analytics)** - Companion project covering the revenue side: ETL pipeline, star schema, ADR/RevPAR/Occupancy KPIs, and 8 revenue-focused visualizations.

Together, these two projects demonstrate full-stack hotel data analytics:
- **Revenue Analytics** = "How is the hotel performing financially?"
- **Guest Analytics** = "How do guests feel about their experience?"

## Technologies

- **R** with tidyverse (dplyr, tidyr, ggplot2, readr, stringr)
- **tidytext** for text mining and sentiment analysis
- **lubridate** for date parsing
- **scales** for formatted axis labels

## Glossary

| Term | Definition |
|------|-----------|
| NPS | Net Promoter Score -- measures guest loyalty and likelihood to recommend |
| Sentiment Analysis | Using text data to determine positive/negative tone |
| Bing Lexicon | Dictionary of ~6,800 words labeled as positive or negative |
| Sub-Rating | Individual rating category (cleanliness, service, etc.) |
| Response Time | Hours between review posting and hotel management response |
| Detractor | Guest rating 1-6 who is likely to leave negative feedback |
| Promoter | Guest rating 9-10 who will actively recommend the hotel |
