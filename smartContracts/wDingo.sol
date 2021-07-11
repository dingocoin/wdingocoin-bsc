// TODO: ADD NONCE TO CONFIGURATION

pragma solidity 0.8.4;

interface IBEP20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}


abstract contract Context {

  constructor () { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract BEP20Token is Context, IBEP20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() {
    _name = "Wrapped Dingocoin";
    _symbol = "wDingocoin";
    _decimals = 8;
    _totalSupply = 0;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  // Harcoded initial configurations. These are subjected to change with the configure() call.
  // DO NOT RELY ON THESE HARDCODED VALUES. Invoke the necessary getters to get the latest values.
  address[] private _authorityAddresses = [
  ];
  uint256 private _authorityThreshold = 2;
  uint256 private _minBurnAmount = 1000000000;

  mapping (address => mapping(string => uint256)) private _mintHistory;
  mapping (address => uint256) private _mintNonce;
  mapping (address => uint256[]) private _burnAmount;
  mapping (address => string[]) private _burnDestination;

  function authorityAddresses() external view returns (address[] memory) {
    return _authorityAddresses;
  }

  function authorityThreshold() external view returns (uint256) {
    return _authorityThreshold;
  }

  function minBurnAmount() external view returns (uint256) {
    return _minBurnAmount;
  }

  function configure(address[] calldata newAuthorityAddresses, uint256 newAuthorityThreshold, uint256 newMinBurnAmount,
      uint8[] calldata signV, bytes32[] calldata signR, bytes32[] calldata signS) external {

    require(newAuthorityAddresses.length >= 1);
    require(newAuthorityThreshold >= 1);
    require(signV.length == _authorityAddresses.length);
    require(signR.length == _authorityAddresses.length);
    require(signS.length == _authorityAddresses.length);

    bytes memory prefix = bytes("\x19Ethereum Signed Message:\n32");
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encode(
        newAuthorityAddresses, newAuthorityThreshold, newMinBurnAmount))));
    uint256 signatures = 0;
    for (uint256 i = 0; i < _authorityAddresses.length; i++) {
      address addr = ecrecover(prefixedHash, signV[i], signR[i], signS[i]);
      if (addr == _authorityAddresses[i]) {
        signatures = SafeMath.add(signatures, 1);
      }
      if (signatures >= _authorityThreshold) {
        break;
      }
    }
    require(signatures >= _authorityThreshold);

    _authorityAddresses = newAuthorityAddresses;
    _authorityThreshold = newAuthorityThreshold;
    _minBurnAmount = newMinBurnAmount;
  }

  function mintNonce(address addr) external view returns (uint256) {
    return _mintNonce[addr];
  }

  function mintHistory(address addr, string calldata depositAddress) external view returns (uint256, uint256) {
    return (_mintNonce[addr], _mintHistory[addr][depositAddress]);
  }

  function mint(string calldata depositAddress, uint256 amount,
      uint8[] calldata signV, bytes32[] calldata signR, bytes32[] calldata signS) external {
    require(signV.length == _authorityAddresses.length);
    require(signR.length == _authorityAddresses.length);
    require(signS.length == _authorityAddresses.length);

    bytes memory prefix = bytes("\x19Ethereum Signed Message:\n32");
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256(abi.encode(
        _msgSender(), _mintNonce[_msgSender()], depositAddress, amount))));
    uint256 signatures = 0;
    for (uint256 i = 0; i < _authorityAddresses.length; i++) {
      address addr = ecrecover(prefixedHash, signV[i], signR[i], signS[i]);
      if (addr == _authorityAddresses[i]) {
        signatures = SafeMath.add(signatures, 1);
      }
      if (signatures >= _authorityThreshold) {
        break;
      }
    }
    require(signatures >= _authorityThreshold);

    _mint(_msgSender(), amount);
    _mintNonce[_msgSender()] = SafeMath.add(_mintNonce[_msgSender()], 1);
    _mintHistory[_msgSender()][depositAddress] = SafeMath.add(_mintHistory[_msgSender()][depositAddress], amount);
  }

  function burnHistory(address addr) external view returns (string[] memory, uint256[] memory) {
    require(_burnDestination[addr].length == _burnAmount[addr].length);
    return (_burnDestination[addr], _burnAmount[addr]);
  }

  function burnHistory(address addr, uint256 index) external view returns (string memory, uint256) {
    require(_burnDestination[addr].length == _burnAmount[addr].length);
    return (_burnDestination[addr][index], _burnAmount[addr][index]);
  }

  function burnHistoryMultiple(address[] calldata addrs, uint256[] calldata indexes) external view returns (string[] memory, uint256[] memory) {
    require(addrs.length == indexes.length);
    string[] memory destinations = new string[](addrs.length);
    uint256[] memory amounts= new uint256[](addrs.length);
    for (uint256 i = 0; i < addrs.length; i++) {
      destinations[i] = _burnDestination[addrs[i]][indexes[i]];
      amounts[i] = _burnAmount[addrs[i]][indexes[i]];
    }
    return (destinations, amounts);
  }

  function burn(uint256 amount, string calldata destination) external {
    require(amount >= _minBurnAmount);
    _burn(_msgSender(), amount);
    _burnAmount[_msgSender()].push(amount);
    _burnDestination[_msgSender()].push(destination);
  }
}
