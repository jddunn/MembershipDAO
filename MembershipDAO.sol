// SPDX-License-Identifier: MIT
/*
███╗░░░███╗███████╗███╗░░░███╗██████╗░███████╗██████╗░░██████╗██╗░░██╗██╗██████╗░  ██████╗░░█████╗░░█████╗░
████╗░████║██╔════╝████╗░████║██╔══██╗██╔════╝██╔══██╗██╔════╝██║░░██║██║██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗
██╔████╔██║█████╗░░██╔████╔██║██████╦╝█████╗░░██████╔╝╚█████╗░███████║██║██████╔╝  ██║░░██║███████║██║░░██║
██║╚██╔╝██║██╔══╝░░██║╚██╔╝██║██╔══██╗██╔══╝░░██╔══██╗░╚═══██╗██╔══██║██║██╔═══╝░  ██║░░██║██╔══██║██║░░██║
██║░╚═╝░██║███████╗██║░╚═╝░██║██████╦╝███████╗██║░░██║██████╔╝██║░░██║██║██║░░░░░  ██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░  ╚═════╝░╚═╝░░╚═╝░╚════╝░
Cross-chain contract meant to support paid membership features. Wraps around OpenZeppelin's Whitelist
contract. Has basic banking and DAO functionality for members. This is usually meant to be inherited but 
can be deployed on its own.

Call the contract with constructor(membershipPrice[uint256], membershipWithdrawalFee[uint256]).

Set membershipWithdrawalFee to 0 if you want no withdrawal fees. Set membershipPrice to 0 if you want no membership
fee.

Users deposit wETH into the contract to gain membership.
Any methods with the modifier `onlyWhitelisted` will guard membership access.
 
   ___  .___    __.    ___    __.    ___/ `  |     ___ 
 .'   ` /   \ .'   \ .'   ` .'   \  /   | |  |   .'   `
 |      |   ' |    | |      |    | ,'   | |  |   |----'
  `._.' /      `._.'  `._.'  `._.' `___,' / /\__ `.___,         
*/

pragma abicoder v2;
pragma solidity ^0.8.7;

// Although we only accept wETH in our contract deposit() methods, 
// we'll include a withdrawal method for any ERC20 tokens in case
// people send wrong tokens to us.
// **** Token Interfaces / Standards **** 
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// **** OpenZeppelin Libs **** 
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Ownable from OpenZepplin
abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender], "You are not on the whitelist. Please invest a minimum of .1 eth with the invest() to get membership.");
    _;
  }

  /**
   * @dev Returns true or false if address is in whitelist.
   * @param addr address
   * @return true if the address is in whitelist.
   */
    function isWhitelisted(address addr) public virtual view returns (bool) {
        return whitelist[addr];
    }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return success if the address was added to the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return success if at least one address was added to the whitelist,
   */
  function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return success if the address was removed from the whitelist,
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    success = false;
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
    return success;
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return success if at least one address was removed from the whitelist,
   */
  function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    success = false;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
    return success;
  }
}

// **** Membership DAO **** 
/*
* @title MembershipDAO contract.
* @dev Contract that supports paid membership, banking, and DAO features.
* @dev Inherits from OpenZeppelin's Whitelist contract. 
* @dev Wrap methods with modifier `onlyWhitelisted` for membership access.
*/
contract MembershipDAO is Whitelist {
    
    // Whitelist of members who can use our contract
    address[] public members;
    
    address public _owner;

    // Let our users deposit and withdraw and keep track of their balances
    mapping(address => uint256) public membershipBalances; 
    
    // If a user deposits enough to reach the $membershipPrice, they will
    // be added onto the whitelist.
    uint256 membershipPrice;

    // Our contract allows banking (deposit and withdrawal features)
    // Set a member withdrawal fee to subtract form their balance on withdrawal
    uint256 membershipWithdrawalFee;

    // Membership subscription events are encompassed in Whitelist contract.
    // Payment / banking events below
    event DepositEvent(address sender, uint amount);
    event WithdrawalEvent(address receiver, uint amount);
    event WithdrawalFailEvent(address receiver, string err);

    constructor(uint256 _membershipPrice, uint256 _membershipWithdrawalFee) {
        membershipPrice = _membershipPrice;
        membershipWithdrawalFee = _membershipWithdrawalFee;
        _owner = msg.sender;
        _addMember(_owner); // add owner to our members
        membershipBalances[_owner] = 0; // initialize owner balance
    }


    // Whitelist wrappers
    /**
    * @dev Private method. Adds members to whitelist.
           Does not add balances to members.
    * @param addr Address to add to membership whitelist.
    */
    function _addMember(address addr) private {
        bool found = false;
        for (uint x = 0; x < members.length; x++) {
            if (addr == members[x]) {
                found = true;
                continue;
            }
        }
        if (!found) {
            addAddressToWhitelist(addr);
            members.push(addr);
        }
    }

    /**
    * @dev Private method. Adds members to whitelist.
           Does not add balances to members.
    * @param addrs Addresses to add to membership whitelist.
    */
    function _addMembers(address[] memory addrs) private {
        for (uint i = 0; i < addrs.length; i++) {
            _addMember(addrs[i]);
        }
    }
    
    /**
    * @dev Private method. Removes members from whitelist. 
           Does not return account balances to members, they
           will need to withdraw().
    * @param addr Address to remove from membership whitelist.
    */
    function _removeMember(address addr) private {
        address[] memory auxArray;
        for (uint x = 0; x < members.length; x++) {
            if(members[x] == addr) {
                _removeMembershipBalance(addr);
                removeAddressFromWhitelist(addr);
                continue;
            } else {
                auxArray[x] = members[x];
            }
        }
        members = auxArray;
    }

    /**
    * @dev Private method. Removes members from whitelist. 
           Does not return account balances to members, they
           will need to withdraw().
    * @param addrs Addresses to remove from membership whitelist.
    */
    function _removeMembers(address[] memory addrs) private {
        for (uint i = 0; i < addrs.length; i++) {
            _removeMember(addrs[i]);
        }
    }

    // Membership / DAO functions

    /**
    * @dev Allow users to invest into our contract funds.
           If their investment exceeds our $membershipPrice,
           add them to our whitelist.
    * @param amount Amount of wETH to deposit from wallet.
    */
    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
        if (isWhitelisted(msg.sender)) {
            // If they're already whitelisted we'll add more to their balance.
            // We can track of our members' investments in us to give out
            // better benefits accordingly later on
            membershipBalances[msg.sender] += amount;
        } else {
            membershipBalances[msg.sender] = 0; // initialize balance
            membershipBalances[msg.sender] += amount; // add amount to balance
            // Check to see if they paid enough for a whitelist
            if (membershipBalances[msg.sender] >= membershipPrice) {
                // Add one more to our members
                _addMember(msg.sender);
                 // Collect our membership fee
                membershipBalances[msg.sender] -= membershipPrice;
            }
        }
        emit DepositEvent(msg.sender, msg.value);
    }

    /**
    * @dev Allow users to withdraw their funds minus the
           withdrawal fee we have set. Users cannot withdraw
           until they become members (have paid membership fee).
    * @param amount Amount of wETH to withdraw to wallet.
    * @return true if successful withdrawal
    */
    function withdraw(uint256 amount) onlyWhitelisted public payable returns (bool) {
        require(msg.value == amount);
        uint256 withdrawBal = membershipBalances[msg.sender];
        if (withdrawBal <= membershipWithdrawalFee) {
            emit WithdrawalFailEvent(msg.sender, "Not enough eth to withdraw.");
            return false;
        }
        if (withdrawBal <= amount) {
            emit WithdrawalFailEvent(msg.sender, "Not enough eth to withdraw.");
            return false;
        }
        payable(msg.sender).transfer(amount - membershipWithdrawalFee);
        membershipBalances[msg.sender] -= amount;
        emit WithdrawalEvent(msg.sender, amount - membershipWithdrawalFee);
        return true;
    }

    /**
    * @dev Allow users to withdraw all funds to their wallet.
    * @return true if successful withdrawal
    */
    function withdrawAll() onlyWhitelisted public payable returns (bool) {
        uint256 withdrawAmount = membershipBalances[msg.sender];
        if (withdrawAmount <= membershipWithdrawalFee) {
            emit WithdrawalFailEvent(msg.sender, "Not enough eth to withdraw.");
            return false;
        }
        payable(msg.sender).transfer(withdrawAmount - membershipWithdrawalFee);
        membershipBalances[msg.sender] -= withdrawAmount;
        emit WithdrawalEvent(msg.sender, withdrawAmount - membershipWithdrawalFee);
        return true;
    }

    // **** Central Banking functions **** 

    /**
    * @dev Gets all balances of all members..
    * @return Two lists, one with member addresses and the other with balances.
    */
    function getMembersBalances() public view returns (address[] memory, uint256[] memory) {
        address[] memory membersArr;
        uint256[] memory balancesArr;
        for (uint256 i = 0; i < members.length; i++) {
             // Return their investment
             membersArr[i] = members[i];
             balancesArr[i] = membershipBalances[members[i]];
        }    
        return (membersArr, balancesArr);
    }

    /**
    * @dev Gets balances of a specific members.
    * @param addr Address of member to get balance of.
    */
    function getMemberBalances(address addr) public view returns (uint256) {
        return membershipBalances[addr];
    }

    /**
    * @dev Gets our members.
    * @return List of member addresses.
    */
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    /**
    * @dev Gets total balance in our contract. 
    * @return uint256 in member account balance.
    */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // **** Owner / Administrative functions **** 
    
    /**
    * @dev Return investments back to users. Removes them from our membership.
    * @param addrs Users to return investments to and remove from memberships
    * @param fee A fee can be set to subtract from user balancess on withdrawl
    */
    function returnInvestmentsRevokeMemberships(
        address[] memory addrs, 
        uint256 fee
        )
        public onlyOwner
        {
        for (uint256 i = 0; i < addrs.length; i++) {
             // Return their investment
            payable(addrs[i]).transfer(membershipBalances[addrs[i]] - fee);
            membershipBalances[addrs[i]] = 0;
            emit WithdrawalEvent(addrs[i], membershipBalances[addrs[i]] - fee);
        }
        _removeMembers(addrs);
    }

    /**
    * @dev Return investments back to all users. Removes them from our membership.
    * @param fee A fee can be set to subtract from user balancess on withdrawl
    */
    function returnInvestmentsAllRevokeMemberships(uint256 fee) public onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            // Return their investment
            payable(members[i]).transfer(membershipBalances[members[i]] - fee);
            emit WithdrawalEvent(members[i], membershipBalances[members[i]] - fee);
            membershipBalances[members[i]] = 0;
        }
        _removeMembers(members);
    }

    /**
    * @dev Return investments back to users. Keeps memberships.
    * @param addrs Users to return investments to
    * @param fee A fee can be set to subtract from user balancess on withdrawl
    */
    function returnInvestmentsKeepMemberships(
        address[] memory addrs, 
        uint256 fee
        )
        public onlyOwner
        {
        for (uint256 i = 0; i < addrs.length; i++) {
            // Return their investments - initial membership to keep being a member
            payable(addrs[i]).transfer(membershipBalances[addrs[i]] - fee);
            membershipBalances[addrs[i]] = 0;
            emit WithdrawalEvent(addrs[i], membershipBalances[addrs[i]] - fee);
        }
    }

    /**
    * @dev Return investments back to all users. Keeps memberships.
    * @param fee A fee can be set to subtract from user balancess on withdrawl
    */
    function returnInvestmentsAllKeepMemberships(uint256 fee) public onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
             // Return their investments - initial membership fee to keep being a member
            payable(members[i]).transfer(membershipBalances[members[i]] - fee);
            emit WithdrawalEvent(members[i], membershipBalances[members[i]]);
            membershipBalances[members[i]] = 0;
        }
    }

    /**
    * @dev Owner can fund wETH into contract.
    */
    function depositOwner(uint256 amount) public payable onlyOwner {
        require(msg.value == amount);
        emit DepositEvent(msg.sender, msg.value);
    }

    /**
    * @dev Owner can withdraw wETH into contract.
    */
    function withdrawOwner() onlyOwner public payable {
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawalEvent(msg.sender, address(this).balance);
    }

    /**
    * @dev Returns all investments to members and revokes membership.
           Transfers remaining eth to contract owner.
    */
    function withdrawAndReturnInvestmentsAndRevokeMemberships() onlyOwner public payable {
        returnInvestmentsAllRevokeMemberships(membershipWithdrawalFee);
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawalEvent(msg.sender, address(this).balance);
    }

    /**
    * @dev Returns all investments to members without revoking membership.
           Transfers remaining eth to contract owner.
    */
    function withdrawAndReturnInvestments() onlyOwner public payable {
        returnInvestmentsAllKeepMemberships(membershipWithdrawalFee);
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawalEvent(msg.sender, address(this).balance);
    }

    /**
    * @dev Emergency transfer for tokens from contract to owner.
           If someone accidentally asends the contract tokens we 
           can return to them.
    * @param tokens Tokens to withdraw.
    */
    function withdrawTokens(address[] memory tokens) onlyOwner public payable {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            token.transfer(msg.sender, balance);
            emit WithdrawalEvent(msg.sender, balance);
        }
    }

    // **** Utils **** 

    /**
    * @dev Removes account balance from the user.
    * @param addr Address to filter and remove.
    */
    function _removeMembershipBalance(address addr) private {
        bool found = false;
        for (uint i = 0; i <= members.length; i++) {
            if (addr == members[i]) {
                found = true;
                membershipBalances[addr] = 0;
                break;
            } else {
                continue;
            }
        }
    }
}