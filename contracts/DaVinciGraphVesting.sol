// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./davincigraph/DavinciFeeChargable.sol";

import "./openzeppelin/Pausable.sol";

import "./hedera/SafeHTS.sol";
import "./hedera/Helpers.sol";

import "./libraries/SafeCast.sol";
import "./libraries/Structs.sol";
import "./libraries/Constants.sol";
import "./libraries/Validate.sol";
import "./libraries/Calculate.sol";

/**
 * @title DaVinciGraphTokenVesting
 * @notice This contract facilitates token vesting for beneficiaries with customizable schedules. It provides
 *         functionality to associate tokens, create vesting schedules, and withdraw released amounts.
 * @dev This contract inherits from `DavinciFeeChargable` to enable fee management and uses various libraries
 *      for modularity and reusability.
 */
contract DaVinciGraphTokenVesting is DavinciFeeChargable, Pausable {
    using SafeCast for uint256;
    address constant HBAR = address(0);

    // Mapping structure for tracking vesting schedules (token => creator => beneficiary => Schedule)
    mapping(address => mapping(address => mapping(address => Structs.Schedule))) public vestingSchedules;

    /**
     * @notice Initializes the vesting contract with a specified fee structure.
     * @param _fee The initial fee amount, denominated in tinycents.
     */
    constructor(int64 _fee) DavinciFeeChargable(_fee) {}

    /**
     * @notice Allows the contract to associate a new fungible token with the locker.
     * @param token The address of the token to be associated.
     * @dev HBAR (native token) does not require association, as it’s represented by `Zero Address`.
     */
    function associateToken(address token) external whenNotPaused {
        HederaHelpers.associateFungibleToken(token);
        
        emit TokenAssociated(token);
    }

    /**
     * @notice Adds a new vesting schedule for one or more beneficiaries.
     * @param token The address of the token involved in the vesting schedule.
     * @param beneficiaries An array of `ScheduleBeneficiary` structs specifying the beneficiaries and their allocations.
     * @param cycleDuration The duration of each vesting cycle, in seconds.
     * @param totalCycles The total number of vesting cycles.
     * @param cliffDuration The duration of the cliff period, in seconds.
     * @dev This function validates input data, stores vesting schedules, and charges a fee. The function is non-reentrant.
     */
    function createSchedules(
        address token, 
        Structs.ScheduleBeneficiary[] calldata beneficiaries, 
        uint256 cycleDuration, 
        uint256 totalCycles, 
        uint256 cliffDuration
    ) external nonReentrant whenNotPaused {
        Validate.commonAttributes(beneficiaries, cycleDuration, totalCycles, cliffDuration);
        int64 totalTransferingAmount = processNewVestingSchedules(token, beneficiaries, totalCycles, cycleDuration, cliffDuration);
        chargeFee(fee * beneficiaries.length.toInt64(), token);

        if (token == HBAR) {
            HederaHelpers.safeTransferHBAR(msg.sender, address(this), totalTransferingAmount);
        } else {
            SafeHTS.safeTransferToken(token, msg.sender, address(this), totalTransferingAmount);
        }
    }

    /**
     * @notice Withdraws the released amount for a beneficiary from a specific vesting schedule.
     * @param token The address of the token being withdrawn.
     * @param creator The address of the account that created the vesting schedule.
     * @param beneficiary The address of the account receiving the withdrawn tokens.
     * @dev This function validates the withdrawal, calculates the unclaimed amount, transfers the tokens,
     *      updates the claimed amount, and emits an appropriate event. The function is non-reentrant.
     */
    function withdrawUnclaimedAmount(
        address token, 
        address creator, 
        address beneficiary
    ) external nonReentrant {
        Validate.withdrawUnclaimedAmount(creator, beneficiary);
        Structs.Schedule storage schedule = vestingSchedules[token][creator][beneficiary];

        require(schedule.totalAmount > 0, "There is no vesting schedule with this data");
        chargeFee(fee / 10, token);

        int64 unclaimedAmount = Calculate.unclaimedAmount(schedule);
        transferUnclaimedAmount(token, beneficiary, unclaimedAmount);
        schedule.claimedAmount += unclaimedAmount;

        emitWithdrawEvent(schedule, token, creator, beneficiary, unclaimedAmount);
    }
    

    /**
     * @notice Pauses the contract, preventing association and schedule creation operations.
     * @dev Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, resuming association and schedule creation operations.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Retrieves a specific vesting schedule.
     * @param token The address of the token in the vesting schedule.
     * @param creator The address of the creator of the vesting schedule.
     * @param beneficiary The address of the beneficiary.
     * @return The vesting schedule as a `Structs.Schedule` struct.
     * @dev This function is `public` to allow users and other contracts to query vesting data.
     */
    function getSchedule(
        address token, 
        address creator, 
        address beneficiary
    ) public view returns (Structs.Schedule memory) {
        return vestingSchedules[token][creator][beneficiary];
    }

    /**
     * @notice Stores multiple vesting schedules for an array of beneficiaries.
     * @param token The address of the token.
     * @param beneficiaries An array of `ScheduleBeneficiary` structs.
     * @param totalCycles The total number of cycles in the vesting schedule.
     * @param cycleDuration The duration of each vesting cycle, in seconds.
     * @param cliffDuration The duration of the cliff period, in seconds.
     * @return The total amount to be transferred for all schedules.
     * @dev This function is `private` and supports `addSchedule` by storing the vesting data.
     */
    function processNewVestingSchedules(
        address token, 
        Structs.ScheduleBeneficiary[] calldata beneficiaries, 
        uint256 totalCycles, 
        uint256 cycleDuration, 
        uint256 cliffDuration
    ) private returns (int64) {
        uint256 vestingDuration = cliffDuration + (totalCycles * cycleDuration);

        if (beneficiaries.length == 1) {
            return storeVestingSchedule(token, beneficiaries[0], totalCycles, vestingDuration, cycleDuration, cliffDuration);
        }

        int64 wholeVestingAmount = 0;
        uint256 len = beneficiaries.length;
        for (uint i = 0; i < len; i++) {
            wholeVestingAmount += storeVestingSchedule(token, beneficiaries[i], totalCycles, vestingDuration, cycleDuration, cliffDuration);
        }

        return wholeVestingAmount;
    }

    /**
     * @notice Stores a single vesting schedule for a beneficiary.
     * @param token The address of the token.
     * @param beneficiaryData A `ScheduleBeneficiary` struct containing beneficiary details.
     * @param totalCycles The total number of cycles in the vesting schedule.
     * @param vestingDuration The total vesting duration, in seconds.
     * @param cycleDuration The duration of each vesting cycle, in seconds.
     * @param cliffDuration The duration of the cliff period, in seconds.
     * @return The total amount to be transferred for the schedule.
     * @dev This function validates the schedule and stores it. It emits a `ScheduleAdded` event upon success.
     */
    function storeVestingSchedule(
        address token, 
        Structs.ScheduleBeneficiary calldata beneficiaryData, 
        uint256 totalCycles, 
        uint256 vestingDuration, 
        uint256 cycleDuration, 
        uint256 cliffDuration
    ) private returns (int64) {
        Validate.specificAttributes(beneficiaryData.beneficiary, beneficiaryData.totalAmount, beneficiaryData.cliffAmount, totalCycles, cliffDuration);

        require(vestingSchedules[token][msg.sender][beneficiaryData.beneficiary].totalAmount == 0, "Vesting schedule already exists");

        vestingSchedules[token][msg.sender][beneficiaryData.beneficiary] = Structs.Schedule(
            block.timestamp.toInt64(), 
            vestingDuration.toInt64(), 
            cycleDuration.toInt64(), 
            cliffDuration.toInt64(), 
            beneficiaryData.totalAmount, 
            beneficiaryData.cliffAmount, 
            0
        );

        emit ScheduleCreated(
            msg.sender, 
            token, 
            beneficiaryData.beneficiary, 
            beneficiaryData.totalAmount, 
            vestingDuration, 
            cycleDuration, 
            cliffDuration, 
            beneficiaryData.cliffAmount
        );

        return beneficiaryData.totalAmount;
    }

    /**
     * @notice Transfers unclaimed tokens to a beneficiary.
     * @param token The address of the token.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount to transfer, expressed as `int64`.
     * @dev This function transfers the unclaimed amount and reverts if the transfer fails. It also ensures
     *      that tokens with custom fees are not withdrawn.
     */
    function transferUnclaimedAmount(
        address token, 
        address beneficiary, 
        int64 amount
    ) private {
        if (token == HBAR) {
            (bool success, ) = beneficiary.call{value: uint256(uint64(amount))}("");
            require(success, "Withdrawal failed.");
        } else {
            HederaHelpers.revertOnTokensWithCustomFees(token);
            SafeHTS.safeTransferToken(token, address(this), beneficiary, amount);
        }
    }

    /**
     * @notice Emits an event after a withdrawal operation.
     * @param schedule The vesting schedule associated with the withdrawal.
     * @param token The address of the token.
     * @param creator The address of the creator of the vesting schedule.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount withdrawn, expressed as `int64`.
     * @dev If the claimed amount equals or exceeds the total amount, the schedule is deleted and a `VestingEnded`
     *      event is emitted. Otherwise, an `UnclaimedAmountWithdrawn` event is emitted.
     */
    function emitWithdrawEvent(
        Structs.Schedule memory schedule,
        address token, 
        address creator, 
        address beneficiary, 
        int64 amount
    ) private {
        if (schedule.claimedAmount >= schedule.totalAmount) {
            delete vestingSchedules[token][creator][beneficiary];
            emit VestingEnded(creator, token, beneficiary, amount, msg.sender);
        } else {
            emit UnclaimedAmountWithdrawn(creator, token, beneficiary, amount, msg.sender);
        }
    }

    /**
     * @notice Retrieves core configuration constants.
     * @return maxNumberOfCycles The maximum number of allowed vesting cycles.
     * @return minCycleDuration The minimum duration of a vesting cycle, in seconds.
     * @return maxCycleDuration The maximum duration of a vesting cycle, in seconds.
     * @return maxCliffPercent The maximum allowed cliff percentage.
     * @dev This function provides access to constants that define operational limits and fees.
     */
    function getConfig()
        external
        pure
        returns (
            uint256 maxNumberOfCycles,
            uint256 minCycleDuration,
            uint256 maxCycleDuration,
            int256 maxCliffPercent
        )
    {
        return (
            Constants.MAX_NUMBER_OF_CYCLES,
            Constants.MIN_CYCLE_DURATION,
            Constants.MAX_CYCLE_DURATION,
            Constants.MAX_CLIFF_PERCENT
        );
    }

    /**
     * @notice Emitted when a token is associated with a contract.
     * @param token The address of the token that has been associated.
     * @dev This event helps track when a new token is linked with the contract, ensuring that external parties
     *      are aware of the token's association.
     */
    event TokenAssociated(address indexed token);

    /**
     * @notice Emitted when a new vesting schedule is added.
     * @param creator The address of the entity creating the vesting schedule.
     * @param token The address of the token involved in the vesting schedule.
     * @param beneficiary The address of the beneficiary who will receive the vested tokens.
     * @param amount The total amount of tokens to be vested.
     * @param vestingDuration The total duration of the vesting period (in seconds).
     * @param cycleDuration The duration of each vesting cycle (in seconds).
     * @param cliffDuration The duration of the initial cliff period (in seconds).
     * @param cliffAmount The amount of tokens released after the cliff period.
     * @dev This event ensures transparency in vesting operations, allowing users and developers to monitor
     *      the creation and structure of vesting schedules.
     */
    event ScheduleCreated(
        address indexed creator, 
        address indexed token, 
        address indexed beneficiary, 
        int64 amount, 
        uint256 vestingDuration, 
        uint256 cycleDuration, 
        uint256 cliffDuration, 
        int64 cliffAmount
    );

    /**
     * @notice Emitted when an amount is released to a beneficiary from a vesting schedule.
     * @param creator The address of the entity that created the vesting schedule.
     * @param token The address of the token being released.
     * @param beneficiary The address of the beneficiary receiving the released tokens.
     * @param amount The amount of tokens released in this specific transaction.
     * @dev This event is essential for tracking partial releases of tokens during the vesting process,
     *      ensuring beneficiaries and external observers can track the progress of their vesting schedules.
     */
    event UnclaimedAmountWithdrawn(
        address indexed creator, 
        address indexed token, 
        address indexed beneficiary,
        int64 amount,
        address actor
    );

    /**
     * @notice Emitted when a vesting schedule is completed and no more tokens remain to be released.
     * @param creator The address of the entity that created the vesting schedule.
     * @param token The address of the token involved in the vesting schedule.
     * @param beneficiary The address of the beneficiary who received the vested tokens.
     * @param amount The total amount of tokens released in the final transaction, marking the end of the vesting period.
     * @dev This event indicates the successful conclusion of a vesting schedule, providing a clear signal that
     *      the schedule has been fully executed.
     */
    event VestingEnded(
        address indexed creator, 
        address indexed token, 
        address indexed beneficiary, 
        int64 amount,
        address actor
    );
}
