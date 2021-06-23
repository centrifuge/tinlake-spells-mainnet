// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

import "ds-test/test.sol";
import "./reserve-migration.sol";
import "tinlake-math/math.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface IReserve {
    function assessor() external returns(address);
    function currency() external returns(address);
    function shelf() external returns(address);
    function pot() external returns(address);
    function lending() external returns(address);
    function currencyAvailable() external returns(uint);
    function balance_() external returns(uint);
}

interface IShelf {
    function distributor() external returns(address);
    function lender() external returns(address);
}

interface ITranche {
    function reserve() external returns(address);
}

contract TinlakeSpellsTest is DSTest, Math {

    Hevm hevm;
    TinlakeSpell spell;
    
    uint poolReserveDAI;

    function setUp() public {
        spell = new TinlakeSpell();
        hevm = Hevm(HEVM_ADDRESS);
        
        hevm.store(address(spell.ROOT_CONTRACT()), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        AuthLike(address(spell.ROOT_CONTRACT())).rely(address(spell));
        poolReserveDAI = SpellERC20Like(spell.TINLAKE_CURRENCY()).balanceOf(spell.RESERVE());

        spell.cast();

        IReserve reserve = IReserve(spell.RESERVE_NEW());
        IReserve reserveOld = IReserve(spell.RESERVE());

         // check dependencies 
        assertEq(reserve.assessor(), spell.ASSESSOR());
        assertEq(reserve.currency(), spell.TINLAKE_CURRENCY());
        assertEq(reserve.shelf(), spell.SHELF());
        assertEq(reserve.lending(), spell.CLERK());
        assertEq(ITranche(spell.JUNIOR_TRANCHE()).reserve(), address(reserve));
        // assertEq(reserve.pot(), pot_); -> has to be public
        assertEq(IShelf(spell.SHELF()).distributor(), address(reserve));
        assertEq(IShelf(spell.SHELF()).lender(), address(reserve));
        // assertEq(collector.distributor(), reserve_); -> has to be public

        // check permissions
        assertHasPermissions(address(reserve), spell.CLERK());
        assertHasPermissions(address(reserve), spell.JUNIOR_TRANCHE());
        assertHasPermissions(address(reserve), spell.SENIOR_TRANCHE());

        // check state
        assertEq(reserve.currencyAvailable(), reserveOld.currencyAvailable());   
        assertEq(reserve.balance_(), safeAdd(reserveOld.balance_(), poolReserveDAI));
        assertEq(SpellERC20Like(spell.TINLAKE_CURRENCY()).balanceOf(address(reserve)), poolReserveDAI);

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