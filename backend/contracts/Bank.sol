// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BorrowCoin.sol";
import "./DebtCoin.sol";

contract Bank {

  IERC20 public collateral;
  IERC20 public coin;
  IERC20 public debt;

  //add mappings
  mapping(address => uint256) public collateralBalanceOf;
  mapping(address => uint256) public currentLoan;
  mapping(address => uint256) public credit; // recorded as % of collateral

  //add events
  event Deposit (
    address indexed user,
    uint256 amount
  );
  event Withdraw (
    address indexed user,
    uint256 amount
  );
  event Borrow (
    address indexed user, 
    uint256 newLoan,
    uint256 totalLoan,
    uint256 creditLimit,
    uint256 totalUncollateralized
  );
  /*event PayOff (
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

  function borrow(uint256 amount) payable {
    // check if borrowing amount would exceed limit
    uint256 requestedLoan = currentLoan[msg.sender] + amount;
    uint256 borrowingLimit = collateralBalanceOf[msg.sender] + credit[msg.sender] * collateralBalanceOf[msg.sender] / 100; 
      // eg limit = 500 + 1 * 500 / 100 = $505
    require(requestedLoan <= borrowingLimit , 'Error, borrowing would exceed limit.');

    // mint tokens user is borrowing that exceed collateral amount
    if (requestedLoan > collateralBalanceOf[msg.sender]) {

      tokensToMint = requestedLoan - collateralBalanceOf[msg.sender] - debt.balanceOf(msg.sender); 
        // eg mint = 101 - 100 - 0 = 1     user had no previous debt
        // or mint = 105 - 100 - 2 = 3     user already has debt = 2
      coin.mint(tokensToMint);
      debt.mint(msg.sender, tokensToMint);
    }

    // lend tokens to user
    coin.transfer(msg.sender, amount);

    // record users loan
    currentLoan[msg.sender] = requestedLoan;

    //emit event (user, new loan, total loan, credit limit, amount uncollateralized)
    emit Borrow(msg.sender, amount, currentLoan[msg.sender], borrowingLimit, debt.balanceOf(msg.sender));
  }

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