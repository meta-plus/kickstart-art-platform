// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

library SLib {
    struct Artist{
        uint id;
        address artistAddress;
        string name;
        string iconURL;
    }  

    struct Project{
        uint id;
        address artistAddress;
        string name;
        string description;
        uint targetFundingAmount;
        uint currentFundingAmount;
        uint totalFunder;
        bool isOpen;
        string dataURL;
    }

    struct ProjectShare {
        uint projectId;
        uint share;
    }

    struct ProjectAddressFund {
        address funderAddress;
        uint amount;
    }
}