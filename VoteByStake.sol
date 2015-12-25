contract VotebyStake{
  // this contract opens a bet if something, is indeed true.
  //For example:  Did Barak Obama win the ellection 2014
	
	struct Bet{
        uint value;
        address betsender;
        bool isbettrue;
    }

	uint public betStart;  
    uint public biddingTime;
    uint public objectionTime;
	
	// objectionTime is timeperiod to ask an oracle whether bets have been manipulated
    
	Bet[] public bets;
    
	string public votingquestion;
	
	uint public total_for_true=0;
    uint public total_for_false=0;
    bool winning;
	event Betting(bool vote, uint value,address owner);
	
	function getvotingquestion() constant returns (string){
		return votingquestion;
	}
	function gettotal_for_true() constant returns (uint){
		return total_for_true;
	}
	
	function gettotal_for_false() constant returns (uint){
		return total_for_false;
	}
	
	
	function VotebyStake(string votingquestiondes) {
		betStart=now;
		biddingTime=3000;
		objectionTime==1000;
		votingquestion=votingquestiondes;
 	 }
	
    function addmyvote(bool vote){
        if (now > betStart + biddingTime)
            // Revert the call if the bidding
            // period is over.
            throw;
        bets.push(Bet({
			value: msg.value,
			betsender: msg.sender,
			isbettrue: vote
		}));
		if(vote)total_for_true+=msg.value;
		else total_for_false+=msg.value;
		Betting(vote,msg.value,msg.sender);
	}
    
    function evalute_bets(){
        if (now < betStart + biddingTime)
            // Revert the call if the bidding
            // period is over.
            throw;
        if( total_for_true==total_for_false)
         winning=true;
         //for simplicity all the ones betting for true should be the winners;
        if (total_for_true< total_for_false) winning=false;
        else winning=true;
    }
    
    function send_winnings(){
        if (now < betStart + biddingTime+ objectionTime) 
            // Revert the call if the bidding
            // period is over.
            return;
            
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].isbettrue && winning){
                bets[i].betsender.send(bets[i].value+bets[i].value*total_for_false/(total_for_true));
            }
            if (!bets[i].isbettrue && !winning){
                bets[i].betsender.send(bets[i].value+bets[i].value*total_for_true/(total_for_false));
            }

        }    
    }
    
	
    address public lastresortoracle=0xf025d81196b72fba60a1d4dddad12eeb8360d828;
    
    function challenge_bet(){
        //if (now < betStart + biddingTime+ objectionTime) 
            // Revert the call if the bidding
            // period is over.
          //  throw;
		//if (msg.value >= 30){
            //invoke contract
		LastResortOracle(lastresortoracle).askoracle.value(1000000).gas(800000000000)(votingquestion);
          // lastresortoracle.call.value(30)('askoracle',votingquestion);
		//lastresortoracle.sendTransaction('true?', {from: web3.eth.coinbase, value: web3.toWei(30,'ether')});
			//lastresortoracle.addmyvote.sendTransaction(votingquestion, {from: web3.eth.coinbase, value: web3.toWei(key,'ether')});
       // }
    }
 	function getchallengeanswer(uint voteoracle){
        if(msg.sender!=lastresortoracle) throw;
		if(voteoracle==1) winning=true;
		if(voteoracle==0) winning=false;
    }
    
}