[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared orders = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "a66b17f5-7c7b-41e0-bae7-97f58eff547d"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "5c51fca0-c582-409d-be1c-4ab253887ab8"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "Sales_Data"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "orders"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "2019.txt"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 9, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Changed column type" = Table.TransformColumnTypes(#"Imported CSV", {{"Column1", type text}, {"Column2", Int64.Type}, {"Column3", type date}, {"Column4", type text}, {"Column5", type text}, {"Column6", type text}, {"Column7", Int64.Type}, {"Column8", type number}, {"Column9", type number}}),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type", {{"Column1", "SalesOrderNumber"}, {"Column2", "SalesOrderLineNumber"}, {"Column3", "OrderDate"}, {"Column4", "CustomerName"}, {"Column5", "Email"}, {"Column6", "Item"}, {"Column7", "Quantity"}, {"Column8", "UnitPrice"}, {"Column9", "Tax"}})
in
  #"Renamed columns";
