import cds from '@sap/cds';

const { SELECT, UPDATE } = cds.ql;

export default cds.service.impl(async function () {
    const {
        SalesOrders,
        SalesOrderItems,
        Products,
        Customers
    } = this.entities;

    function getRequestID(req) {
        return req.data?.ID || req.params?.[0]?.ID;
    }

    async function getCustomer(req, customerID) {
        if (!customerID) {
            return req.reject({
                status: 400,
                code: 'CUSTOMER_REQUIRED',
                message: 'Customer is required.',
                target: 'customer_ID'
            });
        }

        const customer = await SELECT.one
            .from(Customers)
            .where({
                ID: customerID
            });

        if (!customer) {
            return req.reject({
                status: 404,
                code: 'CUSTOMER_NOT_FOUND',
                message: 'Customer not found.',
                target: 'customer_ID'
            });
        }

        return customer;
    }

    async function getProduct(req, productID) {
        if (!productID) {
            return req.reject({
                status: 400,
                code: 'PRODUCT_REQUIRED',
                message: 'Product is required.',
                target: 'product_ID'
            });
        }

        const product = await SELECT.one
            .from(Products)
            .where({
                ID: productID
            });

        if (!product) {
            return req.reject({
                status: 404,
                code: 'PRODUCT_NOT_FOUND',
                message: 'Product not found.',
                target: 'product_ID'
            });
        }

        if (product.active === false) {
            return req.reject({
                status: 400,
                code: 'PRODUCT_INACTIVE',
                message: 'The selected product is inactive.',
                target: 'product_ID'
            });
        }

        return product;
    }

    async function getSalesOrder(req, orderID) {
        if (!orderID) {
            return req.reject(
                400,
                'Sales order ID is required.'
            );
        }

        const order = await SELECT.one
            .from(SalesOrders)
            .where({
                ID: orderID
            });

        if (!order) {
            return req.reject(
                404,
                'Sales order not found.'
            );
        }

        return order;
    }

    async function getOpenOrder(req, orderID) {
        const order = await getSalesOrder(
            req,
            orderID
        );

        if (!order) {
            return;
        }

        if (order.status !== 'Open') {
            return req.reject(
                400,
                'Only Open sales orders can be changed.'
            );
        }

        return order;
    }

    async function calculateItemAmount(
        req,
        existingItem = {}
    ) {
        const productID =
            req.data.product_ID ??
            existingItem.product_ID;

        const quantity =
            req.data.quantity ??
            existingItem.quantity;

        if (!productID) {
            return req.reject({
                status: 400,
                code: 'PRODUCT_REQUIRED',
                message: 'Product is required.',
                target: 'product_ID'
            });
        }

        if (
            quantity == null ||
            Number(quantity) <= 0
        ) {
            return req.reject({
                status: 400,
                code: 'INVALID_QUANTITY',
                message: 'Quantity must be greater than zero.',
                target: 'quantity'
            });
        }

        const product = await getProduct(
            req,
            productID
        );

        if (!product) {
            return;
        }

        const unitPrice =
            Number(product.unitPrice);

        if (!Number.isFinite(unitPrice)) {
            return req.reject({
                status: 400,
                code: 'INVALID_PRODUCT_PRICE',
                message:
                    'The selected product does not have a valid unit price.',
                target: 'product_ID'
            });
        }

        req.data.unitPrice = unitPrice;

        req.data.lineAmount =
            unitPrice * Number(quantity);
    }

    async function recalculateActiveOrderTotal(
        orderID
    ) {
        if (!orderID) {
            return;
        }

        const items = await SELECT
            .from(SalesOrderItems)
            .columns('lineAmount')
            .where({
                order_ID: orderID
            });

        const totalAmount = items.reduce(
            (total, item) =>
                total + Number(item.lineAmount || 0),
            0
        );

        await UPDATE(SalesOrders)
            .set({
                totalAmount
            })
            .where({
                ID: orderID
            });
    }

    async function recalculateDraftOrderTotal(
        orderID
    ) {
        if (
            !orderID ||
            !SalesOrders.drafts ||
            !SalesOrderItems.drafts
        ) {
            return;
        }

        const items = await SELECT
            .from(SalesOrderItems.drafts)
            .columns('lineAmount')
            .where({
                order_ID: orderID
            });

        const totalAmount = items.reduce(
            (total, item) =>
                total + Number(item.lineAmount || 0),
            0
        );

        await UPDATE(SalesOrders.drafts)
            .set({
                totalAmount
            })
            .where({
                ID: orderID
            });
    }

    async function generateOrderNumber(orderDate) {
        const year =
            new Date(orderDate).getFullYear();

        const result = await SELECT.one
            .from(SalesOrders)
            .columns('count(*) as count');

        const nextNumber =
            Number(result?.count || 0) + 1;

        return `SO-${year}-${String(nextNumber).padStart(4, '0')}`;
    }

    if (SalesOrders.drafts) {
        this.before(
            'NEW',
            SalesOrders.drafts,
            req => {
                req.data.orderDate =
                    req.data.orderDate ||
                    new Date()
                        .toISOString()
                        .substring(0, 10);

                req.data.status = 'Open';
                req.data.currency = 'INR';
                req.data.totalAmount = 0;
            }
        );
    }

    if (SalesOrders.drafts) {
        this.before(
            'PATCH',
            SalesOrders.drafts,
            async req => {
                const customerChanged =
                    Object.prototype.hasOwnProperty.call(
                        req.data,
                        'customer_ID'
                    );

                if (!customerChanged) {
                    return;
                }

                if (!req.data.customer_ID) {
                    req.data.region = null;
                    return;
                }

                const customer = await getCustomer(
                    req,
                    req.data.customer_ID
                );

                if (!customer) {
                    return;
                }

                req.data.region =
                    customer.region;
            }
        );
    }

    if (SalesOrders.drafts) {
        this.before(
            'SAVE',
            SalesOrders.drafts,
            async req => {
                const orderID = getRequestID(req);

                if (!req.data.customer_ID) {
                    req.error({
                        code: 'CUSTOMER_REQUIRED',
                        message: 'Please select a customer.',
                        target: 'customer_ID'
                    });
                }

                if (!req.data.orderDate) {
                    req.error({
                        code: 'ORDER_DATE_REQUIRED',
                        message: 'Please enter the order date.',
                        target: 'orderDate'
                    });
                }

                const items = orderID
                    ? await SELECT
                        .from(SalesOrderItems.drafts)
                        .where({
                            order_ID: orderID
                        })
                    : [];

                if (!items.length) {
                    req.error({
                        code: 'ORDER_ITEM_REQUIRED',
                        message:
                            'Add at least one product before saving the order.',
                        target: 'items'
                    });
                }

                if (req.errors?.length) {
                    return;
                }

                const customer = await SELECT.one
                    .from(Customers)
                    .where({
                        ID: req.data.customer_ID
                    });

                if (!customer) {
                    return req.reject({
                        status: 404,
                        code: 'CUSTOMER_NOT_FOUND',
                        message:
                            'The selected customer was not found.',
                        target: 'customer_ID'
                    });
                }

                const invalidItem = items.find(
                    item =>
                        !item.product_ID ||
                        Number(item.quantity) <= 0 ||
                        Number(item.lineAmount) <= 0
                );

                if (invalidItem) {
                    return req.reject({
                        status: 400,
                        code: 'INVALID_ORDER_ITEM',
                        message:
                            'Every order item must have a product, valid quantity, and valid line amount.',
                        target: 'items'
                    });
                }

                req.data.region =
                    customer.region;

                req.data.status = 'Open';

                req.data.currency =
                    req.data.currency || 'INR';

                req.data.totalAmount =
                    items.reduce(
                        (total, item) =>
                            total +
                            Number(item.lineAmount || 0),
                        0
                    );
            }
        );
    }

    this.before(
        'EDIT',
        SalesOrders,
        async req => {
            const orderID = getRequestID(req);

            if (!orderID) {
                return;
            }

            const order = await getSalesOrder(
                req,
                orderID
            );

            if (!order) {
                return;
            }

            if (order.status !== 'Open') {
                return req.reject(
                    400,
                    'Only Open sales orders can be edited.'
                );
            }
        }
    );

    this.before(
        'CREATE',
        SalesOrders,
        async req => {
            if (!req.data.orderDate) {
                req.data.orderDate = new Date()
                    .toISOString()
                    .substring(0, 10);
            }

            req.data.status = 'Open';

            req.data.currency =
                req.data.currency || 'INR';

            if (req.data.customer_ID) {
                const customer = await getCustomer(
                    req,
                    req.data.customer_ID
                );

                if (!customer) {
                    return;
                }

                req.data.region =
                    customer.region;
            }

            let totalAmount = 0;

            if (Array.isArray(req.data.items)) {
                for (const item of req.data.items) {
                    if (!item.product_ID) {
                        return req.reject({
                            status: 400,
                            code: 'PRODUCT_REQUIRED',
                            message:
                                'Product is required for every order item.',
                            target: 'items'
                        });
                    }

                    if (
                        item.quantity == null ||
                        Number(item.quantity) <= 0
                    ) {
                        return req.reject({
                            status: 400,
                            code: 'INVALID_QUANTITY',
                            message:
                                'Quantity must be greater than zero.',
                            target: 'items'
                        });
                    }

                    const product = await getProduct(
                        req,
                        item.product_ID
                    );

                    if (!product) {
                        return;
                    }

                    const unitPrice =
                        Number(product.unitPrice);

                    item.unitPrice =
                        unitPrice;

                    item.lineAmount =
                        unitPrice *
                        Number(item.quantity);

                    totalAmount +=
                        Number(item.lineAmount);
                }
            }

            req.data.totalAmount =
                totalAmount;

            if (!req.data.orderNo) {
                req.data.orderNo =
                    await generateOrderNumber(
                        req.data.orderDate
                    );
            }
        }
    );

    this.before(
        'UPDATE',
        SalesOrders,
        async req => {
            const orderID = getRequestID(req);

            if (!orderID) {
                return;
            }

            const existingOrder =
                await getSalesOrder(
                    req,
                    orderID
                );

            if (!existingOrder) {
                return;
            }

            if (existingOrder.status !== 'Open') {
                return req.reject(
                    400,
                    'Only Open orders can be changed.'
                );
            }

            delete req.data.orderNo;
            delete req.data.totalAmount;
            delete req.data.region;
            delete req.data.currency;
            delete req.data.status;

            if (req.data.customer_ID) {
                const customer = await getCustomer(
                    req,
                    req.data.customer_ID
                );

                if (!customer) {
                    return;
                }

                req.data.region =
                    customer.region;
            }
        }
    );

    this.before(
        'DELETE',
        SalesOrders,
        async req => {
            const orderID = getRequestID(req);

            await getOpenOrder(
                req,
                orderID
            );
        }
    );

    this.before(
        'CREATE',
        SalesOrderItems,
        async req => {
            if (req.data.order_ID) {
                await getOpenOrder(
                    req,
                    req.data.order_ID
                );
            }

            await calculateItemAmount(req);
        }
    );

    this.before(
        'UPDATE',
        SalesOrderItems,
        async req => {
            const itemID = getRequestID(req);

            if (!itemID) {
                return req.reject(
                    400,
                    'Order item ID is required.'
                );
            }

            const existingItem =
                await SELECT.one
                    .from(SalesOrderItems)
                    .where({
                        ID: itemID
                    });

            if (!existingItem) {
                return req.reject(
                    404,
                    'Order item not found.'
                );
            }

            await getOpenOrder(
                req,
                existingItem.order_ID
            );

            await calculateItemAmount(
                req,
                existingItem
            );
        }
    );

    if (SalesOrderItems.drafts) {
        this.before(
            'PATCH',
            SalesOrderItems.drafts,
            async req => {
                const itemID = getRequestID(req);

                if (!itemID) {
                    return;
                }

                const quantityChanged =
                    Object.prototype.hasOwnProperty.call(
                        req.data,
                        'quantity'
                    );

                const productChanged =
                    Object.prototype.hasOwnProperty.call(
                        req.data,
                        'product_ID'
                    );

                if (
                    !quantityChanged &&
                    !productChanged
                ) {
                    return;
                }

                const existingItem =
                    await SELECT.one
                        .from(SalesOrderItems.drafts)
                        .where({
                            ID: itemID
                        });

                if (!existingItem) {
                    return req.reject(
                        404,
                        'Draft order item was not found.'
                    );
                }

                await calculateItemAmount(
                    req,
                    existingItem
                );

                req._orderID =
                    existingItem.order_ID;
            }
        );

        this.after(
            'PATCH',
            SalesOrderItems.drafts,
            async (_data, req) => {
                await recalculateDraftOrderTotal(
                    req._orderID
                );
            }
        );
    }

    this.before(
        'DELETE',
        SalesOrderItems,
        async req => {
            const itemID = getRequestID(req);

            if (!itemID) {
                return req.reject(
                    400,
                    'Order item ID is required.'
                );
            }

            const existingItem =
                await SELECT.one
                    .from(SalesOrderItems)
                    .where({
                        ID: itemID
                    });

            if (!existingItem) {
                return req.reject(
                    404,
                    'Order item not found.'
                );
            }

            await getOpenOrder(
                req,
                existingItem.order_ID
            );

            req._orderID =
                existingItem.order_ID;
        }
    );

    this.after(
        'CREATE',
        SalesOrderItems,
        async data => {
            await recalculateActiveOrderTotal(
                data.order_ID
            );
        }
    );

    this.after(
        'UPDATE',
        SalesOrderItems,
        async data => {
            let orderID =
                data.order_ID;

            if (!orderID && data.ID) {
                const item = await SELECT.one
                    .from(SalesOrderItems)
                    .columns('order_ID')
                    .where({
                        ID: data.ID
                    });

                orderID =
                    item?.order_ID;
            }

            await recalculateActiveOrderTotal(
                orderID
            );
        }
    );

    this.after(
        'DELETE',
        SalesOrderItems,
        async (_data, req) => {
            await recalculateActiveOrderTotal(
                req._orderID
            );
        }
    );

    this.on(
        'shipOrder',
        SalesOrders,
        async req => {
            if (!req.user.is('SalesManager')) {
                return req.reject(
                    403,
                    'Only Sales Managers can ship orders.'
                );
            }

            const orderID = getRequestID(req);

            const order = await getSalesOrder(
                req,
                orderID
            );

            if (!order) {
                return;
            }

            if (order.status !== 'Open') {
                return req.reject(
                    400,
                    'Only Open orders can be shipped.'
                );
            }

            const items = await SELECT
                .from(SalesOrderItems)
                .where({
                    order_ID: orderID
                });

            if (!items.length) {
                return req.reject(
                    400,
                    'Add at least one order item before shipping the order.'
                );
            }

            const invalidItem = items.find(
                item =>
                    !item.product_ID ||
                    Number(item.quantity) <= 0 ||
                    Number(item.lineAmount) <= 0
            );

            if (invalidItem) {
                return req.reject(
                    400,
                    'All order items must have a product, valid quantity, and valid line amount.'
                );
            }

            await recalculateActiveOrderTotal(
                orderID
            );

            const recalculatedOrder =
                await SELECT.one
                    .from(SalesOrders)
                    .where({
                        ID: orderID
                    });

            if (
                Number(
                    recalculatedOrder.totalAmount
                ) <= 0
            ) {
                return req.reject(
                    400,
                    'An order with a zero total amount cannot be shipped.'
                );
            }

            await UPDATE(SalesOrders)
                .set({
                    status: 'Shipped'
                })
                .where({
                    ID: orderID
                });

            return SELECT.one
                .from(SalesOrders)
                .where({
                    ID: orderID
                });
        }
    );

    this.on(
        'cancelOrder',
        SalesOrders,
        async req => {
            if (!req.user.is('SalesManager')) {
                return req.reject(
                    403,
                    'Only Sales Managers can cancel orders.'
                );
            }

            const orderID = getRequestID(req);

            const order = await getSalesOrder(
                req,
                orderID
            );

            if (!order) {
                return;
            }

            if (order.status !== 'Open') {
                return req.reject(
                    400,
                    'Only Open orders can be cancelled.'
                );
            }

            await UPDATE(SalesOrders)
                .set({
                    status: 'Cancelled'
                })
                .where({
                    ID: orderID
                });

            return SELECT.one
                .from(SalesOrders)
                .where({
                    ID: orderID
                });
        }
    );
});