import FungibleToken from 0x05
import WofiToken from 0x05

transaction(receiverAccount: Address, amount: UFix64) {

    // Define references
    let signerVault: &WofiToken.Vault
    let receiverVault: &WofiToken.Vault{FungibleToken.Receiver}

    prepare(acct: AuthAccount) {
        // Borrow references and handle errors
        self.signerVault = acct.borrow<&WofiToken.Vault>(from: /storage/VaultStorage)
            ?? panic("Vault not available in senderAccount")

        self.receiverVault = getAccount(receiverAccount)
            .getCapability(/public/Vault)
            .borrow<&WofiToken.Vault{FungibleToken.Receiver}>()
            ?? panic("Vault not available in receiverAccount")
    }

    execute {
        // Withdraw tokens from signer's vault and deposit into receiver's vault
        self.receiverVault.deposit(from: <-self.signerVault.withdraw(amount: amount))
        log("Tokens transferred")
    }
}
