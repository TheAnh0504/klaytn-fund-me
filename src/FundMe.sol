// FundMe.sol
// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.19;
// 2. Imports
// Chúng ta import thư viện orakl để chúng ta có thể tương tác với oracle
import { IAggregator } from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";

// Chúng ta import thư viện PriceConverter để chúng ta tính toán giá trị Ether
import { PriceConverter } from "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
// Khai báo error không phải là Owner của contract
error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    // Dòng tiếp theo có nghĩa là 
    // "sử dụng library PriceConverter cho những biến có type là uint256"
    using PriceConverter for uint256;

    // State variables
    // Khai báo 1 public constant MINIMUM_USD với giá trị $5 nhưng bằng wei nên phải nhân 10^18
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    // Khai báo 1 address private và immutable với tên là i_owner, i nghĩa là immutable.
    address private immutable i_owner;
    // Khai báo 1 array private chứa danh sách những người fund ether vào với tên là s_funders, s nghĩa là storage.
    address[] private s_funders;
    // Khai báo 1 mapping giữa address với uint256 private liên kết địa chỉ với số tiền fund.
    mapping(address => uint256) private s_addressToAmountFunded;
    // Khai báo contract AggregatorV3Interface private và gán vào biến s_pricefeed, s nghĩa là storage
    IAggregator private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    // Khai báo 1 modifier onlyOwner để gán vào function mà chỉ owner có thể gọi được
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    // Khai báo constructor với 1 địa chỉ cho priceFeed ám chỉ rằng đây là địa chỉ của contract Oracle với IAggregator
    constructor(address priceFeed) {
        // input địa chỉ vào interface và gán vào biến s_priceFeed
        s_priceFeed = IAggregator(priceFeed);
        // Gán biến i_owner là msg.sender (người deploy contract này)
        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the KLAY/USDT price from Orakl
       // Gửi tiền vào contract của chúng ta dựa trên giá ETH/USD
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        // Sau đó map địa chỉ của người gửi với msg.value trong mapping s_addressToAmountFunded
        s_addressToAmountFunded[msg.sender] += msg.value;
        // Sau đó thêm địa chỉ người gửi vào danh sách các funders
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // dùng for loop, bắt đàu từ index 0 đến index ít hơn length của danh sách, và index cộng 1 cho mỗi vòng loop
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            // gán giá trị address tại funderIndex trong danh sách s_funders vào address funder
            address funder = s_funders[funderIndex];
            // thay đổi giá trị của mapping s_addressToAmountFunded có address là funder thành 0, tức là funder này đã withdraw
            s_addressToAmountFunded[funder] = 0;
        }
        // tạo một danh sách s_funders mới với 1 dynamic array (nôm na là danh sách) mới với kích cỡ bằng 0
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // Transfer vs call vs Send
        // - transfer (2300 gas, throws error if any)
        // - send (2300 gas, returns bool for success or failure)
        // - call (forward all gas or set gas, returns bool for success or failure)
        // payable(msg.sender).transfer(address(this).balance);

        // Gửi toàn bộ balance của contract này tới i_owner và không có data trong transaction và trả về boolean success hay không
        (bool success,) = i_owner.call{value: address(this).balance}("");
        // Yêu cầu bool success true nếu không thì revert toàn bộ        
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        // Copy danh sách s_funders từ storage vào memory, tức là load từ global state vào local state. Thay đổi global state tốn nhiều gas hơn local state
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** Getter Functions */
    // Những function chỉ dùng để GET thông tin
    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    /**
     * @notice Gets the funder at a specific index
     * @param index the index of the funder
     * @return the address of the funder
     */
    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    /// @notice Gets the owner of the contract
    function getOwner() public view returns (address) {
        return i_owner;
    }

    /// @notice Gets the price feed
    function getPriceFeed() public view returns (IAggregator) {
        return s_priceFeed;
    }

    /// @notice Gets the decimals of the price feed
    function getDecimals() public view returns (uint8) {
        return s_priceFeed.decimals();
    }

    /// @notice Gets the description of the price feed
    function getDescription() public view returns (string memory) {
        return s_priceFeed.description();
    }
}