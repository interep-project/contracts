# Technical Overview

InterRep is made up of 2 main components: a centralized verification service (with a database, server, API, and front-end accessible at https://interrep.link) and a set of smart contracts for the Twitter badge (this is currently the only badge one can get from InterRep).

By interacting with the front-end, users are able to:

- link and unlink their Ethereum account with their Twitter account
- mint and burn an NFT or “badge” representing this association

Applications can also use InterRep through the API, which returns a Twitter account’s reputation based on publicly available data.

_Query by username_:

```
https://interrep.link/api/reputation/twitter?username=
```

_Query by Twitter id_:

```
https://interrep.link/api/reputation/twitter?id=
```

Users need to connect with an Ethereum account through the Metamask browser extension.

InterRep uses OAuth to allow users to sign in with their Twitter account. The server then fetches public data for that account and determines its reputation based on the criteria described [here](Twitter_Reputation_Criteria.md).

Note: “badge”, “token” and “NFT” are used interchangeably here.

## Linking Twitter accounts to addresses

Users are asked to sign a message linking together the unique id associated with their Twitter account and their Ethereum address. They also need to provide their public key which will be used by the server for encryption.

On the server, the validity of the signature is verified and some checks are performed to make sure the Twitter account the user is connected with is reputable enough and is not already linked to an address.

The server then creates a message containing the user's Ethereum address and basic information about the user's Twitter account. That message is signed with the server's private key.

The signature, the message (together forming an attestation) and a salt is encrypted with the user's public key. The link between a Twitter account and an address is neither logged nor saved anywhere other than in the encrypted attestation. This means that only the user, with their private key, has the ability to reveal this association.

The result of this encryption is saved in the database in a Token with the status NOT_MINTED and a unique `tokenId`. The Twitter account in the database is marked as linked to an address.

The status of a Token can be any of the following:

```
NOT_MINTED
MINT_PENDING
MINTED
BURNED
REVOKED
```

## Minting a badge

On the front-end, badges associated with the user's connected address are displayed along with their status. If the status is NOT_MINTED, minting can be triggered which calls the smart contract for that badge and mints an ERC-721 NFT. The id of that NFT is the `tokenId` mentioned above. At the moment only the server, with its private key, can mint tokens.

## Burning a badge

The owner of a badge can burn it by calling burnToken() on the smart contract, passing in the tokenId. This process is made simpler through the InterRep front-end as users just need to click on a button and approve a transaction. A badge can only be burned by its owner or an account approved by its owner.

## Unlinking accounts

Users might want to change which Ethereum address is associated with their Twitter account. For that, InterRep allows users to unlink their accounts.

As a prerequisite, the badge representing the account association must be burned on-chain. The process is then similar to linking accounts but reversed.

Users select a token they own and decrypt the associated attestation. This decrypted attestation is sent to the server which checks its validity. The server also verifies that the user is signed in with a Twitter account linked to an address.

The Twitter account is retrieved from the decrypted attestation and compared to the account the user is logged in with.

The on-chain tokenId is retrieved and used to check that the token was indeed burned on-chain.

If all checks pass, the Twitter account in the database is marked as not being linked to an address. The token status is updated to REVOKED.
