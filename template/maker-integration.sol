// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";

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

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
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


contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake maker integration mainnet spell";

    address constant public GOVERNANCE = 0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25;

    // TODO: set new swapped contract address here
    address constant public COORDINATOR_NEW = address(0);
    address constant public ASSESSOR_NEW  = address(0);
    address constant public RESERVE_NEW = address(0);
    address constant public SENIOR_TRANCHE_NEW = address(0);

    // TODO: set maker contract addresses here
    address constant public SPOTTER = address(0);
    address constant public VAT = address(0);
    address constant public JUG = address(0);
    address constant public URN = address(0);
    address constant public LIQ = address(0);
    address constant public END = address(0);
    address constant public RWA_GEM = address(0);
    address constant public MAKER_MGR = address(0);

    // TODO: set these
    address constant public POOL_ADMIN1 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public POOL_ADMIN2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public POOL_ADMIN3 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address constant public POOL_ADMIN4 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public POOL_ADMIN5 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address constant public AO_POOL_ADMIN = address(0);

    // TODO: check these
    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, address(this));
        root.relyContract(COLLECTOR, address(this));
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_OPERATOR, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TOKEN, address(this));
        root.relyContract(SENIOR_TRANCHE_NEW, address(this));
        root.relyContract(SENIOR_MEMBERLIST, address(this));
        root.relyContract(JUNIOR_MEMBERLIST, address(this));
        root.relyContract(CLERK, address(this));
        root.relyContract(POOL_ADMIN, address(this));
        root.relyContract(ASSESSOR_NEW, address(this));
        root.relyContract(COORDINATOR_NEW, address(this));
        root.relyContract(RESERVE, address(this));
        root.relyContract(RESERVE_NEW, address(this));
        root.relyContract(MAKER_MGR, address(this));
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        migrateTranche();
        integrateAdapter();
        setupPoolAdmin();

        // for mkr integration: set minSeniorRatio in Assessor to 0      
        FileLike(ASSESSOR_NEW).file("minSeniorRatio", ASSESSOR_MIN_SENIOR_RATIO);
    }

    function migrateAssessor() internal {
        MigrationLike(ASSESSOR_NEW).migrate(ASSESSOR);

        // migrate dependencies 
        DependLike(ASSESSOR_NEW).depend("navFeed", FEED);
        DependLike(ASSESSOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(ASSESSOR_NEW).depend("clerk", CLERK); 

        // migrate permissions
        AuthLike(ASSESSOR_NEW).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR_NEW).rely(RESERVE_NEW);
    }

    function migrateCoordinator() internal {
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR);

         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR); 
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR_NEW);
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE);

        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE_NEW).rely(ASSESSOR_NEW);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE);
        SpellReserveLike(RESERVE).payout(balanceReserve);
        currency.transferFrom(address(this), RESERVE_NEW, balanceReserve);
    }

    function migrateTranche() internal {
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");

        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);
    }

    function integrateAdapter() internal {
        require(SpellERC20Like(RWA_GEM).balanceOf(MAKER_MGR) == 1 ether);

        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MAKER_MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        FileLike(CLERK).file("buffer", MAT_BUFFER);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, type(uint256).max);
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MAKER_MGR, type(uint256).max);

        // setup mgr
        AuthLike(MAKER_MGR).rely(CLERK);
        FileLike(MAKER_MGR).file("urn", URN);
        FileLike(MAKER_MGR).file("liq", LIQ);
        FileLike(MAKER_MGR).file("end", END);
        FileLike(MAKER_MGR).file("owner", CLERK);
        FileLike(MAKER_MGR).file("pool", SENIOR_OPERATOR);
        FileLike(MAKER_MGR).file("tranche", SENIOR_TRANCHE_NEW);

        // lock token
        MgrLike(MAKER_MGR).lock(1 ether);
    }

    function setupPoolAdmin() public {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);

        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR_NEW);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        // setup permissions
        AuthLike(ASSESSOR_NEW).rely(POOL_ADMIN);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);

        // directly relying governance so it can be used to directly add/remove pool admins without going through the root
        AuthLike(POOL_ADMIN).rely(GOVERNANCE);

        // setup admins
        poolAdmin.relyAdmin(POOL_ADMIN1);
        poolAdmin.relyAdmin(POOL_ADMIN2);
        poolAdmin.relyAdmin(POOL_ADMIN3);
        poolAdmin.relyAdmin(POOL_ADMIN4);
        poolAdmin.relyAdmin(POOL_ADMIN5);
        poolAdmin.relyAdmin(AO_POOL_ADMIN);
    }

}