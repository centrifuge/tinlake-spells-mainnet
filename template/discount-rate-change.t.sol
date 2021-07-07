// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "src/draft/spell.sol";
import "src/base.sol";

contract SpellTest is BaseSpellTest {

    function setUp() public virtual {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));

        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002378234398782343987);

        spell.cast();
            
        assertDiscountChange();
    }

    function assertDiscountChange() public {
        // TODO: replace these
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002243467782851344495);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(1);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002108701166920345002);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(2);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000001973934550989345509);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(3);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000001839167935058346017);
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));
        spell.cast();
        spell.cast();
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }

    // --- Math ---
    function safeAdd(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-add-overflow");
    }
}
