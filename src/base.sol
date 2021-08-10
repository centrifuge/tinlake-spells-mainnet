// SPDX-License-Identifier: AGPL-3.0-only\
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./draft/spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IAssessor {
    function navFeed() external returns(address);
    function reserve() external returns(address); 
    function seniorRatio() external view returns(uint);
    function totalBalance() external view returns(uint);
    function seniorDebt_() external view returns(uint);
    function seniorBalance_() external view returns(uint);
    function calcSeniorTokenPrice(uint NAV, uint reserve_) external view returns(uint);
    function calcJuniorTokenPrice(uint NAV, uint reserve_) external view returns(uint);
    function lending() external returns(address);
    function seniorTranche() external returns(address);
    function juniorTranche() external returns(address);
    function seniorInterestRate() external view returns(uint);
    function lastUpdateSeniorInterest() external view returns(uint);
    function minSeniorRatio() external view returns(uint);
    function maxSeniorRatio() external view returns(uint);
    function maxReserve() external view returns(uint);
}

interface INav {
    function currentNAV() external view returns(uint);
    function approximatedNAV() external view returns(uint);
}

interface ITranche {
    function epochTicker() external returns(address);
    function reserve() external returns(address);
}

interface ICoordinator  {
    function assessor() external returns(address);
    function juniorTranche() external returns(address);
    function seniorTranche() external returns(address);
    function reserve() external returns(address);
    function lastEpochClosed() external returns(uint);
    function minimumEpochTime() external returns(uint);
    function lastEpochExecuted() external returns(uint);
    function currentEpoch() external returns(uint);
    function bestSubmission() external returns(uint, uint, uint, uint);
    function order() external returns(uint, uint, uint, uint);
    function bestSubScore() external returns(uint);
    function gotFullValidSolution() external returns(bool);
    function epochSeniorTokenPrice() external returns(uint);
    function epochJuniorTokenPrice() external returns(uint);
    function epochNAV() external returns(uint);
    function epochSeniorAsset() external returns(uint);
    function epochReserve() external returns(uint);
    function submissionPeriod() external returns(bool);
    function weightSeniorRedeem() external returns(uint);
    function weightJuniorRedeem() external returns(uint);
    function weightJuniorSupply() external returns(uint);
    function weightSeniorSupply() external returns(uint);
    function minChallengePeriodEnd() external returns(uint);
    function challengeTime() external returns(uint);
    function bestRatioImprovement() external returns(uint);
    function bestReserveImprovement() external returns(uint);
    function poolClosing() external returns(bool);
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


interface IOperator {
    function tranche() external returns(address);
}

interface IPoolAdminLike {
    function admins(address) external returns(uint);
    function assessor() external returns(address);
    function lending() external returns(address);
    function juniorMemberlist() external returns(address);
    function seniorMemberlist() external returns(address);
}

interface IClerk {
    function assessor() external returns(address);
    function mgr() external returns(address);
    function coordinator() external returns(address);
    function reserve() external returns(address); 
    function tranche() external returns(address);
    function collateral() external returns(address);
    function spotter() external returns(address);
    function vat() external returns(address);
    function jug() external returns(address);
    function matBuffer() external returns(uint);
}

interface IShelf {
    function distributor() external returns(address);
    function lender() external returns(address);
}

interface ICollector {
    function distributor() external returns(address);
}

interface IRestrictedToken {
    function hasMember(address member) external returns(bool);
}

interface IMgr {
    function owner() external returns(address);
    function pool() external returns(address);
    function tranche() external returns(address);
    function urn() external returns(address);
    function liq() external returns(address);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;

    ICoordinator t_coordinator;
    ITranche t_seniorTranche;
    ITranche t_juniorTranche;
    SpellERC20Like t_currency;
    IAssessor t_assessor;
    IReserve t_reserve;
    IClerk t_clerk;
    IMgr t_mgr;
    IOperator t_seniorOperator;
    IShelf t_shelf;
    IRestrictedToken t_seniorToken;
    IPoolAdminLike t_poolAdmin;

    function initSpell() public {
        spell = new TinlakeSpell();

        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        t_coordinator = ICoordinator(spell.COORDINATOR_NEW());
        t_seniorTranche = ITranche(spell.SENIOR_TRANCHE_NEW());
        t_juniorTranche = ITranche(spell.JUNIOR_TRANCHE());
        t_currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        t_assessor = IAssessor(spell.ASSESSOR_NEW());
        t_reserve = IReserve(spell.RESERVE_NEW());
        t_clerk = IClerk(spell.CLERK());
        t_mgr = IMgr(spell.MAKER_MGR());
        t_seniorOperator = IOperator(spell.SENIOR_OPERATOR());
        t_shelf = IShelf(spell.SHELF());
        t_seniorToken = IRestrictedToken(spell.SENIOR_TOKEN());
        t_poolAdmin = IPoolAdminLike(spell.POOL_ADMIN());

        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        t_hevm.store(spell.ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(spell.ROOT_CONTRACT()).rely(address(spell));
        spell.cast();
    }

}
