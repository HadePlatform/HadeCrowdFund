pragma solidity ^0.4.15;

import './lib/safeMath.sol';
import './HadeToken.sol';


contract HadeCrowdFund {

    using SafeMath for uint256;
    
//////////////////////////////////////////// VARIABLES ///////////////////////////////////////////////// 

    HadeToken public token;                         // Token variable
    uint256 public crowdfundStartTime;              // It should be XXXXXXXXXXX starting time of CrowdFund
    uint256 public crowdfundEndTime;                // It should be crowdfundStartTime + 5 * 1 weeks ending time of CrowdFund 
    uint256 public totalWeiRaised;                  // Flag to track the amount raised
    uint32 public exchangeRate = 169500;            // Calculated using priceOfEtherInUSD/priceOfBootToken so xxx/xxx 
    uint32 public transferExchangeRate;             // Calculated using priceOfEtherInUSD/priceOfBootToken so xxx/xxx 
    uint256 public firstPreSaleEndTime;             // First presale end time
    uint32 public firstPreSalePrice;                // No. of BON tokens in 1 ETH in first pre sale
    uint32 public secondPreSalePrice;               // No. of BON tokens in 1 ETH in second pre sale
    uint256 public secondPreSaleEndTime;            // Second presale end time

    // Bonus as per day in crowdfund time

    uint8 public firstDayPremium;
    uint8 public secondDayPremium;
    uint8 public thirdDayPremium;                              
    uint8 public fourthDayPremium; 
    uint8 public fifthDayPremium; 
    uint8 public sixthDayPremium;
    uint8 public seventhDayPremium;
    uint8 public transferBonus;
    

    bool public isFirstPreSaleActive = false;            // Flag to track the first pre sale
    bool public isSecondPreSaleActive = false;           // Flag to track the second pre sale 
    bool internal isTokenDeployed = false;               // Flag to track the token deployment
    bool public isCrowdFundActive = false;               // Flag to track the crowdfund active or not
    bool public isBonusSet = false;                      // Flag to track the bonus
    bool public isTransferBonusSet = false;             //Flag to track the Transfer Bonus on Demand
    bool public isTransferExchangeRate = false;         //Flag to track the Transfer exchange on Demand
    // Addresses
    address public founderMultiSigAddress;          // Founders multi sign address
    address public remainingTokenHolder;            // Address to hold the remaining tokens after crowdfund end
   

    enum State { firstPreSale, secondPreSale, CrowdFund }

   
    //Events
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount); 
    event CrowdFundClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
    
   

    //Modifiers
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }
     modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier checkCrowdFundActive() {
        require(isCrowdFundActive == true);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }


     modifier onlyPayloadSize() {
        require(msg.data.length == 36);
        _;
    }

    modifier onlyFirstPreSale() {
        require(isFirstPreSaleActive != true);
        _;
    }

    modifier onlySecondPreSale() {
        require(isSecondPreSaleActive != true);
        _;
    }
    
    modifier onlyTransferBonus() {
        require(isTransferBonusSet == true);
        _;
    }

    modifier onlyTransferExchangeRate() {
        require(isTransferExchangeRate == true);
        _;
    }

    modifier inState(State state) {
        require(getState() == state); 
        _;
    }

//////////////////////////////////////////// CONSTRUCTOR //////////////////////////////////////////
   
    function HadeCrowdFund (address _founderWalletAddress , address _remainingTokenHolder) {
        founderMultiSigAddress = _founderWalletAddress;
        remainingTokenHolder = _remainingTokenHolder;
      
    }

    /**
        @dev function to change the founder multisig wallet address
        @param _newFounderAddress new address of founder
     */

     function setFounderMultiSigAddress(address _newFounderAddress) 
     onlyFounders 
     {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
     }
    

    /**
        @dev attach the token address with the crowdfund conract
        @param _tokenAddress address of the respective token contract 
    
     */
         
    function setTokenAddress(address _tokenAddress) 
    external 
    onlyFounders 
    nonZeroAddress(_tokenAddress) 
    {
        require(isTokenDeployed == false);
        token = HadeToken(_tokenAddress);
        isTokenDeployed = true;
    }

    /**
        @dev startCrowdfund function use to start the crowdfund at the calling function time
        @param _exchangeRate No. of the Hade token provided corresponding to 1 ETH
        @dev _days No. of days to which crowdfund get active
        @return bool
     */
    
    function startCrowdfund(uint32 _exchangeRate, uint8 _days) 
    onlyFounders 
    tokenIsDeployed 
    returns (bool)
    {
       require(now > secondPreSaleEndTime);
        if (_exchangeRate > 0) {
            exchangeRate = _exchangeRate;
            crowdfundStartTime = now;                            
            crowdfundEndTime = crowdfundStartTime + _days * 1 days;       // end date should after 5 weeks of starting date
            isCrowdFundActive = !isCrowdFundActive;
            return true;
        }
        revert();
    }

    /**
        @dev change the state of crowdfund 
    
     */


    function changeCrowdfundState() 
    tokenIsDeployed 
    onlyFounders 
    inState(State.CrowdFund) 
    {
        isCrowdFundActive = !isCrowdFundActive;
    }



    /**
        @dev function call after crowdFundEndTime 
        it transfers the remaining tokens to remainingTokenHolder address
        @return bool
    */

    function endCrowdfund() onlyFounders returns (bool) {
        require(now > crowdfundEndTime);
        uint256 remainingToken = token.balanceOf(this);  // remaining tokens

        if (remainingToken != 0) {
        //  token.transfer(remainingTokenHolder, remainingToken); 
          CrowdFundClosed(now);
          return true; 
        } 
        return false;
    }

// set exchangeRate for token transfer
  
    function setTransferExchangeRate(uint32 _transferExchangeRate) 
    onlyFounders      
    tokenIsDeployed 
    returns (bool) 
    {
        if (_transferExchangeRate > 0) {
            transferExchangeRate = _transferExchangeRate;
            isTransferExchangeRate = true;           
            return true;
        }
        return false;
    }

    /**
        @dev function to start the first pre sale called only once
        @param _days to set the first presale end time 
        @param _exchangeRate No. of the Hade token provided corresponding to 1 ETH
        @param _bonus bonus provided for the first presale 
        @return bool
     */

  
    function startFirstPreSale(uint256 _days, uint32 _exchangeRate, uint32 _bonus) 
    onlyFounders 
    onlyFirstPreSale 
    tokenIsDeployed 
    returns (bool) 
    {
        if (_exchangeRate > 0 && _days > 0 ) {
            exchangeRate = _exchangeRate;
            firstPreSaleEndTime = now + _days * 1 days;
            firstPreSalePrice = 100 * exchangeRate + _bonus * exchangeRate;
            isFirstPreSaleActive = !isFirstPreSaleActive;
            return true;
        }
        return false;

    }

      /**
        @dev function to start the second pre sale called only once
        @param _days to set the first presale end time 
        @param _exchangeRate No. of the Hade token provided corresponding to 1 ETH
        @param _bonus bonus provided for the first presale 
        @return bool
     */


    function startSecondPreSale(uint256 _days, uint32 _exchangeRate, uint32 _bonus ) 
    onlyFounders 
    onlySecondPreSale 
    tokenIsDeployed 
    returns (bool) 
    {
        require(now > firstPreSaleEndTime);
        if (_exchangeRate > 0 ) {
            exchangeRate = _exchangeRate;
            secondPreSaleEndTime = now + _days * 1 days;
            secondPreSalePrice = 100 * exchangeRate + _bonus * exchangeRate;
            isFirstPreSaleActive = false;            // Flag to track the first pre sale
            isSecondPreSaleActive = true; 
            return true;
        }
        return false;

    }

    // function to set the bonus of the ICO sale
    function setBonus(uint8 _firstDay, uint8 _secondDay, uint8 _thirdDay, uint8 _fourthDay, uint8 _fifthDay, uint8 _sixDay, uint8 _sevenDay) onlyFounders inState(State.CrowdFund) returns(bool) {
      if (isBonusSet == false) {
        firstDayPremium = _firstDay;
        secondDayPremium = _secondDay;
        thirdDayPremium = _thirdDay; 
        fourthDayPremium = _fourthDay;
        fifthDayPremium = _fifthDay;
        sixthDayPremium = _sixDay; 
        seventhDayPremium = _sevenDay;
        isBonusSet = !isBonusSet;
        return true;
      }else {
        return false;
      }
      
    }
    
    // function to set the bonus of the ICO sale
    function setTransferBonus(uint8 _bonus) onlyFounders returns(bool) {
    
        transferBonus = _bonus;
        isTransferBonusSet = true;
      
        return true;     
      
    }

    // Buy token function call only in duration of crowdfund active 
    function buyTokens(address beneficiary) nonZeroEth tokenIsDeployed onlyPublic nonZeroAddress(beneficiary) payable returns(bool) {
        if(getState() == State.firstPreSale) {
            if(buyFirstPreSaleTokens()) {
                return true;
            }
            return false;
        }
        if(getState() == State.secondPreSale) {
            if(buySecondPreSaleTokens()) {
                return true;
            }
            return false;
        }
        if(getState() == State.CrowdFund) {
            require(now < crowdfundEndTime);
            require(isBonusSet == true);
            fundTransfer(msg.value);
            totalWeiRaised = totalWeiRaised.add(msg.value);
            return true;         
        }
        else {
            revert();
        }
        
    }
    // function transfertoken on demand
    function transferToken(address _beneficiary, uint256 _value)tokenIsDeployed onlyTransferBonus onlyTransferExchangeRate onlyFounders returns(bool){
        uint256 amount = getNoOfTokensTransfer(transferExchangeRate , _value);
        
      if (token.transfer(_beneficiary, amount)) {
                token.changeTotalSupply(amount); 
              //  totalWeiRaised = totalWeiRaised.add(_value);
                TokenPurchase(_beneficiary, _value, amount);
                return true;
            }
            return false;
    }


      // function to buy the tokens at pre pressale 
    function buyFirstPreSaleTokens() internal returns(bool) {

            fundTransfer(msg.value);
            totalWeiRaised = totalWeiRaised.add(msg.value);
            return true;
    }


    // function to buy the tokens at presale 
    function buySecondPreSaleTokens() internal returns(bool) {

            fundTransfer(msg.value);
            totalWeiRaised = totalWeiRaised.add(msg.value);
            return true;
    }

    // function to transfer the funds to founders account
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }

// Get functions 

    // function to get the current state of the crowdsale
    function getState() internal constant returns(State) {
        if(firstPreSaleEndTime > now && isFirstPreSaleActive) {
            return State.firstPreSale;
        }
        if(now > firstPreSaleEndTime && secondPreSaleEndTime > now && isSecondPreSaleActive) {
            return State.secondPreSale;
        }
        if(isCrowdFundActive) {
            return State.CrowdFund;
        }
        
    }

   // get the amount of tokens a user would receive for a specific amount of ether
   function getTotalTokens(uint256 _amountOfEth) public constant returns(uint256) {
       if (getState() == State.CrowdFund) {
           return getNoOfTokens(exchangeRate, _amountOfEth);
       }else {
           revert();
       }
      
   } 

   // function to calculate the total no of tokens with bonus multiplication
    function getNoOfTokens(uint32 _exchangeRate , uint256 _amount) internal returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         uint256 noOfTokenWithBonus =((100 + getCurrentBonusRate()) * noOfToken ) / 100;
         return noOfTokenWithBonus;
    }
    
    
    // function to calculate the total no of tokens with bonus multiplication in TokenTransfer Phase
    function getNoOfTokensTransfer(uint32 _exchangeRate , uint256 _amount) internal returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         uint256 noOfTokenWithBonus =((100 + transferBonus) * noOfToken ) / 100;
         return noOfTokenWithBonus;
    }

    // function provide the current bonus rate
    function getCurrentBonusRate() internal returns (uint8) {
        

        if (now > crowdfundStartTime + 6 days) {
            return seventhDayPremium;
        }
        if (now > crowdfundStartTime + 5 days) {
            return sixthDayPremium;
        }
        if (now > crowdfundStartTime + 4 days) {
            return fifthDayPremium;
        }
        if ( now > crowdfundStartTime + 3 days) {
            return fourthDayPremium;
        }
        if (now > crowdfundStartTime + 2 days) {
            return thirdDayPremium;
        }
        if (now > crowdfundStartTime + 1 days) {
            return secondDayPremium;
        }
        if (now > crowdfundStartTime) {
            return firstDayPremium;
        }
    }

    // provides the bonus % 
    function getBonus() constant returns (uint8) {
        return getCurrentBonusRate();
    }

    // send ether to the contract address
    // With at least 200 000 gas
    function() public payable {
        buyTokens(msg.sender);
    }
}