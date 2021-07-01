# How To Use InterRep

## Getting an InterRep Twitter Badge

1. Connect an Ethereum account through the Metamask browser extension. This is the account that will receive a badge. If you don't have Metamask installed, you can download it here: https://metamask.io/download.html

2. Authenticate yourself with Twitter. Under the 'Twitter Account' section click on 'Sign in' and follow the instructions. You might be prompted to sign in with Twitter if you're not signed in on your browser already.

3. Once logged in, the reputation of your Twitter account will be displayed. To understand how reputation is computed please see the [Twitter reputation criteria](Twitter_Reputation_Criteria.md).

4. If your reputation is 'CONFIRMED', you can proceed and click on the 'LINK ACCOUNTS' button.

5. Accept the Metamask prompt to provide your _public_ key. This allows InterRep to encrypt the association.

6. Then, Metamask should present a second pop-up with a message that you need to sign. By signing it, you're attesting with your address that you want to link it with your Twitter account.

7. Under the 'Badges' section, your badge should appear with its status and id. Click on 'MINT' to mint it on-chain.

8. After some time, your badge status should be 'MINTED' and you can verify that your address holds a badge by visiting the link to Etherscan at the bottom of the page.
   \
   &nbsp;

## Revoking an InterRep Twitter Badge and linking another Ethereum address

1. On https://interrep.link, make sure you are connected with both the address and Twitter account that you linked together.

2. Click on the “burn” button next to your badge.

3. This will open a Metamask pop-up. Confirm the transaction to burn your badge.

4. Once the transaction is confirmed, click on “Unlink accounts”.

5. Another Metamask pop-up should appear, asking you to decrypt a message. This message contains the original attestation that you signed to link your accounts. Click on “Decrypt”.

6. Finally, the status of your badge should changed to “REVOKED”. You are now able to switch to another Ethereum address and link it to your Twitter account.
