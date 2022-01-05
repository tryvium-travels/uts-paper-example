// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./OneInchV3TokenSwapper.sol";

/**
 * @title The SimpleOneInchv3TokenSwapper token swapper.
 * @notice The SimpleOneInchV3TokenSwapper contract allows to leverage
 * the 1Inch dex aggregator to perform a swap and return swapped tokens
 * to the sender.
 * @author Alessandro Sanino (@saniales)
 */
contract SimpleOneInchV3TokenSwapper is OneInchV3TokenSwapper, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Creates a new instance of the SimpleOneInchV3TokenSwapper contract.
     * @param _aggregationRouterOneInch The address of the 1Inch router contract.
     * @param _destinationToken The destination token all token swaps must have.
     */
    constructor(address _aggregationRouterOneInch, IERC20 _destinationToken)
        OneInchV3TokenSwapper(_aggregationRouterOneInch, _destinationToken)
        Pausable()
        Ownable()
    {}

    /**
     * @notice The swap method performs a token swap, based on the tx data,
     * which is sent to the router contract.
     * @param _oneInchSwapData the tx.data object from the 1Inch API /swap call.
     */
    function swap(bytes calldata _oneInchSwapData) whenNotPaused external payable {
        _beforeSwap(_oneInchSwapData);
        _swap(_oneInchSwapData);
        _afterSwap(_oneInchSwapData);
    }

    /**
     * @notice _afterSwap allows additional business logic after
     * the swap.
     * @param _oneInchSwapData the custom data to send to the router swap contract.
     */
    function _afterSwap(bytes calldata _oneInchSwapData) internal override {
        uint256 returnAmount;
        
        bytes4 functionSignature = bytes4(_oneInchSwapData);
        if (functionSignature == ONE_INCH_SWAP_SIGNATURE) {
            (, OneInchSwapDescription memory desc, ) = abi.decode(_oneInchSwapData[4:], (address, OneInchSwapDescription, bytes));
            returnAmount = desc.minReturnAmount;
        } else if (functionSignature == ONE_INCH_UNOSWAP_SIGNATURE) {
            (, , uint256 minReturnAmount, ) = abi.decode(_oneInchSwapData[4:], (IERC20, uint256, uint256, bytes));
            returnAmount = minReturnAmount;
        } else {
            revert("Invalid function signature");
        }

        DESTINATION_TOKEN.safeTransfer(msg.sender, returnAmount);
    }

    /**
     * @notice pause stops the contract from working. Can be unpaused with
     * unpause() method.
     */
    function pause() whenNotPaused onlyOwner external {
        _pause();
    }

    /**
     * @notice unpause frees a paused contract, making it possible for it
     * to work again.
     */
    function unpause() whenPaused onlyOwner external {
        _unpause();
    }
}