# Item Purchase Tool — Salesforce

A Salesforce LWC + Apex one-page application for creating purchases from an Account page. Built as a test task for TrueSolv.

## Features

- 📦 **Item Catalog** — Browse items with images, filter by Family/Type, search by name/description
- 🛒 **Shopping Cart** — Add items to cart, adjust quantities, view totals
- ✅ **Checkout** — Creates Purchase + PurchaseLine records, validates stock, decreases available quantity
- 🔢 **Auto-calculated Totals** — Trigger auto-computes TotalItems and GrandTotal on Purchase
- 👔 **Manager Mode** — Users with `IsManager__c = true` can create new items (conditional rendering)
- 🖼️ **Unsplash Integration** — Auto-fetch item images via Unsplash API (optional, requires API key)
- 📊 **Item Count** — Filter section shows count of displayed items

## Data Model

### Custom Objects
| Object | Description |
|--------|-------------|
| `Item__c` | Products available for purchase |
| `Purchase__c` | A purchase order linked to an Account |
| `PurchaseLine__c` | Individual line items within a Purchase (Master-Detail to Purchase__c and Item__c) |

### Custom Fields
- **User.IsManager__c** — Boolean flag for manager access
- **UnsplashSettings__c** — Custom settings for Unsplash API key

## User Stories

1. ✅ Item Purchase Tool embedded on Account page layout
2. ✅ Display Account Name, Number, Industry
3. ✅ Filter items by Family and Type (picklist comboboxes)
4. ✅ Show count of filtered items
5. ✅ Search items by Name and Description
6. ✅ Item detail modal with image (`lightning-record-view-form`)
7. ✅ Add item to Cart with toast notification
8. ✅ View Cart in modal (table with subtotal)
9. ✅ Cannot add out-of-stock items to Cart
10. ✅ Checkout validates quantity, creates Purchase + PurchaseLines, decreases AvailableQuantity
11. ✅ TotalItems & GrandTotal auto-calculated via Apex Trigger
12. ✅ Redirect to Purchase record page after checkout
13. ✅ Manager-only "Create Item" button (conditional)
14. ✅ Unsplash API image search integration

## Tech Stack

- **Frontend:** Lightning Web Components (LWC) + Lightning Design System (SLDS)
- **Backend:** Apex Controllers + Apex Trigger
- **Tests:** 24 Apex unit tests (100% pass rate)
- **Tooling:** Salesforce CLI (`sf`)

## Setup

### Prerequisites
- Salesforce Org (Dev Edition or Enterprise)
- Salesforce CLI: `npm install -g @salesforce/cli`
- VS Code + Salesforce Extension Pack

### Deploy

```bash
# Authenticate
sf org login web

# Deploy all metadata
sf project deploy start --source-dir force-app

# Run all tests
sf apex run test
```

### Configure Unsplash (Optional)
1. Register at [Unsplash Developers](https://unsplash.com/developers)
2. Create an application and copy the Access Key
3. Go to **Setup → Custom Settings → Unsplash Settings → Manage**
4. Create a new record with your Access Key
5. Add `https://api.unsplash.com` to **Remote Site Settings**

### Add to Account Page
1. Open any Account record
2. Click the gear icon → **Edit Page** (Lightning App Builder)
3. Search for **Item Purchase Tool** in the Custom components panel
4. Drag it onto the page layout
5. Save and activate

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── ItemController.cls              # Item CRUD + filtering + picklist values
│   ├── PurchaseController.cls          # Checkout with stock validation
│   ├── UserController.cls              # Manager check (dynamic SOQL)
│   ├── UnsplashController.cls         # Unsplash image search
│   └── *Test.cls                       # Unit tests (24 methods total)
├── lwc/
│   ├── itemPurchaseTool/               # Main page component (cart state, filters)
│   ├── itemPurchaseToolItem/           # Item tile card
│   ├── itemCartModal/                  # Cart modal (quantity, remove, checkout)
│   ├── itemDetailModal/               # Item detail view + add to cart
│   └── createItemModal/               # Create item form (manager only)
├── objects/
│   ├── Item__c/                        # Item custom object + fields
│   ├── Purchase__c/                    # Purchase custom object + fields
│   ├── PurchaseLine__c/                # PurchaseLine custom object + fields
│   ├── User/fields/IsManager__c       # Manager flag on User
│   └── UnsplashSettings__c/           # API key custom setting
├── triggers/
│   └── PurchaseLineTrigger.trigger     # Auto-calculate TotalItems & GrandTotal
└── permissionsets/
    └── Item_Purchase_Tool_Access.permissionset
```

## License

MIT
