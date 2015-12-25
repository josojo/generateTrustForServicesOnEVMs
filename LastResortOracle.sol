contract LastResortOracle {
        
	struct  Staker{
            address owner;
            uint wins;
	 	    uint stake;   
        }

	Staker[] stakes;
	
	struct QuestionForOracle{
            uint identifier;
            address sender;
            string question;
	    	uint value;
        }
	
	QuestionForOracle[]  questions;
	uint questionscount=0;
	
	//account for earnings of oracle
	uint oraclebalance=0;
	function getquestion(uint id) constant returns (string){
		string str=questions[id].question;
		return str;
	}
	function gettrustcapital() constant returns (uint){
		return sumoverallstakes;
	}
	function getoraclebalance() constant returns (uint){
		return oraclebalance;
	}
	//orcale uses this address to report 
	address oracle;
	function LastResortOracle(){
		oracle=msg.sender;
	}
	
	modifier oracleonly { if (msg.sender == oracle) _ }

	//different periods of staking and paying
	modifier period1only { if (block.number%payoutcycleforblocks<payoutcycleforblocks-5000) _ }	
	// collecting earnings from oracle in earningsfristperiod 
        modifier period2only { if (block.number%payoutcycleforblocks>payoutcycleforblocks-5000) _ }	
	// give stakes time to organize, collecting winnings from oracle in separate account:earningssecondperiod
        modifier period3only { if (block.number%payoutcycleforblocks>payoutcycleforblocks-100) _ }  
	// calculating wins for this period
	
	//accounting variables
	uint public earningsfirstperiod=0;
	uint public earningssecondperiod=0;
	uint public payoutcycleforblocks=100000;
	uint public sumoverallstakes=0;	

	//confirgurationofalgorithm
    uint public Stakeforshorttermmin=10;
    uint public Stakeforlongtermmin=1000;
    uint public weight_forshortterminvest=1;
    uint public weight_forlongterminvest=4;
    uint public returninterest_forlongterminvest=1;
    // real public returninterest_forshortterminvet=0.5;
    uint public costsperrequest=30;
    // real public percentageforstakeholders=0.5;
	
	event  Oraclequestion(string question, address sendingcontract,uint value,uint identifier);
    event  Oracleanswer(uint id, string question, uint answer);
   
	function askoracle(string voteforquestion){
            //if(msg.value<costsperrequest){
			//	msg.sender.send(msg.value);
			//	throw;
			//}
			oraclebalance=51;
			//questionscount++;
			questions.push(QuestionForOracle({
				identifier: questionscount,
				sender: msg.sender,
				question: voteforquestion,
				value: msg.value}));
			Oraclequestion(voteforquestion,msg.sender,msg.value,questionscount);	
		}
	
	function oracleinput(uint vote, uint identifier) oracleonly {
			if(vote==2){ //if the oracle could not find an unambigious answer
				(questions[identifier].sender).call.value(questions[identifier].value)('getchallengeanswer',vote);
			delete questions[identifier];
			throw;
			}
			(questions[identifier].sender).call('getchallengeanswer',vote);

			if(block.number%payoutcycleforblocks<payoutcycleforblocks-5000)	
				earningsfirstperiod+=questions[identifier].value/2;
			else
				earningssecondperiod+=questions[identifier].value/2;
			oraclebalance+=questions[identifier].value/2;
			
			Oracleanswer(identifier, questions[identifier].question,vote);
			delete questions[identifier];
			// might cause trouble because questions[questions.length()] will not get the latest object
		}	
	
	//calculates the allocation of wins to each stake
    function calculatewinnings() period3only{
			// no payouts would be able to make. ensures that small stakeholder also get winnings.
			if(earningsfirstperiod*1000000000<sumoverallstakes)throw;
			for (uint i = 0; i < stakes.length; ++i) {
				if(! islongtermstake(stakes[i].stake)){
					stakes[i].wins+= weight_forshortterminvest*stakes[i].stake*earningsfirstperiod/sumoverallstakes;					
				}
				else{
					stakes[i].wins+=weight_forlongterminvest*stakes[i].stake*earningsfirstperiod/sumoverallstakes;
				}
			earningsfirstperiod=earningssecondperiod;
			earningssecondperiod=0;
			}
		}
	
	//sending out all the fund, which earned their return rate
    function sendoutwinnings() period3only {
			for (uint i = 0; i < stakes.length; ++i) {
					if(! islongtermstake(stakes[i].stake)){
						//if(stakes[i].wins>stakes[i].stake*returninterest_forshortterminvet){ in comma since no real datatype
						if(stakes[i].wins>stakes[i].stake/2){
							stakes[i].owner.send(stakes[i].stake+stakes[i].wins);
							sumoverallstakes-=uint(stakes[i].stake*weight_forshortterminvest);
							delete stakes[i];
						}
					}
					else{
						if(stakes[i].wins>uint(stakes[i].stake*returninterest_forlongterminvest)){
							stakes[i].owner.send(stakes[i].stake+stakes[i].wins);
							sumoverallstakes-=uint(stakes[i].stake*weight_forlongterminvest);
							delete stakes[i];
						}
					}
			}
	}
			
	function addmystake() {
		if (msg.value<Stakeforshorttermmin){
			msg.sender.send(msg.value);
			throw;
			}
		stakes.push(Staker({
			owner: msg.sender,
			wins: 0,
			stake : msg.value}));
		if(islongtermstake(msg.value)) sumoverallstakes+=msg.value*weight_forlongterminvest;	
		else sumoverallstakes+=msg.value*weight_forshortterminvest;			
	}
	
	function islongtermstake(uint s) returns (bool){
		if (s<Stakeforlongtermmin) return true;
		else return false;
	}
	
	// Until Ethereum EVM is in testing mode(frontier), this function keeps included. 
	//It ensures that all stakes can be return to their owner if technical difficulties appear. 
	function unstakeallstakes(){
        if(msg.sender!=oracle) throw;
            for (uint i = 0; i < stakes.length; ++i) {
				stakes[i].owner.send(stakes[i].wins+stakes[i].stake);
				delete stakes[i];
			}
        }
    }