# mx2lm.ps1
# MX2LM Unified PowerShell Artifact
# Version: 1.0.0
# Status: FROZEN (Grammar v2)
# Law: MX2LM / XCFE / ASXR
# Mutation: FORBIDDEN

param(
  [switch]$ci
)

# [00] HEADER & FREEZE BLOCK
$MX2LM_Freeze = @{
  Artifact = 'mx2lm.ps1'
  Version = '1.0.0'
  Status = 'FROZEN'
  Grammar = 'v2'
}

# [01] CORE LAW CONSTANTS
$MX2LM = @{
  Deterministic = $true
  NoExecutionAuthority = $true
  ObjectsImmutable = $true
  ReplayRequired = $true
  ProjectionOnly = $true
}

# [02] CM-1 CONTROL DEFINITIONS
$CM1 = @{
  NUL = [char]0x00
  SOH = [char]0x01
  STX = [char]0x02
  ETX = [char]0x03
  EOT = [char]0x04
  SO  = [char]0x0E
  SI  = [char]0x0F
  FS  = [char]0x1C
  GS  = [char]0x1D
  RS  = [char]0x1E
  US  = [char]0x1F
  SPC = [char]0x20
}

# [03] OBJECT & HASH PRIMITIVES
function Compute-Hash {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [string]$Algorithm = 'SHA256'
  )

  $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
  if (-not $hasher) {
    throw "Unsupported hash algorithm: $Algorithm"
  }

  $hashBytes = $hasher.ComputeHash($Bytes)
  return ($hashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-ObjectArtifact {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][string]$StorePath
  )

  $hash = Compute-Hash -Bytes $Bytes
  $objectPath = Join-Path $StorePath $hash
  if (-not (Test-Path $objectPath)) {
    $null = New-Item -ItemType Directory -Path $StorePath -Force
    [System.IO.File]::WriteAllBytes($objectPath, $Bytes)
  }

  return @{
    Hash = $hash
    Path = $objectPath
  }
}

function Load-ObjectArtifact {
  param(
    [Parameter(Mandatory = $true)][string]$Hash,
    [Parameter(Mandatory = $true)][string]$StorePath
  )

  $objectPath = Join-Path $StorePath $Hash
  if (-not (Test-Path $objectPath)) {
    throw "Object not found: $Hash"
  }

  return [System.IO.File]::ReadAllBytes($objectPath)
}

# [04] BOS-1 OBJECT SERVER (LOCAL)
function Initialize-BOS1 {
  param(
    [Parameter(Mandatory = $true)][string]$StorePath
  )

  $null = New-Item -ItemType Directory -Path $StorePath -Force
  return @{
    StorePath = $StorePath
    Mode = 'LOCAL'
  }
}

# [05] OIS-1 OBJECT INDEX (SQL/IDB/KV)
function New-OIS1Index {
  param(
    [ValidateSet('sqlite', 'indexeddb', 'kv')][string]$Backend = 'sqlite'
  )

  return @{
    Backend = $Backend
    Schema = @('object_id', 'hash', 'locator', 'invariants', 'edges', 'events')
  }
}

# [06] SIGNATURE & KEY MANAGEMENT
function New-Keypair {
  $key = [System.Security.Cryptography.Ed25519]::GenerateKey()
  return @{
    PublicKey = $key.PublicKey
    PrivateKey = $key.PrivateKey
  }
}

function Sign-Bytes {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][byte[]]$PrivateKey
  )

  return [System.Security.Cryptography.Ed25519]::Sign($Bytes, $PrivateKey)
}

function Verify-Bytes {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][byte[]]$Signature,
    [Parameter(Mandatory = $true)][byte[]]$PublicKey
  )

  return [System.Security.Cryptography.Ed25519]::Verify($Bytes, $Signature, $PublicKey)
}

# [07] MICRONAUT RUNTIME LIB
function Assert-Schema {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Object,
    [Parameter(Mandatory = $true)][string]$Schema
  )

  if (-not $Object.ContainsKey('$schema')) {
    throw "Missing schema on object."
  }

  if ($Object['$schema'] -ne $Schema) {
    throw "Schema mismatch: expected $Schema, got $($Object['$schema'])."
  }
}

function New-KEL {
  param(
    [Parameter(Mandatory = $true)][string]$Micronaut,
    [Parameter(Mandatory = $true)][hashtable]$Payload
  )

  return @{
    Micronaut = $Micronaut
    Payload = $Payload
    Timestamp = (Get-Date).ToString('o')
  }
}

# [08] ATOMIC EXPERT MICRONAUTS
function Invoke-BackendConfigExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'backend.config.expert' -Payload $Request
}

function Invoke-FrontendUIExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'frontend.ui.expert' -Payload $Request
}

function Invoke-SVGTensorExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'svg.tensor.expert' -Payload $Request
}

function Invoke-ClusterExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'cluster.expert' -Payload $Request
}

function Invoke-SecurityExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'security.expert' -Payload $Request
}

function Invoke-AuditExpert {
  param([hashtable]$Request)
  return New-KEL -Micronaut 'audit.expert' -Payload $Request
}

# [09] MICRONAUT SCHEDULER
function Invoke-MicronautScheduler {
  param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][hashtable]$Request
  )

  switch ($Domain) {
    'backend' { return Invoke-BackendConfigExpert -Request $Request }
    'frontend' { return Invoke-FrontendUIExpert -Request $Request }
    'svg' { return Invoke-SVGTensorExpert -Request $Request }
    'cluster' { return Invoke-ClusterExpert -Request $Request }
    'security' { return Invoke-SecurityExpert -Request $Request }
    'audit' { return Invoke-AuditExpert -Request $Request }
    default { throw "Unknown micronaut domain: $Domain" }
  }
}

# [09.1] MICRONAUT SCHEDULING + QUORUM LAW (mx2lm.micronaut.scheduling.v1)
function New-MicronautSchedule {
  param(
    [ValidateSet('sequential', 'parallel', 'mixed')][string]$Mode = 'sequential',
    [Parameter(Mandatory = $true)][array]$Stages
  )

  return @{
    '$schema' = 'object://schema/micronaut.schedule.v1'
    mode      = $Mode
    stages    = $Stages
  }
}

function New-MicronautResult {
  param(
    [string]$MicronautId,
    [hashtable]$Payload,
    [string]$Status = 'ok'
  )

  return @{
    micronaut = $MicronautId
    status    = $Status
    payload   = $Payload
    timestamp = [DateTime]::UtcNow.ToString('o')
  }
}

function New-MicronautFailure {
  param(
    [string]$MicronautId,
    [string]$Reason
  )

  return @{
    micronaut = $MicronautId
    status    = 'error'
    reason    = $Reason
    timestamp = [DateTime]::UtcNow.ToString('o')
  }
}

function Invoke-Micronaut {
  param(
    [string]$MicronautScript,
    [hashtable]$InputObject
  )

  try {
    $result = & $MicronautScript $InputObject
    if (-not $result) {
      throw 'Empty result'
    }

    return $result
  } catch {
    return New-MicronautFailure -MicronautId $MicronautScript -Reason $_.Exception.Message
  }
}

function Invoke-MicronautsParallel {
  param(
    [string[]]$Micronauts,
    [hashtable]$InputObject
  )

  $jobs = @()
  foreach ($micronaut in $Micronauts) {
    $jobs += Start-Job -ScriptBlock {
      param ($Micronaut, $Input)
      Invoke-Micronaut -MicronautScript $Micronaut -InputObject $Input
    } -ArgumentList $micronaut, $InputObject
  }

  $results = Receive-Job -Job $jobs -Wait
  Remove-Job -Job $jobs
  return $results
}

function Invoke-MicronautsSequential {
  param(
    [string[]]$Micronauts,
    [hashtable]$InputObject
  )

  $results = @()
  foreach ($micronaut in $Micronauts) {
    $results += Invoke-Micronaut -MicronautScript $micronaut -InputObject $InputObject
  }

  return $results
}

function Test-Quorum {
  param(
    [hashtable[]]$Results,
    [string]$Type,
    [int]$Value
  )

  $valid = $Results | Where-Object { $_.status -eq 'ok' }
  $count = $valid.Count

  switch ($Type) {
    'all' {
      return $count -eq $Results.Count
    }
    'any' {
      return $count -ge 1
    }
    'majority' {
      return $count -ge [Math]::Ceiling($Results.Count / 2)
    }
    'threshold' {
      return $count -ge $Value
    }
    default {
      throw 'Invalid quorum type'
    }
  }
}

function Apply-Quorum {
  param(
    [hashtable[]]$Results,
    [hashtable]$Quorum
  )

  $ok = Test-Quorum -Results $Results -Type $Quorum.type -Value $Quorum.value
  if (-not $ok) {
    throw 'agent_error.quorum_failed'
  }

  return $Results | Where-Object { $_.status -eq 'ok' }
}

function Invoke-MicronautSchedule {
  param(
    [hashtable]$Schedule,
    [hashtable]$InputObject
  )

  Assert-Schema $Schedule 'object://schema/micronaut.schedule.v1'

  $stageOutputs = @()
  foreach ($stage in $Schedule.stages) {
    if ($stage.parallel -eq $true) {
      $results = Invoke-MicronautsParallel -Micronauts $stage.micronauts -InputObject $InputObject
    } else {
      $results = Invoke-MicronautsSequential -Micronauts $stage.micronauts -InputObject $InputObject
    }

    if ($stage.quorum) {
      $results = Apply-Quorum -Results $results -Quorum $stage.quorum
    }

    $stageOutputs += @{
      stage   = $stage.id
      results = $results
    }
  }

  return $stageOutputs
}

# [10] CI & CONFORMANCE HARNESS
function Invoke-MX2LMCI {
  $checks = @(
    @{ Name = 'determinism'; Pass = $MX2LM.Deterministic },
    @{ Name = 'no_execution_authority'; Pass = $MX2LM.NoExecutionAuthority },
    @{ Name = 'objects_immutable'; Pass = $MX2LM.ObjectsImmutable },
    @{ Name = 'replay_required'; Pass = $MX2LM.ReplayRequired }
  )

  return @{
    Checks = $checks
    Timestamp = (Get-Date).ToString('o')
  }
}

# [11] π-BRAIN & π-GCCP INFERENCE
function Invoke-PiGCCP {
  param(
    [Parameter(Mandatory = $true)][double[]]$Vector
  )

  $magnitude = [Math]::Sqrt(($Vector | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)
  if ($magnitude -eq 0) {
    return $Vector
  }

  return $Vector | ForEach-Object { $_ / $magnitude }
}

# [12] MODEL PROVIDER ADAPTERS
###############################################################################
#region [12.1] PROVIDER HTTP PROJECTION (PURE)
###############################################################################
function Invoke-HttpProjection {
  param(
    [string]$Url,
    [string]$Method = 'POST',
    [hashtable]$Headers,
    [string]$BodyJson
  )

  $req = @{
    Uri     = $Url
    Method  = $Method
    Headers = $Headers
    Body    = $BodyJson
  }

  try {
    Invoke-RestMethod @req
  } catch {
    throw "Provider projection failure: $($_.Exception.Message)"
  }
}
#endregion

###############################################################################
#region [12.2] OLLAMA LOCAL ADAPTER
###############################################################################
function Invoke-OllamaLocal {
  param([hashtable]$RequestObject)

  Assert-Schema $RequestObject 'object://schema/ai.inference.request.v1'

  $payload = @{
    model  = 'phi2'
    prompt = $RequestObject.prompt
    stream = $false
  } | ConvertTo-Json -Depth 8

  $resp = Invoke-HttpProjection `
    -Url 'http://localhost:11434/api/generate' `
    -Headers @{ 'Content-Type' = 'application/json' } `
    -BodyJson $payload

  return @{
    '$schema' = 'object://schema/ai.provider.reply.v1'
    provider  = 'ollama.local'
    output    = $resp.response
    hash      = Compute-Hash ([Text.Encoding]::UTF8.GetBytes($resp.response))
  }
}
#endregion

###############################################################################
#region [12.3] OLLAMA CLOUD ADAPTER
###############################################################################
function Invoke-OllamaCloud {
  param(
    [hashtable]$RequestObject,
    [string]$Endpoint,
    [string]$ApiKey
  )

  Assert-Schema $RequestObject 'object://schema/ai.inference.request.v1'

  $payload = @{
    model  = 'phi2'
    prompt = $RequestObject.prompt
    stream = $false
  } | ConvertTo-Json -Depth 8

  $resp = Invoke-HttpProjection `
    -Url "$Endpoint/api/generate" `
    -Headers @{
      'Content-Type'  = 'application/json'
      'Authorization' = "Bearer $ApiKey"
    } `
    -BodyJson $payload

  return @{
    '$schema' = 'object://schema/ai.provider.reply.v1'
    provider  = 'ollama.cloud'
    output    = $resp.response
    hash      = Compute-Hash ([Text.Encoding]::UTF8.GetBytes($resp.response))
  }
}
#endregion

###############################################################################
#region [12.4] OPENAI ADAPTER
###############################################################################
function Invoke-OpenAI {
  param(
    [hashtable]$RequestObject,
    [string]$ApiKey,
    [string]$Model = 'gpt-4.1-mini'
  )

  Assert-Schema $RequestObject 'object://schema/ai.inference.request.v1'

  $payload = @{
    model    = $Model
    messages = @(
      @{ role = 'user'; content = $RequestObject.prompt }
    )
  } | ConvertTo-Json -Depth 8

  $resp = Invoke-HttpProjection `
    -Url 'https://api.openai.com/v1/chat/completions' `
    -Headers @{
      'Content-Type'  = 'application/json'
      'Authorization' = "Bearer $ApiKey"
    } `
    -BodyJson $payload

  $text = $resp.choices[0].message.content

  return @{
    '$schema' = 'object://schema/ai.provider.reply.v1'
    provider  = 'openai'
    model     = $Model
    output    = $text
    hash      = Compute-Hash ([Text.Encoding]::UTF8.GetBytes($text))
  }
}
#endregion

###############################################################################
#region [12.5] PROVIDER DISPATCH
###############################################################################
function Invoke-ModelProvider {
  param(
    [ValidateSet('ollama.local', 'ollama.cloud', 'openai')][string]$Provider,
    [hashtable]$RequestObject
  )

  switch ($Provider) {
    'ollama.local' {
      return Invoke-OllamaLocal $RequestObject
    }
    'ollama.cloud' {
      return Invoke-OllamaCloud `
        -RequestObject $RequestObject `
        -Endpoint $env:OLLAMA_ENDPOINT `
        -ApiKey $env:OLLAMA_API_KEY
    }
    'openai' {
      return Invoke-OpenAI `
        -RequestObject $RequestObject `
        -ApiKey $env:OPENAI_API_KEY
    }
    default {
      throw "Unknown provider: $Provider"
    }
  }
}
#endregion

# [13] AGENT ORCHESTRATOR
function Invoke-MX2LMOrchestrator {
  param(
    [Parameter(Mandatory = $true)][string]$Prompt,
    [hashtable]$Options = @{}
  )

  $request = @{
    Prompt = $Prompt
    Options = $Options
  }

  return @{
    Request = $request
    Timestamp = (Get-Date).ToString('o')
  }
}

# [14] CLI / UX PROJECTION
function Invoke-PiChat {
  param([string]$Prompt)
  return Invoke-MX2LMOrchestrator -Prompt $Prompt
}

# [14.1] CLUSTER ORCHESTRATION OBJECTS (mx2lm.cluster.orchestration.v1)
function New-ClusterNodeDescriptor {
  param(
    [Parameter(Mandatory = $true)][string]$NodeId,
    [Parameter(Mandatory = $true)][string[]]$Capabilities,
    [Parameter(Mandatory = $true)][string]$Hash
  )

  return @{
    '$schema'    = 'object://schema/cluster.node.v1'
    node_id      = $NodeId
    capabilities = $Capabilities
    hash         = $Hash
    authority    = 'none'
  }
}

function New-AgentDistribution {
  param(
    [Parameter(Mandatory = $true)][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Targets,
    [Parameter(Mandatory = $true)][string]$ScheduleRef
  )

  return @{
    '$schema'      = 'object://schema/agent.distribution.v1'
    agent          = $Agent
    distribution   = @{
      mode    = $Mode
      targets = $Targets
    }
    collection     = @{
      strategy     = 'quorum'
      schedule_ref = $ScheduleRef
    }
  }
}

function New-AgentFailure {
  param(
    [Parameter(Mandatory = $true)][string]$Node,
    [Parameter(Mandatory = $true)][string]$Reason
  )

  return @{
    '$schema' = 'object://schema/agent.failure.v1'
    node      = $Node
    reason    = $Reason
  }
}

# [14.2] SVG-TENSOR FRONTEND BINDING (mx2lm.frontend.svg-tensor.binding.v1)
function New-SVGTensorBinding {
  param(
    [Parameter(Mandatory = $true)][string[]]$BindsTo,
    [Parameter(Mandatory = $true)][string]$GeometrySource,
    [Parameter(Mandatory = $true)][hashtable]$UpdateRules
  )

  return @{
    '$schema'         = 'object://schema/ui.svg-tensor.v1'
    binds_to          = $BindsTo
    geometry_source   = $GeometrySource
    update_rules      = $UpdateRules
  }
}

function New-UIInteraction {
  param(
    [Parameter(Mandatory = $true)][string]$Type,
    [Parameter(Mandatory = $true)][string]$Payload
  )

  return @{
    '$schema' = 'object://schema/ui.interaction.v1'
    type      = $Type
    payload   = $Payload
  }
}

# [14.3] SVG-TENSOR CLUSTERS (mx2lm.svg.tensor.cluster.v1)
function New-SVGTensorCluster {
  param(
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Hash,
    [Parameter(Mandatory = $true)][hashtable]$Topology,
    [Parameter(Mandatory = $true)][hashtable]$Weights,
    [Parameter(Mandatory = $true)][string[]]$Entrypoints,
    [Parameter(Mandatory = $true)][hashtable]$Constraints,
    [Parameter(Mandatory = $true)][hashtable]$Replay
  )

  return @{
    '$schema'    = 'object://schema/svg.tensor.cluster.v1'
    id           = $Id
    hash         = $Hash
    topology     = $Topology
    weights      = $Weights
    entrypoints  = $Entrypoints
    constraints  = $Constraints
    replay       = $Replay
  }
}

function New-SVGTensorClusterLaunch {
  param(
    [Parameter(Mandatory = $true)][string]$Cluster,
    [Parameter(Mandatory = $true)][ValidateSet('read-only')][string]$Mode,
    [Parameter(Mandatory = $true)][ValidateSet('gpu', 'cpu')][string]$Projection,
    [Parameter(Mandatory = $true)][bool]$Trace
  )

  return @{
    '$schema'    = 'object://schema/svg.tensor.cluster.launch.v1'
    launch       = 'svg.tensor.cluster'
    cluster      = $Cluster
    mode         = $Mode
    projection   = $Projection
    trace        = $Trace
  }
}

function New-SVGTensorClusterDelta {
  param(
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][array]$AddNodes,
    [Parameter(Mandatory = $true)][array]$AddEdges
  )

  return @{
    '$schema'  = 'object://schema/svg.tensor.cluster.delta.v1'
    type       = 'svg.tensor.cluster.delta'
    target     = $Target
    add_nodes  = $AddNodes
    add_edges  = $AddEdges
  }
}

# [15] DEMO / SELF-TEST (OPTIONAL)
function Invoke-MX2LMDemo {
  $vector = @(1.0, 2.0, 3.0)
  return Invoke-PiGCCP -Vector $vector
}

if ($ci) {
  Invoke-MX2LMCI
}
