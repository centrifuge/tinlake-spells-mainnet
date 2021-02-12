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
    }

    function preCast(address root, address seniorMemberlist, address juniorMemberlist) public {
        emit log_named_address("1", root);
        hevm.store(root, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        emit log_named_address("2", root);
        AuthLike(root).rely(spell_);
        emit log_named_address("3", root);

        assertHasNoPermissions(seniorMemberlist, spell.MEMBERADMIN());
        emit log_named_address("4", root);
        assertHasNoPermissions(juniorMemberlist, spell.MEMBERADMIN());
        emit log_named_address("5", root);
    }

    function postCast(address root, address seniorMemberlist, address juniorMemberlist) public {
        assertHasPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function testCast() public {
        preCast(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        preCast(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());

        emit log_named_address("6", 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        spell.cast();

        emit log_named_address("7", 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        postCast(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        postCast(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());
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