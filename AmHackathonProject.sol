// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuizBet {
    struct Bet {
        address participant;
        uint256 amount;
        uint8 selectedOutcome;
    }

    address public admin;
    uint8 public correctOutcome;
    bool public isOutcomeSet;
    uint256 public totalBets;
    mapping(uint8 => uint256) public outcomePool;
    mapping(address => Bet) public bets;

    event BetPlaced(address indexed participant, uint256 amount, uint8 selectedOutcome);
    event OutcomeSet(uint8 correctOutcome);
    event WinningsClaimed(address indexed participant, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function placeBet(uint8 selectedOutcome) external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(!isOutcomeSet, "Betting is closed");
        require(bets[msg.sender].amount == 0, "You have already placed a bet");

        bets[msg.sender] = Bet(msg.sender, msg.value, selectedOutcome);
        outcomePool[selectedOutcome] += msg.value;
        totalBets += msg.value;

        emit BetPlaced(msg.sender, msg.value, selectedOutcome);
    }

    function setOutcome(uint8 _correctOutcome) external onlyAdmin {
        require(!isOutcomeSet, "Outcome already set");
        correctOutcome = _correctOutcome;
        isOutcomeSet = true;

        emit OutcomeSet(_correctOutcome);
    }

    function claimWinnings() external {
        require(isOutcomeSet, "Outcome not yet set");
        Bet memory userBet = bets[msg.sender];
        require(userBet.amount > 0, "No bet placed");
        require(userBet.selectedOutcome == correctOutcome, "You did not bet on the correct outcome");

        uint256 userShare = (userBet.amount * totalBets) / outcomePool[correctOutcome];
        uint256 winnings = userBet.amount + userShare;

        bets[msg.sender].amount = 0; // Prevent reentrancy
        payable(msg.sender).transfer(winnings);

        emit WinningsClaimed(msg.sender, winnings);
    }

    function getPoolSize(uint8 outcome) external view returns (uint256) {
        return outcomePool[outcome];
    }
}
