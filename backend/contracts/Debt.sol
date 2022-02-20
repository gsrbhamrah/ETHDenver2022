// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Debt is ERC20, Ownable {

    address[] private _banks;

    modifier onlyBanks {
        bool isBank = false;
        for (uint256 i = 0; i < _banks.length(); i++) {
            if (_banks[i] == msg.sender) {
                isBank = true;
            }
        }
        require(isBank);
        _;
    }
 
    constructor() ERC20("Universal tokenized debt", "DEBT") {}

    function addBank(address bank) public OnlyOwner {

        _banks.add(bank);
    }

    /* * * * * * * * * * * * * * * BANK ONLY FUNCTIONS * * * * * * * * * * * * * * */

    /*
    * the bank will mint tokens to a debtor when:
    *   the debtor borrows more tokens then their deposited collateral
    */
    function mint(address debtor, uint256 amount) public onlyBanks {
        
        _mint(debtor, amount); // erc20 mint
    }

    /*
    * the bank will burn a debtors tokens when:
    *   the debtor repays any tokens that were borrowed beyond their collateral amount
    */
    function burn(address debtor, uint256 amount) public onlyBanks {
        
        _burn(debtor, amount); // erc20 burn
    }

    /* * * * * * * * * * * * * * * OVERRIDDEN FUNCTIONS * * * * * * * * * * * * * * */

    function transfer(address to, uint256 amount) public virtual override returns (bool) {

        return false;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {       

        return false;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {

        return false;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {

        return false;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {

        return false;
    }

    /* * * * * * * * * * * * * * * GASLESS VIEW FUNCTIONS * * * * * * * * * * * * * * */

    function banks() external view returns(address[]) {
        
        return _banks;
    }
}