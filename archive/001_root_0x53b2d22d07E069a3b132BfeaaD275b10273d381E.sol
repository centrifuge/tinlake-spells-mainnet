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
pragma solidity >=0.5.15 <0.6.0;

import "tinlake-auth/auth.sol";

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface BorrowerDeployerLike {
    function collector() external returns (address);
    function feed() external returns (address);
    function shelf() external returns (address);
    function title() external returns (address);
}

interface LenderDeployerLike {
    function assessor() external returns (address);
    function reserve() external returns (address);
    function assessorAdmin() external returns (address);
    function juniorMemberlist() external returns (address);
    function seniorMemberlist() external returns (address);
}


contract TinlakeRoot is Auth {
    BorrowerDeployerLike public borrowerDeployer;
    LenderDeployerLike public  lenderDeployer;

    bool public             deployed;
    address public          deployUsr;

    constructor (address deployUsr_) public {
        deployUsr = deployUsr_;
    }

    // --- Prepare ---
    // Sets the two deployer dependencies. This needs to be called by the deployUsr
    function prepare(address lender_, address borrower_, address ward_) public {
        require(deployUsr == msg.sender);
        borrowerDeployer = BorrowerDeployerLike(borrower_);
        lenderDeployer = LenderDeployerLike(lender_);
        wards[ward_] = 1;
        deployUsr = address(0); // disallow the deploy user to call this more than once.
    }

    // --- Deploy ---
    // After going through the deploy process on the lender and borrower method, this method is called to connect
    // lender and borrower contracts.
    function deploy() public {
        require(address(borrowerDeployer) != address(0) && address(lenderDeployer) != address(0) && deployed == false);
        deployed = true;

        address reserve_ = lenderDeployer.reserve();
        address shelf_ = borrowerDeployer.shelf();

        // Borrower depends
        DependLike(borrowerDeployer.collector()).depend("distributor", reserve_);
        DependLike(borrowerDeployer.shelf()).depend("lender", reserve_);
        DependLike(borrowerDeployer.shelf()).depend("distributor", reserve_);

        //AuthLike(reserve).rely(shelf_);

        //  Lender depends
        address navFeed = borrowerDeployer.feed();

        DependLike(reserve_).depend("shelf", shelf_);
        DependLike(lenderDeployer.assessor()).depend("navFeed", navFeed);

         // permissions
        address poolAdmin = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;                                             
        address oracle = 0xdD6AF84A98c716C41F036B1836ffB2b8429E20Eb;

        address juniorMemberlistAdmin1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
        address juniorMemberlistAdmin2 = 0x97b2d32FE673af5bb322409afb6253DFD02C0567;

        address seniorMemberlistAdmin1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
        address seniorMemberlistAdmin2 = 0x97b2d32FE673af5bb322409afb6253DFD02C0567;
        address seniorMemberlistAdmin3 = 0xCE30bc6d0c9e489Ab06EC6E7F703E7DB69c5fa01;
        address seniorMemberlistAdmin4 = 0xfEADaD6b75e6C899132587b7Cb3FEd60c8554821;

        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(juniorMemberlistAdmin1);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(juniorMemberlistAdmin2);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(seniorMemberlistAdmin1);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(seniorMemberlistAdmin2);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(seniorMemberlistAdmin3);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(seniorMemberlistAdmin4);
        AuthLike(navFeed).rely(oracle);
    }

    // --- Governance Functions ---
    // `relyContract` & `denyContract` can be called by any ward on the TinlakeRoot
    // contract to make an arbitrary address a ward on any contract the TinlakeRoot
    // is a ward on.
    function relyContract(address target, address usr) public auth {
        AuthLike(target).rely(usr);
    }

    function denyContract(address target, address usr) public auth {
        AuthLike(target).deny(usr);
    }

}
