// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract GHAF_IDO is Ownable {    
    using SafeMath for uint256;
    using Address for address;

    IERC20 constant USDC_TOKEN = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public GHAF_TOKEN = IERC20(0xDe3F6e45985b2E706C3BAc12b10F6427E6f9C53d);
    address private COMPANY_WALLET = address(0xe01fA40A34Fa7d5a023C98b09Af707C199e8eb63);

    uint256 public MAX_PAY_LIMIT_GHOG_HOLDER = 2000_000_000; // 2000 USDC
    uint256 public MAX_PAY_LIMIT_WHITELIST_1 = 300_000_000; // 300 USDC
    uint256 public MAX_PAY_LIMIT_WHITELIST_2 = 300_000_000; // 300 USDC
    uint256 public MAX_PAY_LIMIT_PUBLIC = 500_000_000; // 500 USDC

    uint256 public GHAF_AMOUNT_PER_USDC_GHOG_HOLDER = 200 * 10**18 / 10**6; // 200 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_WHITELIST_1 = 170 * 10**18 / 10**6; // 170 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_WHITELIST_2 = 135 * 10**18 / 10**6; // 135 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_PUBLIC = 115 * 10**18 / 10**6; // 115 GHAF per 1 USDC
    
    uint256 public START_DATETIME_GHOG_HOLDER = 1651708800; // May 5, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_GHOG_HOLDER = 1652054400; // May 9, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_WHITELIST_1 = 1652572800; // May 15, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_WHITELIST_1 = 1653091200; // May 21, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_WHITELIST_2 = 1653436800; // May 25, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_WHITELIST_2 = 1653955200; // May 31, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_PUBLIC = 1654819200; // June 10, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_PUBLIC = 1656201600; // June 26, 2022 12:00:00 AM GMT

    mapping(address=>uint256) public MAP_DEPOSIT_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_DEPOSIT_WHITELIST_1;
    mapping(address=>uint256) public MAP_DEPOSIT_WHITELIST_2;
    mapping(address=>uint256) public MAP_DEPOSIT_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_CLAIM_WHITELIST_1;
    mapping(address=>uint256) public MAP_CLAIM_WHITELIST_2;
    mapping(address=>uint256) public MAP_CLAIM_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_DATETIME_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_WHITELIST_1;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_WHITELIST_2;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_PUBLIC;

    uint256 public TOTAL_DEPOSIT_GHOG_HOLDER;
    uint256 public TOTAL_DEPOSIT_WHITELIST_1;
    uint256 public TOTAL_DEPOSIT_WHITELIST_2;
    uint256 public TOTAL_DEPOSIT_PUBLIC;

    bytes32 public WHITELIST_ROOT_GHOG_HOLDER;
    bytes32 public WHITELIST_ROOT_WHITELIST_1;
    bytes32 public WHITELIST_ROOT_WHITELIST_2;

    uint256 public CLAIM_INTERVAL = 30 days;

    bool public IDO_ENDED = false;

    constructor() {}

    function setGHAFToken(address _address) public onlyOwner {
        GHAF_TOKEN = IERC20(_address);
    }

    function setCompanyWallet(address _address) public onlyOwner {
        COMPANY_WALLET = _address;
    }

    function setWhitelistingRootForGHOGHolder(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_GHOG_HOLDER = _root;
    }

    function setWhitelistingRootForWhitelist1(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_WHITELIST_1 = _root;
    }

    function setWhitelistingRootForWhitelist2(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_WHITELIST_2 = _root;
    }

    function isWhiteListedForGHOGHolder(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_GHOG_HOLDER, _leafNode);
    }

    function isWhiteListedForWhitelist1(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_WHITELIST_1, _leafNode);
    }

    function isWhiteListedForWhitelist2(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_WHITELIST_2, _leafNode);
    }

    function toLeaf(address account, uint256 index, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account, amount));
    }

    function contributeForGHOGHolder(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_GHOG_HOLDER && block.timestamp <= END_DATETIME_GHOG_HOLDER, "IDO is not activated");

        require(isWhiteListedForGHOGHolder(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_GHOG_HOLDER[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_GHOG_HOLDER, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_GHOG_HOLDER[msg.sender] = MAP_DEPOSIT_GHOG_HOLDER[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_GHOG_HOLDER += _contributeAmount;
    }
    function contributeForWhitelist1(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_WHITELIST_1 && block.timestamp <= END_DATETIME_WHITELIST_1, "IDO is not activated");

        require(isWhiteListedForWhitelist1(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_WHITELIST_1[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_WHITELIST_1, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_WHITELIST_1[msg.sender] = MAP_DEPOSIT_WHITELIST_1[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_WHITELIST_1 += _contributeAmount;
    }
    function contributeForWhitelist2(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_WHITELIST_2 && block.timestamp <= END_DATETIME_WHITELIST_2, "IDO is not activated");

        require(isWhiteListedForWhitelist2(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_WHITELIST_2[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_WHITELIST_2, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_WHITELIST_2[msg.sender] = MAP_DEPOSIT_WHITELIST_2[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_WHITELIST_2 += _contributeAmount;
    }
    function contributeForPublic(uint256 _contributeAmount) public {
        require(block.timestamp >= START_DATETIME_PUBLIC && block.timestamp <= END_DATETIME_PUBLIC, "IDO is not activated");

        require((MAP_DEPOSIT_PUBLIC[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_PUBLIC, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_PUBLIC[msg.sender] = MAP_DEPOSIT_PUBLIC[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_PUBLIC += _contributeAmount;
    }

    function reservedTokenAmountForGHOGHolder(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_GHOG_HOLDER[_address] * GHAF_AMOUNT_PER_USDC_GHOG_HOLDER;
    }
    function reservedTokenAmountForWhitelist1(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_WHITELIST_1[_address] * GHAF_AMOUNT_PER_USDC_WHITELIST_1;
    }
    function reservedTokenAmountForWhitelist2(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_WHITELIST_2[_address] * GHAF_AMOUNT_PER_USDC_WHITELIST_2;
    }
    function reservedTokenAmountForPublic(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PUBLIC[_address] * GHAF_AMOUNT_PER_USDC_PUBLIC;
    }

    function claimForGHOGHolder() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_GHOG_HOLDER[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForGHOGHolder(msg.sender) - MAP_CLAIM_GHOG_HOLDER[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForGHOGHolder(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;
        
        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_GHOG_HOLDER[msg.sender] = MAP_CLAIM_GHOG_HOLDER[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_GHOG_HOLDER[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }
    function claimForWhitelist1() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_WHITELIST_1[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForWhitelist1(msg.sender) - MAP_CLAIM_WHITELIST_1[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForWhitelist1(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_WHITELIST_1[msg.sender] = MAP_CLAIM_WHITELIST_1[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_WHITELIST_1[msg.sender] = block.timestamp + CLAIM_INTERVAL;

    }
    function claimForWhitelist2() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_WHITELIST_2[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForWhitelist2(msg.sender) - MAP_CLAIM_WHITELIST_2[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForWhitelist2(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_WHITELIST_2[msg.sender] = MAP_CLAIM_WHITELIST_2[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_WHITELIST_2[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }
    function claimForPublic() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_PUBLIC[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForPublic(msg.sender) - MAP_CLAIM_PUBLIC[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForPublic(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_PUBLIC[msg.sender] = MAP_CLAIM_PUBLIC[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_PUBLIC[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }

    function airdrop(address[] memory _airdropAddresses, uint256 _airdropAmount) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            GHAF_TOKEN.transfer(to, _airdropAmount);
        }
    }

    function setCostForGHOGHolder(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_GHOG_HOLDER = _newCost;
    }
    function setCostForWhitelist1(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_WHITELIST_1 = _newCost;
    }
    function setCostForWhitelist2(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_WHITELIST_2 = _newCost;
    }
    function setCostForPublic(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_PUBLIC = _newCost;
    }

    function setMaxPayLimitForGHOGHolder(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_GHOG_HOLDER = _amount;
    }
    function setMaxPayLimitForWhitelist1(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_WHITELIST_1 = _amount;
    }
    function setMaxPayLimitForWhitelist2(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_WHITELIST_2 = _amount;
    }
    function setMaxPayLimitForPublic(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_PUBLIC = _amount;
    }


    function finishIDO(bool bEnded) public onlyOwner {
        IDO_ENDED = !bEnded;
    }

    function withdrawUSDC() public onlyOwner {
        USDC_TOKEN.transfer(msg.sender, USDC_TOKEN.balanceOf(address(this)));
    }

    function withdrawGHAF() public onlyOwner {
        GHAF_TOKEN.transfer(msg.sender, GHAF_TOKEN.balanceOf(address(this)));
    }
}