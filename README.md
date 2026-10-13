# Sales Order Management Application

A full-stack Sales Order Management application built using SAP Cloud Application Programming Model (CAP), SAP HANA Cloud, SAP Fiori elements, XSUAA, SAP Application Router, and SAP HANA Calculation Views.

The application supports Sales Order creation, product selection, automatic amount calculation, controlled order-status transitions, role-based authorization, and analytical reporting.

---

## Features

### Sales Order Management

- Create and manage Sales Orders
- Add multiple products as Sales Order Items
- Customer and Product value help
- Automatic Region derivation from the selected Customer
- Automatic Unit Price derivation from the selected Product
- Automatic Line Amount calculation
- Automatic Total Amount calculation
- Draft-enabled SAP Fiori elements application
- Data persistence using SAP HANA Cloud
- Role-based access using XSUAA
- Deployment on SAP BTP Cloud Foundry

### Order Status Flow

The application supports the following status transitions:

```text
Open → Shipped
Open → Cancelled
```

After an order becomes `Shipped` or `Cancelled`, the order cannot be modified.

```text
Open      → Editable
Shipped   → Locked
Cancelled → Locked
```

Only a Sales Manager can execute the following actions:

```text
Ship Order
Cancel Order
```

### Analytics

The application contains the following required SAP HANA Calculation Views:

```text
CV_TOP5_PRODUCTS
CV_SALES_REVENUE_ANALYTICS
CV_YEAR_OVER_YEAR_REVENUE
```

Additional supporting Calculation Views:

```text
CV_REVENUE_BY_REGION
CV_REVENUE_BY_CATEGORY
CV_REVENUE_BY_MONTH
```

Cancelled orders are excluded from revenue calculations.

---

## Technology Stack

- SAP Business Technology Platform
- SAP Cloud Application Programming Model
- Node.js
- SAP HANA Cloud
- SAP HANA Deployment Infrastructure
- SAP HANA Calculation Views
- SAP Fiori elements
- OData V4
- XSUAA Authentication and Authorization
- SAP Application Router
- Cloud Foundry
- Multi-Target Application
- Git and GitHub

---

## Architecture

```text
User
  |
  v
SAP Application Router
  |
  +-- XSUAA Authentication
  |
  v
SAP CAP Node.js Service
  |
  +-- OrderService
  |      Path: /orders
  |
  +-- AnalyticsService
         Path: /analytics
  |
  v
SAP HANA Cloud HDI Container
  |
  +-- CAP-generated tables
  |
  +-- SAP HANA Calculation Views
```

---

## Project Structure

```text
sales-order/
├── app/
│   └── salesorders/
│       └── webapp/
│           ├── annotations/
│           ├── controller/
│           ├── i18n/
│           ├── Component.js
│           ├── index.html
│           └── manifest.json
│
├── db/
│   ├── data/
│   │   ├── sales-Customers.csv
│   │   ├── sales-ProductCategories.csv
│   │   ├── sales-Products.csv
│   │   ├── sales-SalesOrderItems.csv
│   │   └── sales-SalesOrders.csv
│   │
│   ├── src/
│   │   ├── .hdiconfig
│   │   ├── CV_TOP5_PRODUCTS.hdbcalculationview
│   │   ├── CV_SALES_REVENUE_ANALYTICS.hdbcalculationview
│   │   ├── CV_YEAR_OVER_YEAR_REVENUE.hdbcalculationview
│   │   ├── CV_REVENUE_BY_REGION.hdbcalculationview
│   │   ├── CV_REVENUE_BY_CATEGORY.hdbcalculationview
│   │   └── CV_REVENUE_BY_MONTH.hdbcalculationview
│   │
│   ├── .gitignore
│   ├── analytics.cds
│   └── schema.cds
│
├── srv/
│   ├── analytics-service.cds
│   ├── sales-service.cds
│   └── sales-service.js
│
├── .deploy/
│   └── app-router/
│       ├── resources/
│       ├── package.json
│       └── xs-app.json
│
├── .gitignore
├── mta.yaml
├── package.json
├── xs-security.json
└── README.md
```

---

## Main Business Entities

The application contains the following business entities:

```text
Customers
ProductCategories
Products
SalesOrders
SalesOrderItems
```

### Customers

Stores customer-related information.

Example fields:

```text
ID
customerCode
name
region
segment
```

### Product Categories

Stores product-category information.

Example fields:

```text
ID
code
name
```

### Products

Stores product master data.

Example fields:

```text
ID
productCode
name
category_ID
unitPrice
currency
```

### Sales Orders

Stores Sales Order header information.

Example fields:

```text
ID
orderNo
orderDate
customer_ID
region
status
totalAmount
currency
```

### Sales Order Items

Stores Sales Order line-item information.

Example fields:

```text
ID
order_ID
product_ID
quantity
unitPrice
lineAmount
```

---

## Technical and Business Identifiers

CAP-generated UUID columns are used as technical database keys.

Examples:

```text
SalesOrders.ID
SalesOrderItems.ORDER_ID
Products.ID
SalesOrderItems.PRODUCT_ID
```

Relationships:

```text
SalesOrders.ID = SalesOrderItems.ORDER_ID
```

```text
Products.ID = SalesOrderItems.PRODUCT_ID
```

Readable business identifiers are presented to application users:

```text
Order Number
Product Code
Customer Code
Category Code
```

UUID values are used internally for database relationships.

---

## Amount Calculations

### Line Amount

```text
Line Amount = Unit Price × Quantity
```

### Total Amount

```text
Total Amount = Sum of all Line Amounts
```

Example:

```text
Product 1:
Quantity    = 2
Unit Price  = 50000
Line Amount = 100000

Product 2:
Quantity    = 3
Unit Price  = 30000
Line Amount = 90000

Total Amount = 190000
```

---

## Order Status Rules

```text
Open      → Can be edited
Open      → Can be deleted
Open      → Can be shipped by Sales Manager
Open      → Can be cancelled by Sales Manager
Shipped   → Cannot be edited or deleted
Cancelled → Cannot be edited or deleted
```

The `shipOrder` and `cancelOrder` bound actions are granted only to the Sales Manager role.

Example authorization rule:

```cds
{
    grant: [
        'shipOrder',
        'cancelOrder'
    ],
    to: 'SalesManager'
}
```

---

## Roles and Authorization

### Sales Representative

Role collection:

```text
SalesOrder-SalesRep
```

Permissions:

- View Sales Orders
- Create Sales Orders
- Edit Open Sales Orders
- Delete Open Sales Orders
- Cannot Ship Sales Orders
- Cannot Cancel Sales Orders
- Cannot access Analytics

### Sales Manager

Role collection:

```text
SalesOrder-SalesManager
```

Permissions:

- View Sales Orders
- Create Sales Orders
- Edit Open Sales Orders
- Delete Open Sales Orders
- Ship Open Sales Orders
- Cancel Open Sales Orders
- Access Analytics

### Leadership

Role collection:

```text
SalesOrder-Leadership
```

Permissions:

- Read-only access to Sales Orders
- Cannot Create Sales Orders
- Cannot Edit Sales Orders
- Cannot Delete Sales Orders
- Cannot Ship Sales Orders
- Cannot Cancel Sales Orders
- Access Analytics

---

## Security Test Matrix

| Function | SalesRep | SalesManager | Leadership |
|---|---|---|---|
| View Sales Orders | Allowed | Allowed | Allowed |
| Create Sales Order | Allowed | Allowed | Blocked |
| Edit Open Order | Allowed | Allowed | Blocked |
| Delete Open Order | Allowed | Allowed | Blocked |
| Ship Order | Blocked | Allowed | Blocked |
| Cancel Order | Blocked | Allowed | Blocked |
| Access Analytics | Blocked | Allowed | Allowed |
| Modify Shipped Order | Blocked | Blocked | Blocked |
| Modify Cancelled Order | Blocked | Blocked | Blocked |

> To test roles correctly, assign only one business role collection at a time. Permissions from multiple role collections are additive.

---

## SAP HANA Calculation Views

### CV_TOP5_PRODUCTS

Returns the five products with the highest sales revenue.

Output columns:

```text
CATEGORY_CODE
CATEGORY_NAME
PRODUCT_CODE
PRODUCT_NAME
CURRENCY
QUANTITY_SOLD
REVENUE
PRODUCT_RANK
```

Rank configuration:

```text
Order By: REVENUE
Direction: Descending
Threshold: 5
```

Recommended node structure:

```text
Join_Orders_Items
        ↓
Join_Products
        ↓
Join_Categories
        ↓
Aggregation_Products
        ↓
Rank
        ↓
Output Aggregation
        ↓
Semantics
```

Revenue calculation:

```text
REVENUE = SUM(LINEAMOUNT)
```

Quantity calculation:

```text
QUANTITY_SOLD = SUM(QUANTITY)
```

Filter:

```text
STATUS <> 'Cancelled'
```

---

### CV_SALES_REVENUE_ANALYTICS

Provides reusable Sales Revenue analytics using the following dimensions:

```text
ORDER_YEAR
ORDER_MONTH
REGION
CATEGORY_CODE
CATEGORY_NAME
PRODUCT_CODE
PRODUCT_NAME
CURRENCY
```

Measures:

```text
QUANTITY_SOLD
REVENUE
```

This view supports revenue analysis by:

- Year
- Month
- Region
- Product Category
- Product
- Currency

Calculated columns:

```text
ORDER_YEAR = YEAR(ORDERDATE)
```

```text
ORDER_MONTH = MONTH(ORDERDATE)
```

Measures:

```text
QUANTITY_SOLD = SUM(QUANTITY)
```

```text
REVENUE = SUM(LINEAMOUNT)
```

Filter:

```text
STATUS <> 'Cancelled'
```

---

### CV_YEAR_OVER_YEAR_REVENUE

Compares current-year revenue with previous-year revenue.

Output columns:

```text
ORDER_YEAR
PREVIOUS_YEAR
CURRENCY
CURRENT_YEAR_REVENUE
PREVIOUS_YEAR_REVENUE
REVENUE_CHANGE
GROWTH_PERCENTAGE
```

Revenue Change formula:

```text
REVENUE_CHANGE =
CURRENT_YEAR_REVENUE - PREVIOUS_YEAR_REVENUE
```

Growth Percentage formula:

```text
GROWTH_PERCENTAGE =
(REVENUE_CHANGE / PREVIOUS_YEAR_REVENUE) × 100
```

If Previous Year Revenue is null or zero:

```text
GROWTH_PERCENTAGE = 0
```

Recommended node structure:

```text
CV_SALES_REVENUE_ANALYTICS
            ↓
Aggregation_Yearly_Revenue
        ↙               ↘
Current Year          Previous Year
Projection            Projection
        ↘               ↙
        Join_Current_Previous
                  ↓
             Aggregation
                  ↓
              Semantics
```

Current-year and previous-year rows are joined using:

```text
CURRENT_YEAR = PREVIOUS_YEAR + 1
```

and:

```text
CURRENT_CURRENCY = PREVIOUS_CURRENCY
```

---

## Supporting Calculation Views

### CV_REVENUE_BY_REGION

Provides revenue and quantity totals by:

```text
REGION
CURRENCY
```

Measures:

```text
QUANTITY_SOLD
REVENUE
```

### CV_REVENUE_BY_CATEGORY

Provides revenue and quantity totals by:

```text
CATEGORY_CODE
CATEGORY_NAME
CURRENCY
```

Measures:

```text
QUANTITY_SOLD
REVENUE
```

### CV_REVENUE_BY_MONTH

Provides revenue and quantity totals by:

```text
ORDER_YEAR
ORDER_MONTH
CURRENCY
```

Measures:

```text
QUANTITY_SOLD
REVENUE
```

---

## CAP Services

### Order Service

Base path:

```text
/orders
```

Main endpoints:

```text
/orders/SalesOrders
/orders/SalesOrderItems
/orders/Customers
/orders/Products
/orders/ProductCategories
```

### Analytics Service

Base path:

```text
/analytics
```

Available endpoints:

```text
/analytics/$metadata
/analytics/Top5Products
/analytics/SalesRevenueAnalytics
/analytics/YearOverYearRevenue
```

Example sorted Top 5 Products request:

```text
/analytics/Top5Products?$orderby=PRODUCT_RANK asc
```

Example Sales Revenue request:

```text
/analytics/SalesRevenueAnalytics
```

Example Region filter:

```text
/analytics/SalesRevenueAnalytics?$filter=REGION eq 'East'
```

Example Year-over-Year request:

```text
/analytics/YearOverYearRevenue?$orderby=ORDER_YEAR asc
```

Analytics access is restricted to:

```text
SalesManager
Leadership
```

A Sales Representative receives:

```text
403 Forbidden
```

when accessing Analytics endpoints.

---

## Prerequisites

Before running or deploying the application, ensure the following tools and services are available:

- Node.js
- npm
- SAP CAP Development Kit
- Cloud Foundry CLI
- MultiApps Cloud Foundry CLI plugin
- Cloud MTA Build Tool
- SAP Business Application Studio
- SAP HANA Tools extension
- SAP HANA Calculation View Editor extension
- SAP HANA Cloud database
- SAP HANA HDI container
- XSUAA service
- Cloud Foundry organization and space

---

## Clone the Repository

```bash
git clone https://github.com/prajnashreepradhan21/sales-order.git
cd sales-order
```

---

## Install Dependencies

```bash
npm install
```

---

## Compile the CDS Models

Compile all project models:

```bash
npx cds compile '*'
```

Compile only the Analytics models:

```bash
npx cds compile db/analytics.cds srv/analytics-service.cds
```

---

## Run Locally

```bash
npx cds watch
```

Local execution may use SQLite and mocked users, depending on the active CAP profile.

---

## SAP HANA Development

Native SAP HANA artifacts are stored under:

```text
db/src
```

The `.hdiconfig` file must contain support for Calculation Views:

```json
"hdbcalculationview": {
  "plugin_name": "com.sap.hana.di.calculationview"
}
```

Bind the source database module to the HDI container:

```text
sales-order/db → sales-order-db
```

Do not bind:

```text
gen/db
```

The `gen/db` directory is generated build output used during production deployment.

---

## Build the Application

Remove previous generated content:

```bash
rm -rf gen mta_archives
```

Build CAP artifacts:

```bash
npx cds build --production
```

Build the MTAR archive:

```bash
mbt build
```

The generated archive is available under:

```text
mta_archives/
```

---

## Deploy to SAP BTP

Log in to Cloud Foundry:

```bash
cf login
```

Target the correct organization and space:

```bash
cf target -o <ORG_NAME> -s <SPACE_NAME>
```

Ensure that the SAP HANA Cloud database is in the `Running` state.

Deploy the application:

```bash
cf deploy mta_archives/sales-order_1.0.0.mtar -f
```

Wait for:

```text
Process finished successfully
```

---

## Verify Applications and Services

Check deployed applications:

```bash
cf apps
```

Expected applications:

```text
sales-order
sales-order-srv
```

Check service instances:

```bash
cf services
```

Expected service instances:

```text
sales-order-auth    xsuaa    application
sales-order-db      hana     hdi-shared
```

Check the HDI container:

```bash
cf service sales-order-db
```

Expected status:

```text
create succeeded
```

Check backend logs:

```bash
cf logs sales-order-srv --recent
```

---

## Application Router Configuration

The Application Router forwards Orders and Analytics requests to the CAP backend.

Example routes in `.deploy/app-router/xs-app.json`:

```json
{
  "source": "^/orders/(.*)$",
  "target": "/orders/$1",
  "destination": "srv-api",
  "authenticationType": "xsuaa",
  "csrfProtection": true
},
{
  "source": "^/analytics/(.*)$",
  "target": "/analytics/$1",
  "destination": "srv-api",
  "authenticationType": "xsuaa",
  "csrfProtection": true
}
```

The SAP Fiori application is served from:

```text
/com.sales.orders.salesorders/index.html
```

---

## Role Testing

After assigning or changing a role collection:

1. Open the logout URL:

```text
https://<APP-ROUTER-URL>/do/logout
```

2. Close all application tabs.
3. Close the private or incognito browser window.
4. Open a new private window.
5. Sign in again.
6. Test the required role behavior.

No redeployment is required when only role assignments are changed.

Redeployment is required when changing:

```text
xs-security.json
sales-service.cds
analytics-service.cds
sales-service.js
xs-app.json
mta.yaml
```

---

## Analytics Verification

### Top 5 Products

Endpoint:

```text
/analytics/Top5Products?$orderby=PRODUCT_RANK asc
```

Expected result:

```text
PRODUCT_RANK values from 1 to 5
```

### Sales Revenue Analytics

Endpoint:

```text
/analytics/SalesRevenueAnalytics
```

Expected dimensions:

```text
ORDER_YEAR
ORDER_MONTH
REGION
CATEGORY_CODE
CATEGORY_NAME
PRODUCT_CODE
PRODUCT_NAME
CURRENCY
```

Expected measures:

```text
QUANTITY_SOLD
REVENUE
```

### Year-over-Year Revenue

Endpoint:

```text
/analytics/YearOverYearRevenue?$orderby=ORDER_YEAR asc
```

Verify:

```text
REVENUE_CHANGE =
CURRENT_YEAR_REVENUE - PREVIOUS_YEAR_REVENUE
```

Verify:

```text
GROWTH_PERCENTAGE =
(REVENUE_CHANGE / PREVIOUS_YEAR_REVENUE) × 100
```

---

## Troubleshooting

### SAP HANA Database Is Stopped

Possible error:

```text
SAP DBTech JDBC: HANA Database instance is stopped
```

Solution:

1. Open SAP HANA Cloud Central.
2. Start the database.
3. Wait until the database status becomes `Running`.
4. Retry deployment.

### Cannot GET `/`

Confirm the Application Router contains a valid `welcomeFile`.

Also confirm that the SAP Fiori files are available under:

```text
.deploy/app-router/resources/
```

### Cannot GET `/analytics/...`

Ensure `.deploy/app-router/xs-app.json` contains the `/analytics/` route.

After changing the route:

```bash
rm -rf gen mta_archives
npx cds build --production
mbt build
cf deploy mta_archives/sales-order_1.0.0.mtar -f
```

### 403 on Ship or Cancel

Confirm the user has:

```text
SalesOrder-SalesManager
```

Confirm that `SalesOrders @restrict` grants:

```text
shipOrder
cancelOrder
```

Log out and sign in again after changing the role assignment.

### Analytics Endpoint Returns 403

Confirm the user has one of the following role collections:

```text
SalesOrder-SalesManager
SalesOrder-Leadership
```

A user with only the Sales Representative role must receive `403 Forbidden`.

### Calculation View Editor Stuck on Loading

Check that the Dev Space includes:

```text
SAP HANA Tools
SAP HANA Calculation View Editor
```

Verify that the following file exists:

```text
db/src/.hdiconfig
```

Bind the source database module:

```text
db
```

Do not bind:

```text
gen/db
```

If the Calculation View Editor does not load in one browser, try Microsoft Edge.

### Rank Node Has No Columns

Use the following node structure:

```text
Join Nodes
    ↓
Aggregation_Products
    ↓
Rank
    ↓
Output Aggregation
    ↓
Semantics
```

The Rank node must consume an already aggregated product-level dataset.

### Cannot Find HDI Tables

Open:

```text
SAP HANA Database Explorer
→ sales-order-db
→ Catalog
→ Tables
```

Expected tables include:

```text
SALES_CUSTOMERS
SALES_PRODUCTCATEGORIES
SALES_PRODUCTS
SALES_SALESORDERS
SALES_SALESORDERITEMS
```

### Generated Module Path Error

Possible error:

```text
gen/db is not a valid CAP DB module path
```

Use the source module for SAP HANA development:

```text
db
```

Use the generated module only for deployment:

```text
gen/db
```

---

## Secure File Handling

Never commit or share:

```text
db/.env
.env
default-env.json
service-key JSON files
VCAP_SERVICES values
SAP HANA passwords
XSUAA client secrets
certificates
```

Recommended `.gitignore` entries:

```gitignore
node_modules/
gen/
mta_archives/
*.mtar
db/.env
.env
default-env.json
*.servicekey
*.service-key.json
*.log
coverage/
.DS_Store
```

If credentials are accidentally exposed, delete or rotate the affected service key immediately.

---

## Git Commands

Check project status:

```bash
git status
```

Add project files:

```bash
git add .
```

Commit changes:

```bash
git commit -m "Complete Sales Order Management application"
```

Push to GitHub:

```bash
git push
```

---

## Repository

```text
https://github.com/prajnashreepradhan21/sales-order
```

---

## Author

Prajnashree Pradhan