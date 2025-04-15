saml2aws configure \
  --idp-provider='AzureAD' \
  --session-duration='43200' \
  --mfa='Auto' \
  --profile='default' \
  --role='arn:aws:iam::767397877485:role/cloudboost_account_operator/2224874@cognizant.com' \
  --url='https://account.activedirectory.windowsazure.com' \
  --username='224874@cognizant.com' \
  --app-id='029af5e5-8cb1-4848-8da4-a6b4a2b52834&tenantId=de08c407-19b9-427d-9fe8-edf254300ca7' \
  --skip-prompt


saml2aws configure \
  --idp-provider='AzureAD' \
  --session-duration='43200' \
  --mfa='Auto' \
  --profile='default' \
  --role='arn:aws:iam::767397877485:role/cloudboost_account_operator' \
  --url='https://account.activedirectory.windowsazure.com' \
  --username='2224874@cognizant.com' \
  --app-id='029af5e5-8cb1-4848-8da4-a6b4a2b52834&tenantId=de08c407-19b9-427d-9fe8-edf254300ca7' \
  --skip-prompt

  saml2aws login