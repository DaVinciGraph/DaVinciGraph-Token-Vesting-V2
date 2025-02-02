// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./SafeHTS.sol";
import "../libraries/SafeCast.sol";

/**
 * @title HederaHelpers Library
 * @notice This library provides helper functions for interacting with the Hedera Token Service (HTS).
 *         These functions abstract common, complex operations into reusable methods to simplify the main
 *         contract code and improve readability.
 * @dev The functions in this library ensure secure and efficient interactions with HTS, including token
 *      associations, transfers, and validation checks.
 */
library HederaHelpers {

    /**
     * @notice Associates a fungible token with the contract.
     * @param token The address of the token to be associated.
     * @dev This function verifies that the token is valid and fungible before associating it with the
     *      contract. It uses the `SafeHTS` library to ensure the association is securely processed.
     *      Emits a `TokenAssociated` event upon successful association.It also prevents the association
     *      of tokens with custom fees.
     */
    function associateFungibleToken(address token) internal {
        require(token != address(0), "Token address must be provided");
        require(SafeHTS.safeGetTokenType(token) == 0, "Only fungible tokens are allowed");
        revertOnTokensWithCustomFees(token);
        SafeHTS.safeAssociateToken(token, address(this));
    }

    /**
     * @notice Prevents the withdrawal of tokens with custom fee structures.
     * @param token The address of the token to check.
     * @dev This function ensures that only tokens without custom fees are withdrawn from the contract.
     *      Custom fees could potentially drain the contract's token balance, posing a risk to users.
     *      The function checks for fixed, fractional, and royalty fees and reverts if any are present.
     *      This is just a reassurance check to make trust between contract owners and users that no token with custom fees ever get the chance, 
     *      even if they are associated to the contract by mistake
     */
    function revertOnTokensWithCustomFees(address token) internal {
        // Retrieve the custom fee schedules for the token
        (IHederaTokenService.FixedFee[] memory fixedFees, IHederaTokenService.FractionalFee[] memory fractionalFees, IHederaTokenService.RoyaltyFee[] memory royaltyFees) = SafeHTS.safeGetTokenCustomFees(token);

        // Revert if the token has any type of custom fees
        require(fixedFees.length == 0 && fractionalFees.length == 0 && royaltyFees.length == 0, "Tokens with custom fees are not supported");
    }

    /**
     * @notice Transfers HBAR securely between two accounts.
     * @param sender The address of the account sending the HBAR.
     * @param receiver The address of the account receiving the HBAR.
     * @param amount The amount of HBAR to transfer, expressed as an `int64`.
     * @dev The function ensures the sender has a sufficient balance before initiating the transfer.
     *      It constructs a transfer list and uses the `SafeHTS` library to process the transfer securely.
     */
    function safeTransferHBAR(address sender, address receiver, int64 amount) internal {
        // Check that the sender has enough balance to cover the transfer amount
        require(SafeCast.toInt64(sender.balance) >= amount, "Sender doesn't have enough HBAR");

        // Create the transfer list with sender and receiver details
        IHederaTokenService.AccountAmount[] memory accountAmounts = new IHederaTokenService.AccountAmount[](2);
        accountAmounts[0] = IHederaTokenService.AccountAmount({
            accountID: sender,
            amount: -amount,
            isApproval: true
        });

        accountAmounts[1] = IHederaTokenService.AccountAmount({
            accountID: receiver,
            amount: amount,
            isApproval: true
        });

        // Execute the transfer using SafeHTS
        SafeHTS.safeCryptoTransfer(IHederaTokenService.TransferList({ transfers: accountAmounts }), new IHederaTokenService.TokenTransferList[](0));
    }
}