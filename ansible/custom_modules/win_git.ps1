#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module Ansible.ModuleUtils.CommandUtil

$spec = @{
    options = @{
        repo = @{ type = "str"; required = $true }
        dest = @{ type = "str"; required = $true }
    }
    mutually_exclusive = @(
    )
    required_one_of = @( )
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$repo = $module.Params.repo
$dest = $module.Params.dest
$module.Result.repo = $repo
$module.Result.dest = $dest

# Return the found Git.exe path or $nil
function Get-GitPath {
    $command = (Get-Command "git.exe" -ErrorAction SilentlyContinue)
    if (!$command) {
        return $nil
    }

    $command.source
}

# Clone Git repo, or perform a Git fetch if it already exists
function Clone-GitRepo([string]$gitPath, [string]$repo, [string]$dest) {
    $res = Run-Command -Command "`"$gitPath`" clone `"$repo`" `"$dest`""
    $module.Result.rc = $res.rc
    $module.Result.git_output = $res
    # There is only output if a change has occurred
    if ($res.stderr -or $res.stdout) {
        $module.Result.changed = $true
    }
}

# Fetch the git repo, only performed if the repo has already been cloned
function Fetch-GitRepo([string]$gitPath, [string]$repo, [string]$dest) {
    git.exe -C "$dest" fetch --all

    $res = Run-Command -Command "`"$gitPath`" -C `"$dest`" fetch --all"
    $module.Result.rc = $res.rc
    $module.Result.git_output = $res
    # Console output suggests a change
    $module.Result.changed = -Not [String]::IsNullOrEmpty($res.stdout)
}

$module.Result.values = @{}
$gitPath = Get-GitPath
if (!$gitPath) {
    $module.FailJson("Could not find git.exe")
}

$has_existing_git_clone = Test-Path -PathType Container -Path $dest
if ($has_existing_git_clone) {
    Fetch-GitRepo -gitPath $gitPath -repo $repo -dest $dest
} else {
    Clone-GitRepo -gitPath $gitPath -repo $repo -dest $dest
}

$module.ExitJson()
