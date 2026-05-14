# 🦠 COVID-19 Impact & Vaccination Effectiveness Analysis

> A full analytical deep-dive into **405,726 daily records** across **243 countries** from the Our World in Data (OWID) dataset.  
> Built to quantify the vaccination–mortality link and isolate the structural drivers of pandemic outcomes.

---

## 🗂️ Project Structure

```
covid-impact-analysis/
│
├── sql/
│   └── covid_analysis.sql          # Full SQL code with inline documentation
│
├── docs/
│   └── COVID_Analysis_Documentation.pdf
│
└── README.md
```

---

## ❓ Research Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Did vaccination reduce COVID death rates? | ✅ Answered |
| 2 | Does GDP per capita predict outcomes better than continent? | ✅ Answered |
| 3 | How did the case-fatality rate evolve over time? | ✅ Answered |
| 4 | Which countries had the most deaths and highest vaccination rates? | ✅ Answered |
| 5 | Is Africa's low reported death rate real or a data artefact? | ✅ Answered |

---

## 🔑 Key Findings

### 💉 Vaccination vs Death Rate

| Vaccination Band | Countries | Avg Death Rate |
|-----------------|-----------|----------------|
| 0 – 20%          | 40        | **1.40%**      |
| 20 – 40%         | 36        | 2.04%          |
| 40 – 60%         | 50        | 1.35%          |
| 60 – 80%         | 72        | 0.88%          |
| 80%+             | 45        | **0.57%**      |

> ✅ Countries above 80% vaccination had **2.5× lower death rates** than countries below 20%

### 💰 GDP Per Capita — The Stronger Predictor

| GDP Band   | Countries | Avg Death Rate | Avg Vax Rate |
|------------|-----------|----------------|--------------|
| < $5k      | —         | **1.92%**      | 34%          |
| $5k–$15k   | —         | 1.61%          | 52%          |
| $15k–$30k  | —         | 1.14%          | 60%          |
| $30k–$50k  | —         | 0.58%          | 73%          |
| $50k+      | —         | **0.35%**      | 79%          |

> 📌 A **5.5× gap** in death rate between the poorest and richest country bands — GDP outperforms continent as a predictor

### 🌍 Deaths per Million by Continent

| Continent      | Deaths per Million |
|----------------|--------------------|
| South America  | **3,104**          |
| North America  | 2,784              |
| Europe         | 2,581              |
| Oceania        | 731                |
| Asia           | 347                |
| Africa         | **182** ⚠️         |

> ⚠️ Africa's 182 deaths/M is implausibly low — almost certainly reflects testing and reporting gaps, not true mortality

### 📅 Timeline Highlights

- **March–April 2020**: CFR reported at 6–9% (early testing only captured the sickest patients)
- **Late 2020 (Alpha wave)**: First major case peak
- **Dec 2021 – Feb 2022 (Omicron)**: 4× the case volume of Alpha, but far lower CFR due to vaccine rollout
- **By mid-2022**: Monthly CFR fell below 0.5%

---

## 🛠️ Tools & Technologies

| Tool | Usage |
|------|-------|
| SQL Server (T-SQL) | Data exploration, view creation, analytical queries |
| Excel | Charts, pivot tables, dashboard |
| OWID Dataset | Source data (Our World in Data) |

---

## 📐 Methodology

```
Phase 0 → Data Import & Exploration
Phase 1 → Create Country_Summary analytical view
Phase 2 → Data Quality & Integrity Checks
Phase 3 → Monthly Trend & Seasonality Analysis
Phase 4 → Vaccination Effectiveness (main analysis)
Phase 5 → GDP & Continent Confounders
Supplementary → Country rankings (deaths, vaccination)
```

---

## ✅ What's Done / 🔜 What's Next

### ✅ Done

- [x] SQL analytical panel (`Country_Summary` view)
- [x] Data quality checks (NULLs, negatives, duplicates, region rows)
- [x] Monthly trend + 7-day rolling average
- [x] Vaccination band analysis
- [x] GDP per capita vs death rate deep-dive
- [x] Continent-level rollup
- [x] Country rankings

### 🔜 Planned

- [ ] Power BI / Tableau interactive dashboard
- [ ] Python / pandas replication of key analyses
- [ ] Excess mortality estimation
- [ ] Predictive model: expected deaths given vax rate

---

## 📁 How to Run

1. Download the **OWID COVID dataset** (daily CSV) from [Our World in Data](https://ourworldindata.org/coronavirus)
2. Import into SQL Server as `dbo.OwidCovid` (keep columns: `location`, `continent`, `date`, `total_cases`, `total_deaths`, `new_cases`, `new_deaths`, `people_fully_vaccinated`, `population`, `gdp_per_capita`)
3. Open `sql/covid_analysis.sql`
4. Run **top to bottom** — phases are clearly marked with comments
5. The script creates `dbo.Country_Summary` and all analysis queries

---

## 💡 Recommendations

**Equity**
- Low-income countries averaged 34% vaccination vs 79% for high-income — COVAX-style global supply mechanisms need stronger funding and earlier delivery in the next pandemic

**Surveillance**
- Undercounting in low-resource regions distorts the global picture — routine population testing and seroprevalence studies should be standing infrastructure, not crisis add-ons

**Reporting Standards**
- CFR comparisons are unreliable without consistent definitions for COVID-attributed death, testing rate, and population denominators — WHO-coordinated reporting standards are needed

**Data Preservation**
- OWID's daily country-level dataset is one of the few clean, comparable cross-country pandemic archives — funding open, longitudinal datasets is the cheapest preparedness investment a government can make

---

## 📊 Global Stats

| Metric | Value |
|--------|-------|
| Total Cases | 775.9M (243 countries) |
| Total Deaths | 7.06M |
| Period | 2020-01 to 2024-08 |
| Avg Country Death Rate (CFR) | 1.23% |
| Avg Country Vaccination Rate | 58.0% |

---

*Dataset: Our World in Data COVID-19 | Period: Jan 2020 – Aug 2024 | 405,726 records*
