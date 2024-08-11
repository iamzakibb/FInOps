# Import the Azure PowerShell module
Import-Module Az

# Login to Azure
Connect-AzAccount

# Define the resource group and subscription
$resourceGroupName = "YourResourceGroup"
$subscriptionId = "YourSubscriptionId"

# Set the subscription context
Set-AzContext -SubscriptionId $subscriptionId

# Function to monitor resource utilization
function Get-ResourceUtilization {
    param (
        [string]$resourceGroupName
    )

    # Get all virtual machines in the resource group
    $vms = Get-AzVM -ResourceGroupName $resourceGroupName

    foreach ($vm in $vms) {
        $metrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU", "Network In Total", "Network Out Total" -TimeGrain 00:01:00 -StartTime (Get-Date).AddMinutes(-60) -EndTime (Get-Date)
        
        $cpuUsage = $metrics | Where-Object { $_.Name.Value -eq "Percentage CPU" } | Select-Object -ExpandProperty Data
        $networkIn = $metrics | Where-Object { $_.Name.Value -eq "Network In Total" } | Select-Object -ExpandProperty Data
        $networkOut = $metrics | Where-Object { $_.Name.Value -eq "Network Out Total" } | Select-Object -ExpandProperty Data

        Write-Output "VM: $($vm.Name)"
        Write-Output "CPU Usage: $(($cpuUsage | Measure-Object -Property Average -Average).Average)%"
        Write-Output "Network In: $(($networkIn | Measure-Object -Property Total -Sum).Sum) bytes"
        Write-Output "Network Out: $(($networkOut | Measure-Object -Property Total -Sum).Sum) bytes"
        Write-Output ""
    }
}

# Function to get cost optimization recommendations
function Get-CostOptimizationRecommendations {
    param (
        [string]$resourceGroupName
    )

    # Get the cost analysis data
    $costDetails = Get-AzConsumptionUsageDetail -ResourceGroupName $resourceGroupName -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)

    # Identify idle resources
    $idleResources = @()
    foreach ($resource in $costDetails) {
        if ($resource.UsageQuantity -eq 0) {
            $idleResources += $resource.ResourceId
        }
    }

    Write-Output "Cost Optimization Recommendations:"
    if ($idleResources.Count -gt 0) {
        Write-Output "Idle Resources:"
        $idleResources | ForEach-Object { Write-Output $_ }
    } else {
        Write-Output "No idle resources detected."
    }
}

# Run the monitoring and cost optimization functions
Get-ResourceUtilization -resourceGroupName $resourceGroupName
Get-CostOptimizationRecommendations -resourceGroupName $resourceGroupName

# Logout from Azure
Disconnect-AzAccount
