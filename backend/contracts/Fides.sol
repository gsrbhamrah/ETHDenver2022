// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Fides is ERC20 {

    address private _bank;

    modifier onlyBank {
        require(msg.sender == _bank);
        _;
    }
 
    constructor(address bank_) ERC20("Fides dollar osculating borrowing token", "FIDES") {

        _bank = bank_;
    }


    /* * * * * * * * * * * * * * * BANK ONLY FUNCTIONS * * * * * * * * * * * * * * */

    /*
    * the bank will mint itself tokens when:
    *   collateral is deposited
    */
    function mint(uint256 amount) public onlyBank {
        
        _mint(_bank, amount); // erc20 mint
    }

    /*
    * the bank will burn its tokens when:
    *  collateral is withdrawn
    *  undercollateralized debt + interest is repayed
    */
    function burn(uint256 amount) public onlyBank {
        
        _burn(_bank, amount); //erc20 burn
    }

    /* * * * * * * * * * * * * * * GASLESS VIEW FUNCTIONS * * * * * * * * * * * * * * */

    function bank() external view returns(address) {
        
        return _bank;
    }
}

    