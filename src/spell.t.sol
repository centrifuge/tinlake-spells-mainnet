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

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;

    address root_;
    address spell_;

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
        // tinlake contracts 
        address seniorMemberList_ = address(spell.SENIOR_MEMBERLIST());
        address juniorMemberList_ = address(spell.JUNIOR_MEMBERLIST());
        address assessorAdmin_ = address(spell.ASSESSOR_ADMIN());
        address navFeed_ = spell.NAV_FEED();    
        NAVFeedLike navFeed = NAVFeedLike(navFeed_);
        
        // addresses for permissions setup
        address seniorMemberListAdmin1_ = address(spell.SENIOR_MEMBERLIST_ADMIN1());
        address seniorMemberListAdmin2_ = address(spell.SENIOR_MEMBERLIST_ADMIN2());
        address seniorMemberListAdminRemove_ = spell.SENIOR_MEMBERLIST_ADMIN_REMOVE();

        address juniorMemberListAdmin1_ = spell.JUNIOR_MEMBERLIST_ADMIN1();
        address juniorMemberListAdmin2_ = spell.JUNIOR_MEMBERLIST_ADMIN2();
        address juniorMemberListAdmin3_ = spell.JUNIOR_MEMBERLIST_ADMIN3();

        address assessorAdminAdmin1_ = spell.ASSESSOR_ADMIN_ADMIN1();
        address assessorAdminAdmin2_ = spell.ASSESSOR_ADMIN_ADMIN2();
       
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin2_);
        assertHasPermissions(seniorMemberList_, seniorMemberListAdminRemove_);

        assertHasNoPermissions(juniorMemberList_, juniorMemberListAdmin1_);
        assertHasNoPermissions(juniorMemberList_, juniorMemberListAdmin2_);
        assertHasNoPermissions(juniorMemberList_, juniorMemberListAdmin3_);

        assertHasNoPermissions(assessorAdmin_, assessorAdminAdmin1_);
        assertHasNoPermissions(assessorAdmin_, assessorAdminAdmin2_);

        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();

        // make sure permissions were set
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin2_);
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdminRemove_);

        assertHasPermissions(juniorMemberList_, juniorMemberListAdmin1_);
        assertHasPermissions(juniorMemberList_, juniorMemberListAdmin2_);
        assertHasPermissions(juniorMemberList_, juniorMemberListAdmin3_);

        assertHasPermissions(assessorAdmin_, assessorAdminAdmin1_);
        assertHasPermissions(assessorAdmin_, assessorAdminAdmin2_);

         // check discountRate set
        assertEq(navFeed.discountRate(), spell.discountRate());
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

    function assertHasPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 0);
    }
}
