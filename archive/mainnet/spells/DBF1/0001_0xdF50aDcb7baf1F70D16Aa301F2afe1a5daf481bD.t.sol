pragma solidity 0.6.7;

import "ds-test/test.sol";
import "./spell.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface ERC20 {
    function balanceOf(address usr) external returns (uint amount);
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
        AuthLike(root_).rely(spell_);
    }

    function testCast() public {
        uint balance = ERC20(spell.CURRENCY()).balanceOf(spell.SENIOR_TRANCHE());
        spell.cast();
        assertEq(ERC20(spell.CURRENCY()).balanceOf(spell.SENIOR_TRANCHE()), balance + spell.payoutAmount());
    }

}
