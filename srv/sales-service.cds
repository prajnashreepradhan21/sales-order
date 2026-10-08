using { sales as db } from '../db/schema';

@path: '/orders'
@title: 'Sales Order Management'
@requires: [
    'SalesRep',
    'SalesManager',
    'Leadership'
]
service OrderService {

    @readonly
    @restrict: [
        {
            grant: 'READ',
            to: [
                'SalesRep',
                'SalesManager',
                'Leadership'
            ]
        }
    ]
    entity Customers
        as projection on db.Customers;

    @readonly
    @restrict: [
        {
            grant: 'READ',
            to: [
                'SalesRep',
                'SalesManager',
                'Leadership'
            ]
        }
    ]
    entity ProductCategories
        as projection on db.ProductCategories;

    @readonly
    @restrict: [
        {
            grant: 'READ',
            to: [
                'SalesRep',
                'SalesManager',
                'Leadership'
            ]
        }
    ]
    entity Products
        as projection on db.Products;

    @odata.draft.enabled
    @restrict: [
        {
            grant: 'READ',
            to: [
                'SalesRep',
                'SalesManager',
                'Leadership'
            ]
        },
        {
            grant: 'CREATE',
            to: [
                'SalesRep',
                'SalesManager'
            ]
        },
        {
            grant: [
                'UPDATE',
                'DELETE'
            ],
            to: [
                'SalesRep',
                'SalesManager'
            ]
        },
        {
            grant: [
                'shipOrder',
                'cancelOrder'
            ],
            to: 'SalesManager'
        }
    ]
    entity SalesOrders
        as projection on db.SalesOrders {
            *,

            case
                when status = 'Open' then 2
                when status = 'Shipped' then 3
                when status = 'Cancelled' then 1
                else 0
            end as statusCriticality : Integer,

            case
                when status = 'Open' then false
                else true
            end as hideOrderActions : Boolean,

            case
                when status = 'Open' then true
                else false
            end as canModify : Boolean
        }
        actions {

            @title: 'Ship Order'
            @requires: 'SalesManager'
            @Common.IsActionCritical: true
            @Common.SideEffects: {
                TargetProperties: [
                    'status',
                    'statusCriticality',
                    'hideOrderActions',
                    'canModify'
                ]
            }
            action shipOrder()
                returns SalesOrders;

            @title: 'Cancel Order'
            @requires: 'SalesManager'
            @Common.IsActionCritical: true
            @Common.SideEffects: {
                TargetProperties: [
                    'status',
                    'statusCriticality',
                    'hideOrderActions',
                    'canModify'
                ]
            }
            action cancelOrder()
                returns SalesOrders;
        };

    @restrict: [
        {
            grant: 'READ',
            to: [
                'SalesRep',
                'SalesManager',
                'Leadership'
            ]
        },
        {
            grant: [
                'CREATE',
                'UPDATE',
                'DELETE'
            ],
            to: [
                'SalesRep',
                'SalesManager'
            ]
        }
    ]
    entity SalesOrderItems
        as projection on db.SalesOrderItems;
}

annotate OrderService.SalesOrders with @(
    Capabilities.UpdateRestrictions : {
        Updatable : canModify
    },
    Capabilities.DeleteRestrictions : {
        Deletable : canModify
    }
);