// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IEIP7702DeleGator {
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable;
    function setEmergencyTriggerWallet(address triggerWallet) external;
    function setSecurityAddress(address securityAddress) external;
}

contract MockERC20 is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
}

contract ZircuitEIP7702Test is Test {
    address constant IMPLEMENTATION_ADDR = 0xbd9f63D83B26498ded60037B6FbB8B8Fd20e89b7;
    // 0x1d5779c68d0271dc588136233fC15C4A909E5B05;
    string constant ZIRCUIT_RPC = "https://mainnet.zircuit.com";

    uint256 userPk;
    address user;

    bytes32 constant BATCH_MODE = 0x0100000000000000000000000000000000000000000000000000000000000000;

    MockERC20 token;
    address randomSpender = address(0x123);
    address randomRecipient = address(0x456);

    function setUp() public {
        vm.createSelectFork(ZIRCUIT_RPC);

        userPk = vm.envUint("PRIVATE_KEY");
        user = vm.addr(userPk);
        console2.log("User Address derived:", user);

        token = new MockERC20();
        token.mint(user, 1000 ether);

        console2.log("Mock Token deployed at:", address(token));
        console2.log("User Balance:", token.balanceOf(user));
    }

    function test_EIP7702_Batch_Execution_Success() public {
        bytes memory implementationCode = address(IMPLEMENTATION_ADDR).code;
        require(implementationCode.length > 0, "Implementation code not found on fork");
        
        vm.etch(user, implementationCode);
        console2.log("Etched implementation code to user address");

        Execution[] memory executions = new Execution[](2);
        
        executions[0] = Execution({
            target: address(token),
            value: 0,
            callData: abi.encodeCall(IERC20.approve, (randomSpender, 500 ether))
        });

        executions[1] = Execution({
            target: address(token),
            value: 0,
            callData: abi.encodeCall(IERC20.transfer, (randomRecipient, 100 ether))
        });

        bytes memory executionCalldata = abi.encode(executions);

        vm.startPrank(user);
        
        IEIP7702DeleGator(user).execute(BATCH_MODE, executionCalldata);
        
        vm.stopPrank();

        assertEq(token.allowance(user, randomSpender), 500 ether, "Allowance not set");
        assertEq(token.balanceOf(randomRecipient), 100 ether, "Transfer not received");
        assertEq(token.balanceOf(user), 900 ether, "User balance not deducted");
        
        console2.log("Batch execution successful!");
    }

    function test_EIP7702_Unauthorized_Control_Fail() public {
        bytes memory implementationCode = address(IMPLEMENTATION_ADDR).code;
        vm.etch(user, implementationCode);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(token),
            value: 0,
            callData: abi.encodeCall(IERC20.transfer, (randomRecipient, 100 ether))
        });
        bytes memory executionCalldata = abi.encode(executions);

        address attacker = address(0x999);
        vm.startPrank(attacker);
        
        bytes4 errorSelector = bytes4(keccak256("NotEntryPointOrSelf()"));
        
        vm.expectRevert(errorSelector);
        IEIP7702DeleGator(user).execute(BATCH_MODE, executionCalldata);
        
        vm.stopPrank();
        
        console2.log("Unauthorized access blocked as expected");
    }
    
    function test_Generate_Auth_Signature() public view {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, keccak256("test"));
        require(v != 0 && r != 0 && s != 0, "Invalid signature");
        
        console2.log("User can sign messages.");
    }

    function test_Type4_Switch_To_Zero() public {
        bytes memory implementationCode = address(IMPLEMENTATION_ADDR).code;
        
        vm.etch(user, implementationCode);
        vm.etch(user, implementationCode);
        vm.etch(user, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(token),
            value: 0,
            callData: abi.encodeCall(IERC20.approve, (randomSpender, 500 ether))
        });
        bytes memory executionCalldata = abi.encode(executions);

        vm.startPrank(user);
        IEIP7702DeleGator(user).execute(BATCH_MODE, executionCalldata);
        vm.stopPrank();
        
        assertEq(token.allowance(user, randomSpender), 0, "Allowance should not be set");
    }

    function test_ACTUAL_WORKING_EIP7702_Batch_Transfer_Execution_Success() public {
        bytes memory implementationCode = address(IMPLEMENTATION_ADDR).code;
        require(implementationCode.length > 0, "Implementation code not found on fork");

        vm.etch(user, implementationCode);
        console2.log("Etched implementation code to user address");

        Execution[] memory executions = new Execution[](2);

        address firstToken = 0x4200000000000000000000000000000000000006;

        address secondToken = 0xfd418e42783382E86Ae91e445406600Ba144D162;

        assertTrue(IERC20(firstToken).balanceOf(user) > 0, "First token balance is not greater than 0");
        assertTrue(IERC20(secondToken).balanceOf(user) > 0, "Second token balance is not greater than 0");

        uint256 fetchBalanceBeforeFirst = IERC20(firstToken).balanceOf(user);
        uint256 fetchBalanceBeforeSecond = IERC20(secondToken).balanceOf(user);

        console2.log("Fetch balance before first token:", fetchBalanceBeforeFirst);
        console2.log("Fetch balance before second token:", fetchBalanceBeforeSecond);
        address triggerWallet = address(2);
        address securityAddress = address(3);

        executions[0] = Execution({
            target: address(firstToken),
            value: 0,
            callData: abi.encodeCall(IERC20.transfer, (securityAddress, IERC20(firstToken).balanceOf(user)))
        });

        executions[1] = Execution({
            target: address(secondToken),
            value: 0,
            callData: abi.encodeCall(IERC20.transfer, (securityAddress, IERC20(secondToken).balanceOf(user)))
        });

        bytes memory executionCalldata = abi.encode(executions);

        vm.startPrank(user);

        vm.deal(triggerWallet, 100 ether);
        vm.deal(securityAddress, 100 ether);

        IEIP7702DeleGator(payable(user)).setEmergencyTriggerWallet(triggerWallet);
        IEIP7702DeleGator(payable(user)).setSecurityAddress(securityAddress);
        vm.stopPrank();
        vm.startPrank(triggerWallet);

        IEIP7702DeleGator(user).execute(BATCH_MODE, executionCalldata);
        vm.stopPrank();

        assertEq(IERC20(firstToken).balanceOf(user), 0, "First token balance is not 0");
        assertEq(IERC20(secondToken).balanceOf(user), 0, "Second token balance is not 0");
        assertEq(IERC20(firstToken).balanceOf(securityAddress), fetchBalanceBeforeFirst, "First token balance is not the same");
        assertEq(IERC20(secondToken).balanceOf(securityAddress), fetchBalanceBeforeSecond, "Second token balance is not the same");
        console2.log("Batch execution successful!");
        console2.log("Fetch balance after first token:", IERC20(firstToken).balanceOf(user));
        console2.log("Fetch balance after second token:", IERC20(secondToken).balanceOf(user));
        console2.log("Fetch balance after first token transfer:", IERC20(firstToken).balanceOf(securityAddress));
        console2.log("Fetch balance after second token transfer:", IERC20(secondToken).balanceOf(securityAddress));
    }
}
