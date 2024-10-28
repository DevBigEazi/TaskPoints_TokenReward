// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IERC20.sol";

contract PointsToClaimReward {

    IERC20 public MPXContract;

    address public admin;

    uint256 public immutable claimableReward = 20_000 * (10**18); 

    struct User {
        uint256 accumulatedPoints;
        uint16 numberOfTaskCompleted;
        uint256 tokenBalnce;
    }

    struct Task {
        string description;
        uint256 points;
        uint256 expiredIn;
        bool isActive;
    }

    Task[] public tasks;

    mapping (address => User) users;

    
    mapping(address => mapping(uint16 taskIndex => bool)) hasCompleted;

    constructor(address _mpxContract) {
        MPXContract = IERC20(_mpxContract);
        admin = msg.sender;
    }

    modifier OnlyAdmin () {
        require(msg.sender != address(0), "Zero address is not allowed");
        require(msg.sender == admin, "Unauthorized");
        _;
    }

    //events
    event TaskAdded (string indexed  _description, uint256 indexed _points);
    event TaskCompleted (uint256 indexed _accumulatedPoints , uint16 indexed _numberOfTaskCompleted);
    event PointsRedeemed (address indexed _claimer, uint256 _amountClaimed);

    function addTask(string memory _description, uint256 _points, uint256 _expiringDate) external  OnlyAdmin {

        Task memory newTask;
        newTask.description = _description;
        newTask.points = _points;
        newTask.isActive = true;
        newTask.expiredIn = block.timestamp + _expiringDate;

        tasks.push(newTask);

        emit TaskAdded(newTask.description, newTask.points);
    }

    function completeTask(uint16 _index) external returns (bool) {
        require(msg.sender != address(0), "Zero address not allowed");
        require(_index < tasks.length, "Out of bound!");
        require(!hasCompleted[msg.sender][_index], "Oops! Task already completed by this user.");
        require(users[msg.sender].accumulatedPoints < 50, "You already have redeemable 50 or more points. you can claim again after redeeming your curent points.");

        Task storage currentTask = tasks[_index];

        if (block.timestamp < currentTask.expiredIn) {
            currentTask.isActive = false;
        }

        hasCompleted[msg.sender][_index] = true;

        users[msg.sender].accumulatedPoints += currentTask.points;
        users[msg.sender].numberOfTaskCompleted +=1;

        emit TaskCompleted(users[msg.sender].accumulatedPoints , users[msg.sender].numberOfTaskCompleted);

        return true;
    }

    function getAllTasks() external view returns (Task[] memory) {
        return tasks;
    }

    function getUserDetails() external view returns (uint256 accumulatedPoints_, uint16 numberOfTaskCompleted_, uint256 tokenBalnce_) {
        require(msg.sender != address(0), "Zero address not allowed");
        
        accumulatedPoints_ = users[msg.sender].accumulatedPoints;
        numberOfTaskCompleted_ = users[msg.sender].numberOfTaskCompleted;
        tokenBalnce_ = users[msg.sender].tokenBalnce;
    }


    function redeemPointToClaimReward() external returns (bool) {
        require(msg.sender != address(0), "Zero address not allowed");
        require(users[msg.sender].accumulatedPoints >= 50, "Your points is not yet redeemable");

        users[msg.sender].accumulatedPoints = users[msg.sender].accumulatedPoints - 50;

        MPXContract.transfer(msg.sender, claimableReward);

        users[msg.sender].tokenBalnce += claimableReward;

        emit PointsRedeemed(msg.sender, claimableReward);

        return true;
    }
}