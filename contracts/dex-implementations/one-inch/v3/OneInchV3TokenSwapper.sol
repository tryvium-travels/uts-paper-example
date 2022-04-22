// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../ITokenSwapper.sol";

/**
 * @title The OneInchV3TokenSwapper token swapper.
 * @notice The OneInchV3TokenSwapper contract allows to leverage
 * the 1Inch dex aggregator.
 * @author Alessandro Sanino (@saniales)
 */
contract OneInchV3TokenSwapper is ITokenSwapper {
    using SafeERC20 for IERC20;

    /**
     * @notice The address of the 1Inch router contract.
     */
    address immutable AGGREGATION_ROUTER_ONE_INCH_V3;

    /**
     * @notice The destination token all token swaps must have.
     * Usually this is set to be a stable coin.
     */
    IERC20 immutable DESTINATION_TOKEN;

    /**
     * @notice The function signature of the 1inch swap function.
     */
    bytes4 internal constant ONE_INCH_SWAP_SIGNATURE = 0x7c025200;

    /**
     * @notice The function signature of the 1inch unoswap function.
     */
    bytes4 internal constant ONE_INCH_UNOSWAP_SIGNATURE = 0x2e95b6c8;
    
    /**
     * @notice The description of a 1Inch swap.
     * The data sent to the _swap function must be decoded
     * into this struct, along with other params.
     */
    struct OneInchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /**
     * @notice Creates a new instance of the OneInchV3TokenSwapper contract.
     * @param _aggregationRouterOneInch The address of the 1Inch router contract.
     * @param _destinationToken The destination token all token swaps must have.
     */
    constructor(address _aggregationRouterOneInch, IERC20 _destinationToken) {
        AGGREGATION_ROUTER_ONE_INCH_V3 = _aggregationRouterOneInch;
        DESTINATION_TOKEN = _destinationToken;
    }

    /**
     * @notice The _swap method performs a token swap, based on the tx data,
     * which is sent to the router contract.
     * Implements ITokenSwapper interface.
     * @param _oneInchSwapData The tx.data object from the 1Inch API /swap call.
     */
    function _swap(bytes calldata _oneInchSwapData) internal override {
        bytes4 functionSignature = bytes4(_oneInchSwapData);
        if (functionSignature == ONE_INCH_SWAP_SIGNATURE) {
            _swapUsingOneInchSwap(_oneInchSwapData);
        } else if (functionSignature == ONE_INCH_UNOSWAP_SIGNATURE) {
            _swapUsingOneInchUnoswap(_oneInchSwapData);
        } else {
            revert("Invalid function signature");
        }
    }

    function _swapUsingOneInchSwap(bytes calldata _oneInchSwapData) internal {
        (, OneInchSwapDescription memory desc,) = abi.decode(_oneInchSwapData[4:], (address, OneInchSwapDescription, bytes));

        desc.srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);

        // if srcToken and dstToken are the same, there is no need to swap, so I do not call 
        // the 1Inch contract at all.
        if (desc.srcToken != desc.dstToken && desc.dstToken == DESTINATION_TOKEN) {
            require(desc.srcToken.approve(AGGREGATION_ROUTER_ONE_INCH_V3, desc.amount), "OneInchV3TokenSwapper.swap: Must be able for the contract to approve transfer to the router");

            (bool callSuccess, bytes memory routerData) = address(AGGREGATION_ROUTER_ONE_INCH_V3).call(_oneInchSwapData);
            require(callSuccess, "OneInchV3TokenSwapper.swap: Must be able to call the aggregation router to perform the swap");

            (uint256 returnAmount, ) = abi.decode(routerData, (uint256, uint256));
            require(returnAmount >= desc.minReturnAmount, "OneInchV3TokenSwapper.swap: Must be able to swap at least minOut");
        }
    }

    function _swapUsingOneInchUnoswap(bytes calldata _oneInchSwapData) internal {
        (IERC20 srcToken, uint256 amount, uint256 minReturnAmount, ) = abi.decode(_oneInchSwapData[4:], (IERC20, uint256, uint256, bytes));

        srcToken.safeTransferFrom(msg.sender, address(this), amount);

        if (srcToken != DESTINATION_TOKEN) {
            require(srcToken.approve(AGGREGATION_ROUTER_ONE_INCH_V3, amount), "OneInchV3TokenSwapper.unoswap: Must be able for the contract to approve transfer to the router");

            uint256 balanceBeforeSwap = DESTINATION_TOKEN.balanceOf(address(this));

            (bool callSuccess, bytes memory routerData) = address(AGGREGATION_ROUTER_ONE_INCH_V3).call(_oneInchSwapData);
            require(callSuccess, "OneInchV3TokenSwapper.unoswap: Must be able to call the aggregation router to perform the unoswap");

            uint256 balanceAfterSwap = DESTINATION_TOKEN.balanceOf(address(this));
            require(balanceBeforeSwap < balanceAfterSwap, "OneInchV3TokenSwapper.unoswap: Balance of DESTINATION_TOKEN must be higher after the swap");

            (uint256 returnAmount) = abi.decode(routerData, (uint256));
            require(returnAmount >= minReturnAmount, "OneInchV3TokenSwapper.unoswap: Must be able to unoswap at least minOut");
        }
    }

    /**
     * @notice _beforeSwap allows additional business logic before
     * the swap.
     * The default implementation just checks that minimumReturnAmount > 0.
     * @param _oneInchSwapData the custom data to send to the router swap contract.
     */
    function _beforeSwap(bytes calldata _oneInchSwapData) internal override view {
        bytes4 functionSignature = bytes4(_oneInchSwapData);
        if (functionSignature == ONE_INCH_SWAP_SIGNATURE) {
            (, OneInchSwapDescription memory desc,) = abi.decode(_oneInchSwapData[4:], (address, OneInchSwapDescription, bytes));
            require(address(desc.dstToken) == address(DESTINATION_TOKEN), "OneInchV3TokenSwapper: Destination token must always be equal to the one specified in the contract");
            require(desc.srcReceiver == address(this), "OneInchV3TokenSwapper: data from 1Inch API must set this contract as source of the swap");
            require(desc.dstReceiver == address(this), "OneInchV3TokenSwapper: data from 1Inch API must set this contract as destination of the swap");
            require(desc.minReturnAmount > 0, "OneInchV3TokenSwapper: minimum return amount must be > 0");    
        } else if (functionSignature == ONE_INCH_UNOSWAP_SIGNATURE) {
            (, , uint256 minReturnAmount, ) = abi.decode(_oneInchSwapData[4:], (IERC20, uint256, uint256, bytes));
            require(minReturnAmount > 0, "OneInchV3TokenSwapper: minimum return amount must be > 0");
        } else {
            revert("Invalid function signature");
        }
    }
}
