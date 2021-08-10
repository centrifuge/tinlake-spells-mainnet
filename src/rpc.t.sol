// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./base.sol";
import "../lib/tinlake-rpc-tests/src/contracts/rpc-tests.sol";


contract SpellRPCTest is TinlakeRPCTests, BaseSpellTest {
    function setUp() public override {
        initSpell();
        castSpell();

        // override addresses
        ASSESSOR = spell.ASSESSOR();
        CLERK = spell.CLERK();
        COLLECTOR = spell.COLLECTOR();
        COORDINATOR = spell.COORDINATOR();
        FEED = spell.FEED();
        JUNIOR_MEMBERLIST = spell.JUNIOR_MEMBERLIST();
        JUNIOR_OPERATOR = spell.JUNIOR_OPERATOR();
        JUNIOR_TOKEN = spell.JUNIOR_TOKEN();
        JUNIOR_TRANCHE = spell.JUNIOR_TRANCHE();
        PILE = spell.PILE();
        POOL_ADMIN = spell.POOL_ADMIN();
        RESERVE = spell.RESERVE();
        ROOT_CONTRACT = spell.ROOT_CONTRACT();
        SENIOR_MEMBERLIST = spell.SENIOR_MEMBERLIST();
        SENIOR_OPERATOR = spell.SENIOR_OPERATOR();
        SENIOR_TOKEN = spell.SENIOR_TOKEN();
        SENIOR_TRANCHE = spell.SENIOR_TRANCHE();
        SHELF = spell.SHELF();
        TINLAKE_CURRENCY = spell.TINLAKE_CURRENCY();

        // rpc tests should use the new addresses from the spell
        COORDINATOR = spell.COORDINATOR_NEW();
        RESERVE = spell.RESERVE_NEW();
        ASSESSOR = spell.ASSESSOR_NEW();
        SENIOR_TRANCHE = spell.SENIOR_TRANCHE_NEW();
        POOL_ADMIN = spell.POOL_ADMIN();
        CLERK = spell.CLERK();
    
        initRPC();
    }

    function testLoanCycleWithMaker() public {
        runLoanCycleWithMaker();
    }

}
