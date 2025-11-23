# SOS NON SUS

### **Overview**

In real emergency situations—such as kidnapping, coercion, or other threats—users may be forced to hand over their crypto wallet. Our project provides a one-click escape mechanism that instantly transfers all funds from a user’s wallet (across multiple chains and tokens) to a trusted, pre-designated “safe wallet” owned by friends, family or stored in a separate location.

The idea is that this action can be triggered discreetly from a small hardware device (e.g., ring, bracelet, or button). For this hackathon, we demonstrate the concept using a Degen1-style hardware gadget.

---

### **The Problem**

Self-custody is powerful—but it also puts individuals at risk. If someone is physically threatened, they may be forced to unlock their wallet and surrender their funds. Traditional EOAs (Externally Owned Accounts) offer no escape mechanism and transferring all funds takes a long time and many transactions.

### **Our Solution**

We built an **emergency fund-escape protocol** that lets a user trigger a secure transfer of _all_ assets across all chains and tokens using a single transaction initiating everything on Zircuit. This is possible by combining the power of our customized ERC7702 and utilizing LayerZero concepts like batch send and compose.

## **How It's Made:

### **EIP-7702 Transformation**

We extend the MetaMask EIP-7702 flow to add the possiblity for a designated wallet to trigger the escape mechanism allowing it to only do token transfers to a specified safe wallet.

### **Cross-Chain Execution with LayerZero**

Once the user triggers an emergency event, our OApp deployed on Zircuit will batch send messages to multiple other chains using LayerZero (in our example to Base and Arbitrum). On those chains we will receive the message and initiate a lzCompose call. This call will go to our Composer contract that extracts the original sender from the source chain and calls it's 7702 delegation on it's behalf to transfer the assets on the destination chain.

You can see the whole transaction flow as an example here: https://layerzeroscan.com/tx/0x40515b12472e76c0ff849620fee28f916bf9027469b587dc19a5848dbd89ab50

## Contract addresses
- OApp
    - Zircuit `0xd36ea10Cb394a13a0BF5a46aB88a37E0C95Af7Ac`
    - Base `0x536271fB18C1D3CD4FCaf4F04fB0513a83961c1A`
    - Arbitrum `0xF802DB56c7C430b564E2B22761b724588374037C`
- Composer
    - Base `0x77Fa754D756556b57422b62D3332654fcA32cf2f`
    - Aribtrum `0x21a0c3A154C0a0B7c0E0f356196Bc83c205d9171`
- EIP7702ForkedMetamaskStatelessDeleGator
    - ZIRCUIT `0xbd9f63D83B26498ded60037B6FbB8B8Fd20e89b7`
    - BASE & ARBITRUM `0x1FeA6d71644272Bda56b5D2fAd3A72B9967D5Ac3`
- DELEGATIONMANAGER
    - ZIRCUIT `0x4eAB75D593Caec7Eb51f47FdBccad6Da434444A9`
    - ARBITRUM & BASE `0x286d75cbB33ddf2699E3db68Ea0EF8AC836d7dD5`
- ENTRYPOINT
    - BASE & ARBITRUM `0x30e8b21247EA364681430c921067794C029131EF`
    - ZIRCUIT `0x602B256097C5C00c45d0f1b7f75474B66BE17747`

- DEPLOYER DELEGATOR
    `0xB9335E2433E2e51cE10aCF37Bc02dFeb5E16e688`
- DEPLOYER DELEGATOR TRIGGER WALLET
    `0x0b6b2F0046eC9386003190E2bF6BBf5DA7F6C3D1`
- DEPLOYER DELEGATOR SECURITY WALLET
    `0xa3b02B8d40230e806e0ec12F6429EBC772E1e8C4`

TOKEN ADDRESSES FOR SOS:
    ZIRCUIT:
        WETH: `0x4200000000000000000000000000000000000006`
        AMOUNT: "1000"
        ZRC: `0xfd418e42783382E86Ae91e445406600Ba144D162`
        AMOUNT: "1000"
    BASE:
        WETH: `0x4200000000000000000000000000000000000006`
        ZBTC: `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf`
        AMOUNT: "100"
    ARBITRUM:
        WETH: `0x82aF49447D8a07e3bd95BD0d56f35241523fBab1`
        GRAPHITE: `0x440017A1b021006d556d7fc06A54c32E42Eb745B`
        AMOUNT: "100"
