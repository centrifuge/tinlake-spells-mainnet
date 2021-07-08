// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "src/draft/spell.sol";
import "src/base.sol";

contract SpellTest is BaseSpellTest {

    function setUp() public virtual {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));

        spell.cast();
            
        assertMigrationCoordinator();
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

    function assertMigrationCoordinator() public {
        ICoordinator coordinatorOld = ICoordinator(spell.COORDINATOR());
    
        // check dependencies
        assertEq(t_coordinator.assessor(), spell.ASSESSOR());
        assertEq(t_coordinator.juniorTranche(), spell.JUNIOR_TRANCHE());
        assertEq(t_coordinator.seniorTranche(), spell.SENIOR_TRANCHE());
        assertEq(t_coordinator.reserve(), spell.RESERVE());
        assertEq(t_juniorTranche.epochTicker(), spell.COORDINATOR_NEW());

        // check permissions
        assertHasPermissions(spell.JUNIOR_TRANCHE(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.ASSESSOR(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.SENIOR_TRANCHE(), spell.COORDINATOR_NEW());
        assertHasNoPermissions(spell.ASSESSOR(), address(coordinatorOld));
        assertHasNoPermissions(spell.JUNIOR_TRANCHE(), address(coordinatorOld));
        assertHasNoPermissions(spell.SENIOR_TRANCHE(), address(coordinatorOld));

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
        assertEq(t_coordinator.minChallengePeriodEnd (), coordinatorOld.minChallengePeriodEnd());
        assertEq(t_coordinator.challengeTime(), coordinatorOld.challengeTime());
        assertEq(t_coordinator.bestRatioImprovement(), coordinatorOld.bestRatioImprovement());
        assertEq(t_coordinator.bestReserveImprovement(), coordinatorOld.bestReserveImprovement());
        assert(t_coordinator.poolClosing() == false);
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
