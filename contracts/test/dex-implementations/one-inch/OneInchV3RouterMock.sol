// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title The OneInchV3RouterMock: a OneInchV3 router mock contract.
 * @notice The OneInchV3RouterMock contract allows to mock
 * the behaviour of the 1Inch v3 router.
 * Swaps only one pair, specified in contract deploy, with
 * a specified ratio.
 * @author Alessandro Sanino (@saniales)
 */
contract OneInchV3RouterMock {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @notice The description of a 1Inch swap.
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
     * @notice The description of a 1Inch swap call.
     */
    struct OneInchSwapCallDescription {
        uint256 targetWithMandatory;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    /**
     * @notice The base/source token.
     */
    IERC20 public immutable TEST_TOKEN_BASE;

    /**
     * @notice The quote/destination token.
     */
    IERC20 public immutable TEST_TOKEN_QUOTE;

    /**
     * @notice The swap ratio between base and quote tokens.
     * 1 TEST_TOKEN_QUOTE = X TEST_TOKEN_BASE
     */
    uint256 public immutable TEST_SWAP_FIXED_RATIO;

    /**
     * @notice Creates a new instance of the mock router for 1Inch dex.
     * @param _testTokenBase The base/source token.
     * @param _testTokenQuote The quote/destination token.
     * @param _testSwapFixedRatio The swap ratio between base and quote tokens.
     */
    constructor(
        IERC20 _testTokenBase,
        IERC20 _testTokenQuote,
        uint256 _testSwapFixedRatio
    ) {
        TEST_TOKEN_BASE = _testTokenBase;
        TEST_TOKEN_QUOTE = _testTokenQuote;
        TEST_SWAP_FIXED_RATIO = _testSwapFixedRatio;
    }

    /**
     * @notice swap mocks the 1Inch router swap function.
     * @param caller See info about it on 1InchRouter contract.
     * @param desc See info about it on 1InchRouter contract.
     * @param data See info about it on 1InchRouter contract.
     * @return returnAmount The swapped amount of destination token.
     */
    function swap(
        address caller,
        OneInchSwapDescription calldata desc,
        bytes calldata data
     ) external returns (uint256, uint256) {
        require(caller != address(0), "In mock calls you must not set this to 0");
        require(data.length > 0, "In mock calls data length must be > 0");

        require(desc.srcToken == TEST_TOKEN_BASE, "Base must be srcToken");
        require(desc.dstToken == TEST_TOKEN_QUOTE, "Quote must be dstToken");
        require(desc.amount > 0, "Amount must be > 0");
        
        // fakes the swap, simply transfers using ratio, assuming to have coins in balance
        uint256 transferAmount = desc.amount.mul(TEST_SWAP_FIXED_RATIO);
        require(TEST_TOKEN_QUOTE.balanceOf(address(this)) > transferAmount, "Must be able to fake the swap, be sure to deposit in tests");

        TEST_TOKEN_QUOTE.safeTransfer(msg.sender, transferAmount);

        return (transferAmount, 9999999);
    }
}