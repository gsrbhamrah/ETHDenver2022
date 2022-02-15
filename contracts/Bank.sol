// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Coin.sol";
import "./Debt.sol";

contract Bank {

  IERC20 public collateral;
  IERC20 public coin;
  IERC20 public debt;

  //add mappings
  mapping(address => uint) public collateralBalanceOf;
  mapping(address => uint) public depositStart;

  //add events
  event Deposit (
    address indexed user,
    uint256 amount
  );
  event Withdraw (
    address indexed user,
    uint256 amount
  );
  /*event Borrow (
    address indexed user, 
    uint256 collateralEtherAmount, 
    uint256 borrowedTokenAmount
  );
  event PayOff (
    address indexed user,
    uint256 interest
  );*/

  // dai collateral
  constructor(IERC20 _collateral, IERC20 _coin, IERC20 _debt) {
    collateral = _collateral; 
    coin = _coin;
    debt = _debt;
  }

  // user must first approve collateral, collateral.approve(bank, amount)
  // 1 dai = 1000000000000000000 amount
  function deposit(uint256 amount) public {
    //check if msg.value is >= than 1 token
    require(amount >= 1 ether, 'Error, deposit must be >= 1');

    // transfer collateral
    collateral.transferFrom(msg.sender, address(this), amount);

    // record balance
    collateralBalanceOf[msg.sender] = collateralBalanceOf[msg.sender] + amount;

    //emit Deposit event
    emit Deposit(msg.sender, amount);
  }

  function withdraw(uint256 amount) public {
    // make sure user does not withdraw too much
    require(amount <= collateralBalanceOf(msg.sender), 'Error, cannot withdraw more than deposited');
    
    // assign msg.sender ether deposit balance to variable for event
    uint256 remainingBalance = collateralBalanceOf[msg.sender] - amount;

    // send collateral back to user
    collateral.transfer(msg.sender, amount);

    // update balance
    collateralBalanceOf[msg.sender] = remainingBalance;
    
    emit Withdraw(msg.sender, remainingBalance);
  }

  /*function borrow() payable public {
    //check if collateral is >= than 0.01 ETH
    require(msg.value >= 1e16, 'Error, collateral must be >= 0.01 ETH');
    //check if user doesn't have active loan
    require(isBorrowed[msg.sender] == false, 'Error, loan already taken');

    //add msg.value to ether collateral (locked until loan payed off)
    collateralEther[msg.sender] = collateralEther[msg.sender] + msg.value;

    //calc tokens amount to mint, 50% of msg.value
    uint tokensToMint = collateralEther[msg.sender] / 2;

    //mint&send tokens to user
    token.mint(msg.sender, tokensToMint);

    //activate borrower's loan status
    isBorrowed[msg.sender] = true;

    //emit event
    emit Borrow(msg.sender, collateralEther[msg.sender], tokensToMint);
  }*/

  /*function payOff() public {
    //check if loan is active
    require(isBorrowed[msg.sender] == true, 'Error, loan not active');
    //transfer tokens from user back to the contract
    require(token.transferFrom(msg.sender, address(this), collateralEther[msg.sender] / 2), "Error, can't receive tokens"); //must approve Bank 1st

    //calc fee
    uint fee = collateralEther[msg.sender] / 8; //calc 12.5% fee
 
    //send user's collateral minus fee
    msg.sender.transfer(collateralEther[msg.sender] - fee);

    //reset borrower's data
    collateralEther[msg.sender] = 0;
    isBorrowed[msg.sender] = false;

    //emit event
    emit PayOff(msg.sender, fee);
  }*/
}