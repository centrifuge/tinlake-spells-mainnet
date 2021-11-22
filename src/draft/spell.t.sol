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

        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000003868594622019279553);

        spell.cast();
            
        assertDiscountChange();
    }

    function assertDiscountChange() public {
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000003329528158295281582);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(1);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002853881278538812785);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(2);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002576420598680872653);

        t_hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(3);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002298959918822932521);
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

}
