using {
    CV_TOP5_PRODUCTS,
    CV_SALES_REVENUE_ANALYTICS,
    CV_YEAR_OVER_YEAR_REVENUE
} from '../db/analytics';

@path: '/analytics'
@title: 'Sales Analytics'
@requires: [
    'SalesManager',
    'Leadership'
]
service AnalyticsService {

    @readonly
    entity Top5Products
        as projection on CV_TOP5_PRODUCTS;

    @readonly
    entity SalesRevenueAnalytics
        as projection on CV_SALES_REVENUE_ANALYTICS;

    @readonly
    entity YearOverYearRevenue
        as projection on CV_YEAR_OVER_YEAR_REVENUE;
}