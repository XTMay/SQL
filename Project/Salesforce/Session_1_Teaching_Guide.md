# SESSION 1: Business Analyst Assignment - Teaching Guide

## Assignment Overview

**Task**: Analyze the effectiveness of different event campaigns (Field Event, Webinars, Conference, Workshop) and provide insights on which campaigns and segments to invest more in.

**Goal**: Drive conversions to opportunities

**Time Limit**: 2-3 hours

**Deliverable**: Analysis + insights + recommendations + presentation explaining your process

---

## PART 1: Understanding the Data Structure

### 1.1 Three Main Tables

#### **Campaigns Table** (Campaign Master Data)
```
Key Fields:
- campaign_id (PK)
- campaign_name
- campaign_type (Field Event, Conference, Workshop, Webinar, etc.)
- activity_type (Events, Campaigns, Other)
- hierarchy_level (1=Fiscal Year, 3=Campaign, 4=Activity)
- status (Planned, Completed, In Progress)
- budgeted_cost
- campaign_region (Global, APAC, EMEA, Americas)
- is_partner_campaign (TRUE/FALSE)
- campaign_start_date, campaign_end_date
- parent_campaign_id (for hierarchy)
```

**What it tells us**: Basic campaign information and budget allocation

---

#### **Members Table** (Campaign Members/Leads)
```
Key Fields:
- campaign_member_id (PK)
- campaign_id (FK to Campaigns)
- lead_id
- opportunity_id (many are NULL - means no conversion yet)
- salesforce_account_id
- title (job title)
- lead_status (Known, Recycle, Working)
- company_segment (Mid-Market, Enterprise)
- company_industry
- sales_region
```

**What it tells us**: Who attended/engaged with each campaign (the leads/prospects)

**Critical Insight**: If `opportunity_id` is NULL → Lead did NOT convert to opportunity
If `opportunity_id` has value → Lead DID convert to opportunity

---

#### **Oppos Table** (Opportunities/Deals)
```
Key Fields:
- opportunity_id (PK)
- opportunity_stage (Closed Lost, ID Business Initiative, etc.)
- opportunity_type (New customer, Existing customer)
- is_won (TRUE/FALSE)
- campaign_id
- attribution_model (Salesforce Model, Last Touch, First Touch, etc.)
- influence (percentage - how much credit this campaign gets)
- revenue_share_usd (revenue attributed to this campaign)
```

**What it tells us**: Which campaigns influenced actual sales opportunities and revenue

---

### 1.2 How Tables Connect (Relationship Diagram)

```
Campaigns
    ↓ (1 to many)
Members (Campaign Members/Leads)
    ↓ (many to 1)
Oppos (Opportunities)
```

**The Flow**:
1. A campaign is created (Campaigns table)
2. Leads/prospects join the campaign (Members table)
3. Some leads convert to opportunities (Oppos table)

---

## PART 2: Key Metrics to Calculate

### 2.1 Campaign Performance Metrics

#### **Metric 1: Lead Volume**
How many leads did each campaign type generate?

```sql
-- Total leads per campaign type
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY total_leads DESC;
```

**Why it matters**: Shows top-of-funnel performance

---

#### **Metric 2: Conversion Rate**
What percentage of leads converted to opportunities?

```sql
-- Conversion rate by campaign type
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) AS converted_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY conversion_rate_pct DESC;
```

**Why it matters**: High lead volume is worthless if they don't convert. This shows quality.

---

#### **Metric 3: Revenue Impact**
How much revenue is attributed to each campaign type?

```sql
-- Total attributed revenue by campaign type
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

**Why it matters**: Shows bottom-line business impact

---

#### **Metric 4: ROI (Return on Investment)**
Which campaigns give the best return?

```sql
-- ROI by campaign type
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

**Why it matters**: Tells us bang-for-buck - which campaign types are most efficient

---

### 2.2 Segmentation Analysis

#### **By Company Segment** (Enterprise vs Mid-Market)

```sql
-- Conversion rate by company segment and campaign type
SELECT
    c.campaign_type,
    m.company_segment,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) AS converted_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND m.company_segment IS NOT NULL
GROUP BY c.campaign_type, m.company_segment
ORDER BY c.campaign_type, conversion_rate_pct DESC;
```

**Insight to look for**: Do Enterprise companies convert better at Conferences while Mid-Market prefers Webinars?

---

#### **By Region** (APAC, EMEA, Americas)

```sql
-- Performance by region
SELECT
    c.campaign_region,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate_pct,
    SUM(o.revenue_share_usd) AS total_revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.campaign_region IS NOT NULL
GROUP BY c.campaign_region, c.campaign_type
ORDER BY c.campaign_region, total_revenue DESC;
```

**Insight to look for**: Does APAC perform better with Field Events? Is EMEA more responsive to digital?

---

#### **By Industry**

```sql
-- Top performing industries per campaign type
SELECT
    c.campaign_type,
    m.company_industry,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    COUNT(DISTINCT o.opportunity_id) AS opportunities,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conversion_rate,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND m.company_industry IS NOT NULL
GROUP BY c.campaign_type, m.company_industry
HAVING COUNT(DISTINCT m.lead_id) >= 10  -- Only industries with significant volume
ORDER BY c.campaign_type, conversion_rate DESC;
```

**Insight to look for**: Software companies might prefer workshops, Finance might prefer conferences

---

### 2.3 Attribution Model Analysis

**Understanding Attribution Models**:
- **First Touch**: Credit goes to the first campaign that touched the lead
- **Last Touch**: Credit goes to the last campaign before opportunity creation
- **Even Distribution**: Credit split equally among all campaigns
- **Data-Driven**: Credit allocated based on ML/statistical analysis
- **Salesforce Model**: Salesforce's default attribution logic

```sql
-- Compare attribution models for campaign effectiveness
SELECT
    c.campaign_type,
    o.attribution_model,
    COUNT(DISTINCT o.opportunity_id) AS opportunities,
    ROUND(SUM(o.revenue_share_usd), 2) AS attributed_revenue
FROM Campaigns c
JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type, o.attribution_model
ORDER BY c.campaign_type, o.attribution_model;
```

**Why it matters**: Different stakeholders (marketing, sales, sales ops) may favor different models. You need to understand how each model views campaign contribution.

---

## PART 3: Analysis Framework (Step-by-Step Approach)

### Step 1: Executive Summary Metrics (15 min)
Calculate these first to get the big picture:

```sql
-- Overall campaign performance snapshot
SELECT
    c.campaign_type,
    COUNT(DISTINCT c.campaign_id) AS total_campaigns,
    COUNT(DISTINCT m.lead_id) AS total_leads,
    COUNT(DISTINCT o.opportunity_id) AS total_opportunities,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conversion_rate,
    SUM(c.budgeted_cost) AS total_budget,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue,
    ROUND(AVG(o.revenue_share_usd), 2) AS avg_deal_size
FROM Campaigns c
LEFT JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type
ORDER BY total_revenue DESC;
```

**Create a summary table** showing:
- Which campaign type has highest volume?
- Which has highest conversion rate?
- Which drives most revenue?
- Which has best ROI?

---

### Step 2: Segment Deep Dive (30 min)
For each high-performing campaign type, analyze:
- Best performing company segments
- Best performing regions
- Best performing industries
- Best performing lead titles/seniority

**Example**:
```sql
-- If Conference is top performer, which segments work best?
SELECT
    m.company_segment,
    m.company_industry,
    m.sales_region,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type = 'Conference'
  AND m.company_segment IS NOT NULL
GROUP BY m.company_segment, m.company_industry, m.sales_region
ORDER BY revenue DESC
LIMIT 10;
```

---

### Step 3: Identify Opportunities (20 min)
Look for:

#### **Underperforming campaigns with potential**
```sql
-- Campaigns with high leads but low conversion
SELECT
    c.campaign_name,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    COUNT(DISTINCT o.opportunity_id) AS opps,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conv_rate
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_name, c.campaign_type
HAVING COUNT(DISTINCT m.lead_id) >= 20
   AND ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) < 5
ORDER BY leads DESC;
```

**Question to ask**: Why are these campaigns getting leads but not converting? Wrong audience? Poor follow-up?

---

#### **High performers to scale**
```sql
-- Campaigns with high ROI that we should double down on
SELECT
    c.campaign_name,
    c.campaign_type,
    c.budgeted_cost,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue,
    ROUND((SUM(o.revenue_share_usd) - c.budgeted_cost) / NULLIF(c.budgeted_cost, 0) * 100, 2) AS roi_pct
FROM Campaigns c
LEFT JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.budgeted_cost > 0
GROUP BY c.campaign_name, c.campaign_type, c.budgeted_cost
HAVING roi_pct > 100  -- More than 100% ROI
ORDER BY roi_pct DESC;
```

---

### Step 4: Build Recommendations (25 min)

Create a structured recommendation framework:

#### **Investment Priority Matrix**

| Campaign Type | Volume | Conversion | Revenue | ROI | Recommendation |
|--------------|--------|------------|---------|-----|----------------|
| Conference | High | High | High | Medium | **Maintain & Scale** |
| Field Event | Medium | High | High | Low | **Optimize Cost** |
| Workshop | Low | Medium | Medium | High | **Increase Investment** |
| Webinar | High | Low | Low | High | **Improve Quality** |

---

#### **Segment-Specific Recommendations**

Example structure:
```
1. Enterprise Segment
   - Best channel: Conferences
   - Best region: Americas
   - Best industry: Software, Finance
   - Recommendation: Invest 60% of budget in Americas conferences targeting
     Software/Finance enterprise companies

2. Mid-Market Segment
   - Best channel: Workshops
   - Best region: APAC
   - Best industry: Retail, Manufacturing
   - Recommendation: Scale APAC workshops with focus on practical,
     hands-on content for Retail/Manufacturing
```

---

## PART 4: SQL Query Templates for Common Questions

### Q1: "Which campaign type should we invest more in?"

**Answer Framework**:
1. Run executive summary query (Step 1)
2. Rank by: Total Revenue → ROI → Conversion Rate
3. Recommendation: "Invest in [X] because it has [Y revenue] with [Z%] ROI"

---

### Q2: "What segments should we target?"

```sql
-- Best performing segment combinations
SELECT
    m.company_segment,
    m.sales_region,
    m.company_industry,
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
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

**Answer**: "Focus on [Enterprise + Americas + Software] using [Conferences] - highest revenue per lead"

---

### Q3: "Are there any patterns in conversion timing?"

```sql
-- Time from campaign to opportunity creation
SELECT
    c.campaign_type,
    ROUND(AVG(DATEDIFF(day, c.campaign_start_date, o.opportunity_created_date)), 1) AS avg_days_to_opp,
    MIN(DATEDIFF(day, c.campaign_start_date, o.opportunity_created_date)) AS min_days,
    MAX(DATEDIFF(day, c.campaign_start_date, o.opportunity_created_date)) AS max_days
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND o.opportunity_created_date >= c.campaign_start_date
GROUP BY c.campaign_type
ORDER BY avg_days_to_opp;
```

**Insight**: "Field Events convert faster (30 days) vs Webinars (90 days) - suggests different lead quality"

---

### Q4: "Partner campaigns vs. non-partner campaigns?"

```sql
-- Partner campaign performance
SELECT
    c.campaign_type,
    c.is_partner_campaign,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conv_rate,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type, c.is_partner_campaign
ORDER BY c.campaign_type, revenue DESC;
```

---

## PART 5: Presentation Structure

### Recommended Flow (for panel interview)

**1. Introduction (2 min)**
- "I analyzed X campaigns across 4 types (Field Event, Conference, Workshop, Webinar)"
- "Used 3 data tables: Campaigns, Members, and Opportunities"
- "Focused on 3 key metrics: lead volume, conversion rate, and attributed revenue"

**2. Executive Summary (3 min)**
- Present the summary table (Step 1)
- "Here's what the data shows at a high level..."
- Highlight: Best performer, biggest opportunity, biggest concern

**3. Key Insights (5 min)**
Show 3-4 specific insights with data:

Example:
- "Conferences drive 45% of total revenue despite being only 25% of campaigns"
- "Enterprise segment converts 3x better than Mid-Market for Field Events"
- "APAC region has 60% lower costs but similar revenue to Americas"

**4. Recommendations (3 min)**
- Prioritized list of 3-5 actionable recommendations
- Each with: What to do, Why (data-backed), Expected impact

Example:
```
Recommendation 1: Double conference budget in Americas for Enterprise/Software segment
- Why: 28% conversion rate vs. 12% average, $500K revenue per campaign
- Expected impact: +$2M in pipeline if we run 4 more conferences
```

**5. Process Explanation (2 min)**
When asked "How did you do this analysis?":

- "First, I explored the data structure and relationships"
- "Then calculated core metrics: volume, conversion, revenue, ROI"
- "Segmented by company size, region, industry to find patterns"
- "Identified outliers - both high performers and underperformers"
- "Built prioritized recommendations based on ROI and strategic fit"

---

## PART 6: Stakeholder-Specific Talking Points

### For Marketing Team Interviewer:
Focus on:
- Lead quality and volume
- Campaign creative/format effectiveness
- Multi-touch attribution
- Budget optimization

**Sample talking point**: "From a marketing perspective, Conferences generate the highest quality leads with 25% conversion rate, but Webinars have 5x the volume. I recommend a blended approach..."

---

### For Sales Operations Interviewer:
Focus on:
- Conversion rates and funnel velocity
- Lead routing and follow-up effectiveness
- Attribution model implications
- Forecast accuracy

**Sample talking point**: "Looking at the data from a sales ops lens, I noticed Field Events have the fastest time-to-opportunity (30 days avg), which helps with quarter-end pipeline building..."

---

### For Sales Team Interviewer:
Focus on:
- Deal size and quality
- Win rates
- Customer segment fit
- Sales cycle length

**Sample talking point**: "From a sales perspective, Enterprise conferences deliver 3x larger deal sizes ($50K vs $15K), which means fewer deals needed to hit quota..."

---

## PART 7: Common Pitfalls to Avoid

### Data Analysis Pitfalls:

1. **Don't ignore NULL values**
   - Many opportunity_id fields are NULL (no conversion)
   - Many budgeted_cost = 0 (handle in ROI calculation)

2. **Don't mix hierarchy levels**
   - hierarchy_level = 1 is fiscal year (not individual campaign)
   - Focus on level 3 or 4 for actual campaigns

3. **Don't forget to filter campaign_type**
   - Assignment asks specifically for: Field Event, Webinars, Conference, Workshop
   - Don't include "Digital Campaign", "Email", "Form", etc.

4. **Don't ignore attribution models**
   - Different models give different revenue credit
   - Explain which model you're using and why

---

### Presentation Pitfalls:

1. **Don't just show SQL queries**
   - Show insights, not code
   - Use tables, charts (if possible in Google Sheets)

2. **Don't make recommendations without data**
   - Always tie recommendations to specific metrics
   - "Because X metric shows Y, we should do Z"

3. **Don't forget the "why"**
   - Explain your reasoning
   - Show you understand the business context

4. **Don't oversell certainty**
   - Use language like "data suggests", "analysis indicates"
   - Acknowledge limitations (e.g., "this assumes attribution is accurate")

---

## PART 8: Time Management Strategy

**Total: 2-3 hours**

### Recommended Timeline:

**Hour 1: Data Exploration & Core Metrics**
- 0-15 min: Understand data structure, explore tables
- 15-45 min: Calculate executive summary metrics (all campaign types)
- 45-60 min: Initial insights - rank campaign types

**Hour 2: Segmentation & Deep Dive**
- 60-90 min: Segment analysis (company size, region, industry)
- 90-110 min: Identify specific opportunities and issues
- 110-120 min: Run attribution model analysis

**Hour 3: Synthesis & Recommendations**
- 120-140 min: Build recommendation framework
- 140-160 min: Create presentation structure/talking points
- 160-180 min: Practice explanation and review

---

## PART 9: Key SQL Techniques to Demonstrate

### Technique 1: LEFT JOIN vs INNER JOIN
```sql
-- INNER JOIN: Only shows campaigns that have members
SELECT c.campaign_name, COUNT(m.lead_id)
FROM Campaigns c
INNER JOIN Members m ON c.campaign_id = m.campaign_id
GROUP BY c.campaign_name;

-- LEFT JOIN: Shows ALL campaigns, even those with zero members
SELECT c.campaign_name, COUNT(m.lead_id)
FROM Campaigns c
LEFT JOIN Members m ON c.campaign_id = m.campaign_id
GROUP BY c.campaign_name;
```

**When to use**: Use LEFT JOIN when you want to include campaigns with zero leads (to show campaigns that didn't perform)

---

### Technique 2: CASE WHEN for Conditional Logic
```sql
-- Flag high/medium/low performers
SELECT
    campaign_type,
    COUNT(*) AS campaigns,
    CASE
        WHEN AVG(conversion_rate) >= 20 THEN 'High Performer'
        WHEN AVG(conversion_rate) >= 10 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_tier
FROM (
    -- Subquery calculating conversion rates
    SELECT
        c.campaign_type,
        ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS conversion_rate
    FROM Campaigns c
    JOIN Members m ON c.campaign_id = m.campaign_id
    LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
    GROUP BY c.campaign_id, c.campaign_type
) AS campaign_performance
GROUP BY campaign_type;
```

---

### Technique 3: HAVING vs WHERE
```sql
-- WHERE: Filters BEFORE grouping (filter rows)
SELECT campaign_type, COUNT(*) AS campaigns
FROM Campaigns
WHERE status = 'Completed'  -- Filter campaigns BEFORE counting
GROUP BY campaign_type;

-- HAVING: Filters AFTER grouping (filter groups)
SELECT campaign_type, COUNT(*) AS campaigns
FROM Campaigns
GROUP BY campaign_type
HAVING COUNT(*) >= 5;  -- Only show campaign types with 5+ campaigns
```

---

### Technique 4: Subqueries for Complex Calculations
```sql
-- Find campaign types that perform above average
SELECT
    campaign_type,
    avg_conversion_rate,
    overall_average
FROM (
    SELECT
        c.campaign_type,
        ROUND(COUNT(DISTINCT o.opportunity_id) * 100.0 / COUNT(DISTINCT m.lead_id), 2) AS avg_conversion_rate,
        (SELECT ROUND(COUNT(DISTINCT o2.opportunity_id) * 100.0 / COUNT(DISTINCT m2.lead_id), 2)
         FROM Members m2
         LEFT JOIN Oppos o2 ON m2.opportunity_id = o2.opportunity_id) AS overall_average
    FROM Campaigns c
    JOIN Members m ON c.campaign_id = m.campaign_id
    LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
    WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
    GROUP BY c.campaign_type
) AS comparison
WHERE avg_conversion_rate > overall_average;
```

---

### Technique 5: COALESCE and NULLIF for NULL Handling
```sql
-- Avoid division by zero and handle NULLs
SELECT
    campaign_type,
    total_revenue,
    total_cost,
    ROUND((total_revenue - COALESCE(total_cost, 0)) /
          NULLIF(total_cost, 0) * 100, 2) AS roi_pct
FROM (
    SELECT
        c.campaign_type,
        SUM(o.revenue_share_usd) AS total_revenue,
        SUM(c.budgeted_cost) AS total_cost
    FROM Campaigns c
    LEFT JOIN Oppos o ON c.campaign_id = o.campaign_id
    GROUP BY c.campaign_type
) AS summary;
```

**COALESCE**: Returns first non-NULL value (treats NULL as 0)
**NULLIF**: Returns NULL if values are equal (prevents division by zero)

---

## PART 10: Practice Questions & Answers

### Q1: "How would you measure campaign effectiveness?"

**Good Answer**:
"I'd look at three dimensions:
1. **Volume**: How many leads did it generate?
2. **Quality**: What's the conversion rate to opportunities?
3. **Value**: How much attributed revenue did it drive?

Then I'd calculate efficiency metrics like cost-per-lead and ROI to determine which campaigns give the best return on investment."

---

### Q2: "What if marketing and sales disagree on which campaigns work best?"

**Good Answer**:
"This often comes down to attribution models. Marketing might prefer first-touch attribution (which campaign started the relationship), while sales prefers last-touch (which campaign closed the deal).

I'd present both views, then recommend using a data-driven or even-distribution model as a compromise. I'd also show that different campaign types serve different purposes - awareness campaigns vs. conversion campaigns."

---

### Q3: "How would you handle campaigns with zero conversions?"

**Good Answer**:
"First, I'd segment them:
1. **Recent campaigns**: May not have had time to convert yet - I'd track these separately
2. **Low-quality campaigns**: Wrong audience, poor execution - recommend stopping
3. **Top-of-funnel campaigns**: Designed for awareness, not immediate conversion - measure differently

I wouldn't immediately cut all zero-conversion campaigns, but I'd investigate why and set timeframes for improvement."

---

### Q4: "The data shows conflicting results - high leads but low revenue. What do you recommend?"

**Good Answer**:
"This suggests a lead quality issue. I'd investigate:
1. **Audience targeting**: Are we attracting the right personas?
2. **Sales follow-up**: Are leads being contacted quickly?
3. **Lead scoring**: Should we qualify leads better before passing to sales?

My recommendation would be to reduce volume slightly and focus on quality - target more specific segments that have shown higher conversion rates in the data."

---

## PART 11: Quick Reference - Must-Know SQL Patterns

```sql
-- Pattern 1: Basic campaign performance
SELECT
    c.campaign_type,
    COUNT(DISTINCT m.lead_id) AS leads,
    COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) AS converted_leads,
    ROUND(COUNT(DISTINCT CASE WHEN m.opportunity_id IS NOT NULL THEN m.lead_id END) * 100.0 /
          COUNT(DISTINCT m.lead_id), 2) AS conversion_rate
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type;

-- Pattern 2: Revenue analysis
SELECT
    c.campaign_type,
    COUNT(DISTINCT o.opportunity_id) AS opportunities,
    ROUND(SUM(o.revenue_share_usd), 2) AS total_revenue,
    ROUND(AVG(o.revenue_share_usd), 2) AS avg_deal_size
FROM Campaigns c
JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type;

-- Pattern 3: Segmentation
SELECT
    c.campaign_type,
    m.company_segment,
    m.sales_region,
    COUNT(DISTINCT m.lead_id) AS leads,
    ROUND(SUM(o.revenue_share_usd), 2) AS revenue
FROM Campaigns c
JOIN Members m ON c.campaign_id = m.campaign_id
LEFT JOIN Oppos o ON m.opportunity_id = o.opportunity_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
GROUP BY c.campaign_type, m.company_segment, m.sales_region
ORDER BY revenue DESC;

-- Pattern 4: ROI calculation
SELECT
    c.campaign_type,
    SUM(c.budgeted_cost) AS cost,
    SUM(o.revenue_share_usd) AS revenue,
    ROUND((SUM(o.revenue_share_usd) - SUM(c.budgeted_cost)) /
          NULLIF(SUM(c.budgeted_cost), 0) * 100, 2) AS roi_pct
FROM Campaigns c
LEFT JOIN Oppos o ON c.campaign_id = o.campaign_id
WHERE c.campaign_type IN ('Field Event', 'Conference', 'Workshop', 'Webinar')
  AND c.budgeted_cost > 0
GROUP BY c.campaign_type;
```

---

## Final Checklist Before Presentation

- [ ] Calculated all core metrics (leads, conversion, revenue, ROI)
- [ ] Identified top 3 insights with data backing
- [ ] Created 3-5 specific, actionable recommendations
- [ ] Can explain SQL logic for key queries
- [ ] Prepared for stakeholder-specific questions
- [ ] Have examples ready for each recommendation
- [ ] Understand attribution model implications
- [ ] Know the limitations of the analysis
- [ ] Can explain the analysis process clearly
- [ ] Practiced 10-15 min presentation flow

---

## Remember:

1. **Focus on business impact**, not just technical skills
2. **Tell a story** with the data, don't just show numbers
3. **Be ready to defend** your recommendations with data
4. **Acknowledge uncertainty** where appropriate
5. **Show curiosity** - ask clarifying questions if needed
6. **Think like a BA** - connect data to business decisions

