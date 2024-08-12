// PriceConverter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import IAggregator từ orakl repository
import { IAggregator } from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";

// Khai báo 1 library tên là PriceConverter
library PriceConverter {
    
    // Khai báo function getPrice với input là interface contract và trả về uint256
    function getPrice(IAggregator priceFeed) internal view returns (uint256) {
        // gọi function latestRoundData() trong priceFeed
        (, int256 answer,,,) = priceFeed.latestRoundData();
        // Trả về ETH/USD rate có 18 digit (oracle có sẵn 8 số 0 nên thêm 10 số 0)
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    // Chuyển đổi số Ether ra số lượng USD
    // function getConversionRate nhận input là ethAmount với type uint256 và interface contract, trả về uint256 
    function getConversionRate(uint256 ethAmount, IAggregator priceFeed) internal view returns (uint256) {
        // Đầu tiên lấy giá eth bằng getPrice và gán vào biến ethPrice
        uint256 ethPrice = getPrice(priceFeed);
        // Sau đó lấy ethPrice nhân với số lượng ether và chia 18 số 0
        // Trong solidity thì chúng ta nên nhân trước khi chia vì không có float
        // phép tính này là ethPrice (18 digit) * ethAmount (18 digit) / 18 digit để nhận lại 18 digit thôi        
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // Trả về giá trị usd của số lượng ether        
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}