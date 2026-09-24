# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a",
# META       "default_lakehouse_name": "Demo_Lakehouse2",
# META       "default_lakehouse_workspace_id": "2c14bfb4-7a6e-418c-9006-b565c36cc0ae",
# META       "known_lakehouses": [
# META         {
# META           "id": "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Transform_SalesData – Notebook Overview
# 
# This notebook prepares and maintains a Delta **Silver** layer table named `SilverTable` in the lakehouse.
# 
# ## High-level steps
# 1. **Inspect current Silver table**  
#    Reads from the Delta table `SilverTable` and displays a sample of rows.
# 
# 2. **(Re)create `SilverTable` as Delta with schema overwrite**  
#    Ensures the `SilverTable` exists as a Delta table and overwrites its data/schema when needed.
# 
# 3. **Apply business transformations**  
#    - Reads the latest data from `SilverTable`.
#    - Adds derived columns:
#      - `IsFlagged`: `true` when `OrderDate` is earlier than `2019-08-01`, else `false`.
#      - `CreatedTS` and `ModifiedTS`: current timestamp.
#    - Cleans `CustomerName`, setting it to `"Unknown"` when null or empty.
#    - Overwrites `SilverTable` with the transformed data.
# 
# 4. **Define table schema (idempotent)**  
#    Uses Delta Lake DDL to **create the `SilverTable` if it does not exist** with the desired schema, including business and metadata columns such as `IsFlagged`, `CreatedTS`, and `ModifiedTS`.
# 
# 5. **Upsert (merge) updates into `SilverTable`**  
#    - Treats the DataFrame `df` as the source of updates.
#    - Matches existing rows on `SalesOrderNumber`, `OrderDate`, `CustomerName`, and `Item`.
#    - **When matched:** updates quantities, prices, taxes, flags, and `ModifiedTS`.
#    - **When not matched:** inserts new rows with all fields including `CreatedTS` and `ModifiedTS`.
# 
# > Tip: Run the cells in order from top to bottom so that the schema definition and DataFrame `df` used in the merge are correctly initialized before the merge cell executes.


# CELL ********************

from pyspark.sql.types import *
df = spark.read.table("SilverTable")
df.show(20, truncate=False)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")

df.write.mode("overwrite").option("overwriteSchema", "true").format("delta").saveAsTable("SilverTable")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.functions import when, lit, col, current_timestamp, input_file_name

# Read from SilverTable
df = spark.read.table("SilverTable")

# Add columns IsFlagged, CreatedTS and ModifiedTS
df = df.withColumn("IsFlagged", when(col("OrderDate") < '2019-08-01', True).otherwise(False)) \
    .withColumn("CreatedTS", current_timestamp()) \
    .withColumn("ModifiedTS", current_timestamp())

# Update CustomerName to "Unknown" if CustomerName null or empty
df = df.withColumn("CustomerName", when((col("CustomerName").isNull() | (col("CustomerName") == "")), lit("Unknown")).otherwise(col("CustomerName")))

# Overwrite the SilverTable with updated data
df.write.mode("overwrite").format("delta").saveAsTable("SilverTable")

df.show(20, truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Define the schema for the sales_silver table
    
from pyspark.sql.types import *
from delta.tables import *
    
DeltaTable.createIfNotExists(spark) \
    .tableName("SilverTable") \
    .addColumn("SalesOrderNumber", StringType()) \
    .addColumn("SalesOrderLineNumber", IntegerType()) \
    .addColumn("OrderDate", DateType()) \
    .addColumn("CustomerName", StringType()) \
    .addColumn("Email", StringType()) \
    .addColumn("Item", StringType()) \
    .addColumn("Quantity", IntegerType()) \
    .addColumn("UnitPrice", FloatType()) \
    .addColumn("Tax", FloatType()) \
    .addColumn("FileName", StringType()) \
    .addColumn("IsFlagged", BooleanType()) \
    .addColumn("CreatedTS", DateType()) \
    .addColumn("ModifiedTS", DateType()) \
    .execute()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from delta.tables import *

deltaTable = DeltaTable.forName(spark, 'SilverTable')

dfUpdates = df

deltaTable.alias('silver') \
  .merge(
    dfUpdates.alias('updates'),
    'silver.SalesOrderNumber = updates.SalesOrderNumber and silver.OrderDate = updates.OrderDate and silver.CustomerName = updates.CustomerName and silver.Item = updates.Item'
  ) \
  .whenMatchedUpdate(set =
    {
      "SalesOrderLineNumber": "updates.SalesOrderLineNumber",
      "Email": "updates.Email",
      "Quantity": "updates.Quantity",
      "UnitPrice": "updates.UnitPrice",
      "Tax": "updates.Tax",
      "IsFlagged": "updates.IsFlagged",
      "ModifiedTS": "updates.ModifiedTS"
    }
  ) \
  .whenNotMatchedInsert(values =
    {
      "SalesOrderNumber": "updates.SalesOrderNumber",
      "SalesOrderLineNumber": "updates.SalesOrderLineNumber",
      "OrderDate": "updates.OrderDate",
      "CustomerName": "updates.CustomerName",
      "Email": "updates.Email",
      "Item": "updates.Item",
      "Quantity": "updates.Quantity",
      "UnitPrice": "updates.UnitPrice",
      "Tax": "updates.Tax",
      "IsFlagged": "updates.IsFlagged",
      "CreatedTS": "updates.CreatedTS",
      "ModifiedTS": "updates.ModifiedTS"
    }
  ) \
  .execute()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
