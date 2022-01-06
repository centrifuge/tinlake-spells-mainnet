// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";
import "./coordinator.sol";
import "./clerk.sol";

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

interface NAVFeedLike {
    function file(bytes32, uint) external;
    function discountRate() external view returns (uint256);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake coordinator migration mainnet spell";

    // TODO: set new addresses here
    // address constant public COORDINATOR_NEW = address(0);
    // address constant public POOL_ADMIN_NEW = address(0);
    // address constant public CLERK_NEW = address(0);
    // address constant public FEED_NEW = address(0);
    
    MigratedCoordinator coordinator_new = new MigratedCoordinator(1800);
    address public COORDINATOR_NEW = address(coordinator_new);

    MigratedClerk clerk_new = new MigratedClerk(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x5b2F0521875B188C0afc925B1598e1FF246F9306);
    address public CLERK_NEW = address(clerk_new);

    address constant public POOL_ADMIN_NEW = POOL_ADMIN;
    address constant public FEED_NEW = FEED;


    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        root.relyContract(ASSESSOR, address(this));
        root.relyContract(RESERVE, address(this));
        // root.relyContract(COORDINATOR_NEW, address(this));
        root.relyContract(POOL_ADMIN_NEW, address(this));
        // root.relyContract(CLERK_NEW, address(this));
        root.relyContract(JUNIOR_MEMBERLIST, address(this));
        root.relyContract(SENIOR_MEMBERLIST, address(this));
        root.relyContract(MGR, address(this));
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateCoordinator();
        migratePoolAdmin();
        migrateClerk();
    }

    function migrateCoordinator() internal {
        // migrate dependencies
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        
        DependLike(CLERK_NEW).depend("coordinator", COORDINATOR_NEW);

        DependLike(SENIOR_TRANCHE).depend("coordinator", COORDINATOR_NEW);
        DependLike(JUNIOR_TRANCHE).depend("coordinator", COORDINATOR_NEW);
        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR).deny(COORDINATOR);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR);

        // migrate state
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR);
    }

    function migratePoolAdmin() public {
        AuthLike(POOL_ADMIN_NEW).rely(ADMIN1);

        // setup dependencies 
        DependLike(POOL_ADMIN_NEW).depend("assessor", ASSESSOR);
        DependLike(POOL_ADMIN_NEW).depend("lending", CLERK_NEW);
        DependLike(POOL_ADMIN_NEW).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN_NEW).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        // setup permissions
        AuthLike(ASSESSOR).rely(POOL_ADMIN_NEW);
        AuthLike(ASSESSOR).deny(POOL_ADMIN);
        AuthLike(CLERK_NEW).rely(POOL_ADMIN_NEW);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN_NEW);
        AuthLike(JUNIOR_MEMBERLIST).deny(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN_NEW);
        AuthLike(SENIOR_MEMBERLIST).deny(POOL_ADMIN);

        //setup admins
        PoolAdminLike(POOL_ADMIN_NEW).relyAdmin(ADMIN1);
        PoolAdminLike(POOL_ADMIN_NEW).relyAdmin(ADMIN2);
    }

    function migrateClerk() public {

        // migrate state
        MigrationLike(CLERK_NEW).migrate(CLERK);

        // dependencies
        DependLike(CLERK_NEW).depend("assessor", ASSESSOR);
        DependLike(CLERK_NEW).depend("mgr", MGR);
        DependLike(CLERK_NEW).depend("coordinator", COORDINATOR);
        DependLike(CLERK_NEW).depend("reserve", RESERVE); 
        DependLike(CLERK_NEW).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK_NEW).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK_NEW).depend("spotter", SPOTTER);
        DependLike(CLERK_NEW).depend("vat", VAT);
        DependLike(CLERK_NEW).depend("jug", JUG);

        // permissions
        AuthLike(CLERK_NEW).rely(RESERVE);
        AuthLike(CLERK_NEW).rely(POOL_ADMIN_NEW);
        AuthLike(SENIOR_TRANCHE).rely(CLERK_NEW);
        AuthLike(RESERVE).rely(CLERK_NEW);
        AuthLike(ASSESSOR).rely(CLERK_NEW);
        AuthLike(MGR).rely(CLERK_NEW);

        FileLike(MGR).file("owner", CLERK_NEW);

        // DependLike(ASSESSOR).depend("clerk", CLERK_NEW); 
        DependLike(RESERVE).depend("lending", CLERK_NEW);
        DependLike(POOL_ADMIN_NEW).depend("lending", CLERK_NEW);

        // restricted token setup
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK_NEW, uint(-1));

        // remove old clerk
        AuthLike(SENIOR_TRANCHE).deny(CLERK);
        AuthLike(RESERVE).deny(CLERK);
        AuthLike(ASSESSOR).deny(CLERK);
        AuthLike(MGR).deny(CLERK);
    }

}