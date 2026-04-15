    mapping (address => Reserve) storage reserve;
    // mapping tracks user to the kind of asset and the balance they have of that asset

mapping address => mapping(address => uint256) userBalance;
mapping address => mapping(address => uint256) userDebt;

    function initReserve (address asset) public {

Reserve storage reserve = reserves[asset];
reserve = Reserve({
uint256 totalDeposited = 0;
uint256 totalDebt= 0;

})
}
struct Reserve {
uint256 totalDeposited;
uint256 totalDebt;
address aToken;
address debtToken;
}
