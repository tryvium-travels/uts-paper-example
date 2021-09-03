// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title The ITokenSwapper token interface.
 * @notice The ITokenSwapper defines the interface to allow
 * a contract to to leverage defi token swap mechanisms.
 * @author Alessandro Sanino (@saniales)
 */
abstract contract ITokenSwapper {
    /**
     * @notice _beforeSwap allows additional business logic before
     * the swap. 
     * @param _data the custom data to send to the router swap contract.
     */
    function _beforeSwap(bytes calldata _data) internal virtual {}
    
    /**
     * @notice The _swap method performs a token swap, based on the tx data,
     * which is sent to the router contract.
     * @param _data the custom data to send to the router swap contract.
     */
    function _swap(bytes calldata _data) internal virtual {}

    /**
     * @notice _afterSwap allows additional business logic after
     * the swap.
     * @param _data the custom data to send to the router swap contract.
     */
    function _afterSwap(bytes calldata _data) internal virtual {}
}
