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
    Hevm hevm;
    TinlakeSpell spell;
    
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(spell.MEMBERADMIN(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function preCast(address root, address seniorMemberlist, address juniorMemberlist) public {
        hevm.store(root, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        AuthLike(root).rely(spell_);

        assertHasNoPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasNoPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function postCast(address root, address seniorMemberlist, address juniorMemberlist) public {
        assertHasPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function testCast() public {
        preCast(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        preCast(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());
        preCast(spell.ROOT_DBF1(), spell.SENIOR_MEMBERLIST_DBF1(), spell.JUNIOR_MEMBERLIST_DBF1());
        preCast(spell.ROOT_FF1(), spell.SENIOR_MEMBERLIST_FF1(), spell.JUNIOR_MEMBERLIST_FF1());
        preCast(spell.ROOT_HTC2(), spell.SENIOR_MEMBERLIST_HTC2(), spell.JUNIOR_MEMBERLIST_HTC2());
        preCast(spell.ROOT_NS2(), spell.SENIOR_MEMBERLIST_NS2(), spell.JUNIOR_MEMBERLIST_NS2());
        preCast(spell.ROOT_PC3(), spell.SENIOR_MEMBERLIST_PC3(), spell.JUNIOR_MEMBERLIST_HTC2());

        spell.cast();

        postCast(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        postCast(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());
        postCast(spell.ROOT_DBF1(), spell.SENIOR_MEMBERLIST_DBF1(), spell.JUNIOR_MEMBERLIST_DBF1());
        postCast(spell.ROOT_FF1(), spell.SENIOR_MEMBERLIST_FF1(), spell.JUNIOR_MEMBERLIST_FF1());
        postCast(spell.ROOT_HTC2(), spell.SENIOR_MEMBERLIST_HTC2(), spell.JUNIOR_MEMBERLIST_HTC2());
        postCast(spell.ROOT_NS2(), spell.SENIOR_MEMBERLIST_NS2(), spell.JUNIOR_MEMBERLIST_NS2());
        postCast(spell.ROOT_PC3(), spell.SENIOR_MEMBERLIST_PC3(), spell.JUNIOR_MEMBERLIST_PC3());
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