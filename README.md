# Hotel Guest Satisfaction & Review Analytics

> Text analytics and NPS pipeline processing 2,000 guest reviews — sentiment analysis, Net Promoter Score tracking, and department-level satisfaction modeling with 8 visualizations.

![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![tidyverse](https://img.shields.io/badge/tidyverse-1A162D?style=flat&logoColor=white)
![ggplot2](https://img.shields.io/badge/ggplot2-FC4E07?style=flat&logoColor=white)
![tidytext](https://img.shields.io/badge/tidytext-NLP-blue?style=flat)

## Business Context

Hotels collect thousands of guest reviews across channels (OTA, direct, surveys) but struggle to extract actionable insights at scale. This project processes 2,000 reviews through a complete NLP and statistical pipeline to answer: Which departments drive satisfaction? Do OTA guests rate differently than direct bookers? How does response time affect scores? What seasonal patterns exist?

## Dashboards

| | |
|:---:|:---:|
| ![Satisfaction Trend](output/plots/01_satisfaction_trend.png) | ![NPS by Month](output/plots/02_nps_by_month.png) |
| **Satisfaction Score Trend** | **Net Promoter Score by Month** |
| ![Dept Satisfaction](output/plots/03_dept_satisfaction.png) | ![Sentiment Keywords](output/plots/04_sentiment_keywords.png) |
| **Department Satisfaction** | **Sentiment Keyword Analysis** |
| ![Rating Distribution](output/plots/05_rating_distribution.png) | ![Satisfaction by Trip](output/plots/06_satisfaction_by_trip.png) |
| **Rating Distribution** | **Satisfaction by Trip Type** |
| ![Sub-Rating Dashboard](output/plots/07_sub_rating_dashboard.png) | ![Correlation Heatmap](output/plots/08_correlation_heatmap.png) |
| **Sub-Rating Dashboard** | **Correlation Heatmap** |

## Key Findings

| Metric | Value | Insight |
|--------|-------|---------|
| OTA vs Direct | **Lower OTA scores** | OTA guests rate lower than direct bookers |
| Top Departments | **Housekeeping & Front Desk** | Most frequently mentioned in reviews |
| Response Time | **Faster = Higher scores** | Significant positive correlation |
| Seasonal Peaks | **Spring & Fall** | Tourism seasons show highest satisfaction |
| NPS Segmentation | **3 categories** | Promoters, Passives, Detractors tracked monthly |

## Project Structure

```
hotel-guest-analytics/
├── scripts/
│   └── guest_satisfaction_pipeline.R     # Complete NLP + analysis pipeline
├── output/
│   └── plots/                            # 8 publication-ready visualizations
├── .gitignore
└── README.md
```

## How to Run

```r
# Requires R >= 4.0 with: tidyverse, tidytext, lubridate, scales
# Run the full pipeline:
source("scripts/guest_satisfaction_pipeline.R")
```

## Tools Used

- **R** (tidyverse): dplyr, tidyr, ggplot2, readr, stringr
- **tidytext**: Sentiment lexicon analysis (Bing, AFINN)
- **lubridate**: Date standardization
- **NLP Methods**: Sentiment scoring, keyword extraction, NPS calculation

## Author

**Deepanshi Behal** | [LinkedIn](https://linkedin.com/in/bdeepanshi) | [GitHub](https://github.com/behaldeepanshi01-gif)
