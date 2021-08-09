// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake clerk unwiring mainnet spell";

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        root.relyContract(ASSESSOR, address(this));
        root.relyContract(RESERVE, address(this));

        DependLike(ASSESSOR).depend("lending", address(0));
        DependLike(RESERVE).depend("lending", address(0));
    }

}