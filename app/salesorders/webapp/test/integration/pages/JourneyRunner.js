sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"com/sales/orders/salesorders/test/integration/pages/SalesOrdersList.gen",
	"com/sales/orders/salesorders/test/integration/pages/SalesOrdersObjectPage.gen",
	"com/sales/orders/salesorders/test/integration/pages/SalesOrderItemsObjectPage.gen"
], function (JourneyRunner, SalesOrdersListGenerated, SalesOrdersObjectPageGenerated, SalesOrderItemsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('com/sales/orders/salesorders') + '/test/flp.html#app-preview',
        pages: {
			onTheSalesOrdersListGenerated: SalesOrdersListGenerated,
			onTheSalesOrdersObjectPageGenerated: SalesOrdersObjectPageGenerated,
			onTheSalesOrderItemsObjectPageGenerated: SalesOrderItemsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

