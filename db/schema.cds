namespace sales;

using { cuid, managed } from '@sap/cds/common';


type OrderStatus : String(12) enum {
    Open      = 'Open';
    Shipped   = 'Shipped';
    Cancelled = 'Cancelled';
}


entity Customers : cuid, managed {
    customerCode : String(20) @mandatory;
    name         : String(100) @mandatory;
    segment      : String(30);
    region       : String(10) @mandatory;
    email        : String(120);
}


entity ProductCategories : cuid {
    code : String(20) @mandatory;
    name : String(80) @mandatory;
}


entity Products : cuid, managed {
    productCode : String(20) @mandatory;
    name        : String(120) @mandatory;

    category : Association to ProductCategories
        @mandatory;

    unitPrice : Decimal(15,2) @mandatory;
    currency  : String(3) default 'INR';
    active    : Boolean default true;
}


entity SalesOrders : cuid, managed {
    orderNo   : String(20) @readonly;
    orderDate : Date @mandatory;

    customer : Association to Customers
        @mandatory;

    region : String(10) @readonly;

    status : OrderStatus default 'Open';

    totalAmount : Decimal(15,2) @readonly;
    currency    : String(3) default 'INR';

    items : Composition of many SalesOrderItems
        on items.order = $self;
}


entity SalesOrderItems : cuid {
    order : Association to one SalesOrders;

    product : Association to Products
        @mandatory;

    quantity   : Integer @mandatory;
    unitPrice  : Decimal(15,2) @readonly;
    lineAmount : Decimal(15,2) @readonly;
}