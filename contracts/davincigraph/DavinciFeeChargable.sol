// SPDX-License-Identifier: MIT

// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

// Importing OpenZeppelin contracts for access control and security
import "../openzeppelin/Ownable.sol";
import "../openzeppelin/ReentrancyGuard.sol";

// Importing SafeHTS for secure interactions with the Hedera Token Service (HTS)
import "../hedera/SafeHTS.sol";

// Importing SafeCast contract for type conversion
import "../libraries/SafeCast.sol";

/**
 * @title DavinciFeeChargable
 * @dev This abstract contract enables inheriting contracts to use the DAVINCI token as the fee for operations. 
 * It is designed for use within the DaVinciGraph ecosystem, allowing contracts to charge and manage fees 
 * denominated in the native DAVINCI token. The contract ensures the safe handling of token transfers 
 * through Hedera's HTS.
 *
 * Key points for both developers and readers:
 * - **Objective**: This contract is primarily written to enable DaVinciGraph smart contracts to use the 
 *   DAVINCI token as the fee for their operations.
 * - **Immutability of Critical Addresses and Constants**: The `DAVINCI_ADDRESS` (address of the DAVINCI token), 
 *   `DAVINCI_TREASURY` (address of the treasury), and `MAX_FEE` (maximum allowed fee) are set as constants. 
 *   This guarantees they remain unchangeable throughout the contract's lifetime, ensuring the integrity of the 
 *   contract's interactions.
 * - **Fee Management**: The contract allows setting a fee during deployment, which must not exceed `MAX_FEE`. 
 *   This safeguard ensures that no excessively high fee can be applied.
 * - **Fee Collection**: Fees collected in DAVINCI tokens are securely transferred to the contract and tracked. 
 *   Collected fees can only be withdrawn to the `DAVINCI_TREASURY`.
 */
abstract contract DavinciFeeChargable is Ownable, ReentrancyGuard {
    // Address of the DAVINCI token (immutable)
    address public constant DAVINCI_ADDRESS = 0x0000000000000000000000000000000000388f0f;

    // Address of the treasury where all collected fees will be withdrawn (immutable)
    address public constant DAVINCI_TREASURY = 0x0000000000000000000000000000000000172Ad1;

    // The maximum allowed fee, set as a constant
    int64 public constant MAX_FEE = 200e9; // 200 DAVINcI

    // The fee for operations, denominated in DAVINCI tokens
    int64 public fee = 0;

    // Tracks the total collected fees, represented in DAVINCI token's smallest unit
    int64 public collectedFees = 0;

    /**
     * @dev Stores exemption status for accounts, mapping an account address to an exemption timestamp.
     *      - A value of `-1` indicates a permanent exemption.
     *      - A positive timestamp represents a temporary exemption until the specified time.
     *      - If no entry exists, the account is not exempt.
     */
    mapping(address => int64) public exemptAccounts;

    /**
     * @notice Initializes the contract with the initial fee.
     * @param _fee Initial fee for operations, set in DAVINCI tokens.
     * @dev Ensures that the initial fee does not exceed the constant `MAX_FEE`, exempts the contract owner from fees, 
     *      and associates the contract with the DAVINCI token via SafeHTS.
     */
    constructor(int64 _fee) {
        require(_fee <= MAX_FEE, "Fee exceeds maximum allowed.");
        fee = _fee;

        exemptAccount(msg.sender, -1);
        
        // Securely associates the contract with the DAVINCI token using Hedera's SafeHTS library
        SafeHTS.safeAssociateToken(DAVINCI_ADDRESS, address(this));
    }

    /**
     * @notice Charges a fee in DAVINCI tokens, unless the sender is exempt.
     * @param _fee The fee amount denominated in DAVINCI tokens to be charged.
     * @dev Internal function that first checks if `_fee` is greater than zero. If the sender is exempt (either permanently or temporarily), 
     *      the function returns without charging a fee. Otherwise, it securely transfers the token amount from the sender to this contract. 
     *      The total collected fees are updated accordingly.
     */
    function chargeFee(int64 _fee) internal {
        if (_fee <= 0) return;
        int64 senderExemption = exemptAccounts[msg.sender];
        bool isTempExempt = senderExemption >= SafeCast.toInt64(block.timestamp);

        if (senderExemption == -1 || isTempExempt) return;
        
        SafeHTS.safeTransferToken(DAVINCI_ADDRESS, msg.sender, address(this), _fee);
        collectedFees += _fee;
    }

    /**
     * @notice Charges a fee in DAVINCI tokens if the specified token is not DAVINCI.
     * @param _fee The fee amount denominated in DAVINCI tokens to be charged.
     * @param token The address of the token being used; if it is the DAVINCI token, no fee is charged.
     * @dev This internal function provides additional flexibility, enabling fees to be conditionally charged 
     *      based on the token used in the operation. If the specified `token` is not the DAVINCI token, it 
     *      calls the main `chargeFee` function with the given amount.
     */
    function chargeFee(int64 _fee, address token) internal {
        if (token == DAVINCI_ADDRESS) return;

        chargeFee(_fee);
    }

    /**
     * @notice Updates the fee for operations. Only callable by the contract owner.
     * @param _fee The new fee amount, denominated in DAVINCI tokens.
     * @dev The new fee must not exceed `MAX_FEE`, ensuring user protection against excessive fees.
     *      Emits a `FeeAmountUpdated` event upon a successful update.
     */
    function updateFee(int64 _fee) external onlyOwner {
        require(_fee <= MAX_FEE, "Fee exceeds maximum allowed.");
        require(_fee >= 0, "Invalid fee");
        
        fee = _fee;
        emit FeeAmountUpdated(_fee);
    }

    /**
     * @notice Withdraws collected fees to the treasury address.
     * @dev Uses the SafeHTS library for secure transfer and ensures the function is non-reentrant.
     *      Emits a `FeesWithdrawn` event upon successful withdrawal.
     */
    function withdrawFees() external nonReentrant {
        require(collectedFees > 0, "No fees have been collected");
        int64 _withdrawingFees = collectedFees;
        
        SafeHTS.safeTransferToken(DAVINCI_ADDRESS, address(this), DAVINCI_TREASURY, _withdrawingFees);
        collectedFees -= _withdrawingFees;
        
        emit FeesWithdrawn(DAVINCI_TREASURY, _withdrawingFees, DAVINCI_ADDRESS);
    }

    /**
     * @notice Exempts an account from paying fees either temporarily or permanently.
     * @param account The address of the account to be exempted from paying fees.
     * @param endOfExemptionTimestamp The timestamp until which the account is exempt from fees. 
     *                  Use `-1` for a permanent exemption, or a future timestamp for temporary exemption.
     * @dev Only callable by the contract owner. Ensures the account provided is valid (non-zero address).
     *      If a timestamp is provided, it must be greater than the current time.
     *      Emits an `AccountExempt` event upon successful exemption.
     */
    function exemptAccount(address account, int64 endOfExemptionTimestamp) public onlyOwner {
        require(account != address(0), "Account must be provided to exempt");
        require(endOfExemptionTimestamp == -1 || endOfExemptionTimestamp > SafeCast.toInt64(block.timestamp), "Incorrect Timestamp");

        exemptAccounts[account] = endOfExemptionTimestamp;

        emit AccountExempt(account, endOfExemptionTimestamp);
    }

    /**
     * @notice Revokes an exemption previously granted to an account.
     * @param account The address of the account for which the exemption is to be revoked.
     * @dev Only callable by the contract owner. Ensures the account is currently exempt (either 
     *      permanently or temporarily) before revocation. Emits an `ExemptionRevoked` event upon 
     *      successful revocation of the exemption.
     */
    function revokeExemption(address account) external onlyOwner {
        int64 exemptTimestamp = exemptAccounts[account];
        require(exemptTimestamp == -1 || exemptTimestamp > 0, "Account is not exempt");

        delete exemptAccounts[account];

        emit ExemptionRevoked(account);
    }
    
    /**
     * @notice Retrieves the exemption status of a specified account.
     * @param account The address of the account whose exemption status is being queried.
     * @return The exemption status as an `int64` value:
     *         - `-1`: The account is permanently exempt.
     *         - A positive timestamp: The account is temporarily exempt until the specified time.
     *         - `0` or absence of entry: The account is not exempt.
     * @dev This is a view-only function that allows external callers to check the exemption status of an account.
     */
    function getExemptAccount(address account) external view returns (int64) {
        return exemptAccounts[account];
    }
    
    // Event emitted when the fee amount is updated
    event FeeAmountUpdated(int64 newFee);
    
    // Event emitted when collected fees are withdrawn to the treasury
    event FeesWithdrawn(address indexed receiver, int64 amount, address indexed davinciAddress);

    // Event emitted when an account is exempted from paying fees
    event AccountExempt(address indexed account, int64 endOfExemptionTimestamp);
    
    // Event emitted when an account's exemption is revoked
    event ExemptionRevoked(address indexed account);
}
