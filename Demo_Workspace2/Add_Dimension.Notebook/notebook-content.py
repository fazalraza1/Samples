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
# META     },
# META     "warehouse": {
# META       "default_warehouse": "9955a7e7-05d1-44b7-b165-42d312180d6c",
# META       "known_warehouses": [
# META         {
# META           "id": "9955a7e7-05d1-44b7-b165-42d312180d6c",
# META           "type": "Lakewarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Notebook Summary – Add_Dimension
# 
# This notebook builds **gold-layer dimension tables** from an existing silver table:
# 
# 1. **Load source data** from the `SilverTable` into a Spark DataFrame.
# 2. **Create `dimdate_gold` Delta table** with date-related attributes (`OrderDate`, day, month, year, `mmmyyyy`, `yyyymm`).
# 3. **Derive the Date dimension DataFrame** (`dfdimDate_gold`) by de-duplicating `OrderDate` and adding calendar attributes.
# 4. **Upsert into `dimdate_gold`** using a Delta Lake `MERGE` to insert new dates and prepare for updates.
# 5. **Create `dimcustomer_gold` Delta table** to hold curated customer attributes (`CustomerName`, `Email`, `First`, `Last`, `CustomerID`).
# 6. A note indicates that **customer cleansing and name-splitting** logic (drop duplicates, split `CustomerName` into `First` and `Last`) is handled in **Dataflow Gen2**, not in this notebook.
# 
# Use this notebook as the final transformation step to materialize **gold-layer dimensions** ready for reporting and analytics.


# CELL ********************

# Load data to the dataframe as a starting point to create the gold layer
df = spark.read.table("SilverTable")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import *
from delta.tables import*
    
# Define the schema for the dimdate_gold table
DeltaTable.createIfNotExists(spark) \
    .tableName("dimdate_gold") \
    .addColumn("OrderDate", DateType()) \
    .addColumn("Day", IntegerType()) \
    .addColumn("Month", IntegerType()) \
    .addColumn("Year", IntegerType()) \
    .addColumn("mmmyyyy", StringType()) \
    .addColumn("yyyymm", StringType()) \
    .execute()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Welcome to your new notebook
# Type here in the cell editor to add code!
from pyspark.sql.functions import col, dayofmonth, month, year, date_format
    
# Create dataframe for dimDate_gold
    
dfdimDate_gold = df.dropDuplicates(["OrderDate"]).select(col("OrderDate"), \
        dayofmonth("OrderDate").alias("Day"), \
        month("OrderDate").alias("Month"), \
        year("OrderDate").alias("Year"), \
        date_format(col("OrderDate"), "MMM-yyyy").alias("mmmyyyy"), \
        date_format(col("OrderDate"), "yyyyMM").alias("yyyymm"), \
    ).orderBy("OrderDate")

# Display the first 10 rows of the dataframe to preview your data

display(dfdimDate_gold.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from delta.tables import *
    
deltaTable = DeltaTable.forName(spark, 'dimdate_gold')
    
dfUpdates = dfdimDate_gold
    
deltaTable.alias('gold') \
  .merge(
    dfUpdates.alias('updates'),
    'gold.OrderDate = updates.OrderDate'
  ) \
   .whenMatchedUpdate(set =
    {
          
    }
  ) \
 .whenNotMatchedInsert(values =
    {
      "OrderDate": "updates.OrderDate",
      "Day": "updates.Day",
      "Month": "updates.Month",
      "Year": "updates.Year",
      "mmmyyyy": "updates.mmmyyyy",
      "yyyymm": "updates.yyyymm"
    }
  ) \
  .execute()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import *
from delta.tables import *
    
# Create customer_gold dimension delta table
DeltaTable.createIfNotExists(spark) \
    .tableName("dimcustomer_gold") \
    .addColumn("CustomerName", StringType()) \
    .addColumn("Email",  StringType()) \
    .addColumn("First", StringType()) \
    .addColumn("Last", StringType()) \
    .addColumn("CustomerID", LongType()) \
    .execute()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# drop duplicate customers, select specific columns, and split the “CustomerName” column to create “First” and “Last” name columns: This is done in the Dataflow Gen2
