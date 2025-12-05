# 🚨 Auto-Block Attacker IPs in Azure WAF (Using Logic App + Log Analytics Alerts)

This solution automatically **detects malicious requests** (SQLi, XSS, Injection attempts) from **Application Gateway WAF Logs**, extracts the attacker IP, and dynamically **adds it to an Azure WAF Policy** as a blocking rule.

Includes:
- Automatic IP extraction  
- WAF rule auto-generation  
- Dynamic updates  
- IP deduplication  
- Optional expiry logic  
- Notification integration  
- Dashboarding options  

---

## 📌 Architecture

```
 Application Gateway WAF
        │ Logs → AzureDiagnostics
        ▼
 Log Analytics Workspace
        │ Alert Rule (KQL)
        ▼
 Azure Monitor Alert 
        │ Triggers Logic App
        ▼
 Logic App (Query → Extract IP → Update Policy)
        ▼
 Application Gateway WAF (Dynamic Blocking)
```

---

## 📦 Prerequisites

| Component | Requirement |
|----------|-------------|
| Azure Subscription | Owner / Contributor |
| WAF-enabled Application Gateway | Required |
| Log Analytics Workspace | Diagnostics enabled |
| Alert Rule | Custom KQL |
| Logic App (Consumption) | With Managed Identity |

---

## 🧪 Detection KQL

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s in ("Blocked","Matched")
| where Message contains "SQL"
    or Message contains "Injection"
    or Message contains "XSS"
    or Message contains "<script"
| project TimeGenerated, clientIp_s, requestUri_s, Message
| order by TimeGenerated desc
| limit 1
```

---

## 🔔 Configure Alert Rule

1. Go to **Monitor → Alerts → Create Alert Rule**
2. **Resource:** Log Analytics Workspace
3. **Condition:** Custom log search (paste KQL)
4. **Alert logic:** Result > 0
5. **Action Group:** Logic App → HTTP trigger
6. **Enable Common Alert Schema**

---

## ⚙ Deploy Logic App

The Logic App performs:

1. Query LA logs using ARM API  
2. Parse attacker IP  
3. Read existing WAF customRules  
4. Create rule if missing  
5. Merge IPs  
6. PUT updated policy (requires full body)  

### Required RBAC

Assign system-managed identity:

| Resource | Roles |
|----------|-------|
| WAF Policy RG | Contributor |
| Log Analytics Workspace | Log Analytics Reader |

---

## 📝 Important JSON Fixes

### Application Gateway WAF expects:
```json
"customRules": [ ... ]
```

### NOT:
```json
"customRules": { "rules": [ ... ] }
```

### Valid action:
```json
"action": "Block"
```

### Required:
```json
"location": "centralindia"
```

---

## 🛡 Testing the System

Trigger an attack:

```
http://<appgw-ip>/index.php?msg=<script>alert(1)</script>
```

Verify:

1. Log entry appears in Log Analytics  
2. Alert fires  
3. Logic App runs successfully  
4. WAF policy updates  
5. Attacker IP blocked  

---

## 📊 Validate Blocked IPs

```bash
az network application-gateway waf-policy show   -g ntms-owasp-wp-rg   -n waf1   --query "customRules"
```

---

## 🧰 Repository Structure

```
/
├── LogicApp.json
├── README.md
└── images/
```

---

## 🛠 Troubleshooting

### ❌ “LocationRequired”
Add `"location": "centralindia"` in PUT body.

### ❌ “InvalidJson: customRules.rules”
Use array format:
```json
"customRules": [ ... ]
```

### ❌ No logs found
Ensure AGW diagnostics → Log Analytics enabled.

---

## 🚀 Optional Enhancements (Included in README)

### 🔶 IP Expiry (Auto-remove after X minutes)
Store IP entries as:
```
1.2.3.4|2025-12-05T12:00:00Z
```
Logic App checks timestamp and removes expired ones.

### 🔶 Email / Teams Alerts
Use:
- **Office 365 Outlook connector**
- **Teams Webhook**
- **Azure Monitor action group email**

### 🔶 Store attackers in Azure Table Storage
For reporting and investigation dashboards.

### 🔶 Build Live Dashboard (Workbook)
Show:
- Attack rate
- Blocked IPs
- WAF rule updates
- Traffic patterns

---

## 🎉 DONE  
Your Azure WAF now dynamically blocks attackers using fully automated, serverless security orchestration.

