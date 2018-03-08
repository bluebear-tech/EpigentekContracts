pragma solidity ^0.4.11;

import "zeppelin/contracts/math/SafeMath.sol";
import "zeppelin/contracts/ownership/Ownable.sol";
import "zeppelin/contracts/token/StandardToken.sol";


contract EpigentekCrowdsale is Ownable {
  using SafeMath for uint256;

  StandardToken public token;

  uint256 public startTime;
  uint256 public endTime;
  address public wallet;
  address public tokenPool;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public weiPending;
  uint256 public minimumInvestment;

  mapping (address => Transaction) transactions;
  mapping (address => bool) approvedAddresses;
  mapping (address => bool) verifiers;

  struct Transaction { uint weiAmount; }

  event TokenPurchaseRequest(address indexed purchaser, address indexed beneficiary, uint256 value);

  function EpigentekCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _tokenPool, address _token) Ownable() {
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    require(_tokenPool != 0x0);

    token = StandardToken(_token);
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
    tokenPool = _tokenPool;

    verifiers[msg.sender] = true;
    rate = 2500;
    minimumInvestment = 0.5 ether;
  }

  function () payable {
    requestTokens(msg.sender);
  }

  function requestTokens(address beneficiary) sufficientApproval(msg.value) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(msg.value >= minimumInvestment);

    uint256 weiAmount = msg.value;

    Transaction transaction = transactions[beneficiary];
    transaction.weiAmount = transaction.weiAmount.add(weiAmount);
    weiPending = weiPending.add(weiAmount);

    if(approvedAddresses[beneficiary]) {
      weiRaised = weiRaised.add(transaction.weiAmount);
      weiPending = weiPending.sub(transaction.weiAmount);
      uint256 tokens = transaction.weiAmount.mul(rate);

      token.transferFrom(tokenPool, beneficiary, tokens);
      wallet.transfer(transaction.weiAmount);
      transaction.weiAmount = 0;
    } else {
      TokenPurchaseRequest(msg.sender, beneficiary, weiAmount);
    }
  }

  function validateTransaction(address purchaser) onlyVerifiers(msg.sender) {
    Transaction transaction = transactions[purchaser];

    weiRaised = weiRaised.add(transaction.weiAmount);
    weiPending = weiPending.sub(transaction.weiAmount);
    uint256 tokens = transaction.weiAmount.mul(rate);
    approvedAddresses[purchaser] = true;

    token.transferFrom(tokenPool, purchaser, tokens);
    wallet.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
  }

  function pendingTransaction(address user) returns (uint value){
    return transactions[user].weiAmount;
  }

  function revokeRequest() {
    Transaction transaction = transactions[msg.sender];
    weiPending = weiPending.sub(transaction.weiAmount);
    msg.sender.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
  }

  modifier sufficientApproval(uint value) {
    uint totalEther = weiPending.add(value);
    uint tokensPending = totalEther.mul(rate);
    uint tokensNeeded = token.allowance(tokenPool, this);
    require(tokensNeeded >= tokensPending);
    _;
  }

  function rejectRequest(address user, uint fee) {
    Transaction transaction = transactions[user];
    weiPending = weiPending.sub(transaction.weiAmount);
    if(fee > 0) {
      transaction.weiAmount = transaction.weiAmount.sub(fee);
      wallet.transfer(fee);
    }

    user.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = (now <= endTime);
    bool nonZeroPurchase = msg.value != 0;
    return (withinPeriod && nonZeroPurchase);
  }

  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function updateMinimumInvestment(uint _minimumInvestment) onlyOwner {
    minimumInvestment = _minimumInvestment;
  }

  function updateRate(uint _rate) onlyOwner {
    rate = _rate;
  }

  function setVerifier(address verifier, bool value) onlyOwner {
    verifiers[verifier] = value;
  }

  function isValidated(address user) returns (bool) {
    return approvedAddresses[user];
  }

  modifier onlyVerifiers(address sender) {
    require(verifiers[sender]);
    _;
  }
}
