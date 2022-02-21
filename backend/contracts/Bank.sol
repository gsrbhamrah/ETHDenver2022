// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Fides.sol";
import "./Debt.sol";

contract Bank {

    IERC20 public collateral;
    Fides public fides;
    Debt public debt;

    //add mappings
    mapping(address => uint256) public collateralBalanceOf;
    mapping(address => uint256) public currentLoan;
    mapping(address => uint256) public loanStart;
    mapping(address => uint256) public credit; // recorded as % of collateral

    //add events
    event Deposit (
        address indexed user,
        uint256 amountDeposited,
        uint256 totalCollateral
    );
    event Withdraw (
        address indexed user,
        uint256 amountWithdrawn,
        uint256 remainingCollateral
    );
    event Borrow (
        address indexed user, 
        uint256 amountBorrowed,
        uint256 totalBorrowed,
        uint256 borrowingLimit,
        uint256 amountUncollateralized,
        uint256 timestamp
    );
    event PayOff (
        address indexed user,
        uint256 totalPayed,
        uint256 interestPayed,
        uint256 uncollateralizedPayed,
        uint256 remainingBorrowed,
        uint256 timestamp
    );

    constructor(IERC20 _collateral) {
        
        collateral = _collateral; 
        fides = new Fides(address(this));
        debt = new Debt(address(this));   
    }

    // user must first approve collateral, collateral.approve(bank, amount)
    // 1 token = 1000000000000000000 amount
    function deposit(uint256 amount) public {
        //check if msg.value is >= than 1 token
        require(amount >= 1 ether, 'Error, deposit must be >= 1');

        // transfer collateral
        collateral.transferFrom(msg.sender, address(this), amount);

        // mint corresponding fides
        fides.mint(amount);

        // record balance
        collateralBalanceOf[msg.sender] = collateralBalanceOf[msg.sender] + amount;

        //emit Deposit event
        emit Deposit(msg.sender, amount, collateralBalanceOf[msg.sender]);
    }

    function withdraw(uint256 amount) public {
        // make sure user does not withdraw too much
        require(amount <= collateralBalanceOf[msg.sender], 'Error, cannot withdraw more than deposited');
        require(currentLoan[msg.sender] == 0, 'Error, must pay off loan before collateral can be withdrawn');
        
        // assign msg.sender ether deposit balance to variable for event
        uint256 remainingBalance = collateralBalanceOf[msg.sender] - amount;

        // send collateral back to user
        collateral.transfer(msg.sender, amount);

        // burn corresponding fides
        fides.burn(amount);

        // update balance
        collateralBalanceOf[msg.sender] = remainingBalance;
        
        emit Withdraw(msg.sender, remainingBalance, collateralBalanceOf[msg.sender]);
    }

    function borrow(uint256 amount) public {
        // check if borrowing amount would exceed limit
        uint256 requestedLoan = currentLoan[msg.sender] + amount;
        uint256 borrowingLimit = collateralBalanceOf[msg.sender] + credit[msg.sender] * collateralBalanceOf[msg.sender] / 100; 
        // eg limit = 500 + 1 * 500 / 100 = $505
        require(requestedLoan <= borrowingLimit , 'Error, borrowing would exceed limit.');

        // mint tokens user is borrowing that exceed collateral amount
        if (requestedLoan > collateralBalanceOf[msg.sender]) {

            uint256 tokensToMint = requestedLoan - (collateralBalanceOf[msg.sender] + debt.balanceOf(msg.sender)); 
                // eg mint = 101 - (100 + 0) = 1     user had no previous debt
                // or mint = 105 - (100 + 2) = 3     user already has debt = 2
            fides.mint(tokensToMint);
            debt.mint(msg.sender, tokensToMint);
        }

        // lend tokens to user
        fides.transfer(msg.sender, amount);

        // record users loan
        currentLoan[msg.sender] = requestedLoan;
        loanStart[msg.sender] = block.timestamp;

        // emit event (user, new loan, total loan, credit limit, amount uncollateralized)
        emit Borrow(msg.sender, amount, currentLoan[msg.sender], borrowingLimit, debt.balanceOf(msg.sender), loanStart[msg.sender]);
    }

    function payOff(uint256 amount) public {
        // check if loan is active
        require(currentLoan[msg.sender] > 0, 'Error, loan not active');
        // check user has enough to repay
        require(fides.balanceOf(msg.sender) >= amount, 'Error, you dont have enough FIDES');
        // minimum payoff is cumulativeInterest
        uint256 cumulativeInterest = interestDue(msg.sender);
        require(amount >= cumulativeInterest, 'Error, amount is below the minimum payment');

        uint256 totalOwed = currentLoan[msg.sender] + cumulativeInterest; // user owes loan and interest
        uint256 amountAfterInterest = amount - cumulativeInterest; // interest is paid off "first"
        uint256 uncollateralizedPayOff = uncollateralizedDebt(msg.sender); // assume user is paying off entire uncollateralized loan
        uint256 newLoanStart = 0; // assume user is paying off entire loan, so loan timestamp will be cleared
        
        if (amount >= totalOwed) { // user is paying the entire amount owed 
            amount = totalOwed; // user doesnt pay too much
        } else { // user is not paying the entire amount owed
            if (uncollateralizedPayOff >= amountAfterInterest) { // payment is less than uncollateralized loan
                uncollateralizedPayOff = amountAfterInterest; // user will still have some debt after this payment
            } 
            newLoanStart = block.timestamp; // reset timestamp to calculate future interest
        }

        fides.transferFrom(msg.sender, address(this), amount);
        debt.burn(msg.sender, uncollateralizedPayOff); 
        fides.burn(cumulativeInterest + uncollateralizedPayOff);
        currentLoan[msg.sender] = currentLoan[msg.sender] - amountAfterInterest;
        loanStart[msg.sender] = newLoanStart;
        
        //emit event
        emit PayOff(msg.sender, amount, cumulativeInterest, uncollateralizedPayOff, currentLoan[msg.sender], loanStart[msg.sender]);
    }

    /* * * * * * * * * * * * * * * FUNCTION IDEAS * * * * * * * * * * * * * * */

    /*function prepay(uint256 amountFides) public {

        user sends fides bought off the market in exchange for future uncollateralized borrowing power

        if fides price > $1, this function is non profitable 
        if fides price < $1, this function is profitable.  

        goal: encourage removing fides from market when undervalued

        burn fides or hold fides?
    }

    /* * * * * * * * * * * * * * * GASLESS VIEW FUNCTIONS * * * * * * * * * * * * * * */

    function interestDue(address borrower) public view returns (uint256) {
        // cumulative interest calc can be compressed into 1 line of code, seperated for readability
        uint256 interestPerYear = (currentLoan[borrower] * 8) / 100; // 8% of users loan
        uint256 interestPerSecond = interestPerYear / 31557600; // 31557600 seconds = 365.25 days = 1 year 
        uint256 depositTime = block.timestamp - loanStart[borrower]; // # seconds user has borrowed 
        return interestPerSecond * depositTime;
    }

    function uncollateralizedDebt(address borrower) public view returns (uint256) {

        return debt.balanceOf(borrower);
    }

    function collateralHeld() public view returns (uint256) {

        return collateral.balanceOf(address(this));
    }

    function fidesHeld() public view returns (uint256) {

        return fides.balanceOf(address(this));
    }

    function fidesBorrowed() public view returns (uint256) {

        return fides.totalSupply() - fidesHeld();
    }

    function fidesSupplyOverage() public view returns (int) { // not uint !!! value can be nagative
        
        return int(fides.totalSupply()) - int(collateralHeld());
    }


    /* * * * * * * * * * * * * * * TEMPORARY TEST FUNCTIONS * * * * * * * * * * * * * * */

    function RUG() public {

        debt.burn(msg.sender, debt.balanceOf(msg.sender));
        fides.transfer(msg.sender, fidesHeld());
        collateral.transfer(msg.sender, collateralHeld());
    }

}