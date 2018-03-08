pragma solidity ^0.4.17;

import "zeppelin/contracts/ownership/Ownable.sol";
import "../installed_contracts/zeppelin/contracts/token/StandardToken.sol";

contract EpigentekToken is Ownable, StandardToken {

  string public name = "EPIC Token";
  string public symbol = "EPIC";
  uint8 public constant decimals = 18;

  function EpigentekToken(address _owner) {
    owner = _owner;
    totalSupply = 100000000 ether;
    balances[owner] = totalSupply;
  }
}
