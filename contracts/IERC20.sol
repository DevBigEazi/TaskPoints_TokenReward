// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 value) external returns (bool);

}