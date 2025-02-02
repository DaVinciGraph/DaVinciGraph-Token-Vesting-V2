// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./Structs.sol";
import "./Constants.sol";
import "./SafeCast.sol";

/**
 * @title Validate Library
 * @notice This library provides validation functions to ensure that vesting schedules and withdrawal operations
 *         adhere to predefined rules and constraints. These checks prevent incorrect data and maintain the
 *         integrity of the system.
 * @dev The functions in this library help enforce input validation for vesting-related operations, ensuring
 *      that the contracts handle only valid data.
 */
library Validate {

    /**
     * @notice Validates the common input parameters for creating a batch of new vesting schedules.
     * @param beneficiaries An array of `ScheduleBeneficiary` structs representing the beneficiaries of the vesting schedules.
     * @param cycleDuration The duration of each vesting cycle, expressed in seconds.
     * @param totalCycles The total number of cycles in the vesting schedule.
     * @param cliffDuration The duration of the cliff period, expressed in seconds.
     * @dev Ensures that the number of cycles, duration of cycles, and the list of beneficiaries are within acceptable limits.
     *      Reverts with an appropriate error message if any of the conditions are not met.
     */
    function commonAttributes(
        Structs.ScheduleBeneficiary[] calldata beneficiaries,
        uint256 cycleDuration,
        uint256 totalCycles,
        uint256 cliffDuration
    ) internal pure {
        require(totalCycles <= Constants.MAX_NUMBER_OF_CYCLES, "Number of vesting iterations exceeds the limit of 250");
        require(totalCycles > 0, "Vesting duration must have at least one cycle");
        require(cycleDuration >= Constants.MIN_CYCLE_DURATION && cycleDuration <= Constants.MAX_CYCLE_DURATION, "Cycle duration must be between 1 hour to 10 years");
        require(beneficiaries.length > 0, "At least one beneficiary must be provided");
        require(beneficiaries.length <= 50, "The list of beneficiaries cannot be more than 50");
        require(cliffDuration <= Constants.MAX_CYCLE_DURATION, "Cliff exceeds max duration of 10 years");
    }

    /**
     * @notice Validates the input parameters for creating a single vesting schedule.
     * @param beneficiary The address of the beneficiary for the vesting schedule.
     * @param totalAmount The total amount of tokens allocated to the beneficiary, expressed as `int64`.
     * @param cliffAmount The amount of tokens released at the end of the cliff period, expressed as `int64`.
     * @param totalCycles The total number of cycles in the vesting schedule.
     * @param cliffDuration The duration of the cliff period, expressed in seconds.
     * @dev Checks that the beneficiary's address is valid, the cliff values are logically consistent, and the
     *      amount per cycle is at least 1 unit of the token. Reverts with an error if any validation fails.
     */
    function specificAttributes(
        address beneficiary,
        int64 totalAmount,
        int64 cliffAmount,
        uint256 totalCycles,
        uint256 cliffDuration
    ) internal pure {
        require(beneficiary != address(0), "Beneficiary address must be provided");
        require((cliffAmount == 0 && cliffDuration == 0) || (cliffAmount > 0 && cliffDuration > 0),"Cliff values are provided incorrectly");
        require(isCliffAmountValid(cliffAmount, totalAmount), "Cliff amount is more than the allowed limit");
        require(totalAmount - cliffAmount >= SafeCast.toInt64(totalCycles), "Each cycle must receive at least 1 unit of the token");
    }

    /**
     * @notice Validates input parameters for a withdrawal operation.
     * @param creator The address of the creator of the vesting schedule.
     * @param beneficiary The address of the beneficiary requesting the withdrawal.
     * @dev Ensures that neither the creator nor the beneficiary addresses are zero addresses. Reverts with
     *      an error if any validation fails.
     */
    function withdrawUnclaimedAmount(
        address creator,
        address beneficiary
    ) internal pure {
        require(creator != address(0), "Creator address must be provided");
        require(beneficiary != address(0), "Beneficiary address must be provided");
    }

    function isCliffAmountValid(int64 cliffAmount, int64 totalAmount) internal pure returns (bool) {
        return int256(cliffAmount) <= (int256(totalAmount) * Constants.MAX_CLIFF_PERCENT) / 100;
    }
}
