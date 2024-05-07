
# Notify FDK (nfdk)

This CLI tool will send message in teams channel when Fynd theme deployment is done. The message will contain last 10 PRs and its details. nfdk will also give a system notification to the user who is deploying when the deployment fails.

## Example
![image](https://github.com/nithinkjoy-tech/nfdk/assets/62066971/cf565e1b-ebe1-4b96-8406-9403634b27e1)

## Installation and Usage

Run below command in terminal to install nfdk
```
curl https://raw.githubusercontent.com/nithinkjoy-tech/nfdk/master/install.sh | bash
```

## Set Webhook URL

Inorder to notify teams channel we need to set teams webhook url.
https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=newteams%2Cdotnet refer this article to get webhook URL
```
nfdk set WEBHOOK_URL=https://examplewebhookurl.com/xyz
```

## View Webhook URL
We can view Webhook URL which we had set using below command
```
nfdk get key
```

## Notify teams channel after deployment
```
nfdk theme sync
```

## Upgrade to latest version
```
nfdk upgrade
```

## Get help
```
nfdk help or --help
```
