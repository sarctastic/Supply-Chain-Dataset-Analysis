# Supply Chain Analysis for 'DataCoSmartSupply' Dataset
### In-depth analysis of the supply chain and operations of a dataset emulating a logistics, courier, and package delivery company: storage, throughput, average traffic. Pinpointing major drivers of revenue, and the major effects of the surrounding economic environment.

---

## Team Members
- **Omar Mohamed Abdelaziz**
- **Ahmed Tarek**
- **Mazen Waleed Fathy**

---

## Instructor
**Amal Mahmoud**

---

## Project Overview
An end-to-end operational, financial, and logistical analysis of the DataCo Smart Supply Chain transactional network. This project details the data engineering, relational star-schema modeling, and front-end analytical design required to transform fragmented shipping rows into structured business intelligence. By mapping fulfillment attributes against financial outcomes, the project isolates core inefficiencies like systemic 1-day transit delays and aggressive discounting patterns to optimize corporate bottom-line margins.

---

## Project Objectives
* **Analyze Line Inputs and Outputs:** Audit the end-to-end throughput of transactional order entries mapped against real-world logistical dispatch variables.
* **Determine Key Revenue Drivers:** Isolate gross revenue performance across geographic markets and product lines, identifying high-velocity segments like the Fan Shop and Apparel categories.
* **Track Highest Risk Factors:** Quantify supply chain vulnerabilities by monitoring late delivery triggers and measuring absolute deviations between scheduled and actual transit windows.
* **Determine Key Areas of Improvement:** Pinpoint financial leakage resulting from sub-optimal discount rates across low-margin product categories.

---

## Project Scope
* **Resource Allocation Optimization:** Streamline delivery channel evaluation by mapping volumetric weight across Standard, Second, First Class, and Same Day shipping.
* **End-to-End Supply Tracking:** Build a centralized data repository tracing orders from initial client checkout down to ultimate delivery arrival verification.
* **Financial Margin Tracking:** Deduct localized operational costs and itemized discounts from gross revenues to calculate accurate transactional profitability metrics.
* **Determining the Bottom Line:** Establish an explicit, real-time calculation engine for absolute Net Benefit to isolate true organizational profit.
* **Strategic Recommendations:** Recommend tactical changes to shipping schedules and pricing frameworks to mitigate high-risk bottlenecks and eliminate margin erosion.

> **Final Deliverable:** A production-ready Power BI business intelligence application featuring dynamic cross-filtering canvas views, responsive global slicer controls, and a dedicated personal branding portfolio navigation dock.

---

## Project Plan

### Building the Data Model
* **Data Preprocessing & Dimensional Modeling:** Extracted raw transactional files, conducted schema normalization via Power Query, and engineered an optimized Star Schema database structure inside Power Pivot.

* > **Data Optimization Note:** Extracted and isolated a highly optimized 64-row dimensional junk table (`Dim_Fulfillment_Status`) capturing all unique mathematical combinations of `Delivery Status`, `Shipping Mode`, and `Order Status`. This structurally decoupled text-heavy status parameters from the core transactional header engine (`Fact_Order_Headers`), significantly reducing file footprint and accelerating execution speeds.

---<img width="1677" height="835" alt="Screenshot 2026-06-22 235857" src="https://github.com/user-attachments/assets/a4a9298e-8043-42e9-840d-67c4a6690d18" />

### Preliminary Analysis
* **Core Operational & Financial Questions Answered:**
    * *What is the scale of absolute gross cash volume passing through the system?* Resolved via **Total Sales** measure ($36.78M).
    * *What is our total distribution scale?* Resolved via **Total Order Volume** ($66K$ distinct orders processed).
    * *Are marketing campaigns causing financial leakage?* Resolved via tracking **Total Discounts** ($18.35K$) and analyzing the correlation between high discount structures and lower net margins inside matrix grids.
    * *What is our true bottom-line profitability?* Resolved via calculating total **Net Benefit** ($3.97M).

---

### Advanced Analytical Insights Phase
* **Fulfillment Rate Verification:** Developed an analytical tracking index to evaluate organizational success rates based on formal completion flags.
  
  *Insight:* The model identified a baseline operational success metric of **33.03%** for fully closed transactional items.

* **Logistical Delay Root-Cause Isolation:** Generated a row-by-row calculated column to track operational delivery errors:
    
  *Insight:* Plotting this variance inside a distribution histogram exposed a critical operational bottleneck skewed at the **+1 Day** mark, signaling systemic shipping delays rather than randomized couriering incidents.

* **Risk Metrics Evaluation:** Isolated a primary red-flag performance metric counting orders flagged with active transactional vulnerability:
    
  *Insight:* Exposed a high-risk volume of **36K orders** experiencing active operational delay vulnerabilities, highlighting a core target for logistics framework revisions.

---

### Visualization Dashboard and Final Presentation
* **Dashboard View — Executive Operations Hub:** Delivered a professional web-application style report interface matching strict user experience (UX) and visual design parameters.
    * **KPI Button Block:** Formatted with conditional text elements dynamically feeding high-level summary totals cleanly across the top header.
    * **Analytical Canvas Layout:** Incorporates a diverse visual layout including a Product Volume TreeMap hierarchy, an unbroken Time-Series Net Benefit line trend, a Shipping Mode horizontal volume split, a Transit Variance distribution chart, and an itemized Category Margin Grid.
    * **Interactive Controls Strip:** A top-level cluster of 5 compact dropdown slicers filtering the canvas dynamically across `Month`, `Shipping Mode`, `Payment Method`, `Order Country`, `Product Category`, and `Product Department`.
    * **Sleek Navigation Dock:** A left-hand dark slate navigation rail maximizing negative canvas space balance, housing operational control triggers (**Home** and **Reset All Filters** actions via custom page bookmarking) along with integrated professional profile web-links directly referencing developer portfolio repositories on **GitHub** and **LinkedIn**.

<img width="1618" height="871" alt="Screenshot 2026-07-07 002542" src="https://github.com/user-attachments/assets/af40aa38-bee1-4a62-a52a-497c20178f3d" />
<img width="1917" height="939" alt="Screenshot 2026-06-22 235957" src="https://github.com/user-attachments/assets/f72915d5-d218-4f0b-b588-97ec96ee8107" />
