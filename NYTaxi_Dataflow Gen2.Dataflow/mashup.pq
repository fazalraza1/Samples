[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared Bronze = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "a66b17f5-7c7b-41e0-bae7-97f58eff547d"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "5c51fca0-c582-409d-be1c-4ab253887ab8"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Bronze", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"lpepPickupDatetime", type date}}),
  #"Choose columns" = Table.SelectColumns(#"Changed column type", {"vendorID", "lpepPickupDatetime", "passengerCount", "tripDistance", "pickupLongitude", "dropoffLatitude", "storeAndFwdFlag", "totalAmount"}),
  #"Filtered rows" = Table.SelectRows(#"Choose columns", each ([storeAndFwdFlag] = "Y")),
  #"Filtered rows 1" = Table.SelectRows(#"Filtered rows", each [lpepPickupDatetime] >= #date(2015, 1, 1) and [lpepPickupDatetime] <= #date(2015, 1, 31))
in
  #"Filtered rows 1";
shared #"Generated-NYC-Taxi-Green-Discounts" = let
  Source = Csv.Document(Web.Contents("https://raw.githubusercontent.com/ekote/azure-architect/master/Generated-NYC-Taxi-Green-Discounts.csv"), [Delimiter = ",", Columns = 32, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"VendorID", Int64.Type}, {"2015-01-01", Int64.Type}, {"2015-01-02", Int64.Type}, {"2015-01-03", Int64.Type}, {"2015-01-04", Int64.Type}, {"2015-01-05", Int64.Type}, {"2015-01-06", Int64.Type}, {"2015-01-07", Int64.Type}, {"2015-01-08", Int64.Type}, {"2015-01-09", Int64.Type}, {"2015-01-10", Int64.Type}, {"2015-01-11", Int64.Type}, {"2015-01-12", Int64.Type}, {"2015-01-13", Int64.Type}, {"2015-01-14", Int64.Type}, {"2015-01-15", Int64.Type}, {"2015-01-16", Int64.Type}, {"2015-01-17", Int64.Type}, {"2015-01-18", Int64.Type}, {"2015-01-19", Int64.Type}, {"2015-01-20", Int64.Type}, {"2015-01-21", Int64.Type}, {"2015-01-22", Int64.Type}, {"2015-01-23", Int64.Type}, {"2015-01-24", Int64.Type}, {"2015-01-25", Int64.Type}, {"2015-01-26", Int64.Type}, {"2015-01-27", Int64.Type}, {"2015-01-28", Int64.Type}, {"2015-01-29", Int64.Type}, {"2015-01-30", Int64.Type}, {"2015-01-31", Int64.Type}}),
  #"Unpivoted other columns" = Table.UnpivotOtherColumns(#"Changed column type", {"VendorID"}, "Attribute", "Value"),
  #"Renamed columns" = Table.RenameColumns(#"Unpivoted other columns", {{"Attribute", "Date"}, {"Value", "Discount"}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Renamed columns", {{"Date", type date}}),
  #"Divided column" = Table.TransformColumns(#"Changed column type 1", {{"Discount", each _ / 100, type number}})
in
  #"Divided column";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Output_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Output = let
  Source = Table.NestedJoin(Bronze, {"lpepPickupDatetime", "vendorID"}, #"Generated-NYC-Taxi-Green-Discounts", {"Date", "VendorID"}, "Generated-NYC-Taxi-Green-Discounts", JoinKind.LeftOuter),
  #"Expanded Generated-NYC-Taxi-Green-Discounts" = Table.ExpandTableColumn(Source, "Generated-NYC-Taxi-Green-Discounts", {"Discount"}, {"Discount"}),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Expanded Generated-NYC-Taxi-Green-Discounts", "TotalAfterDiscount", each if [totalAmount] > 0 then [totalAmount] * ( 1 -[Discount] ) else [totalAmount]), {{"TotalAfterDiscount", Currency.Type}}),
  #"Rounded off" = Table.TransformColumns(#"Added custom", {{"TotalAfterDiscount", each Number.Round(_, 2), type number}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Rounded off", {{"lpepPickupDatetime", type datetime}})
in
  #"Changed column type";
shared Output_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "a66b17f5-7c7b-41e0-bae7-97f58eff547d"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "5c51fca0-c582-409d-be1c-4ab253887ab8"]}[Data],
  TableNavigation = Navigation_2{[Id = "nyc_taxi_with_discounts", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
