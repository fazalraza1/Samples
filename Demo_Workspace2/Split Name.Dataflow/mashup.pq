[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Replace"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared DefaultDestination = let
  Source = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  #"Navigation 1" = Source{[workspaceId = "2c14bfb4-7a6e-418c-9006-b565c36cc0ae"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[lakehouseId = "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"]}[Data]
in
  #"Navigation 2";
[BindToDefaultDestination = true]
shared SilverTable = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "2c14bfb4-7a6e-418c-9006-b565c36cc0ae"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "4f5f817d-3ad7-4b39-8828-0ed8e47baf0a"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "SilverTable", ItemKind = "Table"]}[Data],
  #"Removed duplicates" = Table.Distinct(#"Navigation 2", {"CustomerName"}),
  #"Removed duplicates 1" = Table.Distinct(#"Removed duplicates", {"Email"}),
  #"Split column by delimiter" = Table.SplitColumn(#"Removed duplicates 1", "CustomerName", Splitter.SplitTextByDelimiter(" "), {"CustomerName.1", "CustomerName.2"}),
  #"Renamed columns" = Table.RenameColumns(#"Split column by delimiter", {{"CustomerName.1", "First"}, {"CustomerName.2", "Last"}})
in
  #"Renamed columns";
