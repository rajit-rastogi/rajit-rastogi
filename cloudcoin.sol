// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CloudCoinStaking {
    address public owner;
    uint256 public totalStaked;
    uint256 public beginDate;
    uint256 public endDate;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;

    constructor(uint256 day, uint256 month, uint256 year) {
        owner = msg.sender;
        beginDate = _getDateTimestamp(day, month, year);
        endDate = beginDate + 7 days; // Assuming the stake duration is 7 days
    }

    function _getDateTimestamp(uint256 day, uint256 month, uint256 year) private pure returns (uint256) {
        require(day > 0 && month > 0 && year > 1970, "Invalid date");
        require(month <= 12, "Invalid month");
        
        uint256 daysInMonth;
        if (month == 2) {
            if (_isLeapYear(year)) {
                daysInMonth = 29;
            } else {
                daysInMonth = 28;
            }
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            daysInMonth = 30;
        } else {
            daysInMonth = 31;
        }

        require(day <= daysInMonth, "Invalid day");

        uint256 timestamp = (year - 1970) * 31536000; // Year difference in seconds
        timestamp += _getDaysToMonth(month, year) * 86400; // Days to month in seconds
        timestamp += (day - 1) * 86400; // Day in seconds

        return timestamp;
    }

    function _isLeapYear(uint256 year) private pure returns (bool) {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }

    function _getDaysToMonth(uint256 month, uint256 year) private pure returns (uint256) {
        uint256[12] memory monthDays = [uint256(31), 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

        uint256 daysToMonth = 0;
        for (uint256 i = 1; i < month; i++) {
            daysToMonth += monthDays[i - 1];
            if (i == 2 && _isLeapYear(year)) {
                daysToMonth += 1; // Leap year adjustment for February
            }
        }

        return daysToMonth;
    }

    function stake(uint256 amount) external {
        require(block.timestamp >= beginDate && block.timestamp < endDate, "Staking period has ended");
        require(amount > 0, "Staking amount must be greater than 0");

        stakes[msg.sender] += amount;
        totalStaked += amount;
    }

    function calculateReward(address account) public view returns (uint256) {
        if (totalStaked == 0) return 0;

        return (stakes[account] * 1000000 * (endDate - beginDate)) / totalStaked;
    }

    function claimReward() external {
        require(block.timestamp >= endDate, "Reward period has not ended yet");
        require(stakes[msg.sender] > 0, "No stake found");

        uint256 reward = calculateReward(msg.sender);
        rewards[msg.sender] += reward;
    }

    function withdrawReward() external {
        require(rewards[msg.sender] > 0, "No reward to withdraw");
        
        rewards[msg.sender] = 0;
    }

    function withdrawStake() external {
        require(block.timestamp >= endDate, "Staking period has not ended yet");
        require(stakes[msg.sender] > 0, "No stake found");

        totalStaked -= stakes[msg.sender];
        stakes[msg.sender] = 0;
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "Only owner can call this function");

        // Transfer remaining balance to owner
        payable(owner).transfer(address(this).balance);
    }
}
