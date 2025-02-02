// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

/**
 * @title SafeCast Library
 * @notice This library provides functions to safely cast between different numeric types in Solidity.
 * @dev Safe type conversion helps to prevent potential overflows or data loss when converting between
 *      larger and smaller data types. This library currently includes a function for converting a `uint256`
 *      value to an `int64` type safely.
 */
library SafeCast {

    /**
     * @notice Safely converts a `uint256` value to an `int64` value.
     * @param value The `uint256` value to be converted.
     * @return An `int64` representation of the input value.
     * @dev The function ensures that the input value fits within the range of an `int64` type (i.e., from
     *      -2^63 to 2^63 - 1). If the input value exceeds this range, the function reverts with an error.
     *      This check helps prevent data loss or overflow errors during conversion.
     */
    function toInt64(uint256 value) internal pure returns (int64) {
        // The maximum value that can be safely converted to int64
        uint256 maxInt64Value = 2 ** 63 - 1;

        // Ensure the input value does not exceed the maximum allowable value for int64
        require(value <= maxInt64Value, "Value out of int64 range");

        // Perform the conversion to int64
        return int64(uint64(value));
    }
}
