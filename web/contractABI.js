export const CONTRACT_ABI = [
    {
        "inputs": [
            { "internalType": "address", "name": "initialOwner", "type": "address" },
            { "internalType": "address", "name": "_signerA", "type": "address" },
            { "internalType": "address", "name": "_signerB", "type": "address" },
            { "internalType": "address", "name": "binanceLifeToken", "type": "address" },
            { "internalType": "address", "name": "oracleAddress", "type": "address" },
            { "internalType": "uint256", "name": "targetPrice", "type": "uint256" }
        ],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "owner", "type": "address" }
        ],
        "name": "OwnableInvalidOwner",
        "type": "error"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "account", "type": "address" }
        ],
        "name": "OwnableUnauthorizedAccount",
        "type": "error"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "newSignerA", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "newSignerB", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "updatedBy", "type": "address" }
        ],
        "name": "BothSignersUpdated",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "user", "type": "address" },
            { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256" }
        ],
        "name": "Deposited",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "signer", "type": "address" }
        ],
        "name": "EmergencySigned",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "newVaultAddress", "type": "address" },
            { "indexed": false, "internalType": "uint256", "name": "migratedAmount", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "userCount", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256" }
        ],
        "name": "MigrationExecuted",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "newVaultAddress", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "preparedBy", "type": "address" }
        ],
        "name": "MigrationPrepared",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" }
        ],
        "name": "OwnershipTransferred",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": false, "internalType": "uint256", "name": "currentPrice", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "targetPrice", "type": "uint256" }
        ],
        "name": "RefundEnabled",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "user", "type": "address" },
            { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256" }
        ],
        "name": "Refunded",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "oldSignerA", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "newSignerA", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "updatedBy", "type": "address" }
        ],
        "name": "SignerAUpdated",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "oldSignerB", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "newSignerB", "type": "address" },
            { "indexed": true, "internalType": "address", "name": "updatedBy", "type": "address" }
        ],
        "name": "SignerBUpdated",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            { "indexed": true, "internalType": "address", "name": "user", "type": "address" },
            { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256" }
        ],
        "name": "UserDepositMigrated",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "ORACLE",
        "outputs": [
            { "internalType": "contract BinanceLifePriceOracle", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "TARGET_PRICE",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "TOKEN",
        "outputs": [
            { "internalType": "contract IERC20", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "bytes", "name": "", "type": "bytes" }
        ],
        "name": "checkUpkeep",
        "outputs": [
            { "internalType": "bool", "name": "upkeepNeeded", "type": "bool" },
            { "internalType": "bytes", "name": "performData", "type": "bytes" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "uint256", "name": "amount", "type": "uint256" }
        ],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "name": "depositors",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "name": "deposits",
        "outputs": [
            { "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "internalType": "uint256", "name": "timestamp", "type": "uint256" },
            { "internalType": "bool", "name": "refunded", "type": "bool" },
            { "internalType": "bool", "name": "migrated", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "emergencySign",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "emergencySignedByA",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "emergencySignedByB",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "executeMigration",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getContractBalance",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getCurrentPrice",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getDepositorCount",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getMigrationStatus",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" },
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getPendingMigrationCount",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getSigners",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" },
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "user", "type": "address" }
        ],
        "name": "getUserDeposit",
        "outputs": [
            { "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "internalType": "uint256", "name": "timestamp", "type": "uint256" },
            { "internalType": "bool", "name": "refunded", "type": "bool" },
            { "internalType": "bool", "name": "migrated", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "migrationAllowed",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "migrationEnabled",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "newVaultAddress",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "bytes", "name": "", "type": "bytes" }
        ],
        "name": "performUpkeep",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "refundEnabled",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "renounceOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_newVaultAddress", "type": "address" }
        ],
        "name": "setNewVaultAddress",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "signerA",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "signerB",
        "outputs": [
            { "internalType": "address", "name": "", "type": "address" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "totalDeposits",
        "outputs": [
            { "internalType": "uint256", "name": "", "type": "uint256" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "newOwner", "type": "address" }
        ],
        "name": "transferOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "newSignerA", "type": "address" },
            { "internalType": "address", "name": "newSignerB", "type": "address" }
        ],
        "name": "updateBothSigners",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "newSignerA", "type": "address" }
        ],
        "name": "updateSignerA",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "newSignerB", "type": "address" }
        ],
        "name": "updateSignerB",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "withdrawAllowed",
        "outputs": [
            { "internalType": "bool", "name": "", "type": "bool" }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "withdrawRefund",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];