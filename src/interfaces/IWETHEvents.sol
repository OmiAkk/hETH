/// @notice All of the events WETH contract emits.
interface IWETHEvents {
    /* ERC20 */
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    /* WETH */
    event Deposit(address indexed from, uint value);
    event Withdrawal(address indexed from, uint value);
}
