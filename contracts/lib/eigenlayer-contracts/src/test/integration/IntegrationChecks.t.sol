// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "src/test/integration/IntegrationBase.t.sol";
import "src/test/integration/users/User.t.sol";
import "src/test/integration/users/User_M1.t.sol";
import "src/test/integration/users/User_M2.t.sol";

/// @notice Contract that provides utility functions to reuse common test blocks & checks
contract IntegrationCheckUtils is IntegrationBase {
    using ArrayLib for IStrategy[];
    using SlashingLib for *;

    /*******************************************************************************
                                 EIGENPOD CHECKS
    *******************************************************************************/

    function check_VerifyWC_State(
        User_M2 staker,
        uint40[] memory validators,
        uint64 beaconBalanceGwei
    ) internal {
        uint beaconBalanceWei = beaconBalanceGwei * GWEI_TO_WEI;
        assert_Snap_Added_Staker_DepositShares(staker, BEACONCHAIN_ETH_STRAT, beaconBalanceWei, "staker should have added deposit shares to beacon chain strat");
        assert_Snap_Added_ActiveValidatorCount(staker, validators.length, "staker should have increased active validator count");
        assert_Snap_Added_ActiveValidators(staker, validators, "validators should each be active");
    }

    function check_VerifyWC_State(
        User staker,
        uint40[] memory validators,
        uint64 beaconBalanceGwei
    ) internal {
        uint beaconBalanceWei = beaconBalanceGwei * GWEI_TO_WEI;
        assert_Snap_Added_Staker_DepositShares(staker, BEACONCHAIN_ETH_STRAT, beaconBalanceWei, "staker should have added deposit shares to beacon chain strat");
        assert_Snap_Added_ActiveValidatorCount(staker, validators.length, "staker should have increased active validator count");
        assert_Snap_Added_ActiveValidators(staker, validators, "validators should each be active");
    }

    function check_StartCheckpoint_State(
        User staker
    ) internal {
        assert_ProofsRemainingEqualsActive(staker, "checkpoint proofs remaining should equal active validator count");
        assert_Snap_Created_Checkpoint(staker, "staker should have created a new checkpoint");
    }

    function check_StartCheckpoint_WithPodBalance_State(
        User staker,
        uint64 expectedPodBalanceGwei
    ) internal {
        check_StartCheckpoint_State(staker);

        assert_CheckpointPodBalance(staker, expectedPodBalanceGwei, "checkpoint podBalanceGwei should equal expected");
    }

    function check_StartCheckpoint_NoValidators_State(
        User staker,
        uint64 sharesAddedGwei
    ) internal {
        assert_Snap_Added_Staker_DepositShares(staker, BEACONCHAIN_ETH_STRAT, sharesAddedGwei * GWEI_TO_WEI, "should have added staker shares");
        assert_Snap_Added_WithdrawableGwei(staker, sharesAddedGwei, "should have added to withdrawable restaked gwei");
        
        assert_Snap_Unchanged_ActiveValidatorCount(staker, "active validator count should remain 0");
        assert_Snap_Updated_LastCheckpoint(staker, "last checkpoint timestamp should have increased");
        assert_Snap_Unchanged_Checkpoint(staker, "current checkpoint timestamp should be unchanged");
    }

    function check_CompleteCheckpoint_State(
        User staker
    ) internal {
        assert_Snap_Removed_Checkpoint(staker, "should have deleted active checkpoint");
        assert_Snap_Updated_LastCheckpoint(staker, "last checkpoint timestamp should be updated");
        assert_Snap_Added_PodBalanceToWithdrawable(staker, "pod balance should have been added to withdrawable restaked exec layer gwei");
    }

    function check_CompleteCheckpoint_EarnOnBeacon_State(
        User staker,
        uint64 beaconBalanceAdded
    ) internal {
        check_CompleteCheckpoint_State(staker);

        uint balanceAddedWei = beaconBalanceAdded * GWEI_TO_WEI;
        assert_Snap_Added_Staker_DepositShares(staker, BEACONCHAIN_ETH_STRAT, balanceAddedWei, "should have increased shares by excess beacon balance");
    }

    function check_CompleteCheckpoint_WithPodBalance_State(
        User staker,
        uint64 expectedPodBalanceGwei
    ) internal {
        check_CompleteCheckpoint_State(staker);

        assert_Snap_Added_WithdrawableGwei(staker, expectedPodBalanceGwei, "should have added expected gwei to withdrawable restaked exec layer gwei");
    }

    function check_CompleteCheckpoint_WithSlashing_State(
        User staker,
        uint40[] memory slashedValidators,
        uint64 slashedAmountGwei
    ) internal {
        check_CompleteCheckpoint_State(staker);

        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have decreased");
        assert_Snap_Removed_StakerWithdrawableShares(staker, BEACONCHAIN_ETH_STRAT, slashedAmountGwei * GWEI_TO_WEI, "should have decreased withdrawable shares by slashed amount");
        assert_Snap_Removed_ActiveValidatorCount(staker, slashedValidators.length, "should have decreased active validator count");
        assert_Snap_Removed_ActiveValidators(staker, slashedValidators, "exited validators should each be WITHDRAWN");
    }

    function check_CompleteCheckpoint_WithSlashing_HandleRoundDown_State(
        User staker,
        uint40[] memory slashedValidators,
        uint64 slashedAmountGwei
    ) internal {
        check_CompleteCheckpoint_State(staker);

        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have decreased");
        assert_Snap_Removed_Staker_WithdrawableShares_AtLeast(staker, BEACONCHAIN_ETH_STRAT, slashedAmountGwei * GWEI_TO_WEI, "should have decreased withdrawable shares by at least slashed amount");
        assert_Snap_Removed_ActiveValidatorCount(staker, slashedValidators.length, "should have decreased active validator count");
        assert_Snap_Removed_ActiveValidators(staker, slashedValidators, "exited validators should each be WITHDRAWN");
    }

    function check_CompleteCheckpoint_WithCLSlashing_HandleRoundDown_State(
        User staker,
        uint64 slashedAmountGwei
    ) internal {
        check_CompleteCheckpoint_State(staker);

        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have decreased");
        assert_Snap_Removed_Staker_WithdrawableShares_AtLeast(staker, BEACONCHAIN_ETH_STRAT, slashedAmountGwei * GWEI_TO_WEI, "should have decreased withdrawable shares by at least slashed amount");
        assert_Snap_Unchanged_ActiveValidatorCount(staker, "should not have changed active validator count");
    }

    function check_CompleteCheckpoint_WithCLSlashing_State(
        User staker,
        uint64 slashedAmountGwei
    ) internal {
        check_CompleteCheckpoint_State(staker);

        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have decreased");
        assert_Snap_Removed_StakerWithdrawableShares(staker, BEACONCHAIN_ETH_STRAT, slashedAmountGwei * GWEI_TO_WEI, "should have decreased withdrawable shares by slashed amount");
        assert_Snap_Unchanged_ActiveValidatorCount(staker, "should not have changed active validator count");
    }

    function check_CompleteCheckpoint_WithExits_State(
        User staker,
        uint40[] memory exitedValidators,
        uint64 exitedBalanceGwei
    ) internal {
        check_CompleteCheckpoint_WithPodBalance_State(staker, exitedBalanceGwei);

        assert_Snap_Unchanged_StakerDepositShares(staker, "staker should not have changed shares");
        assert_Snap_Added_BalanceExitedGwei(staker, exitedBalanceGwei, "should have attributed expected gwei to exited balance");
        assert_Snap_Removed_ActiveValidatorCount(staker, exitedValidators.length, "should have decreased active validator count");
        assert_Snap_Removed_ActiveValidators(staker, exitedValidators, "exited validators should each be WITHDRAWN");
    }

    /*******************************************************************************
                              LST/DELEGATION CHECKS
    *******************************************************************************/

    function check_Deposit_State(
        User staker, 
        IStrategy[] memory strategies, 
        uint[] memory shares
    ) internal {
        /// Deposit into strategies:
        // For each of the assets held by the staker (either StrategyManager or EigenPodManager),
        // the staker calls the relevant deposit function, depositing all held assets.
        //
        // ... check that all underlying tokens were transferred to the correct destination
        //     and that the staker now has the expected amount of delegated shares in each strategy
        assert_HasNoUnderlyingTokenBalance(staker, strategies, "staker should have transferred all underlying tokens");
        assert_Snap_Added_Staker_DepositShares(staker, strategies, shares, "staker should expect shares in each strategy after depositing");
    }
    

    function check_Deposit_State_PartialDeposit(User staker, IStrategy[] memory strategies, uint[] memory shares, uint[] memory tokenBalances) internal {
        /// Deposit into strategies:
        // For each of the assets held by the staker (either StrategyManager or EigenPodManager),
        // the staker calls the relevant deposit function, depositing some subset of held assets
        //
        // ... check that some underlying tokens were transferred to the correct destination
        //     and that the staker now has the expected amount of delegated shares in each strategy
        assert_HasUnderlyingTokenBalances(staker, strategies, tokenBalances, "staker should have transferred some underlying tokens");
        assert_Snap_Added_Staker_DepositShares(staker, strategies, shares, "staker should expected shares in each strategy after depositing");
    }

    function check_Delegation_State(
        User staker, 
        User operator, 
        IStrategy[] memory strategies, 
        uint[] memory shares
    ) internal {
        /// Delegate to an operator:
        //
        // ... check that the staker is now delegated to the operator, and that the operator
        //     was awarded the staker shares
        assertTrue(delegationManager.isDelegated(address(staker)), "staker should be delegated");
        assertEq(address(operator), delegationManager.delegatedTo(address(staker)), "staker should be delegated to operator");
        assert_HasExpectedShares(staker, strategies, shares, "staker should still have expected shares after delegating");
        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should be unchanged after delegating");
        // TODO: fix this assertion
        // assert_Snap_Added_OperatorShares(operator, strategies, shares, "operator should have received shares");
    }

    function check_QueuedWithdrawal_State(
        User staker, 
        User operator, 
        IStrategy[] memory strategies, 
        uint[] memory shares, 
        IDelegationManagerTypes.Withdrawal[] memory withdrawals, 
        bytes32[] memory withdrawalRoots
    ) internal {
        // The staker will queue one or more withdrawals for the selected strategies and shares
        //
        // ... check that each withdrawal was successfully enqueued, that the returned roots
        //     match the hashes of each withdrawal, and that the staker and operator have
        //     reduced shares.
        assertEq(withdrawalRoots.length, 1, "check_QueuedWithdrawal_State: should only have 1 withdrawal root after queueing"); 
        assert_AllWithdrawalsPending(withdrawalRoots,
            "check_QueuedWithdrawal_State: staker withdrawals should now be pending");
        assert_ValidWithdrawalHashes(withdrawals, withdrawalRoots,
            "check_QueuedWithdrawal_State: calculated withdrawals should match returned roots");
        assert_Snap_Added_QueuedWithdrawals(staker, withdrawals,
            "check_QueuedWithdrawal_State: staker should have increased nonce by withdrawals.length");
        assert_Snap_Removed_OperatorShares(operator, strategies, shares,
            "check_QueuedWithdrawal_State: failed to remove operator shares");
        assert_Snap_Removed_StakerDepositShares(staker, strategies, shares,
            "check_QueuedWithdrawal_State: failed to remove staker shares");
    }

    function check_Undelegate_State(
        User staker, 
        User operator, 
        IDelegationManagerTypes.Withdrawal[] memory withdrawals,
        bytes32[] memory withdrawalRoots,
        IStrategy[] memory strategies,
        uint[] memory shares 
    ) internal {
        /// Undelegate from an operator
        //
        // ... check that the staker is undelegated, all strategies from which the staker is deposited are unqeuued,
        //     that the returned root matches the hashes for each strategy and share amounts, and that the staker
        //     and operator have reduced shares
        assertFalse(delegationManager.isDelegated(address(staker)),
            "check_Undelegate_State: staker should not be delegated");
        assert_ValidWithdrawalHashes(withdrawals, withdrawalRoots,
            "check_Undelegate_State: calculated withdrawl should match returned root");
        assert_AllWithdrawalsPending(withdrawalRoots,
            "check_Undelegate_State: stakers withdrawal should now be pending");
        assert_Snap_Added_QueuedWithdrawals(staker, withdrawals,
            "check_Undelegate_State: staker should have increased nonce by withdrawals.length");
        assert_Snap_Removed_OperatorShares(operator, strategies, shares,
            "check_Undelegate_State: failed to remove operator shares");
        assert_Snap_Removed_StakerDepositShares(staker, strategies, shares,
            "check_Undelegate_State: failed to remove staker shares");
    }

    /**
     * @notice Overloaded function to check the state after a withdrawal as tokens, accepting a non-user type for the operator.
     * @param staker The staker who completed the withdrawal.
     * @param operator The operator address, which can be a non-user type like address(0).
     * @param withdrawal The details of the withdrawal that was completed.
     * @param strategies The strategies from which the withdrawal was made.
     * @param shares The number of shares involved in the withdrawal.
     * @param tokens The tokens received after the withdrawal.
     * @param expectedTokens The expected tokens to be received after the withdrawal.
     */
    function check_Withdrawal_AsTokens_State(
        User staker,
        User operator,
        IDelegationManagerTypes.Withdrawal memory withdrawal,
        IStrategy[] memory strategies,
        uint[] memory shares,
        IERC20[] memory tokens,
        uint[] memory expectedTokens
    ) internal {
        // Common checks
        assert_WithdrawalNotPending(delegationManager.calculateWithdrawalRoot(withdrawal), "staker withdrawal should no longer be pending");
        
        assert_Snap_Added_TokenBalances(staker, tokens, expectedTokens, "staker should have received expected tokens");
        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have changed");
        assert_Snap_Removed_StrategyShares(strategies, shares, "strategies should have total shares decremented");

        // Checks specific to an operator that the Staker has delegated to
        if (operator != User(payable(0))) {
            if (operator != staker) {
                assert_Snap_Unchanged_TokenBalances(operator, "operator token balances should not have changed");
            }
            assert_Snap_Unchanged_OperatorShares(operator, "operator shares should not have changed");
        }
    }

    function check_Withdrawal_AsShares_State(
        User staker,
        User operator,
        IDelegationManagerTypes.Withdrawal memory withdrawal,
        IStrategy[] memory strategies,
        uint[] memory shares
    ) internal {
        // Common checks applicable to both user and non-user operator types
        assert_WithdrawalNotPending(delegationManager.calculateWithdrawalRoot(withdrawal), "staker withdrawal should no longer be pending");
        assert_Snap_Unchanged_TokenBalances(staker, "staker should not have any change in underlying token balances");
        assert_Snap_Added_Staker_DepositShares(staker, strategies, shares, "staker should have received expected shares");
        assert_Snap_Unchanged_StrategyShares(strategies, "strategies should have total shares unchanged");

        // Additional checks or handling for the non-user operator scenario
        if (operator != User(User(payable(0)))) {
            if (operator != staker) {
                assert_Snap_Unchanged_TokenBalances(operator, "operator should not have any change in underlying token balances");
            }
            assert_Snap_Added_OperatorShares(operator, withdrawal.strategies, withdrawal.scaledShares, "operator should have received shares");
        }
    }

    /// @notice Difference from above is that operator shares do not increase since staker is not delegated
    function check_Withdrawal_AsShares_Undelegated_State(
        User staker,
        User operator,
        IDelegationManagerTypes.Withdrawal memory withdrawal,
        IStrategy[] memory strategies,
        uint[] memory shares
    ) internal {
        /// Complete withdrawal(s):
        // The staker will complete the withdrawal as shares
        // 
        // ... check that the withdrawal is not pending, that the token balances of the staker and operator are unchanged,
        //     that the withdrawer received the expected shares, and that that the total shares of each o
        //     strategy withdrawn remains unchanged 
        assert_WithdrawalNotPending(delegationManager.calculateWithdrawalRoot(withdrawal), "staker withdrawal should no longer be pending");
        assert_Snap_Unchanged_TokenBalances(staker, "staker should not have any change in underlying token balances");
        assert_Snap_Unchanged_TokenBalances(operator, "operator should not have any change in underlying token balances");
        assert_Snap_Added_Staker_DepositShares(staker, strategies, shares, "staker should have received expected shares");
        assert_Snap_Unchanged_OperatorShares(operator, "operator should have shares unchanged");
        assert_Snap_Unchanged_StrategyShares(strategies, "strategies should have total shares unchanged");
    }

    /*******************************************************************************
                                 ALLOCATION MANAGER CHECKS
    *******************************************************************************/
    
    // TODO: improvement needed 

    function check_Withdrawal_AsTokens_State_AfterSlash(
        User staker,
        User operator,
        IDelegationManagerTypes.Withdrawal memory withdrawal,
        IAllocationManagerTypes.AllocateParams memory allocateParams,
        IAllocationManagerTypes.SlashingParams memory slashingParams,
        uint[] memory expectedTokens
    ) internal {
        IERC20[] memory tokens = new IERC20[](withdrawal.strategies.length);

        for (uint i; i < withdrawal.strategies.length; i++) {
            IStrategy strat = withdrawal.strategies[i];

            bool isBeaconChainETHStrategy = strat == beaconChainETHStrategy;

            tokens[i] = isBeaconChainETHStrategy ? NATIVE_ETH : withdrawal.strategies[i].underlyingToken();
            
            if (slashingParams.strategies.contains(strat)) {
                uint wadToSlash = slashingParams.wadsToSlash[slashingParams.strategies.indexOf(strat)];

                expectedTokens[i] -= expectedTokens[i]
                    .mulWadRoundUp(allocateParams.newMagnitudes[i].mulWadRoundUp(wadToSlash));

                uint256 max = allocationManager.getMaxMagnitude(address(operator), strat);

                withdrawal.scaledShares[i] -= withdrawal.scaledShares[i].calcSlashedAmount(WAD, max);

                // Round down to the nearest gwei for beaconchain ETH strategy.
                if (isBeaconChainETHStrategy) {
                    expectedTokens[i] -= expectedTokens[i] % 1 gwei;
                }
            }
        }

        // Common checks
        assert_WithdrawalNotPending(delegationManager.calculateWithdrawalRoot(withdrawal), "staker withdrawal should no longer be pending");
        
        // assert_Snap_Added_TokenBalances(staker, tokens, expectedTokens, "staker should have received expected tokens");
        assert_Snap_Unchanged_StakerDepositShares(staker, "staker shares should not have changed");
        assert_Snap_Removed_StrategyShares(withdrawal.strategies, withdrawal.scaledShares, "strategies should have total shares decremented");

        // Checks specific to an operator that the Staker has delegated to
        if (operator != User(payable(0))) {
            if (operator != staker) {
                assert_Snap_Unchanged_TokenBalances(operator, "operator token balances should not have changed");
            }
            assert_Snap_Unchanged_OperatorShares(operator, "operator shares should not have changed");
        }
    }

    function check_Withdrawal_AsShares_State_AfterSlash(
        User staker,
        User operator,
        IDelegationManagerTypes.Withdrawal memory withdrawal,
        IAllocationManagerTypes.AllocateParams memory allocateParams, // TODO - was this needed?
        IAllocationManagerTypes.SlashingParams memory slashingParams
    ) internal {
        IERC20[] memory tokens = new IERC20[](withdrawal.strategies.length);

        for (uint i; i < withdrawal.strategies.length; i++) {
            IStrategy strat = withdrawal.strategies[i];

            bool isBeaconChainETHStrategy = strat == beaconChainETHStrategy;

            tokens[i] = isBeaconChainETHStrategy ? NATIVE_ETH : withdrawal.strategies[i].underlyingToken();
            
            if (slashingParams.strategies.contains(strat)) {
                uint256 max = allocationManager.getMaxMagnitude(address(operator), strat);

                withdrawal.scaledShares[i] -= withdrawal.scaledShares[i].calcSlashedAmount(WAD, max);
            }
        }
        
        // Common checks applicable to both user and non-user operator types
        assert_WithdrawalNotPending(delegationManager.calculateWithdrawalRoot(withdrawal), "staker withdrawal should no longer be pending");
        assert_Snap_Unchanged_TokenBalances(staker, "staker should not have any change in underlying token balances");
        assert_Snap_Added_Staker_DepositShares(staker, withdrawal.strategies,  withdrawal.scaledShares, "staker should have received expected shares");
        assert_Snap_Unchanged_StrategyShares(withdrawal.strategies, "strategies should have total shares unchanged");

        // Additional checks or handling for the non-user operator scenario
        if (operator != User(User(payable(0)))) {
            if (operator != staker) {
                assert_Snap_Unchanged_TokenBalances(operator, "operator should not have any change in underlying token balances");
            }
        }
    }
}
