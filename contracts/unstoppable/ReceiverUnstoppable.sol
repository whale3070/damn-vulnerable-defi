pragma solidity ^0.6.0;

import "../unstoppable/UnstoppableLender.sol";
//导入刚才分析过的UnstoppableLender合约
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReceiverUnstoppable {
//新建合约ReceiverUnstoppable
    UnstoppableLender private pool;
    // 声明一个私有状态变量 pool，类型为 UnstoppableLender 合约类型
    // 作用：存储 UnstoppableLender 借贷池合约的实例（后续可通过该变量调用借贷池的函数）
    address private owner;
    // 声明一个私有状态变量 owner，类型为地址（address）
    // 作用：记录该 ReceiverUnstoppable 合约的拥有者地址（通常用于权限控制，比如仅主人可调用特定函数）
    constructor(address poolAddress) public {
    //结构体，存储poolAddress地址，以及pool和owner
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    // Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        // Return all tokens to the pool
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Transfer of tokens failed");
    }

    function executeFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        pool.flashLoan(amount);
    }
}
