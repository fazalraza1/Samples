[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "orders_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared orders = let
  Source = Lakehouse.Contents([HierarchicalNavigation = null]),
  #"Navigation 1" = Source{[workspaceId = "a66b17f5-7c7b-41e0-bae7-97f58eff547d"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[lakehouseId = "5c51fca0-c582-409d-be1c-4ab253887ab8"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 4" = #"Navigation 3"{[Name = "Sales_Data"]}[Content],
  Navigation = #"Navigation 4"{[Name = "orders"]}[Content],

  // Read ALL files in the orders folder instead of just one
  #"Filtered to TXT" = Table.SelectRows(Navigation, each Text.EndsWith([Name], ".txt")),

  // Parse each file as CSV
  #"Added CSV" = Table.AddColumn(#"Filtered to TXT", "ParsedCSV", each 
      Csv.Document([Content], [Delimiter = ",", Columns = 9, Encoding = 65001, QuoteStyle = QuoteStyle.None])
  ),

  // Expand all rows from each file into one table
  #"Expanded" = Table.ExpandTableColumn(#"Added CSV", "ParsedCSV", 
      {"Column1","Column2","Column3","Column4","Column5","Column6","Column7","Column8","Column9"}),

  // Set data types
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded", {
      {"Column1", type text}, {"Column2", Int64.Type}, {"Column3", type date}, 
      {"Column4", type text}, {"Column5", type text}, {"Column6", type text}, 
      {"Column7", Int64.Type}, {"Column8", type number}, {"Column9", type number}
  }),

  // Remove file metadata columns (Name, Content, etc.)
  #"Removed Other Columns" = Table.SelectColumns(#"Changed column type", 
      {"Column1","Column2","Column3","Column4","Column5","Column6","Column7","Column8","Column9"}),
  #"Sorted rows" = Table.Sort(#"Removed Other Columns", {{"Column3", Order.Ascending}}),
  #"Renamed columns" = Table.RenameColumns(#"Sorted rows", {{"Column1", "SalesOrderNumber"}, {"Column2", "SalesOrderLineNumber"}, {"Column3", "OrderDate"}, {"Column4", "CustomerName"}, {"Column5", "Email"}, {"Column6", "Item"}, {"Column7", "Quantity"}, {"Column8", "UnitPrice"}, {"Column9", "Tax"}})
in
  #"Renamed columns";
shared orders_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "a66b17f5-7c7b-41e0-bae7-97f58eff547d"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "5c51fca0-c582-409d-be1c-4ab253887ab8"]}[Data],
  TableNavigation = Navigation_2{[Id = "Delta Table", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
