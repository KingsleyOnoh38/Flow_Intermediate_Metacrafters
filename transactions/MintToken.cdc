import FungibleToken from 0x05
import WofiToken from 0x05

transaction (receiver: Address, amount: UFix64) {

    prepare (signer: AuthAccount) {
        // Borrow the WofiToken admin reference
        let minter = signer.borrow<&WofiToken.Admin>(from: WofiToken.AdminStorage)
        ?? panic("You are not the WofiToken admin")

        // Borrow the receiver's WofiToken Vault capability
        let receiverVault = getAccount(receiver)
            .getCapability<&WofiToken.Vault{FungibleToken.Receiver}>(/public/Vault)
            .borrow()
        ?? panic("Error: Check your WofiToken Vault status")
    }

    execute {
        // Mint WofiTokens using the admin minter reference
        let mintedTokens <- minter.mint(amount: amount)

        // Deposit minted tokens into the receiver's WofiToken Vault
        receiverVault.deposit(from: <-mintedTokens)

        log("Minted and deposited Uhanmi tokens successfully")
        log(amount.toString().concat(" Tokens minted and deposited"))
    }
}
