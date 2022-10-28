#=============================================================================#
#                                                                             #
# ImportExportExcel.psm1                                                      #
# Imports data from excel and exports data to excel                           #
# Author: Jeremy Engel                                                        #
# CreationDate: 05.17.2011                                                    #
# ModifiedDate: 07.11.2011                                                    #
# Version: 1.0.8                                                              #
# Ref: https://github.com/jeffbuenting/Office
#                                                                             #
#=============================================================================#

function Import-Excel {
  <#
    .Synopsis
     Converts an Excel document into an array of objects with the columns as separate properties.
    .Example
     Import-Excel -Path .\Example.xlsx
     This example would import the data stored in the Example.xlsx spreadsheet.
    .Description
     The Import-Excel cmdlet converts an Excel document into an array of objects whose property names are determined by the column headers and whose values are determined by the column data.
     Additionally, you can specify whether this particular Excel file has any headers at all, in which case the objects will be given the property names based on their column. Likewise, if the document has headers, but one column does not, its data will be assigned a Column# property name.
    .Parameter Path
     Specifies the path to the Excel file to import. You can also pipe a path to Import-Excel.
    .Parameter NoHeaders
     Specifies that the document being imported has no headers. Default value is False.
    .Outputs
     PSObject[]
    .Notes
     Name:   Import-Excel
     Module: ImportExportExcel.psm1
     Author: Jeremy Engel
     Date:   05.17.2011
    .Link
     Export-Excel
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$Path,
    [Parameter(Mandatory = $false)][int16]$Sheet = 1,
    [Parameter(Mandatory = $false)][switch]$NoHeaders
  )
  $Path = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path -Path (Get-Location) -ChildPath $Path }
  if (!(Test-Path $Path) -or $Path -notmatch '.xls$|.xlsx$') { 
    Write-Host "ERROR: Invalid excel file [$Path]." -ForegroundColor Red; 
    return 
  }
  $Excel = New-Object -ComObject Excel.Application
  if (!$Excel) { 
    Write-Host "ERROR: Please install Excel first. I haven't figured out how to read an Excel file as xml yet." -ForegroundColor Red; 
    return 
  }
  $content = @()
  $Workbooks = $Excel.Workbooks
  $Workbook = $Workbooks.Open($Path)
  $Worksheets = $Workbook.Worksheets
  $Worksheet = $Worksheets.Item($Sheet)
  $Range = $Worksheet.UsedRange
  $Rows = $Range.Rows
  $Columns = $Range.Columns
  $Headers = @()
  $top = if ($NoHeaders) { 1 }else { 2 }  # This tells the import code what line to start on when retrieving data
  if ($NoHeaders) { 
    for ($c = 1; $c -le $Columns.Count; $c++) { $Headers += "Column$c" } 
  }  # If the Excel file has no headers, use Column1, Column2, etc...
  else {
    $Headers = $Rows | Where-Object { $_.Row -eq 1 } | ForEach-Object { $_.Value2 }
    for ($i = 0; $i -lt $Headers.Count; $i++) {
      # If a column is missing a header, then create one
      if (!$Headers[$i]) { 
        $Headers[$i] = "Column$($i+1)" 
      }
    }  
  } 

  if ( !$Headers ) { Write-Host 'ERROR - There are blank rows at the top of the spreadsheet...' -ForegroundColor Red }
	
  for ($r = $top; $r -le $rows.Count; $r++) {
    # This for clause reads the content of Excel file and populates an array of objects, with the headers as property names
    $data = $rows | Where-Object { $_.Row -eq $r } | ForEach-Object { $_.Value2 }
    $line = New-Object PSOBject
    for ($c = 0; $c -lt $columns.Count; $c++) { 
      #		write-host $c, $data[$c]
      #		Write-Host $Headers[$c]
      $line | Add-Member NoteProperty $headers[$c]($data[$c])
		
    }
    $content += $line
  }
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($columns) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($rows) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Worksheet) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Worksheets) } while ($o -gt -1)
  $workbook.Close($false)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbooks) } while ($o -gt -1)
  $Excel.Quit()
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel) } while ($o -gt -1)
  return $content
}
