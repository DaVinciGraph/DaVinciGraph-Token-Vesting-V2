// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

/**
 * @title Structs Library
 * @notice This library defines the data structures used throughout the DaVinciGraph vesting contract for managing
 *         vesting schedules and beneficiaries.
 * @dev These structs help standardize the representation of vesting schedules and beneficiaries, ensuring
 *      consistent data handling across contracts that import this library.
 */
library Structs {

    /**
     * @notice Represents the details of a vesting schedule for a specific beneficiary.
     * @dev This struct is used to track the key attributes of a vesting schedule, including time periods,
     *      amounts, and the progress of claimed tokens.
     * @param start The timestamp indicating when the vesting schedule starts.
     * @param vestingDuration The total duration of the vesting period, expressed in seconds.
     * @param cycleDuration The duration of each vesting cycle, expressed in seconds.
     * @param cliffDuration The duration of the initial cliff period before any tokens are vested, expressed in seconds.
     * @param totalAmount The total amount of tokens allocated for vesting, expressed as an `int64`.
     * @param cliffAmount The amount of tokens released at the end of the cliff period, expressed as an `int64`.
     * @param claimedAmount The total amount of tokens that have already been claimed, expressed as an `int64`.
     */
    struct Schedule {
        int64 start;
        int64 vestingDuration;
        int64 cycleDuration;
        int64 cliffDuration;
        int64 totalAmount;
        int64 cliffAmount;
        int64 claimedAmount;
    }

    /**
     * @notice Represents a beneficiary of a vesting schedule with key allocation details.
     * @dev This struct is used to define basic information about the beneficiary and their vesting allocation.
     * @param beneficiary The address of the beneficiary who will receive the vested tokens.
     * @param totalAmount The total amount of tokens allocated to the beneficiary, expressed as an `int64`.
     * @param cliffAmount The amount of tokens allocated to be released at the end of the cliff period, expressed as an `int64`.
     */
    struct ScheduleBeneficiary {
        address beneficiary;
        int64 totalAmount;
        int64 cliffAmount;
    }
}
