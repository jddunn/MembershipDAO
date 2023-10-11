# MembershipDAO
Smart contract with paid membership access control, basic DAO and banking. Note: This is a basic POC concept and does not guard against reentrancy attacks, so it is not recommended to use for production as-is.

## Intro

This is a smart contract that can be used as a template / base contract to start a members-only organization, where the entry fee / subscription is customizable and paid for in Ethereum. 

Methods that require membership can be guarded with the modifier `isWhitelisted`. 

See this example for another smart contract with Honeypot checking features that is only accessible for members: https://github.com/jddunn/HoneypotRescueWithSafeBuy/blob/main/HoneypotRescueWithSafeBuy.sol.

There are basic investment DAO features, where members can deposit and withdraw tokens. The owner of the contract must be a trusted party as there are CEX-like features, where the owner can withdraw all eth deposited in the contract from membership fees at any time, and the owner can return the invested tokens to members of the smart contract and revoke their memberships at any time also.

## Member functions

`getMembers()`: Gets list of members in the DAO.

`getMemberBalances(address addr)`: Gets membership balances of deposited / invested tokens for address.

`getMembersBalances()`: Gets list of members and their balances in their DAO.

`getMemberTokenBalances(address addr, address token)`: Gets token balance of member address in the DAO.

`depostToken(address token)`: Deposits a token into the membership banking for the message sender address.

`withdrawToken(address token)`: Withdraw full balance of ERC20 token deposited into the membership banking for the message sender address.

`withdrawTokenAll(address token)`: Withdraw full balance of ERC20 token deposited into the membership banking for the message sender address.

## Owner functions

`withdrawInvestmentsOwner()`: Withdraw wETH deposited into contract (membership fees) to owner. Only owner can call this.

`withdrawAndReturnInvestments()`: Withdraw wETH deposited into contract (membership fees) to owner. Returns invested tokens back to members. Only owner can call this.

`withdrawAndReturnInvestmentsAndRevokeMemberships()`: Withdraw wETH deposited into contract (membership fees) to owner. Returns all invested / deposited tokens to members, and revokes their memberships. Only owner can call this.

`withdrawAndReturnInvestmentsAndKeepMemberships()`: Withdraw wETH deposited into contract (membership fees) to owner. Returns all invested / deposited tokens to members. Only owner can call this.

`returnInvestmentsAllAndRevokeMemberships()`: Returns all invested / deposited tokens to members, and revokes their memberships. Only owner can call this.

`returnInvestmentsAllAndKeepMemberships()`: Returns all invested / deposited tokens to members. Only owner can call this.

`returnInvestmentsRevokeMemberships(address[] memory addrs, uint256 fee)`: Returns invested tokens back to users, and revokes memberships. A withdrawal / exit fee can be applied. Only owner can call this.

`returnInvestmentsKeepMemberships(address[] memory addrs, uint256 fee)`: Returns invested tokens back to users. A withdrawal / exit fee can be applied. Only owner can call this.



