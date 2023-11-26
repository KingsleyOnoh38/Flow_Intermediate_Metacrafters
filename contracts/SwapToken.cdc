import FungibleToken from 0x01
import FlowToken from 0x01
import  WofiToken from 0x01

// SwapToken contract: Facilitates token swapping between  WofiToken and FlowToken
pub contract SwapToken {

    // Store the last swap timestamp for the contract
    pub var lastSwapTimestamp: UFix64
    // Store the last swap timestamp for each user
    pub var userLastSwapTimestamps: {Address: UFix64}

    // Function to swap tokens between  WofiToken and FlowToken
    pub fun swapTokens(signer: AuthAccount, swapAmount: UFix64) {

        // Borrow  WofiToken and FlowToken vaults from the signer's storage
        let WofiTokenVault = signer.borrow<& WofiToken.Vault>(from: /storage/VaultStorage)
            ?? panic("Could not borrow  WofiToken Vault from signer")

        let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/FlowVault)
            ?? panic("Could not borrow FlowToken Vault from signer")  

        // Borrow Minter capability from  WofiToken
        let minterRef = signer.getCapability<& WofiToken.Minter>(/public/Minter).borrow()
            ?? panic("Could not borrow reference to  WofiToken Minter")

        // Borrow FlowToken vault capability for receiving tokens
        let autherVault = signer.getCapability<&FlowToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, FungibleToken.Provider}>(/public/FlowVault).borrow()
            ?? panic("Could not borrow reference to FlowToken Vault")  

        // Withdraw tokens from FlowVault and deposit to autherVault
        let withdrawnAmount <- flowVault.withdraw(amount: swapAmount)
        autherVault.deposit(from: <-withdrawnAmount)
        
        // Get the signer's address and current timestamp
        let userAddress = signer.address
        self.lastSwapTimestamp = self.userLastSwapTimestamps[userAddress] ?? 1.0
        let currentTime = getCurrentBlock().timestamp

        // Calculate time since the last swap and minted token amount
        let timeSinceLastSwap = currentTime - self.lastSwapTimestamp
        let mintedAmount = 2.0 * UFix64(timeSinceLastSwap)

        // Mint new WofiTokens and deposit them to the vault
        let newWofiTokenVault <- minterRef.mintToken(amount: mintedAmount)
        WofiTokenVault.deposit(from: <-newWofiTokenVault)

        // Update the user's last swap timestamp
        self.userLastSwapTimestamps[userAddress] = timeSinceLastSwap
    }

    // Initialize the contract
    init() {
        // Set default values for last swap timestamp
        self.lastSwapTimestamp = 1.0
        self.userLastSwapTimestamps = {0x01: 1.0}
    }
}
