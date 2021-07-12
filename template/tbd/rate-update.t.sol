// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

import "ds-test/test.sol";
import "./rate-update.sol";

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

contract TinlakeSpellsTest is DSTest {

    Hevm hevm;
    TinlakeSpell spell;
    
    address root_;
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT_CONTRACT());  
        hevm = Hevm(HEVM_ADDRESS);
        
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        address assessor_ = spell.ASSESSOR();
        AssessorLike assessor = AssessorLike(assessor_);
        PileLike pile = PileLike(spell.PILE());
        AuthLike(root_).rely(spell_);

        spell.cast();

        assertEq(assessor.seniorInterestRate(), spell.seniorInterestRate());
        
        // TODO: add a few risk group checks here
        (,,uint ratePerSecond41,,) = pile.rates(41);
        assertEq(ratePerSecond41, uint(1000000001090820000000000000));
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