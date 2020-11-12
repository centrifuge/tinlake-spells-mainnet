pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./../src/spell.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // tinlake contracts 
        address seniorOperatorNew_ = spell.SENIOR_OPERATOR_NEW();
        address seniorOperatorOld_ = spell.SENIOR_OPERATOR_OLD();
        address seniorTranche_ = spell.SENIOR_TRANCHE();

        // addresses for permissions setup
        address seniorOperatorAdmin1_ = spell.SENIOR_OPERATOR_ADMIN1();
        address seniorOperatorAdmin2_ = spell.SENIOR_OPERATOR_ADMIN2();
        address seniorOperatorAdmin3_ = spell.SENIOR_OPERATOR_ADMIN3();
        address seniorOperatorAdminOld_ = spell.SENIOR_OPERATOR_ADMIN_OLD();

        // make sure permissions are set as expected prior to cast
        assertHasNoPermissions(seniorTranche_, seniorOperatorNew_);
        assertHasPermissions(seniorTranche_, seniorOperatorOld_);
        assertHasNoPermissions(seniorOperatorNew_, seniorOperatorAdmin1_);
        assertHasNoPermissions(seniorOperatorNew_, seniorOperatorAdmin2_);
        assertHasNoPermissions(seniorOperatorNew_, seniorOperatorAdmin3_);
        assertHasPermissions(seniorOperatorNew_, seniorOperatorAdminOld_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // make sure permissions are set correctly after cast
        assertHasPermissions(seniorTranche_, seniorOperatorNew_);
        assertHasNoPermissions(seniorTranche_, seniorOperatorOld_);
        assertHasPermissions(seniorOperatorNew_, seniorOperatorAdmin1_);
        assertHasPermissions(seniorOperatorNew_, seniorOperatorAdmin2_);
        assertHasPermissions(seniorOperatorNew_, seniorOperatorAdmin3_);
        assertHasNoPermissions(seniorOperatorNew_, seniorOperatorAdminOld_);

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