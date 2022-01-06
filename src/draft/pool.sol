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

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "../../tinlake/src/lender/admin/pool.sol";

contract MigratedPoolAdmin is PoolAdmin {
    
    bool public done;
    address public migratedFrom;
    
    constructor() PoolAdmin() public {}

    function migrate(address clone_) public {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        PoolAdmin clone = PoolAdmin(clone_);

        // dependencies
        assessor = clone.assessor();
        lending = clone.lending();
        seniorMemberlist = clone.seniorMemberlist();
        juniorMemberlist = clone.juniorMemberlist();
    }
}