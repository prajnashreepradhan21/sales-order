using OrderService as service from '../../srv/sales-service';


/* ============================================================
   SALES ORDER LIST REPORT AND OBJECT PAGE
   ============================================================ */

annotate service.SalesOrders with @(
    UI.HeaderInfo : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'Sales Order',
        TypeNamePlural : 'Sales Orders',

        Title : {
            $Type : 'UI.DataField',
            Value : orderNo
        },

        Description : {
            $Type : 'UI.DataField',
            Value : customer.name
        }
    },


    /* ------------------------------------------------------------
       Object Page actions

       Open:
       - Ship Order visible
       - Cancel Order visible

       Shipped or Cancelled:
       - Both actions hidden
       ------------------------------------------------------------ */

    UI.Identification : [
        {
            $Type              : 'UI.DataFieldForAction',
            Label              : 'Ship Order',
            Action             : 'OrderService.shipOrder',
            InvocationGrouping : #Isolated,
            Criticality        : #Positive,
            ![@UI.Hidden]      : hideOrderActions
        },
        {
            $Type              : 'UI.DataFieldForAction',
            Label              : 'Cancel Order',
            Action             : 'OrderService.cancelOrder',
            InvocationGrouping : #Isolated,
            Criticality        : #Negative,
            ![@UI.Hidden]      : hideOrderActions
        }
    ],


    /* ------------------------------------------------------------
       List Report filter fields
       ------------------------------------------------------------ */

    UI.SelectionFields : [
        customer_ID,
        orderDate,
        region,
        status
    ],


    /* ------------------------------------------------------------
       List Report columns

       Ship and Cancel are intentionally excluded from this list.
       The actions appear only on the Object Page.
       ------------------------------------------------------------ */

    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Order Number',
            Value : orderNo
        },
        {
            $Type : 'UI.DataField',
            Label : 'Order Date',
            Value : orderDate
        },
        {
            $Type : 'UI.DataField',
            Label : 'Customer',
            Value : customer.name
        },
        {
            $Type : 'UI.DataField',
            Label : 'Region',
            Value : region
        },
        {
            $Type       : 'UI.DataField',
            Label       : 'Status',
            Value       : status,
            Criticality : statusCriticality
        },
        {
            $Type : 'UI.DataField',
            Label : 'Total Amount',
            Value : totalAmount
        }
    ],


    /* ------------------------------------------------------------
       General Information section
       ------------------------------------------------------------ */

    UI.FieldGroup #GeneralInformation : {
        $Type : 'UI.FieldGroupType',

        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Order Number',
                Value : orderNo
            },
            {
                $Type : 'UI.DataField',
                Label : 'Order Date',
                Value : orderDate
            },
            {
                $Type : 'UI.DataField',
                Label : 'Customer',
                Value : customer_ID
            },
            {
                $Type : 'UI.DataField',
                Label : 'Region',
                Value : region
            },
            {
                $Type       : 'UI.DataField',
                Label       : 'Status',
                Value       : status,
                Criticality : statusCriticality
            },
            {
                $Type : 'UI.DataField',
                Label : 'Total Amount',
                Value : totalAmount
            },
            {
                $Type : 'UI.DataField',
                Label : 'Currency',
                Value : currency
            }
        ]
    },


    /* ------------------------------------------------------------
       Object Page sections
       ------------------------------------------------------------ */

    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'GeneralInformation',
            Label  : 'General Information',
            Target : '@UI.FieldGroup#GeneralInformation'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'OrderItems',
            Label  : 'Order Items',
            Target : 'items/@UI.LineItem'
        }
    ]
);


/* ============================================================
   SALES ORDER FIELD LABELS AND FIELD CONTROL
   ============================================================ */

annotate service.SalesOrders with {
    orderNo @(
        title               : 'Order Number',
        Common.Label        : 'Order Number',
        Common.FieldControl : #ReadOnly
    );

    orderDate @(
        title        : 'Order Date',
        Common.Label : 'Order Date'
    );

    customer @(
        title        : 'Customer',
        Common.Label : 'Customer'
    );

    region @(
        title               : 'Region',
        Common.Label        : 'Region',
        Common.FieldControl : #ReadOnly
    );

    status @(
        title               : 'Status',
        Common.Label        : 'Status',
        Common.FieldControl : #ReadOnly
    );

    totalAmount @(
        title                : 'Total Amount',
        Common.Label         : 'Total Amount',
        Common.FieldControl  : #ReadOnly,
        Measures.ISOCurrency : currency
    );

    currency @(
        title               : 'Currency',
        Common.Label        : 'Currency',
        Common.FieldControl : #ReadOnly
    );


    /* Technical properties used by Fiori */

    statusCriticality @UI.Hidden;
    hideOrderActions  @UI.Hidden;
    canModify         @UI.Hidden;
};


/* ============================================================
   CUSTOMER VALUE HELP
   ============================================================ */

annotate service.SalesOrders with {
    customer @Common.ValueList : {
        $Type          : 'Common.ValueListType',
        Label          : 'Select Customer',
        CollectionPath : 'Customers',

        Parameters : [
            {
                $Type             : 'Common.ValueListParameterInOut',
                LocalDataProperty : customer_ID,
                ValueListProperty : 'ID'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'customerCode'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'name'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'segment'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'region'
            }
        ]
    };
};


/* ============================================================
   CUSTOMER SIDE EFFECT

   When Customer changes, refresh Region.
   ============================================================ */

annotate service.SalesOrders with
    @Common.SideEffects #CustomerChanged : {
        SourceProperties : [
            customer_ID
        ],
        TargetProperties : [
            region
        ]
    };


/* ============================================================
   SALES ORDER ITEMS TABLE AND OBJECT PAGE
   ============================================================ */

annotate service.SalesOrderItems with @(
    UI.HeaderInfo : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'Order Item',
        TypeNamePlural : 'Order Items',

        Title : {
            $Type : 'UI.DataField',
            Value : product.name
        },

        Description : {
            $Type : 'UI.DataField',
            Value : lineAmount
        }
    },


    /* ------------------------------------------------------------
       Order Items table shown inside the Sales Order Object Page
       ------------------------------------------------------------ */

    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Product',
            Value : product_ID
        },
        {
            $Type : 'UI.DataField',
            Label : 'Quantity',
            Value : quantity
        },
        {
            $Type : 'UI.DataField',
            Label : 'Unit Price',
            Value : unitPrice
        },
        {
            $Type : 'UI.DataField',
            Label : 'Line Amount',
            Value : lineAmount
        }
    ],


    /* ------------------------------------------------------------
       Order Item detail section
       ------------------------------------------------------------ */

    UI.FieldGroup #ItemInformation : {
        $Type : 'UI.FieldGroupType',

        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Product',
                Value : product_ID
            },
            {
                $Type : 'UI.DataField',
                Label : 'Quantity',
                Value : quantity
            },
            {
                $Type : 'UI.DataField',
                Label : 'Unit Price',
                Value : unitPrice
            },
            {
                $Type : 'UI.DataField',
                Label : 'Line Amount',
                Value : lineAmount
            }
        ]
    },


    /* ------------------------------------------------------------
       Order Item Object Page sections
       ------------------------------------------------------------ */

    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'ItemInformation',
            Label  : 'Item Information',
            Target : '@UI.FieldGroup#ItemInformation'
        }
    ]
);


/* ============================================================
   SALES ORDER ITEM LABELS AND FIELD CONTROL
   ============================================================ */

annotate service.SalesOrderItems with {
    product @(
        title        : 'Product',
        Common.Label : 'Product'
    );

    quantity @(
        title        : 'Quantity',
        Common.Label : 'Quantity'
    );

    unitPrice @(
        title               : 'Unit Price',
        Common.Label        : 'Unit Price',
        Common.FieldControl : #ReadOnly
    );

    lineAmount @(
        title               : 'Line Amount',
        Common.Label        : 'Line Amount',
        Common.FieldControl : #ReadOnly
    );
};


/* ============================================================
   PRODUCT VALUE HELP

   unitPrice and currency belong to Products.
   SalesOrderItems does not contain a currency property.
   ============================================================ */

annotate service.SalesOrderItems with {
    product @Common.ValueList : {
        $Type          : 'Common.ValueListType',
        Label          : 'Select Product',
        CollectionPath : 'Products',

        Parameters : [
            {
                $Type             : 'Common.ValueListParameterInOut',
                LocalDataProperty : product_ID,
                ValueListProperty : 'ID'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'productCode'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'name'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'unitPrice'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'currency'
            }
        ]
    };
};


/* ============================================================
   QUANTITY SIDE EFFECT

   When Quantity changes, refresh Unit Price and Line Amount.
   ============================================================ */

annotate service.SalesOrderItems with
    @Common.SideEffects #QuantityChanged : {
        SourceProperties : [
            quantity
        ],
        TargetProperties : [
            unitPrice,
            lineAmount
        ]
    };


/* ============================================================
   PRODUCT SIDE EFFECT

   When Product changes, refresh Unit Price and Line Amount.
   ============================================================ */

annotate service.SalesOrderItems with
    @Common.SideEffects #ProductChanged : {
        SourceProperties : [
            product_ID
        ],
        TargetProperties : [
            unitPrice,
            lineAmount
        ]
    };