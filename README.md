# Item Purchase Tool — Salesforce

A Salesforce LWC + Apex one-page application for creating purchases from an Account page. Built as a test task for TrueSolv.

## Features

- 📦 **Item Catalog** — Browse items with images, filter by Family/Type, search by name/description
- 🛒 **Shopping Cart** — Add items to cart, adjust quantities, view totals
- ✅ **Checkout** — Creates Purchase + PurchaseLine records, validates stock, decreases available quantity
- 🔢 **Auto-calculated Totals** — Trigger auto-computes TotalItems and GrandTotal on Purchase
- 👔 **Manager Mode** — Users with `IsManager__c = true` can create new items
- 🖼️ **Unsplash Integration** — Auto-fetch item images via Unsplash API
- 📊 **Item Count** — Filter section shows count of displayed items

## Data Model

### Custom Objects
| Object | Description |
|--------|-------------|
| `Item__c` | Products available for purchase |
| `Purchase__c` | A purchase order linked to an Account |
| `PurchaseLine__c` | Individual line items within a Purchase |

### Custom Fields
- **User.IsManager__c** — Boolean flag for manager access
- **UnsplashSettings__c** — Custom settings for Unsplash API key

## User Stories Covered

1. ✅ Button on Account layout → Item Purchase Tool in new tab
2. ✅ Display Account Name, Number, Industry
3. ✅ Filter items by Family and Type
4. ✅ Show item count in filter section
5. ✅ Search items by Name and Description
6. ✅ Item detail modal with image (via `lightning-record-view-form`)
7. ✅ Add item to Cart with toast notification
8. ✅ View Cart in modal (table)
9. ✅ Cannot add out-of-stock items
10. ✅ Checkout validates quantity, creates records, decreases stock
11. ✅ TotalItems & GrandTotal auto-calculated via Trigger
12. ✅ Redirect to Purchase record after checkout
13. ✅ Manager-only Create Item button
14. ✅ Unsplash API image search integration

## Tech Stack

- **Frontend:** Lightning Web Components (LWC) + Lightning Design System (SLDS)
- **Backend:** Apex Controllers + Apex Trigger
- **Tests:** Apex Unit Tests (4 test classes, ~20 test methods)
- **Tooling:** Salesforce CLI (sf), VS Code + Salesforce Extension Pack

## Setup

### Prerequisites
- Salesforce Dev Org
- Salesforce CLI: `npm install -g @salesforce/cli`
- VS Code + Salesforce Extension Pack

### Deploy

```bash
# Authenticate
sf org login web

# Deploy all metadata
sf project deploy start --source-dir force-app

# Assign permission set to users
sf org assign permset --name "Item_Purchase_Tool_Access"

# Run tests
sf apex run test --class "ItemControllerTest"
sf apex run test --class "PurchaseControllerTest"
sf apex run test --class "PurchaseLineTriggerTest"
sf apex run test --class "UserControllerTest"
```

### Configure Unsplash (Optional)
1. Register at [Unsplash Developers](https://unsplash.com/developers)
2. Create an application and copy the Access Key
3. Go to **Setup → Custom Settings → Unsplash Settings → Manage**
4. Create a new record with your Access Key
5. Add `https://api.unsplash.com` to **Remote Site Settings**

### Add Button to Account Layout
1. Go to **Account** object → **Buttons, Links, and Actions** → New Button
2. Type: **Lightning Page**
3. Label: `Item Purchase Tool`
4. Add the button to Account Page Layout

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── ItemController.cls          # Item CRUD operations
│   ├── PurchaseController.cls      # Checkout logic
│   ├── UserController.cls           # Manager check
│   ├── UnsplashController.cls       # Unsplash image search
│   └── *Test.cls                    # Unit tests
├── lwc/
│   ├── itemPurchaseTool/            # Main page component
│   ├── itemPurchaseToolItem/        # Item tile card
│   ├── itemCartModal/               # Cart modal
│   ├── itemDetailModal/             # Item detail modal
│   └── createItemModal/             # Create item (manager only)
├── objects/
│   ├── Item__c/                     # Item custom object + fields
│   ├── Purchase__c/                 # Purchase custom object + fields
│   ├── PurchaseLine__c/             # PurchaseLine custom object + fields
│   ├── User/fields/IsManager__c     # Manager flag
│   └── UnsplashSettings__c/         # API key settings
├── triggers/
│   └── PurchaseLineTrigger.trigger  # Auto-calculate totals
├── tabs/                            # Custom tabs
├── flexipages/                      # Lightning pages
└── permissionsets/                  # Access permissions
```

## License

MIT
