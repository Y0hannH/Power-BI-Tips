let
    /*  
    
        Configuration 

    */ 

    // Set the Today's date
    Today = Date.From(DateTime.LocalNow()),

    // Set the starting year of the date table. Dates will start at the 01/01 of this year.
    From = 2008,

    // Set the end year of the dates table. Dates will stop at 31/12 of this year
    // You can use the current year based on today's date or anything else you need.
    To = Date.Year(Today),

    // Set the starting month of the financial year. 1 is january, 12 is december. 
    FiscalYearStartingMonth = 1,

    // Set the first day of week     
    FirstDayOfTheWeek = Day.Monday, 

    // Set the dates Culture
    Culture = "en-US",

    /* 
        End Configuration 
    */
    
    // Starting date is set 
    DateFrom = #date(From,1,1),

    // Ending date is set 
    DateTo = #date(To,12,31),

    // A list is generated with all dates between the starting/ending dates
    Source=List.Dates(
        DateFrom,
        Duration.Days(DateTo - DateFrom) + 1,
        #duration(1,0,0,0)
    ),

    /* Table is generated */ 
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),

    // Add core columns : a date as date format and a dateId as primary key INT yyyyMMdd 
    #"Add Dateid" = Table.TransformColumnTypes(Table.AddColumn(#"Renamed Columns", "DateId", each Date.Year([Date])*10000 + Date.Month([Date]) * 100 + Date.Day([Date])), {{"DateId", Int64.Type}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Add Dateid",{{"Date", type date}}),
    #"Change Columns Orders" = Table.ReorderColumns(#"Changed Type", {"DateId", "Date"}),
    #"Set DateId as PK" = Table.AddKey(#"Change Columns Orders", {"DateId"}, false),

    // Add others columns
    #"Add Year" = Table.AddColumn(#"Set DateId as PK", "Year", each Date.Year([Date]), Int64.Type),
    #"Add Start of Year" = Table.AddColumn(#"Add Year", "Start of Year", each Date.StartOfYear([Date]), type date),
    #"Add End of Year" = Table.AddColumn(#"Add Start of Year", "End of Year", each Date.EndOfYear([Date]), type date),
    #"Add Month" = Table.AddColumn(#"Add End of Year", "Month", each Date.Month([Date]), Int64.Type),
    #"Add Start of Month" = Table.AddColumn(#"Add Month", "Start of Month", each Date.StartOfMonth([Date]), type date),
    #"Add End of Month" = Table.AddColumn(#"Add Start of Month", "End of Month", each Date.EndOfMonth([Date]), type date),
    #"Add Days in Month" = Table.AddColumn(#"Add End of Month", "Days in Month", each Date.DaysInMonth([Date]), Int64.Type),
    #"Add Day" = Table.AddColumn(#"Add Days in Month", "Day", each Date.Day([Date]), Int64.Type),
    #"Add Day Name" = Table.AddColumn(#"Add Day", "Day Name", each Date.DayOfWeekName([Date], Culture), type text),
    #"Add Day of Week" = Table.AddColumn(#"Add Day Name", "Day of Week", each Date.DayOfWeek([Date]), Int64.Type),
    #"Add Day of Year" = Table.AddColumn(#"Add Day of Week", "Day of Year", each Date.DayOfYear([Date]), Int64.Type),
    #"Add Month Name" = Table.AddColumn(#"Add Day of Year", "Month Name", each Date.MonthName([Date], Culture), type text),
    #"Add Month Name Short" = Table.AddColumn(#"Add Month Name", "Month Name Short", each Date.MonthName([Date], Culture), type text),
    #"Extract Fisrt Characters" = Table.TransformColumns(#"Add Month Name Short", {{"Month Name Short", each Text.Start(_, 3), type text}}),
    #"Add Quarter" = Table.AddColumn(#"Extract Fisrt Characters", "Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
    #"Add Quarter Period" = Table.TransformColumnTypes(Table.AddColumn(#"Add Quarter", "Quarter Period", each Text.From([Year]) & " Q" & Text.From([Quarter])), {{"Quarter Period", type text}}),
    #"Add Start of Quarter" = Table.AddColumn(#"Add Quarter Period", "Start of Quarter", each Date.StartOfQuarter([Date]), type date),
    #"Add End of Quarter" = Table.AddColumn(#"Add Start of Quarter", "End of Quarter", each Date.EndOfQuarter([Date]), type date),
    #"Add Week of Year" = Table.AddColumn(#"Add End of Quarter", "Week of Year", each Date.WeekOfYear([Date],FirstDayOfTheWeek), Int64.Type),
    #"Add Week of Month" = Table.AddColumn(#"Add Week of Year", "Week of Month", each Date.WeekOfMonth([Date],FirstDayOfTheWeek), Int64.Type),
    #"Add Start of Week" = Table.AddColumn(#"Add Week of Month", "Start of Week", each Date.StartOfWeek([Date],FirstDayOfTheWeek), type date),
    #"Add End of Week" = Table.AddColumn(#"Add Start of Week", "End of Week", each Date.EndOfWeek([Date],FirstDayOfTheWeek), type date),
    FiscalMonthBaseIndex=13-FiscalYearStartingMonth,
    adjustedFiscalMonthBaseIndex=if(FiscalMonthBaseIndex>=12 or FiscalMonthBaseIndex<0) then 0 else FiscalMonthBaseIndex,
    #"Added Custom" = Table.AddColumn(#"Add End of Week", "FiscalBaseDate", each Date.AddMonths([Date],adjustedFiscalMonthBaseIndex)),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom",{{"FiscalBaseDate", type date}}),
    #"Add Year1" = Table.AddColumn(#"Changed Type1", "Year.1", each Date.Year([FiscalBaseDate]), Int64.Type),
    #"Renamed Columns1" = Table.RenameColumns(#"Add Year1",{{"Year.1", "Fiscal Year"}}),
    #"Add Quarter1" = Table.AddColumn(#"Renamed Columns1", "Quarter.1", each Date.QuarterOfYear([FiscalBaseDate]), Int64.Type),
    #"Renamed Columns2" = Table.RenameColumns(#"Add Quarter1",{{"Quarter.1", "Fiscal Quarter"}}),
    #"Add Month1" = Table.AddColumn(#"Renamed Columns2", "Month.1", each Date.Month([FiscalBaseDate]), Int64.Type),
    #"Renamed Columns3" = Table.RenameColumns(#"Add Month1",{{"Month.1", "Fiscal Month"}}),
    #"Removed Columns" = Table.RemoveColumns(#"Renamed Columns3",{"FiscalBaseDate"}),
    #"Add Age" = Table.AddColumn(#"Removed Columns", "Age", each [Date]-Today, type duration),
    #"Extracted Days" = Table.TransformColumns(#"Add Age",{{"Age", Duration.Days, Int64.Type}}),
    #"Renamed Columns4" = Table.RenameColumns(#"Extracted Days",{{"Age", "Day Offset"}}),
    #"Added Custom1" = Table.AddColumn(#"Renamed Columns4", "Month Offset", each (([Year]-Date.Year(Today))*12)
+([Month]-Date.Month(Today))),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom1",{{"Month Offset", Int64.Type}}),
    #"Added Custom2" = Table.AddColumn(#"Changed Type2", "Year Offset", each [Year]-Date.Year(Today)),
    #"Changed Type3" = Table.TransformColumnTypes(#"Added Custom2",{{"Year Offset", Int64.Type}}),
    #"Added Custom3" = Table.AddColumn(#"Changed Type3", "Quarter Offset", each (([Year]-Date.Year(Today))*4)
+([Quarter]-Date.QuarterOfYear(Today))),
    #"Changed Type4" = Table.TransformColumnTypes(#"Added Custom3",{{"Quarter Offset", Int64.Type}})
in
   #"Changed Type4"