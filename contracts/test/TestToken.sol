// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This is the definition of basic ERC20 token for tests.
 * @author Alessandro Sanino (@saniales)
 */
contract TestToken is ERC20 {
    /**
     * @notice Creates a new instance of the ERC20 Test Token contract and
     *      performs the minting of the tokens to the vaults specified in
     *      the whitepaper.
     * @param _maxSupply The token max supply.
     */
    constructor(uint256 _maxSupply) ERC20("Tryvium Token", "TRYV") {
        _mint(msg.sender, _maxSupply);
    }
}
