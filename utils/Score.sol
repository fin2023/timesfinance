// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../token/ST.sol";

contract Score is AccessControl {

    bytes32 public constant RECORDER_ROLE = keccak256("RECORDER_ROLE");

    ST private immutable st;

    constructor(ST _st) {
        st = _st;
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function recordScore(address to, uint amount) public onlyRole(RECORDER_ROLE) {
        st.mint(to,amount);
    }

    function grantRecorder(address recorder) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(RECORDER_ROLE, recorder);
    }

    function revokeRecorder(address recorder) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(RECORDER_ROLE, recorder);
    }
}