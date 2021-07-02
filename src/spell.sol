// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 coordinator migration
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 coordinator migration mainnet Spell";

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public JUNIOR_TRANCHE = 0x53CF3CCd97CA914F9e441B8cd9A901E69B170f27;
    address constant public SENIOR_TRANCHE = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
    address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public RESERVE = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;
    address constant public COORDINATOR_OLD = 0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
    address constant public COORDINATOR_NEW = 0x0;
    
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_TRANCHE, self);
        root.relyContract(ASSESSOR, self);
        root.relyContract(RESERVE, self);
        root.relyContract(COORDINATOR_NEW, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateCoordinator();
    }

    function migrateCoordinator() internal {
         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE);
        
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR).deny(COORDINATOR_OLD);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD);

        // migrate state
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR_OLD);
    }
}