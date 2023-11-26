
import FungibleToken from 0x05
import FlowToken from 0x05

// Transaction to initiate a new FlowToken minter
transaction (_allowedAmount: UFix64){
    // Reference to the FlowToken Administrator resource
    let admin: &FlowToken.Administrator
    
    // Signer variable declaration
    let signer: AuthAccount

    // Prepare step: Retrieve the Administrator resource from signer's storage
    prepare(signerRef: AuthAccount) {
        // Assign the signer reference to the variable
        self.signer = signerRef
        // Retrieve the Administrator resource from storage
        self.admin = self.signer.borrow<&FlowToken.Administrator>(from: /storage/newflowTokenAdmin)
            ?? panic("You are not the admin")
    }

    // Execute step: Generate a new minter and store it in storage
    execute {
        // Generate a new minter using the createNewMinter function
        let newMinter <- self.admin.createNewMinter(allowedAmount: _allowedAmount)

        // Save the new minter resource to the designated storage path
        self.signer.save(<-newMinter, to: /storage/FlowMinter)

        // Log a success message
        log("Flow minter created successfully")
    }
}
```