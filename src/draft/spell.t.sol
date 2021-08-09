// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "src/draft/spell.sol";
import "src/base.sol";

interface ContractWithLending {
  function lending() external view returns (address);
}

contract SpellTest is BaseSpellTest {

    function setUp() public virtual {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));

        assertEq(ContractWithLending(spell.ASSESSOR()).lending(), spell.CLERK());
        assertEq(ContractWithLending(spell.RESERVE()).lending(), spell.CLERK());

        spell.cast();

        assertEq(ContractWithLending(spell.ASSESSOR()).lending(), address(0));
        assertEq(ContractWithLending(spell.RESERVE()).lending(), address(0));
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
