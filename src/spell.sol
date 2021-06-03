// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.5.15;

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

// This spell makes multiple rate changes
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Rate Update June 4 2021";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public NS2_ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public NS2_ASSESSOR = 0x6aaf2EE5b2B62fb9E29E021a1bF3B381454d900a;
    address constant public NS2_NAV_FEED = 0x69504da6B2Cd8320B9a62F3AeD410a298d3E7Ac6;

    // change dropAPR to 6%               
    uint constant public ns2_seniorInterestRate = uint(1000000001268391679350583460);
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike ns2_root = TinlakeRootLike(address(NS2_ROOT));
        NAVFeedLike ns2_navFeed = NAVFeedLike(address(NS2_NAV_FEED));
        self = address(this);
        // add permissions  
        // Assessor
        ns2_root.relyContract(NS2_ASSESSOR, self);
        // NavFeed 
        ns2_root.relyContract(NS2_NAV_FEED, self); // required to file riskGroups & change discountRate

        // file drop interest rate
        FileLike(NS2_ASSESSOR).file("seniorInterestRate", ns2_seniorInterestRate);

        // risk group: 24 - ADF3, APR: 9%
        // navFeed.file("riskGroup", 24, ONE, ONE, uint(1000000002853881278538812785), 99.93*10**25);
    }
}