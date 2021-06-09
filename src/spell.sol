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

    uint constant public br3_seniorInterestRate = uint(1000000003170979198376458650);
    uint constant public br3_discountRate = uint(1000000004100076103500761035);

    uint constant public htc2_seniorInterestRate = uint(1000000002219685438863521055);
    address constant public htc2_oracle = 0x47B4B2a7a674da66a557a508f3A8e7b68a4759C3;

    uint constant public ff1_seniorInterestRate = uint(1000000001585489599188229325);

    address constant public dbf1_oracle = 0xE84a6555777452c34Bc1Bf3929484083E81d940a;

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        updateBR3();
        updateHTC2();
        updateFF1();
        updateDBF1();
        updateBL1();
        updateCF4();
    }

    function updateBR3() internal {
        TinlakeRootLike root = TinlakeRootLike(address(BR3_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(BR3_FEED));

        root.relyContract(BR3_ASSESSOR, address(this));
        root.relyContract(BR3_FEED, address(this));

        FileLike(BR3_ASSESSOR).file("seniorInterestRate", br3_seniorInterestRate);
        navFeed.file("discountRate", br3_discountRate);
    }

    function updateHTC2() internal {
        TinlakeRootLike root = TinlakeRootLike(address(HTC2_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(HTC2_FEED));

        root.relyContract(HTC2_ASSESSOR, address(this));
        root.relyContract(HTC2_FEED, address(this));
        root.relyContract(HTC2_FEED, htc2_oracle);

        FileLike(HTC2_ASSESSOR).file("seniorInterestRate", htc2_seniorInterestRate);

        // risk group: 1 - , APR: 5%
        navFeed.file("riskGroup", 1, ONE, ONE, uint(1000000001585490000), 99.95*10**25);
        // risk group: 2 - , APR: 5.25%
        navFeed.file("riskGroup", 2, ONE, ONE, uint(1000000001664760000), 99.93*10**25);
        // risk group: 3 - , APR: 5.5%
        navFeed.file("riskGroup", 3, ONE, ONE, uint(1000000001744040000), 99.91*10**25);
        // risk group: 4 - , APR: 5.75%
        navFeed.file("riskGroup", 4, ONE, ONE, uint(1000000001823310000), 99.9*10**25);
        // risk group: 5 - , APR: 6%
        navFeed.file("riskGroup", 5, ONE, ONE, uint(1000000001902590000), 99.88*10**25);
        // risk group: 6 - , APR: 6.25%
        navFeed.file("riskGroup", 6, ONE, ONE, uint(1000000001981860000), 99.87*10**25);
        // risk group: 7 - , APR: 6.5%
        navFeed.file("riskGroup", 7, ONE, ONE, uint(1000000002061140000), 99.85*10**25);
        // risk group: 8 - , APR: 6.75%
        navFeed.file("riskGroup", 8, ONE, ONE, uint(1000000002140410000), 99.84*10**25);
        // risk group: 9 - , APR: 7%
        navFeed.file("riskGroup", 9, ONE, ONE, uint(1000000002219690000), 99.82*10**25);
        // risk group: 10 - , APR: 7.25%
        navFeed.file("riskGroup", 10, ONE, ONE, uint(1000000002298960000), 99.81*10**25);
        // risk group: 11 - , APR: 7.5%
        navFeed.file("riskGroup", 11, ONE, ONE, uint(1000000002378230000), 99.79*10**25);
        // risk group: 12 - , APR: 7.75%
        navFeed.file("riskGroup", 12, ONE, ONE, uint(1000000002457510000), 99.78*10**25);
        // risk group: 13 - , APR: 8%
        navFeed.file("riskGroup", 13, ONE, ONE, uint(1000000002536780000), 99.76*10**25);
        // risk group: 14 - , APR: 8.25%
        navFeed.file("riskGroup", 14, ONE, ONE, uint(1000000002616060000), 99.74*10**25);
        // risk group: 15 - , APR: 8.5%
        navFeed.file("riskGroup", 15, ONE, ONE, uint(1000000002695330000), 99.73*10**25);
        // risk group: 16 - , APR: 8.75%
        navFeed.file("riskGroup", 16, ONE, ONE, uint(1000000002774610000), 99.71*10**25);
        // risk group: 17 - , APR: 9%
        navFeed.file("riskGroup", 17, ONE, ONE, uint(1000000002853880000), 99.7*10**25);
        // risk group: 18 - , APR: 9.25%
        navFeed.file("riskGroup", 18, ONE, ONE, uint(1000000002933160000), 99.68*10**25);
        // risk group: 19 - , APR: 9.5%
        navFeed.file("riskGroup", 19, ONE, ONE, uint(1000000003012430000), 99.67*10**25);
        // risk group: 20 - , APR: 9.75%
        navFeed.file("riskGroup", 20, ONE, ONE, uint(1000000003091700000), 99.65*10**25);
        // risk group: 21 - , APR: 10%
        navFeed.file("riskGroup", 21, ONE, ONE, uint(1000000003170980000), 99.64*10**25);
        // risk group: 22 - , APR: 10.25%
        navFeed.file("riskGroup", 22, ONE, ONE, uint(1000000003250250000), 99.62*10**25);
        // risk group: 23 - , APR: 10.5%
        navFeed.file("riskGroup", 23, ONE, ONE, uint(1000000003329530000), 99.61*10**25);
        // risk group: 24 - , APR: 10.75%
        navFeed.file("riskGroup", 24, ONE, ONE, uint(1000000003408800000), 99.59*10**25);
        // risk group: 25 - , APR: 11%
        navFeed.file("riskGroup", 25, ONE, ONE, uint(1000000003488080000), 99.58*10**25);
        // risk group: 26 - , APR: 11.25%
        navFeed.file("riskGroup", 26, ONE, ONE, uint(1000000003567350000), 99.56*10**25);
        // risk group: 27 - , APR: 11.5%
        navFeed.file("riskGroup", 27, ONE, ONE, uint(1000000003646630000), 99.54*10**25);
        // risk group: 28 - , APR: 11.75%
        navFeed.file("riskGroup", 28, ONE, ONE, uint(1000000003725900000), 99.53*10**25);
        // risk group: 29 - , APR: 12%
        navFeed.file("riskGroup", 29, ONE, ONE, uint(1000000003805180000), 99.51*10**25);
        // risk group: 30 - , APR: 12.25%
        navFeed.file("riskGroup", 30, ONE, ONE, uint(1000000003884450000), 99.5*10**25);
        // risk group: 31 - , APR: 12.5%
        navFeed.file("riskGroup", 31, ONE, ONE, uint(1000000003963720000), 99.48*10**25);
        // risk group: 32 - , APR: 12.75%
        navFeed.file("riskGroup", 32, ONE, ONE, uint(1000000004043000000), 99.47*10**25);
        // risk group: 33 - , APR: 13%
        navFeed.file("riskGroup", 33, ONE, ONE, uint(1000000004122270000), 99.45*10**25);
    }

    function updateFF1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(FF1_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(FF1_FEED));

        root.relyContract(FF1_ASSESSOR, address(this));
        root.relyContract(FF1_FEED, address(this));

        FileLike(FF1_ASSESSOR).file("seniorInterestRate", 1000000001585489599188229325);

        // risk group: 1 - P A, APR: 5.35%
        navFeed.file("riskGroup", 1, ONE, ONE, uint(1000000001696470000), 99.5*10**25);
        // risk group: 2 - P BBB, APR: 5.83%
        navFeed.file("riskGroup", 2, ONE, ONE, uint(1000000001848680000), 99.5*10**25);
        // risk group: 3 - P BB, APR: 6.3%
        navFeed.file("riskGroup", 3, ONE, ONE, uint(1000000001997720000), 99.5*10**25);
        // risk group: 4 - P B, APR: 6.77%
        navFeed.file("riskGroup", 4, ONE, ONE, uint(1000000002146750000), 99.5*10**25);
        // risk group: 5 - C, APR: 13.98%
        navFeed.file("riskGroup", 5, ONE, ONE, uint(1000000004433030000), 98.5*10**25);
    }

    function updateDBF1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(DBF1_ROOT_CONTRACT));
        root.relyContract(DBF1_FEED, dbf1_oracle);
    }

    function updateBL1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(BL1_ROOT_CONTRACT));
        root.relyContract(BL1_COORDINATOR, address(this));

        FileLike(BL1_COORDINATOR).file("minimumEpochTime", 1 days - 10 minutes);
    }

    function updateCF4() internal {
        TinlakeRootLike root = TinlakeRootLike(address(CF4_ROOT_CONTRACT));
        root.relyContract(CF4_COORDINATOR, address(this));

        FileLike(CF4_COORDINATOR).file("challengeTime", 30 minutes);
    }
}