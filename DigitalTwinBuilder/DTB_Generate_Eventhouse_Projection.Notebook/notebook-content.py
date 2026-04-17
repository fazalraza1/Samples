# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "83b2b42b-433c-436f-a5c8-20c3b7221b15",
# META       "default_lakehouse_name": "TutorialDTBdtdm",
# META       "default_lakehouse_workspace_id": "324687f5-fda2-496e-bc78-7624907eab85",
# META       "known_lakehouses": [
# META         {
# META           "id": "12f3a735-afb2-4f49-ae0d-50da8d56b148"
# META         },
# META         {
# META           "id": "83b2b42b-433c-436f-a5c8-20c3b7221b15"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "default_warehouse": "794e07c2-cc42-4009-838c-32f3b903fc43",
# META       "known_warehouses": [
# META         {
# META           "id": "794e07c2-cc42-4009-838c-32f3b903fc43",
# META           "type": "Lakewarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

%pip install -U --force-reinstall /lakehouse/default/Files/dtb_samples-0.1-py3-none-any.whl --q

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

%pip install duckdb deltalake -q

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Diagnostic: Verify installation and check for import issues
try:
    import dtb
    print(f"✓ dtb package installed successfully")
    print(f"  Location: {dtb.__file__}")
    print(f"  Version: {getattr(dtb, '__version__', 'Unknown')}")
except ImportError as e:
    print(f"✗ Failed to import dtb: {e}")
    print("  Run cell 1 first to install the package")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

dtb_item_name = "TutorialDTB"  # TODO Update your DTB item name here
kql_db_name="Tutorial"  # TODO Upate your kql db name here

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Import required libraries with error handling
try:
    import sempy.fabric as fabric
    import base64
    import time
    import uuid
    import json
    import com.microsoft.spark.fabric
    from com.microsoft.spark.fabric.Constants import Constants
    print("✓ Fabric libraries imported successfully")
except ImportError as e:
    print(f"✗ Error importing Fabric libraries: {e}")
    raise

try:
    from dtb.client import DtbClient, DtbClientConfig
    from dtb.utilities import DtbFabricHelper
    print("✓ DTB libraries imported successfully")
except ImportError as e:
    print(f"✗ Error importing DTB libraries: {e}")
    print("  Make sure you ran cell 1 and the kernel restarted")
    raise

workspace_name = fabric.resolve_workspace_name()
print(f"✓ Workspace: {workspace_name}")

dtb_client = DtbClient(DtbClientConfig(dtb_item_name, workspace_name))
df_reader = spark.read.option(Constants.DatabaseName, dtb_client.get_database_name())
fabric_helper = DtbFabricHelper(dtb_client)
kql_script = fabric_helper.generate_eventhouse_projection(spark, df_reader)
print("✓ Eventhouse projection generated successfully")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

client = fabric.FabricRestClient()
workspaceId = fabric.get_workspace_id()

queryURI = ""
url = f"v1/workspaces/{workspaceId}/kqlDatabases"
response=client.get(url)
for item in response.json()['value']:
    if item['displayName'] == f"{kql_db_name}":
        queryURI = item["properties"]["queryServiceUri"]

token_string = mssparkutils.credentials.getToken(f"{queryURI}")
header = {'Content-Type':'application/json','Authorization': f'Bearer {token_string}'}
mgmturl = f"{queryURI}/v1/rest/mgmt"
payload = {
    "db": kql_db_name,
    "csl": kql_script.encode('utf-8')
}
response=client.post(mgmturl,json=payload,headers=header)
print("Successfully created Eventhouse domain projection functions.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
