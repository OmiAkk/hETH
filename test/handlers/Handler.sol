import "../../src/interfaces/IWETH.sol";
import "forge-std/Test.sol";

contract Handler is Test {
    uint256 public totalDepositsAmount;
    uint256 public totalWithdrawalsAmount;

    uint256 public constant ETH_SUPPLY = 120_000_000 ether;

    IWETH public hWETH;

    constructor(IWETH _hWETH) {
        hWETH = _hWETH;
        vm.deal(address(this), ETH_SUPPLY);
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);
        hWETH.deposit{value: amount}();
        totalDepositsAmount += amount;
    }

    function withdraw(uint256 amount) public {
        hWETH.withdraw(amount);
        totalWithdrawalsAmount += amount;
    }

    function depositFromFallback(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);

        (bool success, ) = address(hWETH).call{value: amount}("");
        require(success, "Fallback failed");

        totalDepositsAmount += amount;
    }
}
