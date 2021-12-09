// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

interface NAVFeedLike {
    function file(bytes32, uint) external;
    function discountRate() external view returns (uint256);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "HTC discount rate change mainnet spell";

    uint[3] discountRates = [1000000002853881278538812785, 1000000002576420598680872653, 1000000002298959918822932521];
    uint[3] timestamps;
    bool[3] rateAlreadySet = [false, false, false];
    
    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        root.relyContract(FEED, address(this));
    
        timestamps = [
            block.timestamp + 0 days,
            block.timestamp + 7 days,
            block.timestamp + 21 days
        ];

        setDiscount(0);
    }

    function setDiscount(uint i) public {
        require(block.timestamp >= timestamps[i], "not-yet-executable");
        require(i == 0 || NAVFeedLike(FEED).discountRate() == discountRates[i-1], "incorrect-execution-order");
        require(rateAlreadySet[i] == false, "already-executed");

        rateAlreadySet[i] = true;
        NAVFeedLike(FEED).file("discountRate", discountRates[i]);
    }

}