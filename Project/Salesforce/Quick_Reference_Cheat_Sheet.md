# QUICK REFERENCE CHEAT SHEET
## Business Analyst Assignment - Campaign Effectiveness Analysis

---

## DATA STRUCTURE SUMMARY

```
┌─────────────────────────┐
│   CAMPAIGNS TABLE       │
│  (Campaign Master)      │
├─────────────────────────┤
│ PK: campaign_id         │
│ campaign_name           │
│ campaign_type ★         │
│ activity_type           │
│ budgeted_cost           │
│ campaign_region         │
│ status                  │
│ campaign_start_date     │
│ campaign_end_date       │
└───────────┬─────────────┘
            │ 1
            │
            │ Many
┌───────────▼─────────────┐
│   MEMBERS TABLE         │
│ (Campaign Members)      │
├─────────────────────────┤
│ PK: campaign_member_id  │
│ FK: campaign_id         │
│ lead_id                 │
│ opportunity_id ★★       │
│ salesforce_account_id   │
│ company_segment         │
│ company_industry        │
│ sales_region            │
│ title                   │
│ lead_status             │
└───────────┬─────────────┘
            │ Many
            │
            │ 1
┌───────────▼─────────────┐
│   OPPOS TABLE           │
│  (Opportunities)        │
├─────────────────────────┤
│ PK: opportunity_id      │
│ FK: campaign_id         │
│ opportunity_stage       │
│ opportunity_type        │
│ is_won                  │
│ attribution_model       │
│ influence               │
│ revenue_share_usd ★★★   │
└─────────────────────────┘
```

**KEY INDICATORS:**
- ★ Focus on: 'Field Event', 'Conference', 'Workshop', 'Webinar'
- ★★ NULL = No conversion, NOT NULL = Converted
- ★★★ This is the money field!

---

## ESSENTIAL SQL QUERIES

### 1️⃣ LEAD VOLUME BY CAMPAIGN TYPE
```sql
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY total_leads DESC;
```
**What it shows:** Top-of-funnel performance - which campaigns attract most leads

---

### 2️⃣ CONVERSION RATE BY CAMPAIGN TYPE
```sql
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL
          THEN m.lead_id END) AS converted_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL
          THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY conversion_rate_pct DESC;
```
**What it shows:** Lead quality - which campaigns convert best

---

### 3️⃣ REVENUE BY CAMPAIGN TYPE
```sql
SELECT
    c.campaign_type,
    COUNT(DISTINCT o.opportunity_id) AS total_opportunities,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue_usd,
    ROUND(AVG(o.revenue_share_usd), 2) AS avg_revenue_per_opp
FROM Campaigns c
JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY total_revenue_usd DESC;
```
**What it shows:** Business impact - which campaigns drive revenue

---

### 4️⃣ ROI BY CAMPAIGN TYPE
```sql
SELECT
    c.campaign_type,
    SUM(c.budgeted_cost) AS total_budget,
    SUM(o.revenue_share_usd) AS total_revenue,
    ROUND((SUM(o.revenue_share_usd) - SUM(c.budgeted_cost)) /
          NULLIF(SUM(c.budgeted_cost), 0) * 100, 2) AS roi_pct
FROM Campaigns c
LEFT JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.budgeted_cost > 0
GROUP BY c.campaign_type
ORDER BY roi_pct DESC;
```
**What it shows:** Efficiency - best bang for buck

---

### 5️⃣ PERFORMANCE BY COMPANY SEGMENT
```sql
SELECT
    c.campaign_type,
    m.company_segment,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL
          THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND m.company_segment IS NOT NULL
GROUP BY c.campaign_type, m.company_segment
ORDER BY total_revenue DESC;
```
**What it shows:** Which segments (Enterprise/Mid-Market) work best for each campaign

---

### 6️⃣ PERFORMANCE BY REGION
```sql
SELECT
    c.campaign_region,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL
          THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.campaign_region IS NOT NULL
GROUP BY c.campaign_region, c.campaign_type
ORDER BY total_revenue DESC;
```
**What it shows:** Geographic performance - where campaigns work best

---

### 7️⃣ TOP PERFORMING SEGMENTS (FULL BREAKDOWN)
```sql
SELECT
    m.company_segment,
    m.sales_region,
    m.company_industry,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue,
    ROUND(SUM(o.revenue_share_usd) / COUNT(DISTINCT m.lead_id), 2) AS revenue_per_lead
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND m.company_segment IS NOT NULL
  AND m.sales_region IS NOT NULL
GROUP BY m.company_segment, m.sales_region, m.company_industry, c.campaign_type
HAVING COUNT(DISTINCT m.lead_id) >= 5
ORDER BY revenue_per_lead DESC
LIMIT 20;
```
**What it shows:** Most valuable segment combinations - where to focus investment

---

### 8️⃣ ATTRIBUTION MODEL COMPARISON
```sql
SELECT
    c.campaign_type,
    o.attribution_model,
    COUNT(DISTINCT o.opportunity_id) AS opportunities,
    ROUND(SUM(o.revenue_share_usd), 2) AS attributed_revenue,
    ROUND(AVG(o.influence), 2) AS avg_influence_pct
FROM Campaigns c
JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type, o.attribution_model
ORDER BY c.campaign_type, attributed_revenue DESC;
```
**What it shows:** How different stakeholders view campaign contribution

---

### 9️⃣ UNDERPERFORMERS (High volume, low conversion)
```sql
SELECT
    c.campaign_name,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    COUNT(DISTINCT o.opportunity_id) AS opportunities,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
    c.budgeted_cost
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_name, c.campaign_type, c.budgeted_cost
HAVING COUNT(DISTINCT m.lead_id) >= 20
   AND ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 /
       COUNT(DISTINCT m.lead_id), 2) < 5
ORDER BY leads DESC;
```
**What it shows:** Problem campaigns - high spend/volume but poor results

---

### 🔟 HIGH PERFORMERS (High ROI to scale)
```sql
SELECT
    c.campaign_name,
    c.campaign_type,
    c.campaign_region,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
    c.budgeted_cost,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue,
    ROUND((SUM(o.revenue_share_usd) - c.budgeted_cost) /
          NULLIF(c.budgeted_cost, 0) * 100, 2) AS roi_pct
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.budgeted_cost > 0
GROUP BY c.campaign_name, c.campaign_type, c.campaign_region, c.budgeted_cost
HAVING roi_pct > 100
ORDER BY roi_pct DESC
LIMIT 15;
```
**What it shows:** Winners to replicate - campaigns with strong ROI

---

## SQL SYNTAX QUICK TIPS

### JOINS
```sql
-- INNER JOIN: Only matching records from both tables
FROM Campaigns c
INNER JOIN Members m ON c.campaign_id = m.campaign_id

-- LEFT JOIN: All from left table + matching from right (use for optional data)
FROM Campaigns c
LEFT JOIN Oppos o ON c.campaign_id = o.campaign_id
```

### COUNTING
```sql
-- Total rows (includes duplicates)
COUNT(*)

-- Unique values only
COUNT(DISTINCT lead_id)

-- Conditional counting
COUNT(CASE WHEN opportunity_id IS NOT NULL THEN lead_id END)
COUNT(DISTINCT CASE WHEN opportunity_id IS NOT NULL THEN lead_id END)
```

### FILTERING
```sql
-- WHERE: Filter BEFORE grouping (filters rows)
WHERE campaign_type IN ('Conference', 'Workshop')
WHERE budgeted_cost > 0
WHERE company_segment IS NOT NULL

-- HAVING: Filter AFTER grouping (filters groups)
HAVING COUNT(DISTINCT lead_id) >= 10
HAVING conversion_rate > 15
```

### CALCULATIONS
```sql
-- Conversion rate (%)
ROUND(converted * 100.0 / total, 2)  -- Use 100.0 not 100!

-- ROI (%)
ROUND((revenue - cost) / NULLIF(cost, 0) * 100, 2)
-- NULLIF prevents division by zero

-- Average
ROUND(AVG(revenue_share_usd), 2)

-- Sum
ROUND(SUM(revenue_share_usd), 2)
```

### NULL HANDLING
```sql
-- Check for NULL
WHERE opportunity_id IS NULL      -- No conversion
WHERE opportunity_id IS NOT NULL  -- Has conversion

-- Replace NULL with default value
COALESCE(budgeted_cost, 0)

-- Avoid division by zero
NULLIF(total_cost, 0)
```

---

## KEY METRICS DEFINITIONS

| Metric | Formula | What It Means |
|--------|---------|---------------|
| **Lead Volume** | COUNT(DISTINCT lead_id) | Total unique leads generated |
| **Conversion Rate** | (Converted Leads / Total Leads) × 100 | % of leads that became opportunities |
| **Total Revenue** | SUM(revenue_share_usd) | Total attributed revenue |
| **Avg Deal Size** | AVG(revenue_share_usd) | Average revenue per opportunity |
| **ROI** | ((Revenue - Cost) / Cost) × 100 | Return on investment % |
| **Revenue per Lead** | Total Revenue / Total Leads | Value per lead generated |
| **Cost per Lead** | Total Budget / Total Leads | Efficiency metric |
| **Cost per Opportunity** | Total Budget / Total Opportunities | Acquisition cost |

---

## BUSINESS QUESTIONS → SQL MAPPING

| Business Question | SQL Approach | Key Tables |
|-------------------|--------------|------------|
| Which campaigns generate most leads? | COUNT(DISTINCT lead_id) GROUP BY campaign_type | Campaigns + Members |
| Which convert best? | Calculate conversion rate | Campaigns + Members |
| Which drive revenue? | SUM(revenue_share_usd) | All 3 tables |
| Which are most efficient? | ROI calculation | All 3 tables |
| Best segment/region? | GROUP BY segment, region | All 3 tables |
| Attribution differences? | GROUP BY attribution_model | Campaigns + Oppos |
| Problem campaigns? | High leads + Low conversion | All 3 tables |
| Winners to scale? | High ROI filter | All 3 tables |

---

## PRESENTATION STRUCTURE (10 MINUTES)

### Slide 1: Introduction (1 min)
- "Analyzed 200+ campaigns across 4 event types"
- "Focus: Field Events, Conferences, Workshops, Webinars"
- "3 key metrics: Volume, Conversion, Revenue"

### Slide 2: Executive Summary (2 min)
**Table format:**
| Campaign Type | Leads | Conv % | Revenue | ROI % |
|--------------|-------|--------|---------|-------|
| Conference | XXX | XX% | $XXX | XX% |
| Field Event | XXX | XX% | $XXX | XX% |
| Workshop | XXX | XX% | $XXX | XX% |
| Webinar | XXX | XX% | $XXX | XX% |

### Slide 3: Key Insight #1 (2 min)
- **Finding**: [Specific data point]
- **Implication**: What it means for business
- **Visual**: Chart or graph

### Slide 4: Key Insight #2 (1 min)
- Segment-specific finding
- Geographic or industry pattern

### Slide 5: Recommendations (3 min)
**3-5 prioritized recommendations:**
1. [Action] - [Data support] - [Expected impact]
2. [Action] - [Data support] - [Expected impact]
3. [Action] - [Data support] - [Expected impact]

### Slide 6: Q&A (1 min)
- "Happy to dive deeper into any area"
- "Can show SQL queries and methodology"

---

## TOUGH QUESTIONS & ANSWERS

### Q: "How reliable is this attribution data?"
**A:** "Attribution models are estimates, not certainties. That's why I looked at multiple models - Salesforce, First Touch, Last Touch, Data-Driven. The patterns are consistent across models: Conferences show strong performance in all views. However, I'd recommend we also track campaign influence manually for validation."

### Q: "This shows correlation, but is it causation?"
**A:** "Great point. This analysis shows which campaigns correlate with conversions and revenue, but there could be other factors - sales follow-up quality, timing, market conditions. To establish causation, I'd recommend A/B testing and comparing similar segments with/without campaigns."

### Q: "Sample sizes are small for some segments. Are they significant?"
**A:** "You're right to question that. I filtered for segments with at least 5-10 leads to avoid noise. For high-confidence recommendations, I focused on segments with 20+ leads. Smaller segments with interesting patterns should be tested with targeted campaigns before scaling."

### Q: "What if we reallocate budget as you suggest and it doesn't work?"
**A:** "I recommend phased rollout: increase conference budget by 20% first, measure results over 1-2 quarters, then scale further if validated. Also set clear KPIs: if we don't see at least 15% conversion rate and 150% ROI, we pause and investigate."

### Q: "Different teams measure success differently. Which metric should we prioritize?"
**A:** "It depends on business stage:
- **Growth stage**: Prioritize lead volume and revenue
- **Efficiency stage**: Prioritize ROI and conversion rate
- **Balanced approach**: Weight all metrics (my recommendation)

For this analysis, I used a balanced scorecard considering all four metrics, with higher weight on revenue since the goal is opportunity conversion."

---

## FINAL CHECKLIST

Before the interview:
- [ ] Run all 10 essential queries
- [ ] Create executive summary table
- [ ] Identify top 3 insights with specific data
- [ ] Write 3-5 recommendations with expected impact
- [ ] Prepare 1-2 visualizations (charts/tables)
- [ ] Practice 10-minute presentation
- [ ] Review attribution model concepts
- [ ] Prepare answers to tough questions
- [ ] Understand limitations of the analysis
- [ ] Get comfortable explaining SQL logic

During the interview:
- [ ] Start with business context, not SQL
- [ ] Use specific numbers, not vague statements
- [ ] Connect every insight to a recommendation
- [ ] Acknowledge data limitations
- [ ] Show analytical thinking, not just results
- [ ] Tailor answers to each interviewer's perspective
- [ ] Ask clarifying questions if needed
- [ ] Be confident but not overconfident

---

## CONFIDENCE BOOSTERS

**You know this!**
- You completed MySQL Bootcamp ✓
- You understand JOINs, GROUP BY, aggregations ✓
- You can calculate conversion rates ✓
- You think analytically ✓

**They're looking for:**
- Can you use SQL? → YES
- Can you think like a BA? → YES
- Can you communicate insights? → YES
- Are you teachable? → YES

**Remember:**
- It's okay to think before answering
- It's okay to ask clarifying questions
- It's okay to acknowledge uncertainty
- It's NOT okay to make up answers

**You've got this! 🎯**

---

## EMERGENCY SQL TEMPLATES

If you freeze during the interview, use these templates:

**Basic Performance Query:**
```sql
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conv_rate
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type;
```

**Segment Breakdown:**
```sql
SELECT
    m.company_segment,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND m.company_segment IS NOT NULL
GROUP BY m.company_segment, c.campaign_type;
```

Just adapt these to whatever question is asked!

---