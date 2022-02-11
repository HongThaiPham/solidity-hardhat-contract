// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./structs/UserInfo.sol";
import "./CryptoHeroes.sol";

import "hardhat/console.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

contract CryptoHeroesPool is Ownable {
    using SafeERC20 for IERC20;
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        bool isNFTNeeded; // need NFT or not
        IERC721 nftToken; // What NFTs accepted for staking.
        uint256 allocPoint; // How many allocation points assigned to this pool. POBs to distribute per block.
        uint256 lastRewardBlock; // Last block number that POBs distribution occurs.
        uint256 accCheroesPerShare; // Accumulated Cheroes per share, times 1e12. See below.
    }

    CryptoHeroes public cheroes;
    address public devaddr;

    // số lượng token được tạo trên mỗi khối
    uint256 public cheroesPerBlock;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // thông tin user stake token
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(IERC20 => bool) public lpTokenIsExist;

    // Tổng số lượng token được phân bổ trên tất cả các pool
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        CryptoHeroes _cheroes,
        address _devaddr,
        uint256 _cheroesPerBlock
    ) {
        cheroes = _cheroes;
        devaddr = _devaddr;
        cheroesPerBlock = _cheroesPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate,
        bool _isNFTNeeded,
        IERC721 _nftToken
    ) public onlyOwner {
        require(
            lpTokenIsExist[_lpToken] == false,
            "This lpToken already added"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                isNFTNeeded: _isNFTNeeded,
                nftToken: _nftToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCheroesPerShare: 0
            })
        );
        lpTokenIsExist[_lpToken] = true;
    }

    // Update the given pool's CHEROES allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint -
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending Cheroes on frontend.
    function pendingCheroes(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCheroesPerShare = pool.accCheroesPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 cheroesReward = (multiplier *
                cheroesPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accCheroesPerShare =
                ((accCheroesPerShare + cheroesReward) * 1e12) /
                lpSupply;
        }
        return ((user.amount * accCheroesPerShare) / 1e12) - user.rewardDebt;
    }

    // Deposit LP tokens to Contract for cheroes allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        console.log("deposit accCheroesPerShare: ", pool.accCheroesPerShare);
        if (pool.isNFTNeeded == true) {
            require(
                pool.nftToken.balanceOf(address(msg.sender)) > 0,
                "requires NTF token!"
            );
        }

        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accCheroesPerShare) / 1e12) -
                user.rewardDebt;

            if (pending > 0) {
                safeCheroesTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount + _amount;
        }

        user.rewardDebt = (user.amount * pool.accCheroesPerShare) / 1e12;
        console.log("deposit rewardDebt: ", user.rewardDebt);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Contract.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        if (pool.isNFTNeeded == true) {
            require(
                pool.nftToken.balanceOf(address(msg.sender)) > 0,
                "requires NFT token!"
            );
        }
        uint256 pending = ((user.amount * pool.accCheroesPerShare) / 1e12) -
            user.rewardDebt;
        if (pending > 0) {
            safeCheroesTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accCheroesPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        // pool đã được phân bổ
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        console.log("updatePool: lpSupply", lpSupply);
        // pool chưa đươc deposit
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // số block từ lastRewardBlock đến block hiện tại
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        console.log("updatePool: multiplier", multiplier);
        // reward = số lượng block * số token mỗi block * số lượng phân bổ cho pool / tổng phân bổ cho các pool
        uint256 cheroesReward = (multiplier *
            cheroesPerBlock *
            pool.allocPoint) / totalAllocPoint;

        cheroes.mint(address(this), cheroesReward);

        pool.accCheroesPerShare =
            ((pool.accCheroesPerShare + cheroesReward) * 1e12) /
            lpSupply;

        pool.lastRewardBlock = block.number;
        console.log("update: accCheroesPerShare ", pool.accCheroesPerShare);
    }

    // Safe Cheroes transfer function, just in case if rounding error causes pool to not have enough cheroes.
    function safeCheroesTransfer(address _to, uint256 _amount) internal {
        uint256 cheroesBal = cheroes.balanceOf(address(this));
        if (_amount > cheroesBal) {
            cheroes.transfer(_to, cheroesBal);
        } else {
            cheroes.transfer(_to, _amount);
        }
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        // lpToken.safeIncreaseAllowance(lptoken, address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setCheroesPerBlock(uint256 _cheroesPerBlock) public onlyOwner {
        require(_cheroesPerBlock > 0, "!CheroesPerBlock-0");
        cheroesPerBlock = _cheroesPerBlock;
    }

    function inMigrate(IERC20 _lpToken) public onlyOwner {
        _lpToken.safeApprove(address(migrator), 0);
        // _lpToken.safeApprove(address(migrator), uint256(-1));
    }
}
