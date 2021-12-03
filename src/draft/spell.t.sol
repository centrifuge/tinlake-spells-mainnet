pragma solidity >=0.7.0;

import "ds-test/test.sol";
import "./spell.sol";


abstract contract Hevm {
    function warp(uint256) public virtual;
    function store(address, bytes32, bytes32) public virtual;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT_CONTRACT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

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
}