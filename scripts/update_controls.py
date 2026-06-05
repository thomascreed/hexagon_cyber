import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTROLS_PATH = ROOT / "src" / "controls.json"


SERVICE_NAME_MAP = {
    "C-038": "AxInstSV",
    "C-039": "AJRouter",
    "C-040": "ALG",
    "C-041": "tzautoupdate",
    "C-042": "BDESVC",
    "C-043": "BthHFSrv",
    "C-044": "bthserv",
    "C-045": "CDPSvc",
    "C-046": "DiagTrack",
    "C-047": "DSSvc",
    "C-048": "DcpSvc",
    "C-049": "DoSvc",
    "C-050": "DsmSvc",
    "C-051": "dmwappushservice",
    "C-052": "MapsBroker",
    "C-053": "embeddedmode",
    "C-054": "EntAppSvc",
    "C-055": "Fax",
    "C-056": "fhsvc",
    "C-057": "lfsvc",
    "C-058": "HomeGroupListener",
    "C-059": "HomeGroupProvider",
    "C-060": "HvHost",
    "C-061": "vmickvpexchange",
    "C-062": "vmicguestinterface",
    "C-063": "vmicshutdown",
    "C-064": "vmicheartbeat",
    "C-065": "vmicvmsession",
    "C-066": "vmicrdv",
    "C-067": "vmictimesync",
    "C-068": "vmicvss",
    "C-069": "irmon",
    "C-070": "SharedAccess",
    "C-071": "KPSSVC",
    "C-072": "wlidsvc",
    "C-073": "AppVClient",
    "C-074": "diagnosticshub.standardcollector.service",
    "C-075": "MSiSCSI",
    "C-076": "smphost",
    "C-077": "SmsRouter",
    "C-078": "NcdAutoSetup",
    "C-079": "NcbService",
    "C-080": "CscService",
    "C-081": "PhoneSvc",
    "C-082": "PNRPAutoReg",
    "C-083": "QWAVE",
    "C-084": "RmSvc",
    "C-085": "RasMan",
    "C-086": "RemoteRegistry",
    "C-087": "RSoPProv",
    "C-088": "RetailDemo",
    "C-089": "SensorDataService",
    "C-090": "SensrSvc",
    "C-091": "SensorService",
    "C-092": "shpamsvc",
    "C-093": "SNMP",
    "C-094": "SQLTELEMETRY",
    "C-095": "WiaRpc",
    "C-096": "StorSvc",
    "C-097": "TieringEngineService",
    "C-098": "SysMain",
    "C-099": "SENS",
    "C-100": "lmhosts",
    "C-101": "TapiSrv",
    "C-102": "Themes",
    "C-103": "TabletInputService",
    "C-104": "UsoSvc",
    "C-105": "upnphost",
    "C-106": "UevAgentService",
    "C-107": "WalletService",
    "C-108": "WarpJITSvc",
    "C-109": "WbioSrvc",
    "C-110": "FrameServer",
    "C-111": "WcmSvc",
    "C-112": "WinDefend",
    "C-113": "WdNisSvc",
    "C-114": "WEPHOSTSVC",
    "C-115": "WerSvc",
    "C-116": "wisvc",
    "C-117": "wlpasvc",
    "C-118": "SmsRouter",
    "C-119": "WMPNetworkSvc",
    "C-120": "icssvc",
    "C-121": "PerceptionSimulation",
    "C-122": "WpnService",
    "C-123": "PushToInstall",
    "C-124": "WinRM",
    "C-125": "WSearch",
    "C-126": "XboxGipSvc",
    "C-127": "XblAuthManager",
    "C-128": "XblGameSave",
    "C-129": "XboxNetApiSvc",
    "C-133": "dot3svc",
    "C-148": "RemoteRegistry",
    "C-181": "Spooler",
}


BIOS_META = {
    "C-001": {
        "path": "Security or Passwords",
        "setting": "Administrator Password, Setup Password, or Supervisor Password",
        "expected": "Configured.",
        "command": "powershell -Command \"Confirm-SecureBootUEFI\"",
        "command_note": "This read-only command only helps confirm the device is using UEFI. It does not show the BIOS password, so the main verification must still be done in BIOS/UEFI.",
    },
    "C-002": {
        "path": "Boot or Startup",
        "setting": "Boot Order or Boot Priority",
        "expected": "The internal fixed disk is first, and external media or network boot is not placed ahead of it.",
        "command": "bcdedit /enum firmware",
        "command_note": "This may show firmware boot entries, but you still need to confirm the real boot order in BIOS/UEFI.",
    },
    "C-003": {
        "path": "Boot or Security",
        "setting": "USB Boot, Removable Media Boot, or External Device Boot",
        "expected": "Disabled unless there is an approved maintenance exception.",
        "command": "bcdedit /enum firmware",
        "command_note": "Look for OEM wording that refers to USB, DVD, SD card, or other removable media boot options.",
    },
    "C-004": {
        "path": "Boot, Network Stack, or Integrated NIC",
        "setting": "PXE Boot, Network Boot, UEFI Network Stack, or LAN PXE Option ROM",
        "expected": "Disabled unless formally approved for OT imaging, build, or recovery.",
        "command": "bcdedit /enum firmware",
        "command_note": "If PXE is only temporarily approved for deployment or recovery, record that approval instead of changing the setting.",
    },
}


PASSWORD_META = {
    "C-005": ("Minimum password length", "At least 8 characters for engineering, standard service, and operator accounts, and at least 14 characters for privileged and administrative service accounts."),
    "C-006": ("Maximum password age", "365 days for human user accounts. Service accounts may be non-expiring only when approved and documented."),
    "C-007": ("Minimum password age", "1 day."),
    "C-008": ("Password must meet complexity requirements", "Enabled."),
    "C-009": ("Enforce password history", "12 passwords remembered."),
    "C-010": ("Password expiry status", "Human user accounts must expire. Service accounts may be non-expiring only when documented and approved."),
    "C-011": ("MFA enforcement", "MFA is enforced where technically supported, especially for privileged, remote, vendor, and externally accessible access."),
}


LOCKOUT_META = {
    "C-012": ("Account lockout threshold", "5 invalid attempts for engineering, maintenance, and privileged users. 10 invalid attempts only for approved service or operator use cases."),
    "C-013": ("Reset account lockout counter after", "30 minutes for engineering, privileged, and service accounts, and 15 minutes for operator accounts."),
    "C-014": ("Account lockout duration", "30 minutes unless an approved operational exception exists."),
    "C-186": ("Reset account lockout counter after", "Minimum 30 minutes unless the approved baseline documents a stricter value."),
}


AUDIT_META = {
    "C-015": ("Audit Account Logon Events", "Credential Validation", "Success and Failure."),
    "C-016": ("Audit Account Management", "Account Management", "Success and Failure."),
    "C-017": ("Audit Object Access", "Object Access", "Failure."),
    "C-018": ("Audit System Event", "System", "Success and Failure."),
    "C-019": ("Audit Directory Services Access", "Directory Service Access", "Failure."),
    "C-020": ("Audit Process Tracking", "Detailed Tracking / Process Creation", "No Auditing unless an approved exception exists."),
    "C-021": ("Audit Policy Change", "Policy Change", "Success and Failure."),
    "C-022": ("Audit Logon Event", "Logon/Logoff", "Success and Failure."),
    "C-023": ("Audit Privilege Use", "Privilege Use", "Success and Failure."),
    "C-024": ("Management of Audit Logs Storage", "Security, System, and Application log properties", "Security minimum 199,680 KB, System minimum 99,840 KB, Application minimum 99,840 KB, with overwrite if necessary unless the approved standard says otherwise."),
    "C-178": ("Configure Windows Event Log Retention Policy", "Event log retention", "Configured according to operational standards, typically an overwrite policy approved by IT/Cybersecurity."),
    "C-192": ("Detailed File System and Registry Tracking", "Advanced Audit Policy Configuration > Object Access", "The required file system and registry advanced audit settings are enabled according to the approved baseline."),
}


ACCESS_META = {
    "C-025": "No shared or generic accounts are present unless there is a formally approved exception.",
    "C-026": "No test, demo, temp, or unused accounts remain active unless formally approved.",
    "C-027": "Access permissions match approved job roles, such as operator read-only, engineer configuration access, and admin full control.",
    "C-028": "Only approved accounts are members of the local Administrators group, and each one has justification.",
    "C-029": "Default accounts such as Administrator and Guest are disabled, renamed, or assigned with documented ownership according to baseline.",
    "C-030": "Recently created accounts match the approved CIP master list or approved request records.",
    "C-031": "Accounts removed from the CIP master list are revoked, disabled, or no longer present.",
    "C-032": "Accounts that should require passwords show Password required: Yes.",
    "C-033": "Any custom groups have business justification, approved membership, and no unnecessary privilege overlap.",
    "C-034": "Service accounts are denied local logon and Remote Desktop logon unless there is an approved exception.",
    "C-035": "MFA is active wherever technically supported, especially for VPN, remote access, privileged accounts, vendors, and external access paths.",
    "C-036": "Critical tasks are separated so the same person does not both request and approve high-impact access changes.",
    "C-037": "Session timeout or lock behavior is set to 15 minutes according to baseline.",
    "C-187": "The built-in Administrator account has been renamed according to the approved standard.",
    "C-188": "The Guest account is disabled and renamed if the baseline requires rename protection.",
}


REGISTRY_META = {
    "C-130": {
        "gui": [
            "Press Windows + R.",
            "Type wf.msc and press Enter.",
            "In Windows Defender Firewall with Advanced Security, select Inbound Rules.",
            "Review rules related to HTTP, HTTPS, web dashboards, or TCP ports 80 and 443.",
            "Open Windows Defender Firewall Properties and review the active firewall profile.",
            "Confirm non-essential inbound web traffic is blocked unless the device is approved to host a web service.",
        ],
        "cmd": [
            "powershell -Command \"Get-NetFirewallProfile | Select Name,Enabled,DefaultInboundAction,DefaultOutboundAction\"",
            "powershell -Command \"Get-NetFirewallRule | Where-Object {$_.DisplayName -match 'HTTP|HTTPS|Web|80|443'} | Select DisplayName,Enabled,Direction,Action\"",
        ],
        "expected": "Inbound HTTP/HTTPS traffic that is not required by the approved baseline is blocked or not allowed by firewall rules.",
    },
    "C-131": {
        "gui_path": "Turn Windows features on or off > SMB 1.0/CIFS File Sharing Support",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters',
        "reg_value": "SMB1",
        "expected": "0, or the value is absent because SMBv1 is disabled.",
    },
    "C-132": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Network access: Restrict anonymous access to Named Pipes and Shares",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters',
        "reg_value": "RestrictNullSessAccess",
        "expected": "1.",
    },
    "C-133": {
        "service": "Wired AutoConfig",
        "service_name": "dot3svc",
        "expected": "Disabled unless the approved baseline specifically requires it.",
    },
    "C-134": {
        "gui_path": "Local Group Policy Editor > Computer Configuration > Administrative Templates > Network > DNS Client > Turn off multicast name resolution",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient',
        "reg_value": "EnableMulticast",
        "expected": "0, or the equivalent policy is enabled to turn off LLMNR.",
    },
    "C-135": {
        "gui": [
            "Press Windows + R.",
            "Type timedate.cpl and press Enter.",
            "Review the date, time, and time zone.",
            "If available, review the synchronization source or ask the system owner whether the PC should follow the domain hierarchy or a plant NTP source.",
        ],
        "cmd": [
            "w32tm /query /status",
            "w32tm /query /configuration",
        ],
        "expected": "The device shows a valid approved time source and is synchronized with the expected domain or plant NTP source.",
    },
    "C-136": {
        "gui_path": "System Properties > Remote or Local Group Policy > Remote Assistance",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance',
        "reg_value": "fAllowToGetHelp",
        "expected": "0.",
    },
    "C-137": {
        "gui_path": "Local Group Policy Editor > Computer Configuration > Administrative Templates > Windows Components > AutoPlay Policies",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        "reg_value": "NoDriveTypeAutoRun",
        "expected": "255 (0xFF) or the equivalent value used by the approved baseline to disable AutoRun on all drives.",
    },
    "C-138": {
        "gui": [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Local Policies > Security Options.",
            "Find the policy related to device driver installation behavior or your approved driver signing baseline.",
            "Read the configured option and confirm it blocks or prevents unsigned drivers according to the standard.",
        ],
        "cmd": [
            "reg query \"HKLM\\SOFTWARE\\Microsoft\\Driver Signing\"",
            "driverquery /v",
        ],
        "expected": "Unsigned driver installation is blocked or restricted according to the approved baseline.",
    },
    "C-139": {
        "gui_path": "Windows Defender Firewall with Advanced Security > right-click active profile > Properties > Logging > Customize",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\Logging',
        "reg_value": "LogDroppedPackets",
        "expected": "Firewall logging is enabled for the approved profile, dropped packets are logged, and the configured log file path and size match the baseline.",
    },
    "C-140": {
        "gui_path": "Registry-based or GPO-managed control; no normal end-user GUI is usually available",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings',
        "reg_value": "Enabled",
        "expected": "0.",
    },
    "C-141": {
        "gui": [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter.",
            "Go to Computer Configuration > Administrative Templates > Windows Components > Windows PowerShell.",
            "Review any policy that limits interactive PowerShell use, such as approved shell access restrictions, execution control, or AppLocker/WDAC enforcement.",
            "If the PC is domain-managed, compare what you see with the approved domain baseline.",
        ],
        "cmd": [
            "powershell -Command \"Get-ExecutionPolicy -List\"",
            "powershell -Command \"Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue\"",
        ],
        "expected": "Interactive PowerShell access is restricted to the approved user population according to policy.",
    },
    "C-142": {
        "gui": [
            "Press Windows + R.",
            "Type ncpa.cpl and press Enter.",
            "Right-click the active network adapter and select Properties.",
            "Review the list of items used by the connection, such as Internet Protocol Version 6 (TCP/IPv6).",
            "Read the checked or unchecked state only. Do not change bindings yourself.",
        ],
        "cmd": [
            "powershell -Command \"Get-NetAdapterBinding -Name * | Where-Object {$_.DisplayName -match 'IPv6|Link'} | Select Name,DisplayName,Enabled\"",
            "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters\"",
        ],
        "expected": "Only the approved network protocols are enabled. IPv6 or link-local options are disabled only where the approved baseline specifically requires that.",
    },
    "C-143": {
        "gui_path": "msinfo32 or BIOS/UEFI firmware screen for Secure Boot",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State',
        "reg_value": "UEFISecureBootEnabled",
        "expected": "1, and Secure Boot State shows On.",
    },
    "C-144": {
        "gui_path": "Control Panel > Power Options > Choose what the power buttons do > Turn on fast startup",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power',
        "reg_value": "HiberbootEnabled",
        "expected": "0.",
    },
    "C-145": {
        "gui_path": "Windows Security > Device Security may show related protection, but registry is the primary check",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
        "reg_value": "RunAsPPL",
        "expected": "1.",
    },
    "C-146": {
        "gui_path": "Local Group Policy Editor > User Configuration > Administrative Templates > System > Prevent access to the command prompt",
        "reg_path": r'HKCU\Software\Policies\Microsoft\Windows\System',
        "reg_value": "DisableCMD",
        "expected": "1 or 2, based on the approved non-admin restriction policy.",
    },
    "C-147": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Interactive logon message settings",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_values": ["legalnoticecaption", "legalnoticetext"],
        "expected": "Both values are populated with the approved warning banner text.",
    },
    "C-149": {
        "gui": [
            "Press Windows + R.",
            "Type windowsdefender: and press Enter if Windows Security is available.",
            "Open App & browser control and review managed protection settings if your environment exposes them there.",
            "If the device is centrally managed, compare the ASR policy shown in your security tooling or policy report with the approved baseline.",
        ],
        "cmd": [
            "powershell -Command \"Get-MpPreference | Select-Object AttackSurfaceReductionRules_Ids,AttackSurfaceReductionRules_Actions\"",
        ],
        "expected": "The approved Attack Surface Reduction rules are present and enabled in the required mode, usually Block unless the approved standard says otherwise.",
    },
    "C-150": {
        "gui": [
            "Press Windows + R.",
            "Type secpol.msc or gpedit.msc and press Enter, depending on how the policy is managed in your environment.",
            "Navigate to the application control or code integrity area used by your organization.",
            "Review the effective WDAC or application control policy details if available.",
        ],
        "cmd": [
            "powershell -Command \"Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue\"",
            "wevtutil qe Microsoft-Windows-CodeIntegrity/Operational /c:20 /f:text",
        ],
        "expected": "WDAC or the equivalent application control policy is enforced and only approved binaries are allowed.",
    },
    "C-151": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Machine account lockout threshold",
        "reg_path": None,
        "reg_value": None,
        "expected": "5 invalid attempts.",
        "cmd_override": [
            "secedit /export /cfg %TEMP%\\secpol.cfg & findstr /i \"MachineAccountLockoutThreshold\" %TEMP%\\secpol.cfg",
        ],
    },
    "C-152": {
        "gui_path": "Local Group Policy Editor > Computer Configuration > Administrative Templates > Network > Lanman Workstation > Enable insecure guest logons",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters',
        "reg_value": "AllowInsecureGuestAuth",
        "expected": "0.",
    },
    "C-153": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Network security: LAN Manager authentication level",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
        "reg_value": "LmCompatibilityLevel",
        "expected": "5.",
    },
    "C-154": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Network security NTLM settings",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0',
        "reg_value": "NTLM restriction values",
        "expected": "NTLMv1 is not allowed. The system requires NTLMv2 or Kerberos according to the approved baseline.",
        "cmd_override": [
            "secedit /export /cfg %TEMP%\\secpol.cfg & findstr /i \"RestrictNTLM\" %TEMP%\\secpol.cfg",
            "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Lsa\\MSV1_0\"",
        ],
    },
    "C-155": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Microsoft network server: Digitally sign communications (always)",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters',
        "reg_value": "RequireSecuritySignature",
        "expected": "1.",
    },
    "C-156": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Microsoft network client: Digitally sign communications (always)",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters',
        "reg_value": "RequireSecuritySignature",
        "expected": "1.",
    },
    "C-157": {
        "gui": [
            "Open the normal server management view used in your environment if one is provided.",
            "If no GUI is provided for this host, use the read-only PowerShell command below.",
            "Review whether unencrypted SMB access is rejected according to the approved baseline.",
        ],
        "cmd": [
            "powershell -Command \"Get-SmbServerConfiguration | Select EncryptData,RejectUnencryptedAccess,EnableSMB1Protocol,RequireSecuritySignature\"",
        ],
        "expected": "Unencrypted SMB access is rejected according to the approved baseline.",
    },
    "C-158": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > UAC admin prompt behavior",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_values": ["ConsentPromptBehaviorAdmin", "PromptOnSecureDesktop"],
        "expected": "The system prompts for credentials on the secure desktop according to the approved baseline.",
    },
    "C-159": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > UAC standard user prompt behavior",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_value": "ConsentPromptBehaviorUser",
        "expected": "1.",
    },
    "C-160": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > UAC virtualization policy",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_value": "EnableVirtualization",
        "expected": "0.",
    },
    "C-161": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Interactive logon: Do not require CTRL+ALT+DEL",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon',
        "reg_value": "DisableCAD",
        "expected": "0.",
    },
    "C-162": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Interactive logon: Do not display last user name",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_value": "DontDisplayLastUserName",
        "expected": "1.",
    },
    "C-163": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Interactive logon: Display user information when the session is locked",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_value": "DontDisplayLockedUserId",
        "expected": "3.",
    },
    "C-164": {
        "gui_path": "Registry-based or GPO-managed control for LocalAccountTokenFilterPolicy",
        "reg_path": r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        "reg_value": "LocalAccountTokenFilterPolicy",
        "expected": "0.",
    },
    "C-165": {
        "gui": [
            "Press Windows + R.",
            "Open Settings > System > Remote Desktop.",
            "Review whether Remote Desktop shows Enabled or Disabled.",
            "Then press Windows + R, type gpedit.msc, and press Enter.",
            "Go to Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Connections.",
            "Review the policy that allows users to connect remotely using Remote Desktop Services.",
        ],
        "cmd": [
            "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\" /v fDenyTSConnections",
        ],
        "expected": "1 unless there is an approved exception for secure jump host use.",
    },
    "C-166": {
        "gui": [
            "Press Windows + R.",
            "Open Settings > System > Remote Desktop.",
            "Select Advanced settings if available and review whether Network Level Authentication is required.",
            "Then press Windows + R, type gpedit.msc, and press Enter.",
            "Go to Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Security.",
            "Open Require user authentication for remote connections by using Network Level Authentication.",
        ],
        "cmd": [
            "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp\" /v UserAuthentication",
        ],
        "expected": "1.",
    },
    "C-167": {
        "gui": [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter.",
            "Go to Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Security.",
            "Open Set client connection encryption level.",
            "Read the configured value.",
        ],
        "cmd": [
            "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp\" /v MinEncryptionLevel",
        ],
        "expected": "3 or 4, depending on whether the approved baseline requires High or FIPS-compliant encryption.",
    },
    "C-168": {
        "gui": [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter.",
            "Go to Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Session Time Limits.",
            "Open the idle session time limit policy.",
            "Read the configured value.",
        ],
        "cmd": [
            "reg query \"HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services\" /v MaxIdleTime",
        ],
        "expected": "15 minutes and the session is terminated according to policy.",
    },
    "C-169": {
        "gui": [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter.",
            "Go to Computer Configuration > Administrative Templates > System > Removable Storage Access.",
            "Open the policies that deny read, write, or all access to removable storage.",
            "Read the configured state only.",
        ],
        "cmd": [
            "reg query \"HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\RemovableStorageDevices\" /s",
        ],
        "expected": "All removable storage is blocked unless there is an approved exception.",
    },
    "C-170": {
        "gui": [
            "Press Windows + R.",
            "Type optionalfeatures and press Enter.",
            "In Windows Features, review Windows PowerShell 2.0.",
            "Confirm it is not enabled.",
        ],
        "cmd": [
            "powershell -Command \"Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2\"",
        ],
        "expected": "Disabled.",
    },
    "C-171": {
        "gui": [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter if the setting is centrally managed.",
            "Go to the Windows PowerShell policy area if available.",
            "Read the configured execution policy.",
        ],
        "cmd": [
            "powershell -Command \"Get-ExecutionPolicy -List\"",
        ],
        "expected": "AllSigned or RemoteSigned, according to the approved baseline.",
    },
    "C-172": {
        "gui_path": "Local Group Policy Editor > Administrative Templates > Windows Components > Windows PowerShell > Turn on PowerShell Transcription",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription',
        "reg_value": "EnableTranscripting",
        "expected": "1.",
    },
    "C-173": {
        "gui_path": "Local Group Policy Editor > Administrative Templates > Windows Components > Windows PowerShell > Turn on PowerShell Script Block Logging",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging',
        "reg_value": "EnableScriptBlockLogging",
        "expected": "1.",
    },
    "C-174": {
        "gui": [
            "Press Windows + R.",
            "Type optionalfeatures and press Enter.",
            "In Windows Features, review Windows Subsystem for Linux.",
            "Confirm it is not enabled.",
        ],
        "cmd": [
            "powershell -Command \"Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux\"",
        ],
        "expected": "Disabled.",
    },
    "C-175": {
        "gui": [
            "Press Windows + R.",
            "Type optionalfeatures and press Enter.",
            "In Windows Features, review Windows Sandbox.",
            "Confirm it is not enabled.",
        ],
        "cmd": [
            "powershell -Command \"Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM\"",
        ],
        "expected": "Disabled.",
    },
    "C-176": {
        "gui_path": "Group Policy > Windows Remote Management (WinRM)",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client',
        "reg_value": "AllowBasic",
        "expected": "0 for both WinRM client and WinRM service locations.",
        "cmd_override": [
            "reg query \"HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WinRM\\Client\" /v AllowBasic",
            "reg query \"HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WinRM\\Service\" /v AllowBasic",
        ],
    },
    "C-177": {
        "gui_path": "Group Policy > Windows Remote Management (WinRM) > WinRM Service",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service',
        "reg_value": "AllowUnencryptedTraffic",
        "expected": "0.",
    },
    "C-179": {
        "gui": [
            "Press Windows + R.",
            "Type optionalfeatures and press Enter.",
            "Review any MultiPoint-related feature entries if they appear.",
            "Confirm the feature is not enabled.",
        ],
        "cmd": [
            "powershell -Command \"Get-WindowsOptionalFeature -Online | findstr /i MultiPoint\"",
        ],
        "expected": "Disabled or not installed.",
    },
    "C-180": {
        "gui_path": "Windows Security or registry review for LSA protection",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
        "reg_value": "RunAsPPL",
        "expected": "1.",
    },
    "C-181": {
        "service": "Print Spooler",
        "service_name": "Spooler",
        "expected": "Disabled on systems that do not need printing, unless there is an approved exception.",
    },
    "C-182": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Accounts: Limit local account use of blank passwords to console logon only",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
        "reg_value": "LimitBlankPasswordUse",
        "expected": "1.",
    },
    "C-183": {
        "gui_path": "Local Group Policy Editor > Windows Update policies",
        "reg_path": r'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate',
        "reg_values": ["WUServer", "WUStatusServer"],
        "expected": "Both values point to the approved internal WSUS or update source.",
    },
    "C-148": {
        "gui": [
            "Press Windows + R.",
            "Type services.msc and press Enter.",
            "Open Remote Registry and review the Startup type and Service status.",
            "Then press Windows + R, type gpedit.msc, and press Enter if Local Group Policy Editor is available.",
            "Go to Computer Configuration > Windows Settings > Security Settings > System Services or the approved service-hardening policy area used by your environment.",
            "Review whether Remote Registry is disabled by the approved policy baseline.",
        ],
        "cmd": [
            "powershell -Command \"Get-Service -Name RemoteRegistry | Select Name,Status,StartType\"",
            "powershell -Command \"Get-CimInstance Win32_Service -Filter \\\"Name='RemoteRegistry'\\\" | Select Name,State,StartMode\"",
        ],
        "expected": "The Remote Registry service is disabled and not running unless there is an approved exception.",
    },
    "C-184": {
        "gui": [
            "Open Event Viewer if your environment allows log property review.",
            "Review whether access to the Security log is limited to the approved administrator or auditor population.",
            "If your organization manages this centrally, compare with the approved event log access baseline.",
        ],
        "cmd": [
            "wevtutil gl Security",
        ],
        "expected": "Security log access is restricted to authorized administrators or auditors only.",
    },
    "C-185": {
        "gui": [
            "If your environment uses a policy console for WinRM, review the configured listeners there.",
            "Confirm only HTTPS listeners are approved for this host.",
        ],
        "cmd": [
            "winrm enumerate winrm/config/listener",
        ],
        "expected": "Only HTTPS listeners are present.",
    },
    "C-189": {
        "gui": [
            "Press Windows + R.",
            "Type wf.msc and press Enter.",
            "Review firewall rules related to WMI, remote administration, or similar remote execution tooling.",
            "If your environment uses endpoint protection or EDR controls for this requirement, compare with the approved policy or exception list.",
        ],
        "cmd": [
            "powershell -Command \"Get-NetFirewallRule | Where-Object {$_.DisplayName -match 'WMI|Remote|Admin'} | Select DisplayName,Enabled,Direction,Action\"",
            "wmic /namespace:\\root\\cimv2 path Win32_Service get Name,StartMode,State | findstr /i \"Winmgmt RemoteRegistry\"",
        ],
        "expected": "Remote execution tools are blocked or tightly restricted according to the baseline.",
    },
    "C-190": {
        "gui_path": "Local Security Policy > Local Policies > Security Options > Network security: Do not store LAN Manager hash value on next password change",
        "reg_path": r'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
        "reg_value": "NoLMHash",
        "expected": "Enabled.",
    },
    "C-191": {
        "gui": [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Security Settings > Application Control Policies > AppLocker if AppLocker is used in your environment.",
            "Review Executable Rules or the effective path control policy.",
            "If your environment uses WDAC instead of AppLocker, compare with the effective WDAC policy report.",
        ],
        "cmd": [
            "powershell -Command \"Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue\"",
        ],
        "expected": "Only approved executable paths, such as Windows system paths or approved application directories, are allowed according to the baseline.",
    },
}


REQUIREMENT_MAP = {
    "C-001": "Configured. Do not configure startup password unless specifically approved by OEM or operational requirement.",
    "C-002": "Set boot order to internal fixed disk only. External media, network boot, and other non-approved boot sources shall not precede the internal system disk.",
    "C-003": "Disabled unless explicitly approved for maintenance under controlled procedure.",
    "C-004": "Disabled unless formally required for an approved OT build, imaging, or recovery process.",
    "C-005": "Minimum 8 characters for engineering, standard service and operator accounts. Minimum 14 characters for privileged and administrative service accounts.",
    "C-006": "365 days for human user accounts; service accounts may be non-expiring only where justified and approved.",
    "C-007": "Minimum password age set to 1 day across account types.",
    "C-008": "Complexity enabled for all account types.",
    "C-009": "Last 12 passwords remembered.",
    "C-010": "Expiry enabled for human user accounts.",
    "C-011": "MFA enforced where technically supported, with priority for privileged, remote, vendor, and externally accessible access paths.",
    "C-012": "Lock account after 5 invalid logon attempts for engineering/maintenance and privileged users; 10 invalid logon attempts for service and operator accounts.",
    "C-013": "Reset failed logon counter after 30 minutes for engineering, privileged and service accounts; 15 minutes for operator accounts.",
    "C-014": "Maintain 30-minute account lockout duration for all applicable account categories unless an approved operational exception exists.",
    "C-015": "Determines whether the OS audits each time this computer validates an account's credential. Recommended setting: Success, Failure.",
    "C-016": "Determines whether to audit each event of account management on a computer (for example creation of user account or group account). Recommended setting: Success, Failure.",
    "C-017": "Determines whether the OS audits user attempts to access non-Active Directory objects. Audit is only generated for objects that have system access control lists (SACL) specified. Recommended setting: Failure.",
    "C-018": "This option audits user attempts to shut down or restart the computer as well as events that affect system security or the security log. Recommended setting: Success, Failure.",
    "C-019": "Determines whether the OS audits user attempts to access Active Directory objects. Recommended setting: Failure.",
    "C-020": "Determines whether the OS audits process-related events such as process creation, process termination, handle duplication, and indirect object access. Recommended setting: No Auditing.",
    "C-021": "Enable auditing for Security Policy Changes success and failure in the audit options within the appropriate Group Policy Object for the server. Recommended setting: Success, Failure.",
    "C-022": "This security setting determines whether to audit each instance of a user logging on to or logging off from a computer. Recommended setting: Success, Failure.",
    "C-023": "Determines whether to audit each instance of a user exercising a user right. Recommended setting: Success, Failure.",
    "C-024": "Allocate enough disk space for Event Viewer audit logs. Recommended setting: Security minimum 199,680 KB (overwrite if necessary), System minimum 99,840 KB (overwrite if necessary), Application minimum 99,840 KB (overwrite if necessary).",
    "C-025": "Not Allowed.",
    "C-026": "Not Allowed.",
    "C-027": "Operator: Read-only access to OT systems. Engineer: Configuration access. Admin: Full system control.",
    "C-028": "Ensure the existence of these accounts with justification, approval and segregation of duties perspective.",
    "C-029": "Recommending disabling Administrator after creating a user with administrator rights. All the default accounts should be disabled or assigned to a relevant person to establish ownership with appropriate password.",
    "C-030": "Raise and fix any mismatch with reference list for justification.",
    "C-031": "Raise and fix any mismatch with reference list for justification.",
    "C-032": "Password Required Status should be Yes. Ask for justification for any other status.",
    "C-033": "Ask for justification for any custom groups created and review in terms of segregation of duties and approval from the system engineer.",
    "C-034": "Confirm deny logon locally, deny logon through RDP [include also PI, OPC, ...].",
    "C-035": "Require additional authentication factors: Password + OTP for VPN or privileged access.",
    "C-036": "Separate critical tasks among users - one user creates accounts; another approves them.",
    "C-037": "Automatically terminate inactive sessions, session timeout after 15 minutes.",
    "C-038": "Startup / configuration settings for ALL: Disabled.",
    "C-039": "Disabled.",
    "C-040": "Disabled.",
    "C-041": "Disabled.",
    "C-042": "Disabled.",
    "C-043": "Disabled.",
    "C-044": "Disabled.",
    "C-045": "Disabled.",
    "C-046": "Disabled.",
    "C-047": "Disabled.",
    "C-048": "Disabled.",
    "C-049": "Disabled.",
    "C-050": "Disabled.",
    "C-051": "Disabled.",
    "C-052": "Disabled.",
    "C-053": "Disabled.",
    "C-054": "Disabled.",
    "C-055": "Disabled.",
    "C-056": "Disabled.",
    "C-057": "Disabled.",
    "C-058": "Disabled.",
    "C-059": "Disabled.",
    "C-060": "Disabled.",
    "C-061": "Disabled.",
    "C-062": "Disabled.",
    "C-063": "Disabled.",
    "C-064": "Disabled.",
    "C-065": "Disabled.",
    "C-066": "Disabled.",
    "C-067": "Disabled.",
    "C-068": "Disabled.",
    "C-069": "Disabled.",
    "C-070": "Disabled.",
    "C-071": "Disabled.",
    "C-072": "Disabled.",
    "C-073": "Disabled.",
    "C-074": "Disabled.",
    "C-075": "Disabled.",
    "C-076": "Disabled.",
    "C-077": "Disabled.",
    "C-078": "Disabled.",
    "C-079": "Disabled.",
    "C-080": "Disabled.",
    "C-081": "Disabled.",
    "C-082": "Disabled.",
    "C-083": "Disabled.",
    "C-084": "Disabled.",
    "C-085": "Disabled.",
    "C-086": "Disabled.",
    "C-087": "Disabled.",
    "C-088": "Disabled.",
    "C-089": "Disabled.",
    "C-090": "Disabled.",
    "C-091": "Disabled.",
    "C-092": "Disabled.",
    "C-093": "Disabled.",
    "C-094": "Disabled.",
    "C-095": "Disabled.",
    "C-096": "Disabled.",
    "C-097": "Disabled.",
    "C-098": "Disabled.",
    "C-099": "Disabled.",
    "C-100": "Disabled.",
    "C-101": "Disabled.",
    "C-102": "Disabled.",
    "C-103": "Disabled.",
    "C-104": "Disabled.",
    "C-105": "Disabled.",
    "C-106": "Disabled.",
    "C-107": "Disabled.",
    "C-108": "Disabled.",
    "C-109": "Disabled.",
    "C-110": "Disabled.",
    "C-111": "Disabled.",
    "C-112": "Disabled (* If 3rd Party Used).",
    "C-113": "Disabled (* If 3rd Party Used).",
    "C-114": "Disabled.",
    "C-115": "Disabled.",
    "C-116": "Disabled.",
    "C-117": "Disabled.",
    "C-118": "Disabled.",
    "C-119": "Disabled.",
    "C-120": "Disabled.",
    "C-121": "Disabled.",
    "C-122": "Disabled.",
    "C-123": "Disabled.",
    "C-124": "Disabled (* unless explicitly required).",
    "C-125": "Disabled.",
    "C-126": "Disabled.",
    "C-127": "Disabled.",
    "C-128": "Disabled.",
    "C-129": "Disabled.",
    "C-130": "Enabled / Configured.",
    "C-131": "Enabled / Configured.",
    "C-132": "Enabled / Configured.",
    "C-133": "Disabled.",
    "C-134": "Enabled / Configured.",
    "C-135": "Enabled / Configured.",
    "C-136": "Enabled / Configured.",
    "C-137": "Enabled / Configured.",
    "C-138": "Enabled / Configured.",
    "C-139": "Enabled / Configured.",
    "C-140": "Enabled / Configured.",
    "C-141": "Enabled / Configured.",
    "C-142": "Disabled (* where approved).",
    "C-143": "Enabled / Configured.",
    "C-144": "Enabled / Configured.",
    "C-145": "Enabled / Configured.",
    "C-146": "Enabled / Configured.",
    "C-147": "Enabled / Configured.",
    "C-148": "Disabled.",
    "C-149": "Enabled / Configured.",
    "C-150": "Enabled / Enforced.",
    "C-151": "5 invalid attempts.",
    "C-152": "Enabled.",
    "C-153": "Send NTLMv2 response only. Refuse LM & NTLM.",
    "C-154": "Enabled.",
    "C-155": "Enabled.",
    "C-156": "Enabled.",
    "C-157": "Reject Unencrypted Access.",
    "C-158": "Prompt for credentials on secure desktop.",
    "C-159": "Prompt for credentials.",
    "C-160": "Enabled.",
    "C-161": "Enabled.",
    "C-162": "Enabled.",
    "C-163": "Do not display any information.",
    "C-164": "Restrict Remote Administrative Rights.",
    "C-165": "Disabled (* unless secure jump host used).",
    "C-166": "Enabled.",
    "C-167": "High Level / FIPS Compliant.",
    "C-168": "Terminate after 15 minutes.",
    "C-169": "Block All Removable Media (* unless authorized).",
    "C-170": "Enabled / Disallowed.",
    "C-171": "AllSigned or RemoteSigned.",
    "C-172": "Enabled.",
    "C-173": "Enabled.",
    "C-174": "Enabled / Disabled.",
    "C-175": "Enabled / Disabled.",
    "C-176": "Disable Basic / Enforce Negotiate or Kerberos.",
    "C-177": "Enabled.",
    "C-178": "As dictated by operational standards (Overwrite older logs).",
    "C-179": "Enabled / Disabled.",
    "C-180": "Enabled (RunAsPPL).",
    "C-181": "Disabled (* on non-printing nodes).",
    "C-182": "Enabled (Restrict to console logons only).",
    "C-183": "Enforce Local WSUS / WSUS source alignment.",
    "C-184": "Configured / Restricted.",
    "C-185": "Enabled / Configured.",
    "C-186": "Configured (Minimum 30 minutes).",
    "C-187": "Configured / Renamed.",
    "C-188": "Renamed & Disabled.",
    "C-189": "Enabled / Restricted.",
    "C-190": "Enabled / Configured.",
    "C-191": "Enabled / Enforced.",
    "C-192": "Enabled / Configured.",
}


def make_text(purpose, gui_steps, commands, expected):
    return (
        f"Purpose: {purpose}\n\n"
        f"GUI Method:\n" + "\n".join(f"- {step}" for step in gui_steps) + "\n\n"
        f"Command Method:\n" + "\n".join(f"- {command}" for command in commands) + "\n\n"
        f"Expected Compliant Result: {expected}\n\n"
        "If It Does Not Match: Do not change the setting yourself. Mark Fail or Exception, add a short note describing what you observed, and report it to IT/Cybersecurity."
    )


def build_bios(control):
    meta = BIOS_META[control["id"]]
    return make_text(
        f"This check confirms the {control['control']} setting in BIOS/UEFI matches the approved hardening baseline.",
        [
            "Save your work and restart the computer.",
            "During startup, press the BIOS/UEFI entry key shown by the manufacturer, such as F2, Delete, Esc, or F10.",
            "If prompted, enter the approved BIOS/UEFI password using the authorized process.",
            f"Navigate to {meta['path']}.",
            f"Open or view {meta['setting']}.",
            "Read the current setting only. Do not change anything in BIOS/UEFI.",
            "If needed, capture approved evidence and then exit BIOS/UEFI without saving changes.",
        ],
        [meta["command"], meta["command_note"]],
        meta["expected"],
    )


def build_password(control):
    setting, expected = PASSWORD_META[control["id"]]
    if control["id"] == "C-011":
        gui = [
            "Open the normal sign-in path used for this system, such as the VPN portal, jump host, Windows sign-in flow, or remote access portal.",
            "Review whether a second factor is required, such as an authenticator prompt, OTP, smart card, or hardware token.",
            "If the device is domain-managed or uses a corporate identity provider, compare what you see with the approved MFA policy or access standard.",
        ]
        commands = [
            "whoami",
            "powershell -Command \"Get-EventLog -LogName Security -Newest 20\"",
            "Review the approved identity provider, VPN, or remote access policy because MFA is usually validated in those systems rather than by one local Windows command.",
        ]
    elif control["id"] == "C-010":
        gui = [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Account Policies > Password Policy and review the local password expiry-related settings if present.",
            "Then press Windows + R, type compmgmt.msc, and press Enter.",
            "Go to System Tools > Local Users and Groups > Users.",
            "Open the relevant user account and review whether Password never expires is selected.",
            "If the PC is domain-managed, compare what you see with the domain or GPO baseline because the effective setting may not be controlled locally.",
        ]
        commands = [
            "net user <username>",
            "wmic useraccount get name,passwordexpires,passwordrequired",
        ]
    else:
        gui = [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Account Policies > Password Policy.",
            f"Open {setting}.",
            "Read the configured value and compare it with the approved baseline.",
            "If the computer is joined to a domain, remember the effective value may come from Group Policy rather than the local device.",
        ]
        commands = ["net accounts"]
        if control["id"] == "C-008":
            commands.append("If the device is domain-managed, also compare with the effective domain password policy because net accounts may not show the full complexity rule.")
        else:
            commands.append(f"Review the line for {setting}.")
    return make_text(
        f"This check confirms the {control['control'].lower()} setting protects accounts according to the approved password policy.",
        gui,
        commands,
        expected,
    )


def build_lockout(control):
    setting, expected = LOCKOUT_META[control["id"]]
    return make_text(
        "This check confirms the account lockout settings limit repeated failed sign-in attempts and match the approved baseline.",
        [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Account Policies > Account Lockout Policy.",
            f"Open {setting}.",
            "Read the configured value and compare it with the approved baseline.",
            "If the computer is domain-managed, note that the effective setting may come from domain Group Policy rather than the local device.",
        ],
        [
            "net accounts",
            f"Review the line related to {setting} in the output.",
        ],
        expected,
    )


def build_audit(control):
    _, audit_area, expected = AUDIT_META[control["id"]]
    if control["id"] in {"C-024", "C-178"}:
        gui = [
            "Press Windows + R.",
            "Type eventvwr.msc and press Enter.",
            "In the left pane, open Windows Logs.",
            "Right-click the relevant log, such as Security, System, or Application, and select Properties.",
            "Review the maximum log size and the overwrite or retention behavior.",
        ]
        commands = [
            "wevtutil gl Security",
            "wevtutil gl System",
            "wevtutil gl Application",
        ]
    elif control["id"] == "C-192":
        gui = [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter if the device supports Local Group Policy Editor.",
            "Go to Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration > System Audit Policies > Object Access.",
            "Open File System and Registry and review the configured audit settings.",
            "Also open Event Viewer and confirm related events are being recorded where SACLs are configured.",
        ]
        commands = [
            "auditpol /get /subcategory:*",
            "wevtutil qe Security /c:20 /f:text",
        ]
    else:
        gui = [
            "Press Windows + R.",
            "Type secpol.msc and press Enter.",
            "Go to Security Settings > Local Policies > Audit Policy.",
            f"Open {audit_area}.",
            f"Confirm the setting shows {expected}",
            "Then open Event Viewer by pressing Windows + R, typing eventvwr.msc, and pressing Enter.",
            "Review recent Security log events if this device is expected to generate them.",
        ]
        commands = [
            "auditpol /get /category:*",
            f"Review the audit subcategory related to {audit_area}.",
        ]
    return make_text(
        f"This check confirms Windows auditing and logging for {control['control'].lower()} is configured to capture the security activity required by the baseline.",
        gui,
        commands,
        expected,
    )


def build_access(control):
    expected = ACCESS_META[control["id"]]
    base_gui = [
        "Press Windows + R.",
        "Type compmgmt.msc and press Enter.",
        "Go to System Tools > Local Users and Groups.",
    ]
    if control["id"] == "C-028":
        base_gui.extend([
            "Open Groups.",
            "Double-click Administrators.",
            "Review every listed member and compare it with the approved administrator list.",
        ])
        commands = [
            "net localgroup administrators",
            "powershell -Command \"Get-LocalGroupMember -Group Administrators\"",
        ]
    elif control["id"] in {"C-027", "C-033", "C-036"}:
        base_gui.extend([
            "Review the relevant users, groups, or memberships.",
            "Compare them with the approved role matrix, access list, or segregation-of-duties record.",
        ])
        commands = [
            "net localgroup",
            "powershell -Command \"Get-LocalGroup | Select Name,Description\"",
        ]
    elif control["id"] == "C-037":
        base_gui = [
            "Press Windows + R.",
            "Type gpedit.msc and press Enter.",
            "Go to User Configuration > Administrative Templates > Control Panel > Personalization.",
            "Review the screen saver timeout and password protection related settings.",
            "If the device is domain-managed, compare the effective value with the approved domain baseline.",
        ]
        commands = [
            "reg query \"HKCU\\Control Panel\\Desktop\" /v ScreenSaveTimeOut",
            "powercfg /q",
        ]
    elif control["id"] == "C-034":
        base_gui.extend([
            "Open Users and review the service account properties.",
            "Then open Local Security Policy if needed and review deny logon locally and deny logon through Remote Desktop rights.",
            "If the account is domain-managed, compare the result with the approved domain policy or service account standard.",
        ])
        commands = [
            "secedit /export /cfg %TEMP%\\secpol.cfg & findstr /i \"SeDenyInteractiveLogonRight SeDenyRemoteInteractiveLogonRight\" %TEMP%\\secpol.cfg",
            "net user",
        ]
    elif control["id"] == "C-035":
        base_gui = [
            "Open the normal VPN, jump host, or privileged access sign-in path used for this device.",
            "Review whether a second factor is required.",
            "Compare that with the approved MFA policy for this system or access path.",
        ]
        commands = [
            "whoami",
            "powershell -Command \"Get-EventLog -LogName Security -Newest 20\"",
        ]
    elif control["id"] == "C-187":
        base_gui.extend([
            "Open Users.",
            "Identify the built-in administrator account or compare the visible name with the approved naming standard.",
        ])
        commands = [
            "wmic useraccount where sid like \"S-1-5-21%%-500\" get name,sid",
            "secedit /export /cfg %TEMP%\\secpol.cfg & findstr /i \"NewAdministratorName\" %TEMP%\\secpol.cfg",
        ]
    elif control["id"] == "C-188":
        base_gui.extend([
            "Open Users.",
            "Review the Guest account status and visible name.",
        ])
        commands = [
            "net user guest",
            "wmic useraccount where sid like \"S-1-5-21%%-501\" get name,disabled,sid",
        ]
    else:
        base_gui.extend([
            "Open Users and review the relevant account names, status, descriptions, and properties.",
            "If the device is domain-managed, remember some accounts or groups may be controlled in Active Directory rather than only on the local PC.",
        ])
        commands = ["net user", "net localgroup"]
    return make_text(
        f"This check confirms {control['control'].lower()} follows the approved access control baseline and that only authorized users or accounts have the expected access.",
        base_gui,
        commands,
        expected,
    )


def build_service(control):
    service_name = SERVICE_NAME_MAP.get(control["id"], control["control"])
    expected = "The service Startup type is Disabled and the service is not running unless an approved exception exists."
    if control["id"] in {"C-112", "C-113"}:
        expected = "The service is Disabled only where an approved third-party security product replaces it. Otherwise the exception record must explain why it is different."
    elif control["id"] == "C-124":
        expected = "The WinRM service is Disabled unless there is an explicit approved requirement."
    elif control["id"] == "C-181":
        expected = "The Print Spooler service is Disabled on systems that do not need printing, unless there is an approved exception."

    return make_text(
        f"This check confirms the Windows service for {control['control']} is set to the approved startup state and is not exposing unnecessary functionality.",
        [
            "Press Windows + R.",
            "Type services.msc and press Enter.",
            f"Scroll to the service named {control['control']}.",
            "Double-click the service to open its properties.",
            "Review the Startup type and Service status fields.",
            "Read the values only. Do not start, stop, enable, disable, or reconfigure the service yourself.",
        ],
        [
            f"powershell -Command \"Get-Service -Name {service_name} | Select Name,Status,StartType\"",
            f"powershell -Command \"Get-CimInstance Win32_Service -Filter \\\"Name='{service_name}'\\\" | Select Name,State,StartMode\"",
        ],
        expected,
    )


def build_registry(control):
    meta = REGISTRY_META[control["id"]]
    if "service" in meta:
        return make_text(
            f"This check confirms the {meta['service']} service matches the approved baseline.",
            [
                "Press Windows + R.",
                "Type services.msc and press Enter.",
                f"Open {meta['service']}.",
                "Review the Startup type and Service status fields.",
            ],
            [
                f"powershell -Command \"Get-Service -Name {meta['service_name']} | Select Name,Status,StartType\"",
                f"powershell -Command \"Get-CimInstance Win32_Service -Filter \\\"Name='{meta['service_name']}'\\\" | Select Name,State,StartMode\"",
            ],
            meta["expected"],
        )

    if "gui" in meta and "cmd" in meta:
        return make_text(
            f"This check confirms the {control['control'].lower()} setting matches the approved baseline.",
            meta["gui"],
            meta["cmd"],
            meta["expected"],
        )

    gui = [
        "Press Windows + R.",
        "Review the setting in the policy, Windows feature, or configuration area shown below.",
        f"Open {meta['gui_path']}.",
        "Read the value only and compare it with the approved baseline.",
    ]
    if meta.get("cmd_override"):
        commands = meta["cmd_override"]
    elif meta.get("reg_values"):
        commands = [f'reg query "{meta["reg_path"]}" /v {value}' for value in meta["reg_values"]]
    else:
        commands = [f'reg query "{meta["reg_path"]}" /v {meta["reg_value"]}']
    return make_text(
        f"This check confirms the {control['control'].lower()} setting is present and set to the approved hardened value.",
        gui,
        commands,
        meta["expected"],
    )


def build_default(control):
    return make_text(
        f"This check confirms the {control['control'].lower()} setting matches the approved cybersecurity baseline for this device.",
        [
            "Review the setting in the normal Windows, policy, firmware, or application interface used for this control.",
            "Read the configured value carefully and compare it with the approved baseline or build record.",
            "If the device is domain-managed, remember the effective setting may come from Group Policy or a central management platform.",
        ],
        ["Use the approved read-only command or policy report for this control."],
        "The value or status matches the approved baseline exactly.",
    )


def main():
    controls = json.loads(CONTROLS_PATH.read_text(encoding="utf-8"))

    for control in controls:
        cid = control["id"]
        if cid in REQUIREMENT_MAP:
            control["requirement"] = REQUIREMENT_MAP[cid]
        if cid in BIOS_META:
            control["howToCheck"] = build_bios(control)
        elif cid in PASSWORD_META:
            control["howToCheck"] = build_password(control)
        elif cid in LOCKOUT_META:
            control["howToCheck"] = build_lockout(control)
        elif cid in AUDIT_META:
            control["howToCheck"] = build_audit(control)
        elif cid in ACCESS_META:
            control["howToCheck"] = build_access(control)
        elif cid in REGISTRY_META:
            control["howToCheck"] = build_registry(control)
        elif control["category"] == "OS Service Hardening Configurations":
            control["howToCheck"] = build_service(control)
        else:
            control["howToCheck"] = build_default(control)

    CONTROLS_PATH.write_text(json.dumps(controls, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {len(controls)} controls")


if __name__ == "__main__":
    main()