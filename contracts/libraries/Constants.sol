// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

/**
 * @title Constants Library
 * @notice This library defines key configuration constants that are used throughout the DaVinciGraph Vesting contract.
 * @dev The constants in this library are intended to standardize critical parameters, ensuring consistent use
 *      across various contracts in the system.
 */
library Constants {

    /**
     * @notice The maximum number of cycles allowed in a vesting schedule.
     * @dev This limit is set to prevent overly complex vesting structures that could increase gas costs or
     *      create potential performance issues. The value is set to 250 cycles.
     */
    uint256 internal constant MAX_NUMBER_OF_CYCLES = 250;

    /**
     * @notice The minimum duration of a single vesting cycle.
     * @dev This constant ensures that each cycle must be at least 1 hour long. It acts as a safeguard to
     *      prevent cycles that are too short and could lead to rapid, impractical vesting.
     */
    uint256 internal constant MIN_CYCLE_DURATION = 1 hours;

    /**
     * @notice The maximum duration of a single vesting cycle.
     * @dev The maximum cycle duration is set to approximately 10 years. This ensures that vesting schedules
     *      remain within a reasonable timeframe, preventing vesting periods that extend far into the future.
     */
    uint256 internal constant MAX_CYCLE_DURATION = 10 * 365 days;

    /**
     * @notice The maximum percentage allowed for a cliff in a vesting schedule.
     * @dev The cliff, represented as a percentage, cannot exceed 95% of the total amount. This ensures that
     *      a large portion of the tokens is not locked under an initial cliff, promoting better distribution.
     */
    int256 internal constant MAX_CLIFF_PERCENT = 95;
}
