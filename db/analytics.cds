@cds.persistence.exists
@readonly
entity CV_TOP5_PRODUCTS {

    key PRODUCT_CODE : String(30);
    key CURRENCY     : String(3);

    PRODUCT_NAME     : String(100);
    CATEGORY_CODE    : String(30);
    CATEGORY_NAME    : String(100);

    QUANTITY_SOLD    : Decimal(15, 2);
    REVENUE           : Decimal(15, 2);
    PRODUCT_RANK      : Integer;
}


@cds.persistence.exists
@readonly
entity CV_SALES_REVENUE_ANALYTICS {

    key ORDER_YEAR    : Integer;
    key ORDER_MONTH   : Integer;
    key REGION        : String(50);
    key CATEGORY_CODE : String(30);
    key PRODUCT_CODE  : String(30);
    key CURRENCY      : String(3);

    CATEGORY_NAME     : String(100);
    PRODUCT_NAME      : String(100);

    QUANTITY_SOLD     : Decimal(15, 2);
    REVENUE            : Decimal(15, 2);
}


@cds.persistence.exists
@readonly
entity CV_YEAR_OVER_YEAR_REVENUE {

    key ORDER_YEAR : Integer;
    key CURRENCY   : String(3);

    PREVIOUS_YEAR          : Integer;
    CURRENT_YEAR_REVENUE   : Decimal(15, 2);
    PREVIOUS_YEAR_REVENUE  : Decimal(15, 2);
    REVENUE_CHANGE         : Decimal(15, 2);
    GROWTH_PERCENTAGE      : Decimal(15, 2);
}