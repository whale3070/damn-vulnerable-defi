pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}
//定义一个外部函数接收tokens, 定义一个接口“我接受”IReceiver
//这个外部函数的参数是token地址和token数量

contract UnstoppableLender is ReentrancyGuard {
//此处用到了合约的继承，UnstoppableLender继承了ReentrancyGuard
//从合约名字ReentrancyGuard，可以看出是考察重入攻击
    using SafeMath for uint256;
    //使用安全的数学，uint256是比较大的数字类型，基本上都可以存储常见的变量
    IERC20 public damnValuableToken;
    //IERC20 是 Solidity 中对 ERC20 代币标准的接口（Interface）
    uint256 public poolBalance;
    //公开变量poolBalance，类型是uint256
    constructor(address tokenAddress) public {
    //结构体，存储信息，存储token地址
        require(tokenAddress != address(0), "Token address cannot be zero");
        //要求token地址不是0，如果是0，那么就报错提示token地址不能为0
        damnValuableToken = IERC20(tokenAddress);  
        //变量damnValuableToken的值，是ERC20 代币标准的接口IERC20获取到的token地址的值
    } 

    function depositTokens(uint256 amount) external nonReentrant {
    //函数depositTokens，修饰符nonReentrant
    //这行代码定义了一个外部可调用的、防重入的「代币存入」函数，用于让用户向合约存入指定数量的代币。
        require(amount > 0, "Must deposit at least one token");
        // Transfer token from sender. Sender must have first approved them.
        damnValuableToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance.add(amount);
        //将「资金池余额」（poolBalance）加上用户存入的代币数量（amount），并把计算后的新值重新赋值给 poolBalance
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
    //函数flashLoan闪电贷，使用函数修饰符borrowAmount
        require(borrowAmount > 0, "Must borrow at least one token");
        //要求borrowAmount大于0
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        //balanceBefore变量存储了damnValuableToken的余额
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");
        //要求balanceBefore变量大于borrowAmount，否则借不到足够的token
        // Ensured by the protocol via the `depositTokens` function
        assert(poolBalance == balanceBefore);
        //断言，poolBalance等于balanceBefore
        damnValuableToken.transfer(msg.sender, borrowAmount);
        // 1. 调用 DVT 代币合约的 transfer 函数，将 borrowAmount 数量的代币从当前合约转给调用者（msg.sender）
        //    注：当前合约必须持有足够的 DVT 代币，否则转账失败
        IReceiver(msg.sender).receiveTokens(address(damnValuableToken), borrowAmount);
        // 2. 将调用者地址强制转换为 IReceiver 接口类型，并调用其 receiveTokens 函数
        //    作用：通知调用者的合约已收到代币，触发对方的后续业务逻辑（如记账、套利等）
        //    注：若调用者不是合约/未实现 IReceiver 接口，此行会报错
        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        //获取转账后的余额地址
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}
