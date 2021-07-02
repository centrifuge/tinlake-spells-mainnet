// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

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

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint, uint48, uint);
}

interface AssessorLike {
    function seniorInterestRate() external returns (uint);
}

interface CoordinatorLike {
    function minimumEpochTime() external returns(uint);
    function challengeTime() external returns(uint);
}

contract TinlakeSpellsTest is DSTest {

    Hevm hevm;
    TinlakeSpell spell;
    
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        hevm = Hevm(HEVM_ADDRESS);
        
        hevm.store(spell.BR3_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(spell.HTC2_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(spell.FF1_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(spell.DBF1_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(spell.BL1_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(spell.CF4_ROOT_CONTRACT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        AssessorLike br3_assessor = AssessorLike(spell.BR3_ASSESSOR());
        AssessorLike htc2_assessor = AssessorLike(spell.HTC2_ASSESSOR());
        AssessorLike ff1_assessor = AssessorLike(spell.FF1_ASSESSOR());
        NAVFeedLike br3_feed = NAVFeedLike(spell.BR3_FEED());
        PileLike htc2_pile = PileLike(spell.HTC2_PILE());
        PileLike ff1_pile = PileLike(spell.FF1_PILE());
        CoordinatorLike bl1_coordinator = CoordinatorLike(spell.BL1_COORDINATOR());
        CoordinatorLike cf4_coordinator = CoordinatorLike(spell.CF4_COORDINATOR());

        AuthLike(spell.BR3_ROOT_CONTRACT()).rely(spell_);
        AuthLike(spell.HTC2_ROOT_CONTRACT()).rely(spell_);
        AuthLike(spell.FF1_ROOT_CONTRACT()).rely(spell_);
        AuthLike(spell.DBF1_ROOT_CONTRACT()).rely(spell_);
        AuthLike(spell.BL1_ROOT_CONTRACT()).rely(spell_);
        AuthLike(spell.CF4_ROOT_CONTRACT()).rely(spell_);

        assertHasNoPermissions(spell.HTC2_FEED(), spell.htc2_oracle());
        assertHasNoPermissions(spell.DBF1_FEED(), spell.dbf1_oracle());

        spell.cast();

        assertEq(br3_assessor.seniorInterestRate(), spell.br3_seniorInterestRate());
        assertEq(htc2_assessor.seniorInterestRate(), spell.htc2_seniorInterestRate());
        assertEq(ff1_assessor.seniorInterestRate(), spell.ff1_seniorInterestRate());

        assertEq(br3_feed.discountRate(), spell.br3_discountRate());

        (,,uint ratePerSecondHtc2_1,,) = htc2_pile.rates(1);
        assertEq(ratePerSecondHtc2_1, uint(1000000001585490000));
        (,,uint ratePerSecondHtc2_16,,) = htc2_pile.rates(16);
        assertEq(ratePerSecondHtc2_16, uint(1000000002774610000));
        (,,uint ratePerSecondHtc2_33,,) = htc2_pile.rates(33);
        assertEq(ratePerSecondHtc2_33, uint(1000000004122270000));

        (,,uint ratePerSecondFf1_1,,) = ff1_pile.rates(1);
        assertEq(ratePerSecondFf1_1, uint(1000000001696470000));
        (,,uint ratePerSecondFf1_3,,) = ff1_pile.rates(3);
        assertEq(ratePerSecondFf1_3, uint(1000000001997720000));
        (,,uint ratePerSecondFf1_5,,) = ff1_pile.rates(5);
        assertEq(ratePerSecondFf1_5, uint(1000000004433030000));

        assertEq(bl1_coordinator.minimumEpochTime(), spell.bl1_minEpochTime());
        assertEq(cf4_coordinator.challengeTime(), spell.cf4_challengeTime());

        assertHasPermissions(spell.HTC2_FEED(), spell.htc2_oracle());
        assertHasPermissions(spell.DBF1_FEED(), spell.dbf1_oracle());
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