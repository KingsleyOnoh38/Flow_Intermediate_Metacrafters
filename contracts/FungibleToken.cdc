/**
# Fungible Token Standard Overview

This standard defines the `FungibleToken` contract interface, mandatory for all token contracts. 
Deploying a new token contract requires adherence to specified rules and naming conventions outlined 
in the interface.

## `Vault` Resource
Each token-holding account must store a `Vault` resource, enabling account-specific method calls 
for both owners and other users.

## Resource Interfaces
`Provider`, `Receiver`, and `Balance` interfaces set pre- and post-conditions, 
allowing users to selectively share references to their Vault. This flexibility 
supports custom resource implementations, such as creating faucets using the Provider interface.

By employing resources and interfaces, Fungible Token contracts enable 
peer-to-peer token transactions without reliance on a central ledger smart contract. 
Transfers involve withdrawing from the sender's Vault and depositing into the recipient's Vault.
*/

/// The interface implemented by Fungible Token contracts.
pub contract interface FungibleToken {

/// The overall quantity of tokens in existence.
    pub var totalSupply: UFix64

    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// The event that is emitted when tokens are deposited into a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// The interface that enforces the requirements for withdrawing
    /// tokens from the implementing type.
    ///
    /// It does not enforce requirements on `balance` here,
    /// because it leaves open the possibility of creating custom providers
    /// that do not necessarily need their own balance.
    ///
    pub resource interface Provider {

        /// Subtracts tokens from the owner's Vault
        /// and returns a Vault with the removed tokens.
        ///
        /// The function's access level is public, but this is not a problem
        /// because only the owner storing the resource in their account
        /// can initially call this function.
        ///
        /// The owner may grant other accounts access by creating a private
        /// capability that allows specific other users to access
        /// the provider resource through a reference.
        ///
        /// The owner may also grant all accounts access by creating a public
        /// capability that allows all users to access the provider
        /// resource through a reference.
        ///
        /// @param amount: The amount of tokens to be withdrawn from the vault
        /// @return The Vault resource containing the withdrawn funds
        /// 
        pub fun withdraw(amount: UFix64): @Vault {
            post {
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }

    /// The interface that enforces the requirements for depositing
    /// tokens into the implementing type.
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the tokens, like split them up and
    /// send them to different places.
    ///
    pub resource interface Receiver {

        /// Takes a Vault and deposits it into the implementing resource type
        ///
        /// @param from: The Vault resource containing the funds that will be deposited
        ///
        pub fun deposit(from: @Vault)

        /// Below is referenced from the FLIP #69 https://github.com/onflow/flips/blob/main/flips/20230206-fungible-token-vault-type-discovery.md
        /// 
        /// Returns the dictionary of Vault types that the the receiver is able to accept in its `deposit` method
        /// this then it would return `{Type<@FlowToken.Vault>(): true}` and if any custom receiver
        /// uses the default implementation then it would return empty dictionary as its parent
        /// resource doesn't conform with the `FungibleToken.Vault` resource.
        ///
        /// Custom receiver implementations are expected to upgrade their contracts to add an implementation
        /// that supports this method because it is very valuable for various applications to have.
        ///
        /// @return dictionary of supported deposit vault types by the implementing resource.
        /// 
    }

    /// The interface that contains the `balance` field of the Vault
    /// and enforces that when new Vaults are created, the balance
    /// is initialized correctly.
    ///
    pub resource interface Balance {

        /// The total balance of a vault
        ///
        pub var balance: UFix64

        init(balance: UFix64) {
            post {
                self.balance == balance:
                    "Balance must be initialized to the initial balance"
            }
        }

        /// Function that returns all the Metadata Views implemented by a Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        //pub fun getViews(): [Type]

        /// Function that resolves a metadata view for this fungible token by type.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        //pub fun resolveView(_ view: Type): AnyStruct? 
    }

    /// The resource that contains the functions to send and receive tokens.
    /// The declaration of a concrete type in a contract interface means that
    /// every Fungible Token contract that implements the FungibleToken interface
    /// must define a concrete `Vault` resource that conforms to the `Provider`, `Receiver`,
    /// and `Balance` interfaces, and declares their required fields and functions
    ///
    pub resource Vault: Provider, Receiver, Balance {

        /// The total balance of the vault
        pub var balance: UFix64

        // The conforming type must declare an initializer
        // that allows providing the initial balance of the Vault
        //
        init(balance: UFix64)

        /// Subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        /// @param amount: The amount of tokens to be withdrawn from the vault
        /// @return The Vault resource containing the withdrawn funds
        ///
        pub fun withdraw(amount: UFix64): @Vault {
            pre {
                self.balance >= amount:
                    "Amount withdrawn must be less than or equal to the balance of the Vault"
            }
            post {
                // use the special function `before` to get the value of the `balance` field
                // at the beginning of the function execution
                //
                self.balance == before(self.balance) - amount:
                    "New Vault balance must be the difference of the previous balance and the withdrawn Vault"
            }
        }

        /// Takes a Vault and deposits it into the implementing resource type
        ///
        /// @param from: The Vault resource containing the funds that will be deposited
        ///
        pub fun deposit(from: @Vault) {
            // Assert that the concrete type of the deposited vault is the same
            // as the vault that is accepting the deposit
            pre {
                from.isInstance(self.getType()): 
                    "Cannot deposit an incompatible token type"
            }
            post {
                self.balance == before(self.balance) + before(from.balance):
                    "New Vault balance must be the sum of the previous balance and the deposited Vault"
            }
        }
    }

    /// Allows any user to create a new Vault that has a zero balance
    ///
    /// @return The new Vault resource
    ///
    pub fun createEmptyVault(): @Vault {
        post {
            result.balance == 0.0: "The newly created Vault must have zero balance"
        }
    }
}
