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
        address oldPoolAdmin_ = address(spell.POOL_ADMIN_OLD());
        address newPoolAdmin_ = address(spell.POOL_ADMIN_NEW());
        address assessor_ = address(spell.ASSESSOR());
        address clerk_ = spell.CLERK();
        address seniorMemberList_ = address(spell.SENIOR_MEMBERLIST());
        address juniorMemberList_ = address(spell.JUNIOR_MEMBERLIST());
        
        assertHasPermissions(assessor_, oldPoolAdmin_);
        assertHasPermissions(clerk_, oldPoolAdmin_);
        assertHasPermissions(seniorMemberList_, oldPoolAdmin_);
        assertHasPermissions(juniorMemberList_, oldPoolAdmin_);
        
        assertHasNoPermissions(assessor_, newPoolAdmin_);
        assertHasNoPermissions(clerk_, newPoolAdmin_);
        assertHasNoPermissions(seniorMemberList_, newPoolAdmin_);
        assertHasNoPermissions(juniorMemberList_, newPoolAdmin_);

        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();

        // make sure permissions were moved
        assertHasNoPermissions(assessor_, oldPoolAdmin_);
        assertHasNoPermissions(clerk_, oldPoolAdmin_);
        assertHasNoPermissions(seniorMemberList_, oldPoolAdmin_);
        assertHasNoPermissions(juniorMemberList_, oldPoolAdmin_);

        assertHasPermissions(assessor_, newPoolAdmin_);
        assertHasPermissions(clerk_, newPoolAdmin_);
        assertHasPermissions(seniorMemberList_, newPoolAdmin_);
        assertHasPermissions(juniorMemberList_, newPoolAdmin_);
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
