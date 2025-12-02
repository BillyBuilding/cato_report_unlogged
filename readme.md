# Cato Networks Inactive User Reporter

This PowerShell script queries the Cato Networks API to identify users who have not connected to the VPN for more than one month. It retrieves user details including their last connection time, device name, and the country of their last connection.

## Prerequisites

- **PowerShell 5.1** or later (PowerShell Core 7+ recommended).
- A **Cato Networks API Key**.
- Your **Cato Account ID**.

## Setup

1.  Clone this repository or download the script.
2.  Open `catoreporting.ps1` in a text editor.
3.  Update the configuration variables at the top of the script with your specific details:
    ```powershell
    $catoApiKey = "YOUR_API_KEY_HERE"
    $accountId  = 12345 # Replace with your Account ID
    ```
    *Alternatively, you can modify the script to accept these as parameters.*

## Usage

Run the script from a PowerShell terminal:

```powershell
.\catoreporting.ps1
```

## Output

The script outputs a JSON array containing the following details for each non-compliant (inactive) user:

- `UserID`
- `Name`
- `Device`
- `LastConnected` (Date and Time)
- `LastCountry`
- `Email`

## Disclaimer

This script is provided as-is. Please ensure you handle your API keys securely and do not share them publicly.
