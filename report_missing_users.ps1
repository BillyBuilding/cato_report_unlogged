[Console]::OutputEncoding = [Text.Encoding]::UTF8

$catoApiUrl = "https://api.catonetworks.com/api/v1/graphql2"

# --- CONFIGURATION ---
# PLEASE REPLACE THESE VALUES WITH YOUR OWN
$apiKey = "YOUR_API_KEY_HERE" 
$accountID = 12345 # REPLACE WITH YOUR ACCOUNT ID
# ---------------------

$headers = @{
  "x-api-key"    = $apiKey
  "Content-Type" = "application/json"
}

function Invoke-GraphQL($query) {
  $payload = @{ query = $query } | ConvertTo-Json
  return Invoke-RestMethod -Uri $catoApiUrl -Method Post -Body $payload -Headers $headers
}

# 1) Initial GraphQL request to get a list of user IDs
$initialQuery = @"
{
  entityLookup(
    accountID: $accountID,
    type: vpnUser,
    limit: 1000,
    from: 0
  ) {
    items {
      entity {
        id
      }
    }
  }
}
"@

try {
  $initResp = Invoke-GraphQL $initialQuery
  if ($initResp.errors) {
    $initResp.errors | ConvertTo-Json -Depth 5 | Write-Output
    return
  }
}
catch {
  Write-Output "Initial request error: $($_.Exception.Message)"
  return
}

$userIDs = $initResp.data.entityLookup.items | ForEach-Object { $_.entity.id }
if (-not $userIDs) {
  Write-Output "No users found."
  return
}
# Build a comma-separated list of numeric IDs (no quotes)
$idList = $userIDs -join ", "

# 2) Batch follow-up query with full field set
$followUpQuery = @"
{
  accountSnapshot(accountID: $accountID) {
    id
    timestamp
    users(userIDs: [$idList]) {
      id
      name
      deviceName
      lastConnected
      info {
        email
      }
      recentConnections {
        duration
        interfaceName
        deviceName
        lastConnected
        popName
        remoteIP
        remoteIPInfo {
          ip
          countryCode
          countryName
          city
          state
          provider
          latitude
          longitude
        }
      }
    }
  }
}
"@

try {
  $snapResp = Invoke-GraphQL $followUpQuery
  if ($snapResp.errors) {
    $snapResp.errors | ConvertTo-Json -Depth 5 | Write-Output
    return
  }
}
catch {
  Write-Output "Follow-up request error: $($_.Exception.Message)"
  return
}

# Calculate cutoff time (1 month earlier than snapshot)
$snapshotTime = [datetime]::Parse($snapResp.data.accountSnapshot.timestamp)
$cutoff = $snapshotTime.AddMonths(-1)

# 3) Collect users not connected for more than one month
$NonCompliantUsers = foreach ($user in $snapResp.data.accountSnapshot.users) {
  if ($user.lastConnected) {
    $lastConnected = [datetime]::Parse($user.lastConnected)
    if ($lastConnected -lt $cutoff) {
      # Retrieve country from first recent connection if available
      $lastCountry = if ($user.recentConnections -and $user.recentConnections.Count -gt 0) {
        $user.recentConnections[0].remoteIPInfo.countryName
      }
      else { $null }
      [pscustomobject]@{
        UserID        = $user.id
        Name          = $user.name
        Device        = $user.deviceName
        LastConnected = $user.lastConnected
        LastCountry   = $lastCountry
        Email         = $user.info.email
      }
    }
  }
}

$NonCompliantUsers | ConvertTo-Json -Depth 10
