pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./spell.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {
    TinlakeSpell spell;
    
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
    }

    function testSpecificPool(address root, address seniorMemberlist, address juniorMemberlist) public {
        Hevm hevm = Hevm(root);
        hevm.store(root, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        AuthLike(root).rely(spell_);

        assertHasNoPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasNoPermissions(juniorMemberlist, spell.MEMBERADMIN());

        spell.cast();

        assertHasPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function testCast() public {
        testSpecificPool(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
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