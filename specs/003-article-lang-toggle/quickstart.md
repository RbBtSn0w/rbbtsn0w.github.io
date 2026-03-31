# Quickstart: Article Language Toggle (Google Apps Script Version)

## Description
This feature uses a private **Google Apps Script (GAS)** proxy to pre-translate articles at build-time. This is **100% free**, requires **no credit card**, and keeps your keys hidden.

## Prerequisites
1.  **Google Account**: A standard Gmail account is all you need.
2.  **GAS Deployment**:
    -   Go to [script.google.com](https://script.google.com/).
    -   Create a **New Project**.
    -   Paste the `doPost` code (see below).
    -   Click **Deploy > New Deployment**.
    -   Set type to **Web App**.
    -   Set "Execute as" to **Me**.
    -   Set "Who has access" to **Anyone**.
    -   **Copy the Web App URL**.

### GAS Code
```javascript
var ALLOWED_TOKEN = "YOUR_SECRET_TOKEN_HERE"; // Replace with your chosen token

function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  if (data.token !== ALLOWED_TOKEN) {
    return ContentService.createTextOutput(JSON.stringify({ error: "Unauthorized" }))
      .setMimeType(ContentService.MimeType.JSON);
  }
  
  var target = data.target || 'en';
  var translated = data.q.map(function(t) {
    try { return LanguageApp.translate(t, '', target); } catch (err) { return t; }
  });
  return ContentService.createTextOutput(JSON.stringify({
    data: { translations: translated.map(function(t) { return { translatedText: t }; }) }
  })).setMimeType(ContentService.MimeType.JSON);
}
```

## GitHub Configuration
1.  Go to your GitHub repository: **Settings > Secrets and variables > Actions**.
2.  Click **New repository secret**.
3.  **Name**: `GOOGLE_APPS_SCRIPT_URL` | **Value**: Paste your **Web App URL**.
4.  **Name**: `GOOGLE_APPS_SCRIPT_TOKEN` | **Value**: Paste your **SECRET_TOKEN**.

## Deployment
1.  Push your changes to the `main` branch.
2.  The GitHub Action will automatically generate translation JSONs for each post in `assets/translations/`.

## Why this is better:
- **Free**: No API key or billing required.
- **Fast**: Translation happens during build; readers get instant results.
- **Secure**: No secrets are exposed to the browser.
- **Efficient**: Only translates new or modified articles (using content hashing).
