pragma solidity >=0.5.15;

import "ds-test/test.sol";
import "./../src/spell.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
}

interface AssessorLike {
    function seniorInterestRate() external returns (uint);
}

contract TinlakeSpellsTest is DSTest {

    Hevm hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;
    address constant public PILE = 0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.NS2_ROOT());  
        hevm = Hevm(HEVM_ADDRESS);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        address assessor_ = spell.NS2_ASSESSOR();

        AssessorLike assessor = AssessorLike(assessor_);
        PileLike pile = PileLike(PILE);

        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // check seniorInterestRate
        assertEq(assessor.seniorInterestRate(), spell.ns2_seniorInterestRate());
        
        // check a few riskGroups
        (,,uint ratePerSecond41,,) = pile.rates(41);
        assertEq(ratePerSecond41, uint(1000000001090820000000000000));
        (,,uint ratePerSecond53,,) = pile.rates(53);
        assertEq(ratePerSecond53, uint(1000000001547440000000000000));
        (,,uint ratePerSecond65,,) = pile.rates(65);
        assertEq(ratePerSecond65, uint(1000000001996765601217656012));
        (,,uint ratePerSecond97,,) = pile.rates(97);
        assertEq(ratePerSecond97, uint(1000000003166222729578893962));
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