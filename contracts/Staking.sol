// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is ERC20, ERC20Burnable, Ownable {
     using SafeMath for uint256;
     uint tokenPrice = 0.001 ether; //1 ETH = 1000 BGT, 1BGT = 0.001ETH
     /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;
       /**
    * @notice The stakes for each stakeholder.
    */
   mapping(address => uint256) internal stakes;
      /**
    * @notice The accumulated rewards for each stakeholder.
    */
   mapping(address => uint256) internal rewards;
      /**
    * @notice The rewards duedate for each stakeholder.
    */
   mapping(address => uint256) internal rewardDueDate;

    constructor() ERC20("StakingToken", "STK") {
        _mint(msg.sender, 1_000*10**18);
    }


     function buyTokens(address _receiver) public payable {
        require(msg.value >= tokenPrice, "Sale Price is 1ETH for 1000BGT");
        //calculate amount of tokens the receiver will get will the token price
        uint tokens = msg.value.div(tokenPrice);
        _mint(_receiver, tokens*10**18);
    }

    function modifyTokenBuyPrice(uint _tokenPrice)public onlyOwner {
        tokenPrice = (_tokenPrice);
    }
    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s++){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

     /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder)
       internal
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

    /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder)
      internal
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }
     /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
   function stakeOf(address _stakeholder)
       public
       onlyOwner
       view
       returns(uint256)
   {
       return stakes[_stakeholder];
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes()
       public
       view
       returns(uint256)
   {
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
       return _totalStakes;
   }
     /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stake The size of the stake to be created.
    */
   function StakeToken(uint256 _stake)
       public
   {
       rewardDueDate[msg.sender] = block.timestamp + 7 days;
       _burn(msg.sender, _stake);
       if(stakes[msg.sender] == 0) {
           addStakeholder(msg.sender);
       }
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
   }
   /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
   function removeStake(uint256 _stake)
       public
   {
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
       _mint(msg.sender, _stake);
   }
   
   /**
    * @notice A method to allow a stakeholder to check his rewards.
    * @param _stakeholder The stakeholder to check rewards for.
    */
   function rewardOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return calculateReward(_stakeholder);
   }
      /**
    * @notice A method to the aggregated rewards from all stakeholders.
    * @return uint256 The aggregated rewards from all stakeholders.
    */
   function totalRewards()
       public
       onlyOwner
       view
       returns(uint256)
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s++){
           _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
       }
       return _totalRewards;
   }
     /**
    * @notice A simple method that calculates the rewards for each stakeholder.
    * @param _stakeholder The stakeholder to calculate rewards for.
    */
   function calculateReward(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return stakes[_stakeholder] / 100;
   }

    /**
    * @notice A method to allow a stakeholder to withdraw his rewards.
    */
   function withdrawReward()
       public
   {
       require(block.timestamp >= rewardDueDate[msg.sender],"Claim date is 7 days after Staking!!!");
       if(block.timestamp >= rewardDueDate[msg.sender]){
           rewards[msg.sender] = calculateReward(msg.sender);
           uint256 reward = rewards[msg.sender];
            rewards[msg.sender] = 0;
            _mint(msg.sender, reward);
            rewardDueDate[msg.sender] = block.timestamp + 7 days;
       }

      /**
      *
      */
   }
}
