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

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;
    address constant public PILE = 0x3fC72dA5545E2AB6202D81fbEb1C8273Be95068C;

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

        address assessor_ = spell.ASSESSOR();
        address coordinator_ = spell.COORDINATOR();
        address navFeed_ = spell.NAV_FEED();
        address assessorAdminToBeRemoved_ = spell.ASSESSOR_ADMIN_TO_BE_REMOVED();
        address assessorWrapper_ = spell.ASSESSOR_ADMIN_WRAPPER();
        address coordinatorAdminToBeRemoved_ = spell.COORDINATOR_ADMIN_TO_BE_REMOVED();

        CoordinatorLike coordinator = CoordinatorLike(coordinator_);
        NAVFeedLike navFeed = NAVFeedLike(navFeed_);
        PileLike pile = PileLike(PILE);

        // check if assessor admin to be removed has permissions
        assertHasPermissions(assessor_, assessorAdminToBeRemoved_);
        // check if assessor admin wrapper has no permissions 
        assertHasNoPermissions(assessor_, assessorWrapper_);
        // check if coordinator admin to be removed has permissions
        assertHasPermissions(coordinator_, coordinatorAdminToBeRemoved_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // check if assessor admin to be removed has no permissions anymore
        assertHasNoPermissions(assessor_, assessorAdminToBeRemoved_);
        // check if assessor admin wrapper got permissions 
        assertHasPermissions(assessor_, assessorWrapper_);
        // check if corodinator admin to be removed has no permissions anymore
        assertHasNoPermissions(coordinator_, coordinatorAdminToBeRemoved_);
        // check if minimum epoch time was set correctly
        assertEq(coordinator.minimumEpochTime(), spell.minEpochTime());
        // check discountRate set
        assertEq(navFeed.discountRate(), spell.discountRate());
        
        //check riskGroups
        (,,uint ratePerSecond12,,) = pile.rates(12);
        assertEq(ratePerSecond12, uint(1000000003488077118214104515));
        (,,uint ratePerSecond13,,) = pile.rates(13);
        assertEq(ratePerSecond13, uint(1000000003646626078132927447));
        (,,uint ratePerSecond14,,) = pile.rates(14);
        assertEq(ratePerSecond14, uint(1000000003646626078132927447));
        (,,uint ratePerSecond15,,) = pile.rates(15);
        assertEq(ratePerSecond15, uint(1000000003805175038051750380));
        (,,uint ratePerSecond16,,) = pile.rates(16);
        assertEq(ratePerSecond16, uint(1000000003488077118214104515));
        (,,uint ratePerSecond17,,) = pile.rates(17);
        assertEq(ratePerSecond17, uint(1000000003646626078132927447));
        (,,uint ratePerSecond18,,) = pile.rates(18);
        assertEq(ratePerSecond18, uint(1000000003646626078132927447));
        (,,uint ratePerSecond19,,) = pile.rates(19);
        assertEq(ratePerSecond19, uint(1000000003805175038051750380));
        (,,uint ratePerSecond20,,) = pile.rates(20);
        assertEq(ratePerSecond20, uint(1000000003488077118214104515));
        (,,uint ratePerSecond21,,) = pile.rates(21);
        assertEq(ratePerSecond21, uint(1000000003646626078132927447));
        (,,uint ratePerSecond22,,) = pile.rates(22);
        assertEq(ratePerSecond22, uint(1000000003646626078132927447));
        (,,uint ratePerSecond23,,) = pile.rates(23);
        assertEq(ratePerSecond23, uint(1000000003805175038051750380));
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
