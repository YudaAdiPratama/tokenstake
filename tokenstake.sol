// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract TokenStaking {
    struct Stake {
        uint256 amount;
        uint256 startTimestamp;
        uint256 lockPeriod; // dalam detik
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStaked;

    Token public token;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function stake(uint256 _amount, uint256 _lockPeriod) external {
        require(_amount > 0, "Invalid amount");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        // Transfer token dari pengguna ke kontrak staking
        token.transferFrom(msg.sender, address(this), _amount);

        // Tambahkan staking baru ke dalam array stakes
        stakes[msg.sender].push(
            Stake({amount: _amount, startTimestamp: block.timestamp, lockPeriod: _lockPeriod})
        );

        // Tambahkan jumlah total yang di-stake oleh pengguna
        totalStaked[msg.sender] += _amount;
    }

    function unstake(uint256 _index) external {
    require(_index < stakes[msg.sender].length, "Invalid index");

            Stake storage userStake = stakes[msg.sender][_index];

            require(block.timestamp >= userStake.startTimestamp + userStake.lockPeriod, "Lock period not over yet");

            uint256 amount = userStake.amount;
            userStake.amount = 0;

            // Transfer token from the staking contract back to the user
            token.transfer(msg.sender, amount);

            // Reduce the total staked amount by the user
            totalStaked[msg.sender] -= amount;
        }


    function getStakeCount(address _address) external view returns (uint256) {
        return stakes[_address].length;
    }

    function getStakeDetails(address _address, uint256 _index)
    external
    view
    returns (uint256 amount, uint256 startTimestamp, uint256 lockPeriod)
    {
        require(_index < stakes[_address].length, "Invalid index");

        Stake storage userStake = stakes[_address][_index];

        amount = userStake.amount;
        startTimestamp = userStake.startTimestamp;
        lockPeriod = userStake.lockPeriod;
    }

}
