// SPDX-License-Identifier: MIT

// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./SafeCast.sol";
import "./Structs.sol";

/**
 * @title Calculate Library
 * @notice This library provides essential calculation functions for determining the released and unclaimed amounts
 *         within a vesting schedule. These calculations support the logic needed for managing vesting processes.
 */
library Calculate {

    /**
     * @notice Computes the unclaimed amount available for withdrawal in a given vesting schedule.
     * @param schedule The vesting schedule to evaluate.
     * @return _unclaimedAmount The amount that is available for withdrawal, expressed as an `int64`.
     * @dev The function calculates the difference between the total released amount and the amount already claimed.
     *      If no unclaimed amount exists, the function reverts with an error message.
     */
    function unclaimedAmount(Structs.Schedule storage schedule) internal view returns (int64 _unclaimedAmount) {
        int64 _totalReleasedAmount = totalReleasedAmount(schedule);
        _unclaimedAmount = _totalReleasedAmount - schedule.claimedAmount;

        require(_unclaimedAmount > 0, "Nothing to claim");
        return _unclaimedAmount;
    }
    
    /**
     * @notice Computes the total amount that has been released so far for a given vesting schedule.
     * @param schedule The vesting schedule to evaluate.
     * @return The total released amount, expressed as an `int64`.
     * @dev This function handles various cases:
     *      - Returns zero if the current time is before the start plus the cliff duration.
     *      - Returns the full amount if the vesting duration has completed.
     *      - Calculates the released amount based on the elapsed cycles if within the vesting period.
     */
    function totalReleasedAmount(Structs.Schedule storage schedule) private view returns (int64) {
        int64 currentTimestamp = SafeCast.toInt64(block.timestamp);

        if (currentTimestamp < schedule.start + schedule.cliffDuration) {
            // Vesting has not started; no tokens are released yet.
            return 0;
        }
        
        if (currentTimestamp >= schedule.start + schedule.vestingDuration) {
            // Vesting has completed; release the total vested amount.
            return schedule.totalAmount; 
        }
        
        // Calculate the number of complete cycles that have passed after the cliff period.
        int64 elapsedCycles = (currentTimestamp - (schedule.start + schedule.cliffDuration)) / schedule.cycleDuration;

        // Calculate the total number of cycles between the end of the cliff and the end of vesting.
        int64 totalCycles = (schedule.vestingDuration - schedule.cliffDuration) / schedule.cycleDuration;

        // Calculate the amount vested per cycle.
        int64 vestedPerCycle = (schedule.totalAmount - schedule.cliffAmount) / totalCycles;

        // Return the cumulative amount released, which includes the cliff amount plus the total vested amount over the elapsed cycles.
        return schedule.cliffAmount + (elapsedCycles * vestedPerCycle);
    }
}
