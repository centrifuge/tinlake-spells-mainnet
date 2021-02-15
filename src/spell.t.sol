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

    function preMakeWard(address root, address seniorMemberlist, address juniorMemberlist) public {
        hevm.store(root, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        AuthLike(root).rely(spell_);
        assertHasNoPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasNoPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function postMakeWard(address root, address seniorMemberlist, address juniorMemberlist) public {
        assertHasPermissions(seniorMemberlist, spell.MEMBERADMIN());
        assertHasPermissions(juniorMemberlist, spell.MEMBERADMIN());
    }

    function test() public {
        // Memberadmin is not a ward on the memberlists
        preMakeWard(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        preMakeWard(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());
        preMakeWard(spell.ROOT_DBF1(), spell.SENIOR_MEMBERLIST_DBF1(), spell.JUNIOR_MEMBERLIST_DBF1());
        preMakeWard(spell.ROOT_FF1(), spell.SENIOR_MEMBERLIST_FF1(), spell.JUNIOR_MEMBERLIST_FF1());
        preMakeWard(spell.ROOT_HTC2(), spell.SENIOR_MEMBERLIST_HTC2(), spell.JUNIOR_MEMBERLIST_HTC2());
        preMakeWard(spell.ROOT_NS2(), spell.SENIOR_MEMBERLIST_NS2(), spell.JUNIOR_MEMBERLIST_NS2());
        preMakeWard(spell.ROOT_PC3(), spell.SENIOR_MEMBERLIST_PC3(), spell.JUNIOR_MEMBERLIST_HTC2());

        // Onboard API is not an admin
        hevm.store(spell.MEMBERADMIN(), keccak256(abi.encode(spell_, uint(0))), bytes32(uint(1)));
        uint perm = MemberAdminLike(spell.MEMBERADMIN()).admins(spell.ONBOARD_API());
        assertEq(perm, 0);

        // Run spell
        spell.cast();

        // Memberadmin is a ward on the memberlists
        postMakeWard(spell.ROOT_BL1(), spell.SENIOR_MEMBERLIST_BL1(), spell.JUNIOR_MEMBERLIST_BL1());
        postMakeWard(spell.ROOT_CF4(), spell.SENIOR_MEMBERLIST_CF4(), spell.JUNIOR_MEMBERLIST_CF4());
        postMakeWard(spell.ROOT_DBF1(), spell.SENIOR_MEMBERLIST_DBF1(), spell.JUNIOR_MEMBERLIST_DBF1());
        postMakeWard(spell.ROOT_FF1(), spell.SENIOR_MEMBERLIST_FF1(), spell.JUNIOR_MEMBERLIST_FF1());
        postMakeWard(spell.ROOT_HTC2(), spell.SENIOR_MEMBERLIST_HTC2(), spell.JUNIOR_MEMBERLIST_HTC2());
        postMakeWard(spell.ROOT_NS2(), spell.SENIOR_MEMBERLIST_NS2(), spell.JUNIOR_MEMBERLIST_NS2());
        postMakeWard(spell.ROOT_PC3(), spell.SENIOR_MEMBERLIST_PC3(), spell.JUNIOR_MEMBERLIST_PC3());

        // Onboard API is an admin
        perm = MemberAdminLike(spell.MEMBERADMIN()).admins(spell.ONBOARD_API());
        assertEq(perm, 1);
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