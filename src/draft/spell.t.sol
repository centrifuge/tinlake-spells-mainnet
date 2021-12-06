pragma solidity >=0.7.0;

import "ds-test/test.sol";
import "./spell.sol";


abstract contract Hevm {
    function warp(uint256) public virtual;
    function store(address, bytes32, bytes32) public virtual;
}

interface IFile {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface IAuth {
    function wards(address) external returns(uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface IMgr {
    function owner() external returns(address);
}

interface IReserve {
    function lending() external returns(address);
}

interface IAssessor {
    function clerk() external returns(address);
    function calcJuniorRatio() external returns(uint);
    function maxSeniorRatio() external returns(uint);
    function seniorRatio() external returns(uint);
}

interface ICoordinator {
    function assessor() external returns(address);
    function juniorTranche() external returns(address);
    function seniorTranche() external returns(address);
    function reserve() external returns(address);
    function lastEpochClosed() external returns(uint);
    function minimumEpochTime() external returns(uint);
    function lastEpochExecuted() external returns(uint);
    function currentEpoch() external returns(uint);
    function bestSubScore() external returns(uint);
    function gotFullValidSolution() external returns(bool);
    function epochSeniorTokenPrice() external returns(uint);
    function epochJuniorTokenPrice() external returns(uint);
    function epochNAV() external returns(uint);
    function epochSeniorAsset() external returns(uint);
    function epochReserve() external returns(uint);
    function weightSeniorRedeem() external returns(uint);
    function weightJuniorRedeem() external returns(uint);
    function weightJuniorSupply() external returns(uint);
    function weightSeniorSupply() external returns(uint);
    function minChallengePeriodEnd() external returns(uint);
    function challengeTime() external returns(uint);
    function bestRatioImprovement() external returns(uint);
    function bestReserveImprovement() external returns(uint);
    function poolClosing() external returns(bool);
    function bestSubmission() external returns(uint, uint, uint, uint);
    function order() external returns(uint, uint, uint, uint);
    function executeEpoch() external;
    function submissionPeriod() external returns(bool);
    function submitSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) external returns(int);
}

interface IRoot {
    function relyContract(address, address) external;
}

interface IPoolAdmin {
    function admins(address) external returns(uint);
    function assessor() external returns(address);
    function lending() external returns(address);
    function juniorMemberlist() external returns(address);
    function seniorMemberlist() external returns(address);
}

interface IClerk {
    function assessor() external returns(address);
    function mgr() external returns(address);
    function coordinator() external returns(address);
    function reserve() external returns(address); 
    function tranche() external returns(address);
    function collateral() external returns(address);
    function spotter() external returns(address);
    function vat() external returns(address);
    function jug() external returns(address);
    function creditline() external returns(uint);
    function matBuffer() external returns(uint);
    function collateralTolerance() external returns(uint);
    function wipeThreshold() external returns(uint);
    function sink(uint amountDAI) external;
}

interface ITranche {
    function reserve() external returns(address);
    function epochTicker() external returns(address);
}

interface IRestrictedToken {
    function hasMember(address member) external returns(bool);
}

contract TinlakeSpellsTest is DSTest {

    IHevm public hevm;
    TinlakeSpell spell;
    IClerk clerkNew;
    IClerk clerk;
    IMgr mgr;
    IRestrictedToken seniorToken;
    IAssessor assessor;
    IReserve reserve;
    IPoolAdmin poolAdminNew;
    IPoolAdmin poolAdmin;
    ICoordinator coordinatorNew;
    ICoordinator coordinator;
    IRoot root;
    ITranche juniorTranche;

    address spell_;
    address root_;
    address clerkNew_;
    address clerk_;
    address reserve_;
    address assessor_;
    address poolAdminNew_;
    address poolAdmin_;
    address seniorMemberList_;
    address juniorMemberList_;
    address coordinatorNew_;
    address coordinator_;
    address seniorTranche_;
    address currency_;
    address mgr_;
    address seniorToken_;
    address spotter_;
    address vat_;
    address jug_;
    address juniorTranche_;
    address admin1;
    address admin2;

    uint256 constant RAD = 10 ** 27;
    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        assessor_ = spell.ASSESSOR();
        poolAdminNew_ = spell.POOL_ADMIN_NEW();
        poolAdmin_ = spell.POOL_ADMIN();
        reserve_ = spell.RESERVE();
        coordinatorNew_ = spell.COORDINATOR_NEW();
        coordinator_ = spell.COORDINATOR();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        mgr_ = spell.MGR();
        seniorToken_ = spell.SENIOR_TOKEN();
        seniorMemberList_ = spell.SENIOR_MEMBERLIST();
        juniorMemberList_ = spell.JUNIOR_MEMBERLIST();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        juniorTranche_ = spell.JUNIOR_TRANCHE();
        clerkNew_ = spell.CLERK_NEW();
        clerk_ = spell.CLERK();
        spotter_ = spell.SPOTTER();
        vat_ = spell.VAT();
        jug_ = spell.JUG();
        admin1 = spell.ADMIN1();
        admin2 = spell.ADMIN2();
        root_ = address(spell.ROOT_CONTRACT());  
        mgr = IMgr(mgr_);
        clerkNew = IClerk(clerkNew_);
        clerk = IClerk(clerk_);
        seniorToken = IRestrictedToken(seniorToken_);
        reserve = IReserve(reserve_);
        assessor = IAssessor(assessor_);
        coordinatorNew = ICoordinator(coordinatorNew_);
        coordinator = ICoordinator(coordinator_);
        poolAdminNew = IPoolAdmin(poolAdminNew_);
        poolAdmin = IPoolAdmin(poolAdmin_);
        juniorTranche = ITranche(juniorTranche_);
        root = IRoot(root_);
        hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function setUp() public {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();
        assertClerkMigrated();

    }

    function testFailCastNoPermissions() public {
        // do not give spell permissions on root contract

        spell.cast();
    }

    function testFailCastTwice() public {

        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();
        spell.cast();
    }

    function assertCoordinatorMigrated() public {    
        // check dependencies
        assertEq(coordinatorNew.assessor(), spell.ASSESSOR());
        assertEq(coordinatorNew.juniorTranche(), spell.JUNIOR_TRANCHE());
        assertEq(coordinatorNew.seniorTranche(), spell.SENIOR_TRANCHE());
        assertEq(coordinatorNew.reserve(), spell.RESERVE());
        assertEq(juniorTranche.epochTicker(), spell.COORDINATOR_NEW());

        // check permissions
        assertHasPermissions(spell.JUNIOR_TRANCHE(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.ASSESSOR(), spell.COORDINATOR_NEW());
        assertHasPermissions(spell.SENIOR_TRANCHE(), spell.COORDINATOR_NEW());
        assertHasNoPermissions(spell.ASSESSOR(), address(coordinator));
        assertHasNoPermissions(spell.JUNIOR_TRANCHE(), address(coordinator));
        assertHasNoPermissions(spell.SENIOR_TRANCHE(), address(coordinator));

        // check state
        assertEq(coordinatorNew.lastEpochClosed(), coordinator.lastEpochClosed());
        assertEq(coordinatorNew.minimumEpochTime(), coordinator.minimumEpochTime());
        assertEq(coordinatorNew.lastEpochExecuted(), coordinator.lastEpochExecuted());
        assertEq(coordinatorNew.currentEpoch(), coordinator.currentEpoch());
        assertEq(coordinatorNew.bestSubScore(), coordinator.bestSubScore());
        assert(coordinatorNew.gotFullValidSolution() == coordinator.gotFullValidSolution());

        assertEq(coordinatorNew.epochSeniorTokenPrice(), coordinator.epochSeniorTokenPrice());
        assertEq(coordinatorNew.epochJuniorTokenPrice(), coordinator.epochJuniorTokenPrice());
        assertEq(coordinatorNew.epochNAV(), coordinator.epochNAV());
        assertEq(coordinatorNew.epochSeniorAsset(), coordinator.epochSeniorAsset());
        assertEq(coordinatorNew.epochReserve(), coordinator.epochReserve());

        assert(coordinatorNew.submissionPeriod() == coordinator.submissionPeriod());
        assertEq(coordinatorNew.weightSeniorRedeem(), coordinator.weightSeniorRedeem());
        assertEq(coordinatorNew.weightJuniorRedeem(), coordinator.weightJuniorRedeem());
        assertEq(coordinatorNew.weightJuniorSupply(), coordinator.weightJuniorSupply());
        assertEq(coordinatorNew.weightSeniorSupply(), coordinator.weightSeniorSupply());
        assertEq(coordinatorNew.minChallengePeriodEnd (), coordinator.minChallengePeriodEnd());
        assertEq(coordinatorNew.challengeTime(), coordinator.challengeTime());
        assertEq(coordinatorNew.bestRatioImprovement(), coordinator.bestRatioImprovement());
        assertEq(coordinatorNew.bestReserveImprovement(), coordinator.bestReserveImprovement());
        assert(coordinatorNew.poolClosing() == false);
        assertOrderMigration(); 
    }

    function assertOrderMigration() public {
        (uint seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = coordinatorNew.bestSubmission();
        (uint seniorRedeemSubmissionOld, uint juniorRedeemSubmissionOld, uint juniorSupplySubmissionOld, uint seniorSupplySubmissionOld) = ICoordinator(spell.COORDINATOR()).bestSubmission();
        assertEq(seniorRedeemSubmission, seniorRedeemSubmissionOld);
        assertEq(juniorRedeemSubmission, juniorRedeemSubmissionOld);
        assertEq(juniorSupplySubmission, juniorSupplySubmissionOld);
        assertEq(seniorSupplySubmission, seniorSupplySubmissionOld);

        (uint seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = coordinatorNew.order();
        (uint seniorRedeemOrderOld, uint juniorRedeemOrderOld, uint juniorSupplyOrderOld, uint seniorSupplyOrderOld) = ICoordinator(spell.COORDINATOR()).order();
        assertEq(seniorRedeemOrder, seniorRedeemOrderOld);
        assertEq(juniorRedeemOrder, juniorRedeemOrderOld);
        assertEq(juniorSupplyOrder, juniorSupplyOrderOld);
        assertEq(seniorSupplyOrder, seniorSupplyOrderOld);
    }

    function assertPoolAdminMigrated() public {

        // setup dependencies 
        assertEq(poolAdminNew.assessor(), assessor_);
        assertEq(poolAdminNew.lending(), clerk_);
        assertEq(poolAdminNew.seniorMemberlist(), seniorMemberList_);
        assertEq(poolAdminNew.juniorMemberlist(), juniorMemberList_);

        assertHasPermissions(assessor_, poolAdminNew_);
        assertHasPermissions(clerk_, poolAdminNew_);
        assertHasPermissions(seniorMemberList_, poolAdminNew_);
        assertHasPermissions(juniorMemberList_, poolAdminNew_);
        // todo add admin checks once we have addresses

        assertHasPermissions(poolAdminNew_, admin1);
        assertEq(poolAdminNew.admins(admin1), 1);
        assertEq(poolAdminNew.admins(admin2), 1);

        assertHasNoPermissions(assessor_, poolAdmin_);
        assertHasNoPermissions(clerk_, poolAdmin_);
        assertHasNoPermissions(seniorMemberList_, poolAdmin_);
        assertHasNoPermissions(juniorMemberList_, poolAdmin_);
        assertHasNoPermissions(poolAdmin_, admin1);
    }

    function assertClerkMigrated() internal {
        // assert state migrated correctly
        assertEq(clerkNew.creditline(), clerk.creditline());
        assertEq(clerkNew.matBuffer(), clerk.matBuffer());
        assertEq(clerkNew.collateralTolerance(), clerk.collateralTolerance());
        assertEq(clerkNew.wipeThreshold(), clerk.wipeThreshold());

        // check clerk dependencies
        assertEq(clerkNew.assessor(), assessor_);
        assertEq(clerkNew.mgr(), mgr_);
        assertEq(clerkNew.coordinator(), coordinator_);
        assertEq(clerkNew.reserve(), reserve_); 
        assertEq(clerkNew.tranche(), seniorTranche_);
        assertEq(clerkNew.collateral(), seniorToken_);
        assertEq(clerkNew.spotter(), spotter_);
        assertEq(clerkNew.vat(), vat_);
        assertEq(clerkNew.jug(), jug_);

        assertEq(reserve.lending(), clerkNew_);
        assertEq(assessor.clerk(), clerkNew_);
        assertEq(poolAdmin.lending(), clerkNew_);

        // check permissions
        assertHasPermissions(clerkNew_, reserve_);
        assertHasPermissions(clerkNew_, poolAdmin_);
        assertHasPermissions(reserve_, clerkNew_);
        assertHasPermissions(seniorTranche_, clerkNew_);
        assertHasPermissions(assessor_, clerkNew_);
        assertHasPermissions(mgr_, clerkNew_);

        // check clerk is owner of the mgr
        assertEq(mgr.owner(), clerkNew_);

        // assert clerk whitelisted to hold DROP
        assert(seniorToken.hasMember(clerkNew_));

        // assert old clerk was removed from contracts
        assertHasNoPermissions(reserve_, clerk_);
        assertHasNoPermissions(seniorTranche_, clerk_);
        assertHasNoPermissions(assessor_, clerk_);
        assertHasNoPermissions(mgr_, clerk_);
    }

    function assertEpochExecution() internal {
        coordinatorNew.executeEpoch();
        assert(coordinatorNew.submissionPeriod() == false);
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }
}