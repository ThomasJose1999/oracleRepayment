# oracleRepayment

## set up a oracle node 
details - https://docs.chain.link/chainlink-nodes/v1/running-a-chainlink-node.  
change .chainlink-sepolia in the commands to the working folder pwd

### deploy operator.sol contract and save the contract address

### call the setAuthorizedSenders function of oraclewith the address of your node. Note the function expects an array.

### deploy the repayment consumer contract and pass the address of records in the constructor 

### add a new bridge in the oracle node with values name : demobridge and url : http://host.docker.internal:8080/ (external adapter)

### add job in the oracle with the jobspec and change the contract address in the jobspec to address of the operator

### call request repayment data of the repayment consumer contract note that add the job id with out "-"

for further details checkout https://docs.chain.link/chainlink-nodes/v1/fulfilling-requests
