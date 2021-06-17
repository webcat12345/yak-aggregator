//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//                              

// SPDX-License-Identifier: GPL-3.0-only


// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/lib/BytesToTypes.sol

// From https://github.com/pouladzade/Seriality/blob/master/src/BytesToTypes.sol (Licensed under Apache2.0)

pragma solidity >=0.7.0;

library BytesToTypes {

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
}


// File contracts/lib/BytesManipulation.sol

pragma solidity >=0.7.0;

library BytesManipulation {

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toBytes(address x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        // From https://ethereum.stackexchange.com/a/40456
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address) {
        return BytesToTypes.bytesToAddress(_offst, _input);
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256) {
        return BytesToTypes.bytesToUint256(_offst, _input);
    } 

}


// File contracts/interface/IAdapter.sol

pragma solidity >=0.7.0;

interface IAdapter {
    function name() external view returns (string memory);
    function swapGasEstimate() external view returns (uint);
    function swap(uint256, uint256, address, address, address) external;
    function query(uint256, address, address) external view returns (uint);
}


// File contracts/interface/IERC20.sol

pragma solidity >=0.7.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint);
    function decimals() external view returns (uint8);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint); 
}


// File contracts/interface/IWETH.sol

pragma solidity >=0.7.0;

interface IWETH is IERC20 {
    function withdraw(uint256 amount) external;
    function deposit() external payable;
}


// File contracts/lib/SafeMath.sol

pragma solidity >=0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}


// File contracts/lib/SafeERC20.sol

// This is a simplified version of OpenZepplin's SafeERC20 library
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/lib/Context.sol

pragma solidity >=0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/lib/Ownable.sol

pragma solidity >=0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/YakRouter.sol

pragma solidity >=0.7.0;

contract YakRouter is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant AVAX = address(0);
    string public constant NAME = 'YakRouter';
    uint public constant FEE_DENOMINATOR = 1e4;
    uint public MIN_FEE = 0;
    address public FEE_CLAIMER;
    address[] public TRUSTED_TOKENS;
    address[] public ADAPTERS;

    event Recovered(
        address indexed _asset, 
        uint amount
    );

    event UpdatedTrustedTokens(
	    address[] _newTrustedTokens
    );

    event UpdatedAdapters(
        address[] _newAdapters
    );

    event UpdatedMinFee(
        uint _oldMinFee,
        uint _newMinFee
    );

    event UpdatedFeeClaimer(
        address _oldFeeClaimer, 
        address _newFeeClaimer 
    );

    event YakSwap(
        address indexed _tokenIn, 
        address indexed _tokenOut, 
        uint _amountIn, 
        uint _amountOut
    );

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct OfferWithGas {
        bytes amounts;
        bytes adapters;
        bytes path;
        uint gasEstimate;
    }

    struct Offer {
        bytes amounts;
        bytes adapters;
        bytes path;
    }

    struct FormattedOfferWithGas {
        uint[] amounts;
        address[] adapters;
        address[] path;
        uint gasEstimate;
    }

    struct FormattedOffer {
        uint[] amounts;
        address[] adapters;
        address[] path;
    }

    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address[] adapters;
    }

    constructor(
        address[] memory _adapters, 
        address[] memory _trustedTokens, 
        address _feeClaimer
    ) {
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        _setAllowances();
    }

    // -- SETTERS --

    function _setAllowances() internal {
        IERC20(WAVAX).safeApprove(WAVAX, type(uint).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens) public onlyOwner {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
    }

    function setAdapters(address[] memory _adapters) public onlyOwner {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setMinFee(uint _fee) external onlyOwner {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer) public onlyOwner {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    //  -- GENERAL --

    function trustedTokensCount() external view returns (uint) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() external view returns (uint) {
        return ADAPTERS.length;
    }

    function recoverERC20(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        require(_tokenAmount > 0, 'YakRouter: Nothing to recover');
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverAVAX(uint _amount) external onlyOwner {
        require(_amount > 0, 'YakRouter: Nothing to recover');
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    // Fallback
    receive() external payable {}


    // -- HELPERS -- 

    function _applyFee(uint _amountIn, uint _fee) internal view returns (uint) {
        require(_fee>=MIN_FEE, 'YakRouter: Insufficient fee');
        return _amountIn.mul(FEE_DENOMINATOR.sub(_fee))/FEE_DENOMINATOR;
    }

    function _wrap(uint _amount) internal {
        IWETH(WAVAX).deposit{value: _amount}();
    }

    function _unwrap(uint _amount) internal {
        IWETH(WAVAX).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for AVAX
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(address _token, uint _amount, address _to) internal {
        if (address(this)!=_to) {
            if (_token == AVAX) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Makes a deep copy of Offer struct
     */
    function _cloneOffer(
        Offer memory _queries
    ) internal pure returns (Offer memory) {
        return Offer(
            _queries.amounts, 
            _queries.adapters, 
            _queries.path
        );
    }

    /**
     * Makes a deep copy of OfferWithGas struct
     */
    function _cloneOfferWithGas(
        OfferWithGas memory _queries
    ) internal pure returns (OfferWithGas memory) {
        return OfferWithGas(
            _queries.amounts, 
            _queries.adapters, 
            _queries.path, 
            _queries.gasEstimate
        );
    }

    /**
     * Appends Query elements to Offer struct
     */
    function _addQuery(
        Offer memory _queries, 
        uint256 _amount, 
        address _adapter, 
        address _tokenOut
    ) internal pure {
        _queries.path = BytesManipulation.mergeBytes(_queries.path, BytesManipulation.toBytes(_tokenOut));
        _queries.amounts = BytesManipulation.mergeBytes(_queries.amounts, BytesManipulation.toBytes(_amount));
        _queries.adapters = BytesManipulation.mergeBytes(_queries.adapters, BytesManipulation.toBytes(_adapter));
    }

    /**
     * Appends Query elements to Offer struct
     */
    function _addQueryWithGas(
        OfferWithGas memory _queries, 
        uint256 _amount, 
        address _adapter, 
        address _tokenOut, 
        uint _gasEstimate
    ) internal pure {
        _queries.path = BytesManipulation.mergeBytes(_queries.path, BytesManipulation.toBytes(_tokenOut));
        _queries.amounts = BytesManipulation.mergeBytes(_queries.amounts, BytesManipulation.toBytes(_amount));
        _queries.adapters = BytesManipulation.mergeBytes(_queries.adapters, BytesManipulation.toBytes(_adapter));
        _queries.gasEstimate += _gasEstimate;
    }

    /**
     * Converts byte-arrays to an array of integers
     */
    function _formatAmounts(bytes memory _amounts) internal pure returns (uint256[] memory) {
        // Format amounts
        uint256 chunks = _amounts.length / 32;
        uint256[] memory amountsFormatted = new uint256[](chunks);
        for (uint256 i=0; i<chunks; i++) {
            amountsFormatted[i] = BytesManipulation.bytesToUint256(i*32+32, _amounts);
        }
        return amountsFormatted;
    }

    /**
     * Converts byte-array to an array of addresses
     */
    function _formatAddresses(bytes memory _addresses) internal pure returns (address[] memory) {
        uint256 chunks = _addresses.length / 32;
        address[] memory addressesFormatted = new address[](chunks);
        for (uint256 i=0; i<chunks; i++) {
            addressesFormatted[i] = BytesManipulation.bytesToAddress(i*32+32, _addresses);
        }
        return addressesFormatted;
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function _formatOffer(Offer memory _queries) internal pure returns (FormattedOffer memory) {
        return FormattedOffer(
            _formatAmounts(_queries.amounts), 
            _formatAddresses(_queries.adapters), 
            _formatAddresses(_queries.path)
        );
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function _formatOfferWithGas(OfferWithGas memory _queries) internal pure returns (FormattedOfferWithGas memory) {
        return FormattedOfferWithGas(
            _formatAmounts(_queries.amounts), 
            _formatAddresses(_queries.adapters), 
            _formatAddresses(_queries.path), 
            _queries.gasEstimate
        );
    }


    // -- QUERIES --


    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut,
        uint8 _index
    ) external view returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function queryNoSplit(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut,
        uint8[] calldata _options
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i<_options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint amountOut = IAdapter(_adapter).query(
                _amountIn, 
                _tokenIn, 
                _tokenOut
            );
            if (i==0 || amountOut>bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function queryNoSplit(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i<ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint amountOut = IAdapter(_adapter).query(
                _amountIn, 
                _tokenIn, 
                _tokenOut
            );
            if (i==0 || amountOut>bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        uint _gasPrice
    ) external view returns (FormattedOfferWithGas memory) {
        require(_maxSteps>0 && _maxSteps<5, 'YakRouter: Invalid max-steps');
        OfferWithGas memory queries;
        queries.amounts = BytesManipulation.toBytes(_amountIn);
        queries.path = BytesManipulation.toBytes(_tokenIn);
        FormattedOffer memory gasQuery = findBestPath(_gasPrice, WAVAX, _tokenOut, 2);
        uint tknOutPrice = gasQuery.amounts[gasQuery.amounts.length-1];
        queries = _findBestPathWithGas(
            _amountIn, 
            _tokenIn, 
            _tokenOut, 
            _maxSteps,
            queries, 
            tknOutPrice
        );
        // If no paths are found return empty struct
        if (queries.adapters.length==0) {
            queries.amounts = '';
            queries.path = '';
        }
        return _formatOfferWithGas(queries);
    } 

    function _findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        OfferWithGas memory _queries, 
        uint _tknOutPrice
    ) internal view returns (OfferWithGas memory) {
        OfferWithGas memory bestOption = _cloneOfferWithGas(_queries);
        uint256 bestAmountOut;
        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = queryNoSplit(_amountIn, _tokenIn, _tokenOut);
        if (queryDirect.amountOut!=0) {
            uint gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
            _addQueryWithGas(
                bestOption, 
                queryDirect.amountOut, 
                queryDirect.adapter, 
                queryDirect.tokenOut, 
                gasEstimate
            );
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps>1 && _queries.adapters.length/32<=_maxSteps-2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i=0; i<TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = queryNoSplit(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut==0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                OfferWithGas memory newOffer = _cloneOfferWithGas(_queries);
                uint gasEstimate = IAdapter(bestSwap.adapter).swapGasEstimate();
                _addQueryWithGas(newOffer, bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPathWithGas(
                    bestSwap.amountOut, 
                    TRUSTED_TOKENS[i], 
                    _tokenOut, 
                    _maxSteps, 
                    newOffer, 
                    _tknOutPrice
                );
                address tokenOut = BytesManipulation.bytesToAddress(newOffer.path.length, newOffer.path);
                uint256 amountOut = BytesManipulation.bytesToUint256(newOffer.amounts.length, newOffer.amounts);
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint gasCostDiff = _tknOutPrice.mul(newOffer.gasEstimate-bestOption.gasEstimate);
                        uint priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) { continue; }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;   
    }

    /**
     * Return path with best returns between two tokens
     */
    function findBestPath(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps
    ) public view returns (FormattedOffer memory) {
        require(_maxSteps>0 && _maxSteps<5, 'YakRouter: Invalid max-steps');
        Offer memory queries;
        queries.amounts = BytesManipulation.toBytes(_amountIn);
        queries.path = BytesManipulation.toBytes(_tokenIn);
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries);
        // If no paths are found return empty struct
        if (queries.adapters.length==0) {
            queries.amounts = '';
            queries.path = '';
        }
        return _formatOffer(queries);
    } 

    function _findBestPath(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        Offer memory _queries
    ) internal view returns (Offer memory) {
        Offer memory bestOption = _cloneOffer(_queries);
        uint256 bestAmountOut;
        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = queryNoSplit(_amountIn, _tokenIn, _tokenOut);
        if (queryDirect.amountOut!=0) {
            _addQuery(bestOption, queryDirect.amountOut, queryDirect.adapter, queryDirect.tokenOut);
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps>1 && _queries.adapters.length/32<=_maxSteps-2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i=0; i<TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = queryNoSplit(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut==0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                Offer memory newOffer = _cloneOffer(_queries);
                _addQuery(newOffer, bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut);
                newOffer = _findBestPath(
                    bestSwap.amountOut, 
                    TRUSTED_TOKENS[i], 
                    _tokenOut, 
                    _maxSteps,
                    newOffer
                );  // Recursive step
                address tokenOut = BytesManipulation.bytesToAddress(newOffer.path.length, newOffer.path);
                uint256 amountOut = BytesManipulation.bytesToUint256(newOffer.amounts.length, newOffer.amounts);
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut>bestAmountOut) {
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;   
    }


    // -- SWAPPERS --

    function _swapNoSplit(
        Trade calldata _trade,
        address _from,
        address _to, 
        uint _fee
    ) internal returns (uint) {
        uint[] memory amounts = new uint[](_trade.path.length);
        if (_fee > 0 || MIN_FEE > 0) {
            // Transfer fees to the claimer account and decrease initial amount
            amounts[0] = _applyFee(_trade.amountIn, _fee);
            IERC20(_trade.path[0]).safeTransferFrom(
                _from, 
                FEE_CLAIMER, 
                _trade.amountIn.sub(amounts[0])
            );
        } else {
            amounts[0] = _trade.amountIn;
        }
        IERC20(_trade.path[0]).safeTransferFrom(
            _from, 
            _trade.adapters[0], 
            amounts[0]
        );
        // Get amounts that will be swapped
        for (uint i=0; i<_trade.adapters.length; i++) {
            amounts[i+1] = IAdapter(_trade.adapters[i]).query(
                amounts[i], 
                _trade.path[i], 
                _trade.path[i+1]
            );
        }
        require(amounts[amounts.length-1] >= _trade.amountOut, 'YakRouter: Insufficient output amount');
        for (uint256 i=0; i<_trade.adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i<_trade.adapters.length-1 ? _trade.adapters[i+1] : _to;
            IAdapter(_trade.adapters[i]).swap(
                amounts[i], 
                amounts[i+1], 
                _trade.path[i], 
                _trade.path[i+1],
                targetAddress
            );
        }
        emit YakSwap(
            _trade.path[0], 
            _trade.path[_trade.path.length-1], 
            _trade.amountIn, 
            amounts[amounts.length-1]
        );
        return amounts[amounts.length-1];
    }

    function swapNoSplit(
        Trade calldata _trade,
        address _to,
        uint _fee
    ) public {
        _swapNoSplit(_trade, msg.sender, _to, _fee);
    }

    function swapNoSplitFromAVAX(
        Trade calldata _trade,
        address _to,
        uint _fee
    ) external payable {
        require(_trade.path[0]==WAVAX, 'YakRouter: Path needs to begin with WAVAX');
        _wrap(_trade.amountIn);
        _swapNoSplit(_trade, address(this), _to, _fee);
    }

    function swapNoSplitToAVAX(
        Trade calldata _trade,
        address _to,
        uint _fee
    ) public {
        require(_trade.path[_trade.path.length-1]==WAVAX, 'YakRouter: Path needs to end with WAVAX');
        uint returnAmount = _swapNoSplit(_trade, msg.sender, address(this), _fee);
        _unwrap(returnAmount);
        _returnTokensTo(AVAX, returnAmount, _to);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapNoSplitWithPermit(
        Trade calldata _trade,
        address _to,
        uint _fee,
        uint _deadline, 
        uint8 _v,
        bytes32 _r, 
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(
            msg.sender, 
            address(this), 
            _trade.amountIn, 
            _deadline, 
            _v, 
            _r, 
            _s
        );
        swapNoSplit(_trade, _to, _fee);
    } 

    /**
     * Swap token to AVAX without the need to approve the first token
     */
    function swapNoSplitToAVAXWithPermit(
        Trade calldata _trade,
        address _to,
        uint _fee,
        uint _deadline, 
        uint8 _v,
        bytes32 _r, 
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(
            msg.sender, 
            address(this), 
            _trade.amountIn, 
            _deadline, 
            _v, 
            _r, 
            _s
        );
        swapNoSplitToAVAX(_trade, _to, _fee);
    }

}
