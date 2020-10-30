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
        address seniorMemberList_ = spell.SENIOR_MEMBERLIST();

        // addresses for permissions setup
        address seniorMemberListAdmin1_ = spell.SENIOR_MEMBERLIST_ADMIN1();
         address seniorMemberListAdmin2_ = spell.SENIOR_MEMBERLIST_ADMIN2();
        
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin2_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // make sure permissions were set
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin2_);

    }

    function testFailCastNoPermissions() public {
        // tinlake contracts 
        address seniorMemberList_ = spell.SENIOR_MEMBERLIST();

        // addresses for permissions setup
        address seniorMemberListAdmin1_ = spell.SENIOR_MEMBERLIST_ADMIN1();
         address seniorMemberListAdmin2_ = spell.SENIOR_MEMBERLIST_ADMIN2();
        
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin2_);
        
        // do not give spell permissions on root contract

        spell.cast();
    }

    function testFailCastTwice() public {

        // tinlake contracts 
        address seniorMemberList_ = spell.SENIOR_MEMBERLIST();

        // addresses for permissions setup
        address seniorMemberListAdmin1_ = spell.SENIOR_MEMBERLIST_ADMIN1();
         address seniorMemberListAdmin2_ = spell.SENIOR_MEMBERLIST_ADMIN2();
        
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin2_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // make sure permissions were set
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin1_);
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin2_);

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