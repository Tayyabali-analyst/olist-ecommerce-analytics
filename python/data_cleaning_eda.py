import pandas as pd

orders = pd.read_csv('archive/olist_orders_dataset.csv')
#print(orders.head())
#print(orders.columns)
#print(orders.shape)
#print(orders.isnull().sum()) 
#print(orders['order_status'].value_counts())

customers = pd.read_csv('archive/olist_customers_dataset.csv')
#print(customers.head())
#print(customers.columns)

customers = pd.read_csv('archive/olist_customers_dataset.csv')
#print(customers.head())
#print(customers.columns)
#print(customers.shape)
#print(customers.isnull().sum())

merged = orders.merge(customers, on='customer_id', how='left')
#print(merged.shape)
#print(merged.head())

items = pd.read_csv('archive/olist_order_items_dataset.csv')
# print(items.shape)
# print(items.columns)
# print(items.head())

merged = merged.merge(items, on='order_id', how='left')
# print(merged.shape)

products = pd.read_csv('archive/olist_products_dataset.csv')
# print(products.shape)
# print(products.columns)


merged = merged.merge(products, on='product_id', how='left')
# print(merged.shape)

translation = pd.read_csv('archive/product_category_name_translation.csv')
# merged = merged.merge(translation, on='product_category_name', how='left')
# print(merged.shape)
# print(merged['product_category_name_english'].value_counts().head(10))


payments = pd.read_csv('archive/olist_order_payments_dataset.csv')
# print(payments.shape)
# print(payments.columns)
# print(payments['payment_type'].value_counts())

merged = merged.merge(payments, on='order_id', how='left')
# print(merged.shape)

reviews = pd.read_csv('archive/olist_order_reviews_dataset.csv')
# print(reviews.shape)
# print(reviews.columns)
# print(reviews['review_score'].value_counts())

merged = merged.merge(reviews, on='order_id', how='left')
# print(merged.shape)

print(merged.isnull().sum())

merged = merged.dropna(subset=['review_score'])
print(merged.shape)

merged = merged.dropna(subset=['product_id', 'price'])
print(merged.shape)

print(merged.duplicated().sum())

date_cols = ['order_purchase_timestamp', 'order_approved_at', 
             'order_delivered_carrier_date', 'order_delivered_customer_date', 
             'order_estimated_delivery_date']

for col in date_cols:
    merged[col] = pd.to_datetime(merged[col])

print(merged[date_cols].dtypes)

merged['delivery_delay_days'] = (merged['order_delivered_customer_date'] - 
                                   merged['order_estimated_delivery_date']).dt.days

print(merged['delivery_delay_days'].describe())

late_reviews = merged[merged['delivery_delay_days'] > 0]['review_score'].mean()
early_reviews = merged[merged['delivery_delay_days'] <= 0]['review_score'].mean()

print(f"Avg review score when LATE: {late_reviews:.2f}")
print(f"Avg review score when ON-TIME/EARLY: {early_reviews:.2f}")

merged.to_csv('olist_merged_cleaned.csv', index=False)
print("Saved successfully")
