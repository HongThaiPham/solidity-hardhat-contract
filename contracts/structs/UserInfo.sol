// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct UserInfo {
    uint256 amount; // Số lượng LP token user cung cấp
    uint256 rewardDebt; // Số lượng LP token user phải trả cho pool
    uint256 requestAmount; // Số lượng LP token user yêu cầu
    uint256 requestBlock; // Block mà token transfer được yêu cầu

    // bất kỳ thời điểm nào, số lượng token user có thể được trả nhưng cần chờ được phân phối là
    // pending_reward_amount  = (user.amount * pool.accCheroesPerShare) - user.rewardDebt
    // mỗi khi user deposit hoặc withdraw LP token khỏi pool thì:
    // 1. accCheroesPerShare và lastRewardBlock của pool được update
    // 2. user sẽ nhận được pending_reward_amount chuyển đến ví
    // 3. user.amount và user.rewardDebt của user được update
}
