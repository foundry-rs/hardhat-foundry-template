// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC20/Creds.sol";
import "../ERC20/Credit.sol";
import "../ERC20/TokenManager.sol";

contract CreditFactory is Ownable {
    error AlreadyRegistered();
    error NotRegistered();
    error CredsDeploymentFailed();
    error CreditDeploymentFailed();
    error TokenManagerDeploymentFailed();

    //events:
    //registerCredit
    //run
    //createCreds
    //createCredit
    //createTokenManager

    struct CREDIT {
        address TokenManager;
        address Creds;
        address Credit;
    }

    mapping(address => CREDIT) public CreditMapping;
    address[] public registeredAddresses;
    address private TokenAddress; //prevents stack too deep errors

    string private constant CREDSPOOLNAME = " Creds";
    string private constant CREDSPOOLSYMBOL = "w";
    string private constant CREDITPOOLNAME = " Credit";
    string private constant CREDITPOOLSYMBOL = "c";

    // refactor
    function getTokenNameSymbolDecimal(address tokenAddress)
        public
        view
        returns (
            string memory,
            string memory,
            uint8,
            string memory,
            string memory
        )
    {
        string memory tokenName = ERC20(tokenAddress).name();
        string memory tokenSymbol = ERC20(tokenAddress).symbol();
        string memory credsName = join(tokenName, CREDSPOOLNAME);
        string memory credsSymbol = join(CREDSPOOLSYMBOL, tokenSymbol);
        uint8 credsDecimal = ERC20(tokenAddress).decimals();

        string memory creditName = join(tokenName, CREDITPOOLNAME);
        string memory creditSymbol = join(CREDITPOOLSYMBOL, tokenSymbol);
        return (credsName, credsSymbol, credsDecimal, creditName, creditSymbol);
    }

    function registerCredit(address tokenAddress)
        external
        returns (
            address,
            address,
            address
        )
    {
        TokenAddress = tokenAddress;
        if (CreditMapping[TokenAddress].TokenManager != address(0))
            revert AlreadyRegistered();

        (
            string memory credsName,
            string memory credsSymbol,
            uint8 credsDecimal,
            string memory creditName,
            string memory creditSymbol
        ) = getTokenNameSymbolDecimal(TokenAddress);

        (address creds, address credit, address tokenManager) = run(
            credsName,
            credsSymbol,
            credsDecimal,
            creditName,
            creditSymbol,
            TokenAddress
        );

        //emit
        return (creds, credit, tokenManager);
    }

    function run(
        string memory credsName,
        string memory credsSymbol,
        uint8 credsDecimal,
        string memory creditName,
        string memory creditSymbol,
        address tokenAddress
    )
        private
        returns (
            address,
            address,
            address
        )
    {
        address credit = createCredit(creditName, creditSymbol, tokenAddress);

        address creds = createCreds(
            credsName,
            credsSymbol,
            credsDecimal,
            tokenAddress
        );

        address tokenManager = createTokenManager(
            ICREDS(creds),
            ICREDIT(credit),
            tokenAddress
        );

        //check to make sure it transferred properly?
        ICREDS(creds).transferOwnership(tokenManager);
        ICREDIT(credit).transferOwnership(tokenManager);
        //emit
        return (creds, credit, tokenManager);
    }

    function createCreds(
        string memory credsName,
        string memory credsSymbol,
        uint8 credsDecimal,
        address tokenAddress
    ) private returns (address) {
        address local = address(
            new Creds(credsName, credsSymbol, credsDecimal)
        );
        if (local == address(0)) revert CredsDeploymentFailed();
        CreditMapping[tokenAddress].Creds = local;
        //emit
        return local;
    }

    function createCredit(
        string memory creditName,
        string memory creditSymbol,
        address tokenAddress
    ) private returns (address) {
        address local = address(new Credit(creditName, creditSymbol));
        if (local == address(0)) revert CreditDeploymentFailed();
        CreditMapping[tokenAddress].Credit = local;
        //emit
        return local;
    }

    function createTokenManager(
        ICREDS _creds,
        ICREDIT _credit,
        address _tokenAddress
    ) private returns (address) {
        address local = address(
            new TokenManager(_creds, _credit, _tokenAddress)
        );
        if (local == address(0)) revert TokenManagerDeploymentFailed();
        CreditMapping[_tokenAddress].TokenManager = local;
        //emit
        return local;
    }

    function join(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function getCreditMapping(address tokenAddress)
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        if (CreditMapping[tokenAddress].TokenManager == address(0))
            revert NotRegistered();
        address a = CreditMapping[tokenAddress].TokenManager;
        address b = CreditMapping[tokenAddress].Creds;
        address c = CreditMapping[tokenAddress].Credit;

        return (a, b, c);
    }

    //TODO
    function getAllRegisteredAddresses(address[] memory poolAddresses)
        external
        view
        returns (address[] memory)
    {}
}
