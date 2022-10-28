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
function Export-Excel {
  <#
    .Synopsis
     Converts an array of objects into an Excel document.
    .Example
     Export-Excel -Path .\Example.xlsx -InputObject $data
     This example would import the data stored in $data into an Excel document and save it as Example.xlsx.
    .Description
     The Export-Excel cmdlet converts an array of objects into an Excel document.
     Additionally, you can specify whether you would like the header of each column bolded, and also if you would like it to have a bottom border.
    .Parameter InputObject
     Specifies the objects to export to Excel. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe objects to Export-Excel.
    .Parameter Path
     Specifies the path to the Excel output file. The parameter is required.
    .Parameter HeaderBorder
     Specifies whether to give each header a border, and if so, what type of border to be used. The available options are Line, ThickLine, or DoubleLine.
    .Parameter BoldHeader
     Specifies that the header row should be bolded.
    .Parameter Force
     Overwrites the file specified in path without prompting.
    .Outputs
     String Path
    .Notes
     Name:   Export-Excel
     Module: ImportExportExcel.psm1
     Author: Jeremy Engel
     Date:   05.17.2011
    .Link
     Import-Excel
  #>
  [CmdletBinding()]
  Param([Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSObject]$InputObject,
    [Parameter(Mandatory = $false)][ValidateSet('Line', 'ThickLine', 'DoubleLine')][string]$HeaderBorder,
    [Parameter(Mandatory = $false)][switch]$BoldHeader,
    [Parameter(Mandatory = $false)][switch]$Force
  )
  $Path = if ([IO.Path]::IsPathRooted($Path)) { $Path }else { Join-Path -Path (Get-Location) -ChildPath $Path }
  if ($Path -notmatch '.xls$|.xlsx$') { Write-Host "ERROR: Invalid file extension in Path [$Path]." -ForegroundColor Red; return }
  $excel = New-Object -ComObject Excel.Application
  if (!$excel) { Write-Host 'ERROR: Please install Excel first.' -ForegroundColor Red; return }
  $workbook = $excel.Workbooks.Add()
  $sheet = $workbook.Worksheets.Item(1)
  $xml = ConvertTo-Xml $InputObject # I couldn't figure out how else to read the NoteProperty names
  $lines = $xml.Objects.Object.Property
  for ($r = 2; $r -le $lines.Count; $r++) {
    $fields = $lines[$r - 1].Property
    for ($c = 1; $c -le $fields.Count; $c++) {
      if ($r -eq 2) { $sheet.Cells.Item(1, $c) = $fields[$c - 1].Name }
      $sheet.Cells.Item($r, $c) = $fields[$c - 1].InnerText
    }
  }
  [void]($sheet.UsedRange).EntireColumn.AutoFit()
  $headerRow = $sheet.Range('1:1')
  if ($BoldHeader) { $headerRow.Font.Bold = $true }
  switch ($HeaderBorder) {
    'Line' { $style = 1 }
    'ThickLine' { $style = 4 }
    'DoubleLine' { $style = -4119 }
    default { $style = -4142 }
  }
  $headerRow.Borders.Item(9).LineStyle = $style
  if ($Force) { $excel.DisplayAlerts = $false }
  $workbook.SaveAs($Path)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($headerRow) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheet) } while ($o -gt -1)
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) } while ($o -gt -1)
  $excel.ActiveWorkbook.Close($false)
  $excel.Quit()
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) } while ($o -gt -1)
  return $Path
}

Export-ModuleMember Export-Excel, Import-Excel