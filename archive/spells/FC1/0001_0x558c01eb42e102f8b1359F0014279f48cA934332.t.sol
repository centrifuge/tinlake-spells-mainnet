pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./../src/spell.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
    address root_;
    address spell_;
    address constant public PILE = 0x99D0333f97432fdEfA25B7634520d505e58B131B;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        address assessor_ = spell.ASSESSOR();
        address assessorAdmin_ = spell.ASSESSOR_ADMIN();
        address coordinator_ = spell.COORDINATOR();
        address navFeed_ = spell.FEED();
        address juniorMemberlist_ = spell.JUNIOR_MEMBERLIST();
        address seniorMemberlist = spell.SENIOR_MEMBERLIST();
        address adminToBeRemoved_ = spell.ADMIN_TO_BE_REMOVED();
        address newAdmin_ = spell.NEW_ADMIN1();

        CoordinatorLike coordinator = CoordinatorLike(coordinator_);
        NAVFeedLike navFeed = NAVFeedLike(navFeed_);
        PileLike pile = PileLike(PILE);

        // check if admin to be removed has permissions
        assertHasPermissions(assessor_, adminToBeRemoved_);
        assertHasPermissions(assessorAdmin_, adminToBeRemoved_);
        assertHasPermissions(coordinator_, adminToBeRemoved_);
        assertHasPermissions(navFeed_, adminToBeRemoved_);
        assertHasPermissions(juniorMemberlist_, adminToBeRemoved_);
        assertHasPermissions(seniorMemberlist, adminToBeRemoved_);
        
        // check if new admin has no permissions
        assertHasNoPermissions(assessorAdmin_, newAdmin_);
        assertHasNoPermissions(juniorMemberlist_, newAdmin_);
        assertHasNoPermissions(seniorMemberlist, newAdmin_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // check if admin to be removed has no permissions anymore
        assertHasNoPermissions(assessor_, adminToBeRemoved_);
        assertHasNoPermissions(assessorAdmin_, adminToBeRemoved_);
        assertHasNoPermissions(coordinator_, adminToBeRemoved_);
        assertHasNoPermissions(navFeed_, adminToBeRemoved_);
        assertHasNoPermissions(juniorMemberlist_, adminToBeRemoved_);
        assertHasNoPermissions(seniorMemberlist, adminToBeRemoved_);

        // check if new admin got permisions
        assertHasPermissions(assessorAdmin_, newAdmin_);
        assertHasPermissions(juniorMemberlist_, newAdmin_);
        assertHasPermissions(seniorMemberlist, newAdmin_);

        // check if minimum epoch time was set correctly
        assertEq(coordinator.minimumEpochTime(), spell.minEpochTime());
        
        //check riskGroups
        (,,uint ratePerSecond5,,) = pile.rates(5);
        assertEq(ratePerSecond5, uint(1000000003805175038051750380));
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 0);
    }
}
