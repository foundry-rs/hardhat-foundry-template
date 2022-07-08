// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {CREATE3} from "solmate/utils/CREATE3.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import "../ERC20/Creds.sol";
import "../ERC20/Credit.sol";
import "../ERC20/TokenManager.sol";

contract CreditFactory {
    //using CREATE3 for ??;
    //using Clones for ??;

    //ignore tokens transferred to this contract accept to transfer them to the treasury

    struct CREDIT {
        address TokenManager;
        address Creds;
        address Credit;
    }

    address payable private treasury;
    uint256 public globalCeiling; // set default global ceiling for a given CREDIT
    //address public tokenAddress;

    //how to register a token for credit?
    //function registerCredit() public {}

    mapping(address => CREDIT) public CreditMapping;

    //how to generate salt?

    function createCreds(
        string memory credsName,
        string memory credsSymbol,
        uint8 credsDecimal,
        bytes32 salt,
        address tokenAddress
    ) internal returns (address) {
        Creds creds = new Creds{salt: salt}(
            credsName,
            credsSymbol,
            credsDecimal
        );
        address local = address(creds);
        CreditMapping[tokenAddress].Creds = local;
        return local;
    }

    function createCredit(
        string memory creditName,
        string memory creditSymbol,
        bytes32 salt,
        address tokenAddress
    ) internal returns (address) {
        Credit credit = new Credit{salt: salt}(creditName, creditSymbol);

        address local = address(credit);
        CreditMapping[tokenAddress].Credit = local;
        return local;
    }

    function run(
        string memory credsName,
        string memory credsSymbol,
        uint8 credsDecimal,
        string memory creditName,
        string memory creditSymbol,
        bytes32 salt,
        address tokenAddress
    ) external {
        address creds = createCreds(
            credsName,
            credsSymbol,
            credsDecimal,
            salt,
            tokenAddress
        );
        address credit = createCredit(
            creditName,
            creditSymbol,
            salt,
            tokenAddress
        );
        createTokenManager(
            ICREDS(creds),
            ICREDIT(credit),
            treasury,
            tokenAddress,
            globalCeiling,
            salt
        );
    }

    function createTokenManager(
        ICREDS _creds,
        ICREDIT _credit,
        address payable _treasury,
        address _tokenAddress,
        uint256 _globalCeiling,
        bytes32 _salt
    ) internal {
        TokenManager tokenmanager = new TokenManager{salt: _salt}(
            _creds,
            _credit,
            _treasury,
            _tokenAddress,
            _globalCeiling
        );
        CreditMapping[_tokenAddress].TokenManager = address(tokenmanager);
    }
}
