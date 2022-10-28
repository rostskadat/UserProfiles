$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe 'Dump Idle Times' {
  Context 'readable, without grouping' {
    Mock Invoke-SqliteQuery { return [PSCustomObject] @{ 'StartDate' = 0 ; 'StopDate' = 1 ; 'Consolidated' = 1 ; 'DeltaSecond' = 3660 } }
    $result = Register-Idle -Dump -Readable
    It 'returns the raw result' {
      $result.StartDate | Should Be 0
      $result.StopDate | Should Be 1
      $result.Consolidated | Should Be 1
      $result.Hours | Should Be 1
      $result.Minutes | Should Be 1
    }
  }
  Context 'raw, without grouping' {
    Mock Invoke-SqliteQuery { return [PSCustomObject] @{ 'StartDate' = 0 ; 'StopDate' = 1 ; 'Consolidated' = 1 ; 'DeltaSecond' = 3660 } }
    $result = Register-Idle -Dump
    It 'returns the raw result' {
      $result.StartDate | Should Be 0
      $result.StopDate | Should Be 1
      $result.Consolidated | Should Be 1
      $result.DeltaSecond | Should Be 3660
    }
  }
}