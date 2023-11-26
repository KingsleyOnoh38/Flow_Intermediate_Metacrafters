import FungibleToken from 0x05
import WofiToken from 0x05

pub fun main(account: Address) {

    // Attempt to borrow PublicVault capability
    let publicVault: &WofiToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, WofiToken.CollectionPublic}? =
        getAccount(account).getCapability(/public/Vault)
            .borrow<&WofiToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, WofiToken.CollectionPublic}>()

    if (publicVault == nil) {
        // Create and link an empty vault if capability is not present
        let newVault <- WofiToken.createEmptyVault()
        getAuthAccount(account).save(<-newVault, to: /storage/VaultStorage)
        getAuthAccount(account).link<&WofiToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, WofiToken.CollectionPublic}>(
            /public/Vault,
            target: /storage/VaultStorage
        )
        log("Empty vault created")
        
        // Borrow the vault capability again to display its balance
        let retrievedVault: &WofiToken.Vault{FungibleToken.Balance}? =
            getAccount(account).getCapability(/public/Vault)
                .borrow<&WofiToken.Vault{FungibleToken.Balance}>()
        log(retrievedVault?.balance)
    } else {
        log("Vault already exists and is properly linked")
        
        // Borrow the vault capability for further checks
        let checkVault: &WofiToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, WofiToken.CollectionPublic} =
            getAccount(account).getCapability(/public/Vault)
                .borrow<&WofiToken.Vault{FungibleToken.Balance, FungibleToken.Receiver, WofiToken.CollectionPublic}>()
                ?? panic("Vault capability not found")
        
        // Check if the vault's UUID is in the list of vaults
        if WofiToken.vaults.contains(checkVault.uuid) {
            log(publicVault?.balance)
            log("This is a WofiToken vault")
        } else {
            log("This is not a WofiToken vault")
        }
    }
}
