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
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// TODO: split interfaces between tests and spell. Exclude all the function that afre only used in tests
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

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
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

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell {


// {
//   "DEPLOYMENT_NAME": "NewSilver 2 mainnet deployment",
//   "ROOT_CONTRACT": "0x53b2d22d07E069a3b132BfeaaD275b10273d381E",
//   "TINLAKE_CURRENCY": "0x6b175474e89094c44da98b954eedeac495271d0f",
//   "BORROWER_DEPLOYER": "0x9137BFdbB43BDf83DB5B8e691B5D2ceBE6475392",
//   "TITLE": "0x07cdD617c53B07208b0371C93a02deB8d8D49C6e",
//   "PILE": "0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f",
//   "SHELF": "0x7d057A056939bb96D682336683C10EC89b78D7CE",
//   "COLLECTOR": "0x62f290512c690a817f47D2a4a544A5d48D1408BE",
//   "FEED": "0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D",
//   "JUNIOR_OPERATOR": "0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01",
//   "SENIOR_OPERATOR": "0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C",
//   "JUNIOR_TRANCHE": "0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707",
//   "SENIOR_TRANCHE": "0xfB30B47c47E2fAB74ca5b0c1561C2909b280c4E5",
//   "JUNIOR_TOKEN": "0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1",
//   "SENIOR_TOKEN": "0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0",
//   "JUNIOR_MEMBERLIST": "0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD",
//   "SENIOR_MEMBERLIST": "0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA",
//   "ASSESSOR": "0xdA0bA5Dd06C8BaeC53Fa8ae25Ad4f19088D6375b",
//   "ASSESSOR_ADMIN": "0x46470030e1c732A9C2b541189471E47661311375",
//   "COORDINATOR": "0xFE860d06fF2a3A485922A6a029DFc1CD8A335288",
//   "RESERVE": "0x30FDE788c346aBDdb564110293B20A13cF1464B6",
//   "GOVERNANCE": "0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25",
//   "POOL_ADMIN": "0x6A82DdF0DF710fACD0414B37606dC9Db05a4F752"
// }

    bool public done;
    string constant public description = "Tinlake clerk migration mainnet spell";

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public SHELF = 0x7d057A056939bb96D682336683C10EC89b78D7CE;
    address constant public COLLECTOR = 0x62f290512c690a817f47D2a4a544A5d48D1408BE;
    address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
    address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
    address constant public JUNIOR_TRANCHE = 0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707;
    address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;
    address constant public POOL_ADMIN = 0x6A82DdF0DF710fACD0414B37606dC9Db05a4F752;
    address constant public NAV = 0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D;
    address constant public SENIOR_TRANCHE_OLD = 0xfB30B47c47E2fAB74ca5b0c1561C2909b280c4E5;
    address constant public ASSESSOR_OLD = 0xdA0bA5Dd06C8BaeC53Fa8ae25Ad4f19088D6375b;
    address constant public COORDINATOR_OLD = 0xFE860d06fF2a3A485922A6a029DFc1CD8A335288;
    address constant public RESERVE_OLD = 0x30FDE788c346aBDdb564110293B20A13cF1464B6;
    
    address constant public OLD_CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public NEW_CLERK = 0x0000000000000000000000000000000000000000;

    address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI

    // new contracts
    address constant public COORDINATOR_NEW = 0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
    address constant public ASSESSOR_NEW  = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public RESERVE_NEW = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;
    address constant public SENIOR_TRANCHE_NEW = 0x636214f455480D19F17FE1aa45B9989C86041767;

    // adapter contracts
    address constant public MGR =  0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    // https://changelog.makerdao.com/releases/mainnet/1.3.0/index.html
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    // rwa contracts
    address constant public URN = 0x225B3da5BE762Ee52B182157E67BeA0b31968163;
    address constant public LIQ = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant public END = 0xBB856d1742fD182a90239D7AE85706C2FE4e5922;
    address constant public RWA_GEM = 0xAAA760c2027817169D7C8DB0DC61A2fb4c19AC23;

    // Todo: add correct addresses
    address constant public ADMIN1 = address(0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8);
    address constant public ADMIN2 = address(0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9);

    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, self); // Do we need this?
        root.relyContract(COLLECTOR, self); // Do we need this?
        root.relyContract(JUNIOR_TRANCHE, self); // Do we need this?
        root.relyContract(SENIOR_OPERATOR, self); // Do we need this?
        root.relyContract(SENIOR_TRANCHE_OLD, self); // Do we need this?
        root.relyContract(SENIOR_TOKEN, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(JUNIOR_MEMBERLIST, self); // Do we need this?
        root.relyContract(OLD_CLERK, self);
        root.relyContract(NEW_CLERK, self);
        root.relyContract(POOL_ADMIN, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_OLD, self);  // Do we need this?
        root.relyContract(RESERVE_NEW, self);
        root.relyContract(MGR, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateReserve();
        migrateAdapter();
        migratePoolAdmin();
    }

    function migrateAssessor() internal {
        DependLike(ASSESSOR_NEW).depend("clerk", NEW_CLERK); 
    }

    function migrateReserve() internal {
        DependLike(RESERVE_NEW).depend("lending", NEW_CLERK);
    }

    function migrateAdapter() internal {
        require(SpellERC20Like(RWA_GEM).balanceOf(MGR) == 1 ether);
        // dependencies
        DependLike(NEW_CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(NEW_CLERK).depend("mgr", MGR);
        DependLike(NEW_CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(NEW_CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(NEW_CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(NEW_CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(NEW_CLERK).depend("spotter", SPOTTER);
        DependLike(NEW_CLERK).depend("vat", VAT);
        DependLike(NEW_CLERK).depend("jug", JUG);

        FileLike(NEW_CLERK).file("buffer", MAT_BUFFER);

        // permissions
        AuthLike(NEW_CLERK).rely(COORDINATOR_NEW);
        AuthLike(NEW_CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(NEW_CLERK);
        AuthLike(RESERVE_NEW).rely(NEW_CLERK);
        AuthLike(ASSESSOR_NEW).rely(NEW_CLERK);
        AuthLike(SENIOR_TRANCHE_NEW).deny(OLD_CLERK);
        AuthLike(RESERVE_NEW).deny(OLD_CLERK);
        AuthLike(ASSESSOR_NEW).deny(OLD_CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(NEW_CLERK, uint(-1));
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(OLD_CLERK, uint(-1));

        // setup mgr
        AuthLike(MGR).rely(NEW_CLERK);
        AuthLike(MGR).deny(OLD_CLERK);
    }

    function migratePoolAdmin() public {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);
        AuthLike(POOL_ADMIN).rely(ADMIN1);

        DependLike(POOL_ADMIN).depend("lending", NEW_CLERK);

        AuthLike(NEW_CLERK).rely(POOL_ADMIN);
    }

}