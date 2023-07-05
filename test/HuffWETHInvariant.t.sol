import {Handler} from "./handlers/Handler.sol";

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "forge-std/console.sol";
import "../src/interfaces/IWETH.sol";
import "foundry-huff/HuffDeployer.sol";

contract HuffWETHInvariant is Test {
    IWETH public hWeth;
    Handler public handler;

    function setUp() public {
        hWeth = IWETH(HuffDeployer.deploy("HuffWETH"));
        handler = new Handler(hWeth);

        targetContract(address(handler));
    }

    // total ETH supply = hETH supply + not converted ETH supply
    function invariant_conservationOfETH() public {
        assertEq(
            handler.ETH_SUPPLY(),
            address(handler).balance + hWeth.totalSupply()
        );
    }

    function invariant_alwaysEnoughToWithdraw() public {
        assertGe(address(hWeth).balance, hWeth.totalSupply());
    }
}
