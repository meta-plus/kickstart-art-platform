
const ElectionV2 = artifacts.require('ElectionV2');
const NodeRSA = require('node-rsa');
const key = new NodeRSA({b: 512});
const publicPem = key.exportKey('public');
const privatePem = key.exportKey('private');

contract("ElectionV2", (accounts) =>{
    let organizerAddress = accounts[1]

    it("init with 0 votes", async () =>{
        const electionV2Instance = await ElectionV2.deployed();
        const count = await electionV2Instance.contractVoteCounts()
        assert.equal(count.toNumber(),0, "not init with 0 votes")
    })

    it("add 1 vote", async() =>{
        const electionV2Instance = await ElectionV2.deployed();
        
        let voteName = "test vote 1"
        let organizerName = "HK voting organizer"
        let dummyVoteOptions = ['apple','banana','watermelon'];
        let voteCounts = dummyVoteOptions.length

        try {
            const receipt2 = await electionV2Instance.addVote(voteName,organizerName,publicPem, [], {from:organizerAddress})
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
        }
        

        const receipt = await electionV2Instance.addVote(voteName,organizerName,publicPem, dummyVoteOptions, {from:organizerAddress})
        const count = await electionV2Instance.contractVoteCounts()
        assert.equal(count.toNumber(),1, `count = ${count}, not add 1 new Vote`)

        let voteID = 1
        const vote = await electionV2Instance.contractVotes(voteID)
        assert.equal(vote[0].toNumber(),1, `vote ID not equal to ${voteID}`)
        assert.equal(vote[1],voteName, `vote name not equal to ${voteName}`)
        assert.equal(vote[2],organizerName, `vote organizerName not equal to ${organizerName}`)
        assert.equal(vote[3],organizerAddress, `vote organizerAddress not equal to ${organizerAddress}`)
        assert.equal(vote[4],publicPem, `vote publicKey not equal to ${publicPem}`)
        assert.equal(vote[5],"", `vote privateKey not empty at beginning`)
        assert.equal(vote[6].toNumber(),voteCounts, `voteOptionCount not equal to ${voteCounts}`)
        
        assert.equal(vote[7].toNumber(),0, `total vote count not equal to ${0}`)
        assert.equal(vote[8],false, `vote end not equal to false`)
        // check if exist in myVotes
        const myVotes = await electionV2Instance.getMyOrganizedVotes({from:organizerAddress});
        assert.equal(myVotes.length, 1, "not found 1 vote i myVotes")
        assert.equal(myVotes[0].toNumber(), 1, "myVote[0] voteID ot equal to 1")

        const voteOptions = await electionV2Instance.getVoteOptionsByVoteID(voteID);
        assert.equal(voteOptions.length,voteCounts,`total voteOptions not equal to ${voteCounts}`)
        for(let i = 0; i < voteOptions.length; i++){
            assert.equal(voteOptions[i].name,dummyVoteOptions[i], `voteOption #${voteOptions[i].id} name ${voteOptions[i].name} not equal to ${dummyVoteOptions[i]}`)
        }

    })

    it("vote to specific vote by voteID", async() =>{
        const electionV2Instance = await ElectionV2.deployed();
        
        let existVoteID = 1;
        let notExistVoteID = 2;
        let ballot = 2
        let signature = "5678"
        const voteBefore = await electionV2Instance.contractVotes(existVoteID)
        assert.equal(voteBefore[7].toNumber(), 0, `total votes not equal to ${0} before vote`)
        const publicKeyInContract = voteBefore[4]
        const pKey = new NodeRSA();
        pKey.importKey(publicKeyInContract, 'public');
        let encryptedBallot = pKey.encrypt(ballot,'base64')
        // const originalBallot = key.decrypt(encryptedBallot,'json')
        // console.log("originalBallot", originalBallot)
        try {
            await electionV2Instance.caseVoteByVoteID(notExistVoteID,encryptedBallot, signature)
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
        }

        await electionV2Instance.caseVoteByVoteID(existVoteID,encryptedBallot, signature)
        const voteAfter = await electionV2Instance.contractVotes(existVoteID)
        let ticketCount = voteAfter[7].toNumber()
        assert.equal(ticketCount, 1, `total votes not equal to ${1} after vote`)

        
        const voteTickets = await electionV2Instance.getVoteTicketsByVoteID(existVoteID)
        assert.equal(voteTickets.length,ticketCount,`total vote tickets not equal to ${ticketCount}`)
        // console.log("voteTickets",voteTickets)
        // console.log("voteTickets[0].id",voteTickets[0].id)
        assert.equal(Number(voteTickets[0].id), 1, `vote ticket ID not equal to ${1} `)
        assert.equal(voteTickets[0].encryptedBallot, encryptedBallot, `vote ticket encryptedBallot not equal to encryptedBallot ${encryptedBallot} `)
        assert.equal(voteTickets[0].signature, signature, `vote ticket signature not equal to signature ${signature} `)

        const keyProvideByOrganizer = new NodeRSA();
        keyProvideByOrganizer.importKey(privatePem,'private')
        let decryptOption = keyProvideByOrganizer.decrypt(voteTickets[0].encryptedBallot,'json')
        assert.equal(decryptOption, ballot, `decrypt vote ticket not equal to ballot ${ballot} `)
    })

    it("end a vote by voteID", async() =>{
        const electionV2Instance = await ElectionV2.deployed();
        let existVoteID = 1;
        let notExistVoteID = 2;

        try {
            await electionV2Instance.endVoteByVoteID(notExistVoteID,"",[])
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
            assert.equal(error.reason,"voteID must less than contractVoteCounts", `detect wrong error reason ${error.reason}`)
        }

        try {
            await electionV2Instance.endVoteByVoteID(existVoteID,"",[],{from:accounts[9]})
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
            assert.equal(error.reason,"Only Organizer can end the vote", `detect wrong error reason ${error.reason}`)
        }

        try {
            await electionV2Instance.endVoteByVoteID(existVoteID,"",[],{from:organizerAddress})
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
            assert.equal(error.reason,"You must upload tickets count of all options", `detect wrong error reason ${error.reason}`)
        }
        
        const voteBefore = await electionV2Instance.contractVotes(existVoteID)
        const publicKeyInContract = voteBefore[4]
        let voteOptionMax = voteBefore[6].toNumber()

        // add more votes
        // allow number, numStr
        let ballots = [1,2,1,1,2,3,1,,'2',0, (voteOptionMax + 1),"asdasd"]
        for(let i = 0; i < ballots.length; i++){
            const pKey = new NodeRSA();
            pKey.importKey(publicKeyInContract, 'public');
            if(ballots[i] !== null && ballots[i] !== undefined){
                let encryptedBallot = pKey.encrypt(ballots[i],'base64')
                await electionV2Instance.caseVoteByVoteID(existVoteID,encryptedBallot, "")
            }
        }

        const vote = await electionV2Instance.contractVotes(existVoteID)
        const voteTickets = await electionV2Instance.getVoteTicketsByVoteID(existVoteID)
        const keyProvideByOrganizer = new NodeRSA();
        keyProvideByOrganizer.importKey(privatePem,'private')
        let ticketCount = new Array(vote[6].toNumber()).fill(0);
        voteTickets.map(t=>{
            try {
                let ballot = keyProvideByOrganizer.decrypt(t.encryptedBallot,'json')
                if(ballot > 0 && ballot <= voteOptionMax){
                    ticketCount[ballot - 1] ++;
                    // console.log("ballot",ballot)
                }
            } catch (error) {
                
            }
        })
        // console.log("final ticketCount",ticketCount)

        let totalSuccessVote = 0
        ticketCount.map(t=>totalSuccessVote+= t)
        assert.equal(totalSuccessVote, 9, `success total votes not equal to 9`)
        // console.log("totalSuccessVote",totalSuccessVote)

        // end the vote
        await electionV2Instance.endVoteByVoteID(existVoteID,privatePem,ticketCount,{from:organizerAddress})

        // try case vote after vote end
        try {
            await electionV2Instance.caseVoteByVoteID(existVoteID,"asdasd", "")
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
            assert.equal(error.reason,"Vote is end", `detect wrong error reason ${error.reason}`)
        }

        try {
            const result = await electionV2Instance.getVoteResultsByVoteID(999)
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, "error message must contain revert")
        }

        const results = await electionV2Instance.getVoteResultsByVoteID(existVoteID)
        let totalSuccessVoteInBlockChain = 0
        results.map(t=>totalSuccessVoteInBlockChain+= t.toNumber())
        assert.equal(results.length, ticketCount.length, "result length in blockchain not equal in local")
        assert.equal(totalSuccessVote, totalSuccessVoteInBlockChain, `totalSuccessVote in blochain not equal in local`)
        // console.log("results",results)
    })



})