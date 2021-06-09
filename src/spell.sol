// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

import "./addresses.sol";

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake Rate Update spell";

    uint constant public seniorInterestRate = uint(1000000003170979198376458650);
    uint constant public discountRate = uint(1000000004100076103500761035);

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike root = TinlakeRootLike(address(ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(FEED));
        self = address(this);

        root.relyContract(ASSESSOR, self);
        root.relyContract(FEED, self);

        FileLike(ASSESSOR).file("seniorInterestRate", seniorInterestRate);
        navFeed.file("discountRate", discountRate);
    }
}