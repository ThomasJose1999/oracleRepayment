// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OnchainRecords.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";



/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract repyamentDataFetcher is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    OnchainRecords public records;
    event RequestEthereumPriceFulfilled(
        bytes32 indexed requestId,
        string indexed loanId
    );

    struct repaymentData{
        string loanId;
        uint256 stage2FinanceFee;
        uint256 penaltyCommitmentFee;
        uint256 penaltyFinanceFee;
        uint256 newrepaymentAmount;
    }

    mapping(string => repaymentData) public repaymentList;

    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor(address recordAddress) ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        records = OnchainRecords(recordAddress);
    }

    function requestRepaymentData(
        address _oracle,
        string memory _jobId,
        string memory loanId
    ) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillRepaymentData.selector
        );
        req.add("loanId", loanId);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillRepaymentData(
        bytes32 _requestId,
        string memory loanId, 
        uint256 stage2FinanceFee, 
        uint256 penaltyCommitmentFee, 
        uint256 penaltyFinanceFee,
        uint256 newrepaymentAmount
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestEthereumPriceFulfilled(_requestId, loanId);
        repaymentList[loanId] = repaymentData(
                loanId,
                stage2FinanceFee,
                penaltyCommitmentFee,
                penaltyFinanceFee,
                newrepaymentAmount
            );
        records.updateRepaymentAmount(loanId, repaymentList[loanId].stage2FinanceFee, repaymentList[loanId].penaltyCommitmentFee, repaymentList[loanId].penaltyFinanceFee, repaymentList[loanId].newrepaymentAmount);    
    }

    function updateRepayment(string memory loanId) public {
        records.updateRepaymentAmount(loanId, repaymentList[loanId].stage2FinanceFee, repaymentList[loanId].penaltyCommitmentFee, repaymentList[loanId].penaltyFinanceFee, repaymentList[loanId].newrepaymentAmount);
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
