// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";
import "src/base.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract SpellTest is BaseSpellTest {

    uint poolReserveDAI;

    function setUp() public virtual {
        initSpell();

        poolReserveDAI = t_currency.balanceOf(spell.RESERVE());
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));
        AuthLike(spell.POOL_REGISTRY()).rely(address(spell));

        spell.cast();
        
        assertMigrationAssessor();
        assertMigrationCoordinator();
        assertMigrationReserve();
        assertMigrationSeniorTranche();
        assertMigrationJuniorTranche();
        assertIntegrationAdapter();
        assertPoolAdminSet();
        assertRegistryUpdated();
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));
        spell.cast();
        spell.cast();
    }

    function assertMigrationSeniorTranche() public {
        assertEq(t_seniorTranche.reserve(), spell.RESERVE_NEW());
        assertEq(t_seniorTranche.coordinator(),spell.COORDINATOR_NEW());
        assertEq(t_seniorOperator.tranche(), spell.SENIOR_TRANCHE_NEW());
        assertHasPermissions(spell.SENIOR_TOKEN(), spell.SENIOR_TRANCHE_NEW());
        assertHasNoPermissions(spell.SENIOR_TOKEN(), spell.SENIOR_TRANCHE());
    }

    function assertMigrationJuniorTranche() public {
        assertEq(t_juniorTranche.reserve(), spell.RESERVE_NEW());
        assertEq(t_juniorTranche.coordinator(),spell.COORDINATOR_NEW());
        assertEq(t_juniorOperator.tranche(), spell.JUNIOR_TRANCHE_NEW());
        assertHasPermissions(spell.JUNIOR_TOKEN(), spell.JUNIOR_TRANCHE_NEW());
        assertHasNoPermissions(spell.JUNIOR_TOKEN(), spell.JUNIOR_TRANCHE());
    }

    function assertMigrationAssessor() public {  
        IAssessor assessorOld = IAssessor(spell.ASSESSOR());

        // check dependencies
        assertEq(t_assessor.lending(), spell.CLERK());
        assertEq(t_assessor.seniorTranche(), spell.SENIOR_TRANCHE_NEW());
        assertEq(t_assessor.juniorTranche(), spell.JUNIOR_TRANCHE_NEW());
        assertEq(t_assessor.reserve(), spell.RESERVE_NEW());
        assertEq(t_assessor.navFeed(), spell.FEED());

        // check permissions
        assertHasPermissions(spell.ASSESSOR_NEW(), spell.CLERK());
        assertHasPermissions(spell.ASSESSOR_NEW(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.ASSESSOR_NEW(), spell.RESERVE_NEW());

        // check state
        assertEq(t_assessor.seniorRatio(), assessorOld.seniorRatio());
        assertEq(t_assessor.seniorDebt_(), assessorOld.seniorDebt_());
        assertEq(t_assessor.seniorBalance_(), assessorOld.seniorBalance_());
        assertEq(t_assessor.seniorInterestRate(), assessorOld.seniorInterestRate());
        assertEq(t_assessor.lastUpdateSeniorInterest(), assessorOld.lastUpdateSeniorInterest());
        assertEq(t_assessor.maxSeniorRatio(), assessorOld.maxSeniorRatio());
        assertEq(t_assessor.minSeniorRatio(), spell.ASSESSOR_MIN_SENIOR_RATIO()); // has to be 0 for mkr integration
        assertEq(t_assessor.maxReserve(), assessorOld.maxReserve());  
    }

    function assertMigrationReserve() public {
        IReserve reserveOld =IReserve(spell.RESERVE());
         // check dependencies 
        assertEq(t_reserve.currency(), spell.TINLAKE_CURRENCY());
        assertEq(t_reserve.shelf(), spell.SHELF());
        assertEq(t_reserve.lending(), spell.CLERK());
        assertEq(t_juniorTranche.reserve(), spell.RESERVE_NEW());
        // assertEq(t_reserve.pot(), pot_); -> has to be public
        assertEq(t_shelf.distributor(), spell.RESERVE_NEW());
        assertEq(t_shelf.lender(), spell.RESERVE_NEW());
        // assertEq(collector.distributor(), spell.RESERVE_NEW()); -> has to be public

        // check permissions
        assertHasPermissions(spell.RESERVE_NEW(), spell.CLERK());
        assertHasPermissions(spell.RESERVE_NEW(), spell.JUNIOR_TRANCHE_NEW());
        assertHasPermissions(spell.RESERVE_NEW(), spell.SENIOR_TRANCHE_NEW());

        // check state
        assertEq(t_reserve.currencyAvailable(), reserveOld.currencyAvailable());   
        assertEq(t_reserve.balance_(), safeAdd(reserveOld.balance_(), poolReserveDAI));
        assertEq(t_currency.balanceOf(spell.RESERVE_NEW()), poolReserveDAI);
    }

    function assertMigrationCoordinator() public {
        ICoordinator coordinatorOld = ICoordinator(spell.COORDINATOR());
    
        // check dependencies
        assertEq(t_coordinator.assessor(), spell.ASSESSOR_NEW());
        assertEq(t_coordinator.juniorTranche(), spell.JUNIOR_TRANCHE_NEW());
        assertEq(t_coordinator.seniorTranche(), spell.SENIOR_TRANCHE_NEW());
        assertEq(t_coordinator.reserve(), spell.RESERVE_NEW());
        assertEq(t_juniorTranche.coordinator(),spell.COORDINATOR_NEW());
        // check permissions
        assertHasPermissions(spell.JUNIOR_TRANCHE_NEW(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.SENIOR_TRANCHE_NEW(), spell.COORDINATOR_NEW());
        assertHasNoPermissions(spell.JUNIOR_TRANCHE_NEW(), address(coordinatorOld));
        assertHasNoPermissions(spell.SENIOR_TRANCHE_NEW(), address(coordinatorOld));

        // check state
        assertEq(t_coordinator.lastEpochClosed(), coordinatorOld.lastEpochClosed());
        assertEq(t_coordinator.minimumEpochTime(), coordinatorOld.minimumEpochTime());
        assertEq(t_coordinator.lastEpochExecuted(), coordinatorOld.lastEpochExecuted());
        assertEq(t_coordinator.currentEpoch(), coordinatorOld.currentEpoch());
        assertEq(t_coordinator.bestSubScore(), coordinatorOld.bestSubScore());
        assert(t_coordinator.gotFullValidSolution() == coordinatorOld.gotFullValidSolution());
        assertEq(t_coordinator.epochSeniorTokenPrice(), coordinatorOld.epochSeniorTokenPrice());
        assertEq(t_coordinator.epochJuniorTokenPrice(), coordinatorOld.epochJuniorTokenPrice());
        assertEq(t_coordinator.epochNAV(), coordinatorOld.epochNAV());
        assertEq(t_coordinator.epochSeniorAsset(), coordinatorOld.epochSeniorAsset());
        assertEq(t_coordinator.epochReserve(), coordinatorOld.epochReserve());
        assert(t_coordinator.submissionPeriod() == coordinatorOld.submissionPeriod());
        assertEq(t_coordinator.weightSeniorRedeem(), coordinatorOld.weightSeniorRedeem());
        assertEq(t_coordinator.weightJuniorRedeem(), coordinatorOld.weightJuniorRedeem());
        assertEq(t_coordinator.weightJuniorSupply(), coordinatorOld.weightJuniorSupply());
        assertEq(t_coordinator.weightSeniorSupply(), coordinatorOld.weightSeniorSupply());
        assertEq(t_coordinator.minChallengePeriodEnd (), coordinatorOld.minChallengePeriodEnd ());
        assertEq(t_coordinator.challengeTime(), coordinatorOld.challengeTime());
        assertEq(t_coordinator.bestRatioImprovement(), coordinatorOld.bestRatioImprovement());
        assertEq(t_coordinator.bestReserveImprovement(), coordinatorOld.bestReserveImprovement());
        assert(t_coordinator.poolClosing() == coordinatorOld.poolClosing());
        assertOrderMigration(); 
    }

    function assertOrderMigration() public {
        (uint seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = t_coordinator.bestSubmission();
        (uint seniorRedeemSubmissionOld, uint juniorRedeemSubmissionOld, uint juniorSupplySubmissionOld, uint seniorSupplySubmissionOld) = ICoordinator(spell.COORDINATOR()).bestSubmission();
        assertEq(seniorRedeemSubmission, seniorRedeemSubmissionOld);
        assertEq(juniorRedeemSubmission, juniorRedeemSubmissionOld);
        assertEq(juniorSupplySubmission, juniorSupplySubmissionOld);
        assertEq(seniorSupplySubmission, seniorSupplySubmissionOld);

        (uint seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = t_coordinator.order();
        (uint seniorRedeemOrderOld, uint juniorRedeemOrderOld, uint juniorSupplyOrderOld, uint seniorSupplyOrderOld) = ICoordinator(spell.COORDINATOR()).order();
        assertEq(seniorRedeemOrder, seniorRedeemOrderOld);
        assertEq(juniorRedeemOrder, juniorRedeemOrderOld);
        assertEq(juniorSupplyOrder, juniorSupplyOrderOld);
        assertEq(seniorSupplyOrder, seniorSupplyOrderOld);
    }

    function assertIntegrationAdapter() public {
        // check dependencies 
        // vars have to be made public first
        assertEq(t_clerk.assessor(), spell.ASSESSOR_NEW());
        assertEq(t_clerk.mgr(), spell.MAKER_MGR());
        assertEq(t_clerk.coordinator(), spell.COORDINATOR_NEW());
        assertEq(t_clerk.reserve(), spell.RESERVE_NEW()); 
        assertEq(t_clerk.tranche(), spell.SENIOR_TRANCHE_NEW());
        assertEq(t_clerk.collateral(), spell.SENIOR_TOKEN());
        assertEq(t_clerk.spotter(), spell.SPOTTER());
        assertEq(t_clerk.vat(), spell.VAT());
        assertEq(t_clerk.jug(), spell.JUG());

        // assertEq(t_clerk.matBuffer(), matBuffer);

        // check permissions
        assertHasPermissions(spell.CLERK(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.CLERK(), spell.RESERVE_NEW());
        assertHasPermissions(spell.RESERVE_NEW(), spell.CLERK());
        assertHasPermissions(spell.SENIOR_TRANCHE_NEW(), spell.CLERK());
        assertHasPermissions(spell.ASSESSOR_NEW(), spell.CLERK());
        
        // state
        assert(t_seniorToken.hasMember(spell.CLERK()));
        assert(t_seniorToken.hasMember(spell.MAKER_MGR()));

        assertEq(t_mgr.owner(), spell.CLERK()); // assert clerk owner of mgr
        assertEq(t_mgr.pool(), spell.SENIOR_OPERATOR());
        assertEq(t_mgr.tranche(), spell.SENIOR_TRANCHE_NEW());
        assertEq(t_mgr.urn(), spell.URN());
        assertEq(t_mgr.liq(), spell.LIQ());
        assertHasPermissions(spell.MAKER_MGR(), spell.CLERK());

        // check rwa token balance = 0
        assertEq(SpellERC20Like(spell.RWA_GEM()).balanceOf(spell.MAKER_MGR()), 0);
    }

    function assertPoolAdminSet() public {
        // setup dependencies 
        assertEq(t_poolAdmin.assessor(), spell.ASSESSOR_NEW());
        assertEq(t_poolAdmin.lending(), spell.CLERK());
        assertEq(t_poolAdmin.seniorMemberlist(), spell.SENIOR_MEMBERLIST());
        assertEq(t_poolAdmin.juniorMemberlist(), spell.JUNIOR_MEMBERLIST());

        assertHasPermissions(spell.ASSESSOR_NEW(), spell.POOL_ADMIN());
        assertHasPermissions(spell.CLERK(), spell.POOL_ADMIN());
        assertHasPermissions(spell.SENIOR_MEMBERLIST(), spell.POOL_ADMIN());
        assertHasPermissions(spell.JUNIOR_MEMBERLIST(), spell.POOL_ADMIN());

        assertHasPermissions(spell.POOL_ADMIN(), spell.GOVERNANCE());
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN1()), 1);
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN2()), 1);
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN3()), 1);
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN4()), 1);
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN5()), 1);
        assertEq(t_poolAdmin.admins(spell.POOL_ADMIN6()), 1);
        assertEq(t_poolAdmin.admins(spell.AO_POOL_ADMIN()), 1);
    }

    function assertRegistryUpdated() public {
        (,,string memory data) = PoolRegistryLike(spell.POOL_REGISTRY()).find(spell.ROOT_CONTRACT());
        assertEq(data, spell.IPFS_HASH());
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }

    // --- Math ---
    function safeAdd(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-add-overflow");
    }
}
