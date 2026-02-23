[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Sample file_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared #"Sample file" = let
  Source = Lakehouse.Contents([HierarchicalNavigation = null]),
  #"Navigation 1" = Source{[workspaceId = "2c14bfb4-7a6e-418c-9006-b565c36cc0ae"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[lakehouseId = "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 4" = #"Navigation 3"{[Name = "bronze"]}[Content],
  #"Appended query" = Table.Combine({#"Navigation 4", #"Navigation 4"}),
  #"Filtered hidden files" = Table.SelectRows(#"Appended query", each [Attributes]?[Hidden]? <> true),
  #"Invoke custom function" = Table.AddColumn(#"Filtered hidden files", "Transform file", each #"Transform file"([Content])),
  #"Removed other columns" = Table.SelectColumns(#"Invoke custom function", {"Transform file"}),
  #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file", Table.ColumnNames(#"Transform file"(#"Sample file (2)"))),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {{"Prop_0", type text}, {"Prop_1", Int64.Type}, {"Prop_2", type date}, {"Prop_3", type text}, {"Prop_4", type text}, {"Prop_5", type text}, {"Prop_6", Int64.Type}, {"Prop_7", type number}, {"Prop_8", type number}}),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type", {{"Prop_0", "SalesOrderNumber"}, {"Prop_1", "SalesOrderLineNumber"}, {"Prop_2", "OrderDate"}, {"Prop_3", "CustomerName"}, {"Prop_4", "Email"}, {"Prop_5", "Item"}, {"Prop_6", "Quantity"}, {"Prop_7", "UnitPrice"}, {"Prop_8", "Tax"}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Renamed columns", {{"OrderDate", type date}}),
  #"Sorted rows" = Table.Sort(#"Changed column type 1", {{"OrderDate", Order.Ascending}}),
  #"Removed duplicates" = Table.Distinct(#"Sorted rows", {"OrderDate"}),
  #"Changed column type 2" = Table.TransformColumnTypes(#"Removed duplicates", {{"UnitPrice", Currency.Type}, {"Tax", Currency.Type}})
in
  #"Changed column type 2";
shared #"Sample file (2)" = let
  Source = Lakehouse.Contents([HierarchicalNavigation = null]),
  #"Navigation 1" = Source{[workspaceId = "2c14bfb4-7a6e-418c-9006-b565c36cc0ae"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[lakehouseId = "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 4" = #"Navigation 3"{[Name = "bronze"]}[Content],
  #"Appended query" = Table.Combine({#"Navigation 4", #"Navigation 4"}),
  #"Filtered hidden files" = Table.SelectRows(#"Appended query", each [Attributes]?[Hidden]? <> true),
  Navigation = #"Filtered hidden files"{0}[Content]
in
  Navigation;
shared Parameter = let
  Parameter = #"Sample file (2)" meta [IsParameterQuery = true, IsParameterQueryRequired = false, Type = type binary, BinaryIdentifier = #"Sample file (2)"]
in
  Parameter;
shared #"Transform Sample file (2)" = let
  Source = Csv.Document(Parameter, [Delimiter = ",", Columns = 9, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true])
in
  #"Promoted headers";
[FunctionQueryBinding = "{""exemplarFormulaName"":""Transform Sample file (2)""}"]
shared #"Transform file" = (Parameter as binary) => let
  Source = Csv.Document(Parameter, [Delimiter = ",", Columns = 9, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true])
in
  #"Promoted headers";
shared #"Sample file_DataDestination" = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2c14bfb4-7a6e-418c-9006-b565c36cc0ae"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"]}[Data],
  TableNavigation = Navigation_2{[Id = "SilverTable", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
