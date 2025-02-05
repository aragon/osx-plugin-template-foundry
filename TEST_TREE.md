# Test tree definitions

Below is the graphical definition of the contract tests implemented on [the test folder](./test)

```
LockManagerTest
├── Given Deploying the contract
│   ├── When Constructor has invalid unlock mode
│   │   └── It Should revert
│   ├── When Constructor has invalid plugin mode
│   │   └── It Should revert
│   └── When Constructor with valid params
│       ├── It Registers the DAO address
│       ├── It Stores the given settings
│       └── It Stores the given token addresses
├── When calling setPluginAddress
│   ├── Given Invalid plugin
│   │   └── It should revert
│   ├── Given Invalid plugin interface
│   │   └── It should revert
│   ├── When setPluginAddress the first time
│   │   ├── It should set the address
│   │   └── It should revert if trying to update it later
│   └── When setPluginAddress when already set
│       └── It should revert
├── Given No locked tokens
│   ├── Given No token allowance no locked
│   │   ├── When Calling lock 1
│   │   │   └── It Should revert
│   │   ├── When Calling lockAndApprove 1
│   │   │   └── It Should revert
│   │   ├── When Calling approve 1
│   │   │   └── It Should revert
│   │   ├── When Calling lockAndVote 1
│   │   │   └── It Should revert
│   │   └── When Calling vote 1
│   │       └── It Should revert
│   └── Given With token allowance no locked
│       ├── When Calling lock 2
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should approve with the full token balance
│       │   └── It Should emit an event
│       ├── When Calling lockAndApprove 2
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should approve with the full token balance
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       ├── When Calling approve 2
│       │   └── It Should revert
│       ├── When Calling lockAndVote 2
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should vote with the full token balance
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       └── When Calling vote 2
│           └── It Should revert
├── Given Locked tokens
│   ├── Given No token allowance some locked
│   │   ├── When Calling lock 3
│   │   │   └── It Should revert
│   │   ├── When Calling lockAndApprove 3
│   │   │   └── It Should revert
│   │   ├── When Calling approve same balance 3
│   │   │   └── It Should revert
│   │   ├── When Calling approve more locked balance 3
│   │   │   ├── It Should approve with the full token balance
│   │   │   └── It Should emit an event
│   │   ├── When Calling lockAndVote 3
│   │   │   └── It Should revert
│   │   ├── When Calling vote same balance 3
│   │   │   └── It Should revert
│   │   └── When Calling vote more locked balance 3
│   │       ├── It Should vote with the full token balance
│   │       └── It Should emit an event
│   └── Given With token allowance some locked
│       ├── When Calling lock 4
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should approve with the full token balance
│       │   ├── It Should increase the locked amount
│       │   └── It Should emit an event
│       ├── When Calling lockAndApprove no prior power 4
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should approve with the full token balance
│       │   ├── It Should increase the locked amount
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       ├── When Calling lockAndApprove with prior power 4
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should approve with the full token balance
│       │   ├── It Should increase the locked amount
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       ├── When Calling approve same balance 4
│       │   └── It Should revert
│       ├── When Calling approve more locked balance 4
│       │   ├── It Should approve with the full token balance
│       │   └── It Should emit an event
│       ├── When Calling lockAndVote no prior power 4
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should vote with the full token balance
│       │   ├── It Should increase the locked amount
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       ├── When Calling lockAndVote with prior power 4
│       │   ├── It Should allow any token holder to lock
│       │   ├── It Should vote with the full token balance
│       │   ├── It Should increase the locked amount
│       │   ├── It The allocated token balance should have the full new balance
│       │   └── It Should emit an event
│       ├── When Calling vote same balance 4
│       │   └── It Should revert
│       └── When Calling vote more locked balance 4
│           ├── It Should vote with the full token balance
│           └── It Should emit an event
├── Given Calling lock lockAndApprove or lockAndVote
│   ├── Given Empty plugin
│   │   └── It Locking and voting should revert
│   └── Given Invalid token
│       ├── It Locking should revert
│       ├── It Locking and voting should revert
│       └── It Voting should revert
├── Given ProposalCreated is called
│   ├── When The caller is not the plugin proposalCreated
│   │   └── It Should revert
│   └── When The caller is the plugin proposalCreated
│       └── It Adds the proposal ID to the list of known proposals
├── Given ProposalEnded is called
│   ├── When The caller is not the plugin ProposalEnded
│   │   └── It Should revert
│   └── When The caller is the plugin ProposalEnded
│       └── It Removes the proposal ID from the list of known proposals
├── Given Strict mode is set
│   ├── Given Didnt lock anything strict
│   │   └── When Trying to unlock 1 strict
│   │       └── It Should revert
│   ├── Given Locked but didnt approve anywhere strict
│   │   └── When Trying to unlock 2 approval strict
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but didnt vote anywhere strict
│   │   └── When Trying to unlock 2 voting strict
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but approved ended or executed proposals strict
│   │   └── When Trying to unlock 3 approved strict
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but voted on ended or executed proposals strict
│   │   └── When Trying to unlock 3 voted strict
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked and approved currently active proposals strict
│   │   └── When Trying to unlock 4 voted strict
│   │       └── It Should revert
│   └── Given Locked and voted on currently active proposals strict
│       └── When Trying to unlock 4 voted strict 2
│           └── It Should revert
├── Given Flexible mode is set
│   ├── Given Didnt lock anything flexible
│   │   └── When Trying to unlock 1 flexible
│   │       └── It Should revert
│   ├── Given Locked but didnt approve anywhere flexible
│   │   └── When Trying to unlock 2 approval flexible
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but didnt vote anywhere flexible
│   │   └── When Trying to unlock 2 voting flexible
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but approved on ended or executed proposals flexible
│   │   └── When Trying to unlock 3 approved flexible
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked but voted on ended or executed proposals flexible
│   │   └── When Trying to unlock 3 flexible
│   │       ├── It Should unlock and refund the full amount right away
│   │       └── It Should emit an event
│   ├── Given Locked and approved currently active proposals flexible
│   │   └── When Trying to unlock 4 approved flexible
│   │       ├── It Should deallocate the existing voting power from active proposals
│   │       ├── It Should unlock and refund the full amount
│   │       └── It Should emit an event
│   └── Given Locked and voted on currently active proposals flexible
│       └── When Trying to unlock 4 voted flexible
│           ├── It Should deallocate the existing voting power from active proposals
│           ├── It Should unlock and refund the full amount
│           └── It Should emit an event
├── When Calling plugin
│   └── It Should return the right address
├── When Calling token
│   └── It Should return the right address
├── Given No underlying token
│   └── When Calling underlyingToken empty
│       └── It Should return the token address
└── Given Underlying token defined
    └── When Calling underlyingToken set
        └── It Should return the right address
```

```
LockToApproveTest
├── When deploying the contract
│   ├── It should disable the initializers
│   └── It should initialize normally
├── Given a deployed contract
│   └── It should refuse to initialize again
├── Given a new proxy
│   └── Given calling initialize
│       ├── It should set the DAO address
│       ├── It should define the approval settings
│       ├── It should define the target config
│       ├── It should define the plugin metadata
│       └── It should define the lock manager
├── When calling updateSettings
│   ├── When updateSettings without the permission
│   │   └── It should revert
│   └── When updateSettings with the permission
│       └── It should update the values
├── When calling supportsInterface
│   ├── It does not support the empty interface
│   ├── It supports IERC165Upgradeable
│   ├── It supports IMembership
│   └── It supports ILockToApprove
├── Given Proposal not created
│   ├── Given No proposal creation permission
│   │   └── When Calling createProposal no perm
│   │       └── It Should revert
│   ├── Given Proposal creation permission granted
│   │   ├── When Calling createProposal empty dates
│   │   │   ├── It Should register the new proposal
│   │   │   ├── It Should assign a unique proposalId to it
│   │   │   ├── It Should register the given parameters
│   │   │   ├── It Should start immediately
│   │   │   ├── It Should end after proposalDuration
│   │   │   ├── It Should emit an event
│   │   │   └── It Should call proposalCreated on the manager
│   │   ├── When Calling createProposal explicit dates
│   │   │   ├── It Should start at the given startDate
│   │   │   ├── It Should revert if endDate is before proposalDuration
│   │   │   ├── It Should end on the given endDate
│   │   │   ├── It Should call proposalCreated on the manager
│   │   │   └── It Should emit an event
│   │   └── When Calling createProposal with duplicate data
│   │       ├── It Should revert
│   │       └── It Different data should produce different proposalId's
│   ├── When Calling the getters not created
│   │   ├── It getProposal should return empty values
│   │   ├── It isProposalOpen should return false
│   │   ├── It canApprove should return false
│   │   ├── It hasSucceeded should return false
│   │   └── It canExecute should return false
│   └── When Calling the rest of methods
│       └── It Should revert, even with the required permissions
├── Given Proposal created
│   ├── When Calling getProposal
│   │   └── It Should return the right values
│   ├── When Calling isProposalOpen
│   │   └── It Should return true
│   ├── When Calling canApprove
│   │   └── It Should return true when there is balance left to allocate
│   ├── Given No lock manager permission
│   │   ├── When Calling approve
│   │   │   └── It Reverts, regardless of the balance
│   │   └── When Calling clearApproval
│   │       └── It Reverts, regardless of the balance
│   ├── Given Lock manager permission is granted
│   │   ├── Given Proposal created unstarted
│   │   │   └── It Calling approve should revert, with or without balance
│   │   └── Given Proposal created and started
│   │       ├── When Calling approve no new locked balance
│   │       │   └── It Should revert
│   │       ├── When Calling approve new locked balance
│   │       │   ├── It Should increase the tally by the new amount
│   │       │   └── It Should emit an event
│   │       ├── When Calling clearApproval no approve balance
│   │       │   └── It Should do nothing
│   │       └── When Calling clearApproval with approve balance
│   │           ├── It Should unassign the current approver's approval
│   │           ├── It Should decrease the proposal tally by the right amount
│   │           ├── It Should emit an event
│   │           └── It usedVotingPower should return the right value
│   ├── When Calling hasSucceeded canExecute created
│   │   ├── It hasSucceeded should return false
│   │   └── It canExecute should return false
│   └── When Calling execute created
│       └── It Should revert, even with the required permission
├── Given Proposal defeated
│   ├── When Calling the getters defeated
│   │   ├── It getProposal should return the right values
│   │   ├── It isProposalOpen should return false
│   │   ├── It canApprove should return false
│   │   ├── It hasSucceeded should return false
│   │   └── It canExecute should return false
│   ├── When Calling approve or clearApproval defeated
│   │   ├── It Should revert for approve, despite having the permission
│   │   └── It Should do nothing for clearApproval
│   └── When Calling execute defeated
│       └── It Should revert, with or without permission
├── Given Proposal passed
│   ├── When Calling the getters passed
│   │   ├── It getProposal should return the right values
│   │   ├── It isProposalOpen should return false
│   │   ├── It canApprove should return false
│   │   ├── It hasSucceeded should return true
│   │   └── It canExecute should return true
│   ├── When Calling approve or clearApproval passed
│   │   └── It Should revert, despite having the permission
│   ├── Given No execute proposal permission
│   │   └── When Calling execute no perm
│   │       └── It Should revert
│   └── Given Execute proposal permission
│       └── When Calling execute passed
│           ├── It Should execute the actions of the proposal on the target
│           ├── It Should call proposalEnded on the LockManager
│           └── It Should emit an event
├── Given Proposal executed
│   ├── When Calling the getters executed
│   │   ├── It getProposal should return the right values
│   │   ├── It isProposalOpen should return false
│   │   ├── It canApprove should return false
│   │   ├── It hasSucceeded should return false
│   │   └── It canExecute should return false
│   ├── When Calling approve or clearApproval executed
│   │   └── It Should revert, despite having the permission
│   └── When Calling execute executed
│       └── It Should revert regardless of the permission
├── When Underlying token is not defined
│   └── It Should use the lockable token's balance to compute the approval ratio
├── When Underlying token is defined
│   └── It Should use the underlying token's balance to compute the approval ratio
├── When Calling isMember
│   ├── It Should return true when the sender has positive balance or locked tokens
│   └── It Should return false otherwise
├── When Calling customProposalParamsABI
│   └── It Should return the right value
├── Given Update approval settings permission granted
│   └── When Calling updatePluginSettings granted
│       ├── It Should set the new values
│       └── It Settings() should return the right values
└── Given No update approval settings permission
    └── When Calling updatePluginSettings not granted
        └── It Should revert
```

```
LockToApprovePluginSetupTest
├── When deploying a new instance
│   └── It completes without errors
├── When preparing an installation
│   ├── When passing an invalid token contract
│   │   └── It should revert
│   ├── It should return the plugin address
│   ├── It should return a list with the 3 helpers
│   ├── It all plugins use the same implementation
│   ├── It the plugin has the given settings
│   ├── It should set the address of the lockManager on the plugin
│   ├── It the plugin should have the right lockManager address
│   └── It the list of permissions should match
└── When preparing an uninstallation
    ├── Given a list of helpers with more or less than 3
    │   └── It should revert
    └── It generates a correct list of permission changes
```

```
LockToVoteTest
├── When deploying the contract
│   ├── It should disable the initializers
│   └── It should initialize normally
├── Given a deployed contract
│   └── It should refuse to initialize again
├── Given a new proxy
│   └── Given calling initialize
│       ├── It should set the DAO address
│       ├── It should define the voting settings
│       ├── It should define the target config
│       ├── It should define the plugin metadata
│       └── It should define the lock manager
├── When calling updateVotingSettings
│   ├── Given the caller has permission to call updateVotingSettings
│   │   ├── It Should set the new values
│   │   └── It Settings() should return the right values
│   └── Given the caller has no permission to call updateVotingSettings
│       └── It Should revert
├── When calling supportsInterface
│   ├── It does not support the empty interface
│   ├── It supports IERC165Upgradeable
│   ├── It supports IMembership
│   └── It supports ILockToVote
├── When calling createProposal
│   ├── Given create permission
│   │   ├── Given no minimum voting power
│   │   │   └── Given valid parameters
│   │   │       ├── It sets the given failuremap, if any
│   │   │       ├── It proposalIds are predictable and reproducible
│   │   │       ├── It sets the given voting mode, target, params and actions
│   │   │       ├── It emits an event
│   │   │       └── It reports proposalCreated() on the lockManager
│   │   ├── Given minimum voting power above zero
│   │   │   ├── It should succeed when the creator has enough balance
│   │   │   └── It should revert otherwise
│   │   ├── Given invalid dates
│   │   │   └── It should revert
│   │   └── Given duplicate proposal ID
│   │       └── It should revert
│   └── Given no create permission
│       └── It should revert
├── When calling canVote
│   ├── Given the proposal is open
│   │   ├── Given non empty vote
│   │   │   ├── Given submitting the first vote
│   │   │   │   ├── It should return true when the voter locked balance is positive
│   │   │   │   ├── It should return false when the voter has no locked balance
│   │   │   │   └── It should happen in all voting modes
│   │   │   └── Given voting again
│   │   │       ├── Given standard voting mode
│   │   │       │   ├── It should return true when voting the same with more balance
│   │   │       │   └── It should return false otherwise
│   │   │       ├── Given vote replacement mode
│   │   │       │   ├── It should return true when the locked balance is higher
│   │   │       │   └── It should return false otherwise
│   │   │       └── Given early execution mode
│   │   │           └── It should return false
│   │   └── Given empty vote
│   │       └── It should return false
│   ├── Given the proposal ended
│   │   ├── It should return false, regardless of prior votes
│   │   ├── It should return false, regardless of the locked balance
│   │   └── It should return false, regardless of the voting mode
│   └── Given the proposal is not created
│       └── It should revert
├── When calling vote
│   ├── Given canVote returns false // This relies on the tests above for canVote()
│   │   └── It should revert
│   ├── Given standard voting mode 2
│   │   ├── Given Voting the first time
│   │   │   ├── Given Has locked balance
│   │   │   │   ├── It should set the right voter's usedVotingPower
│   │   │   │   ├── It should set the right tally of the voted option
│   │   │   │   ├── It should set the right total voting power
│   │   │   │   └── It should emit an event
│   │   │   └── Given No locked balance // Redundant with canVote being false
│   │   │       └── It should revert
│   │   ├── Given Voting the same option
│   │   │   ├── Given Voting with the same locked balance // Redundant with canVote being false
│   │   │   │   └── It should revert
│   │   │   └── Given Voting with more locked balance
│   │   │       ├── It should increase the voter's usedVotingPower
│   │   │       ├── It should increase the tally of the voted option
│   │   │       ├── It should increase the total voting power
│   │   │       └── It should emit an event
│   │   └── Given Voting another option // Redundant with canVote being false
│   │       ├── Given Voting with the same locked balance 2
│   │       │   └── It should revert
│   │       └── Given Voting with more locked balance 2
│   │           └── It should revert
│   ├── Given vote replacement mode 2
│   │   ├── Given Voting the first time 2
│   │   │   ├── Given Has locked balance 2
│   │   │   │   ├── It should set the right voter's usedVotingPower
│   │   │   │   ├── It should set the right tally of the voted option
│   │   │   │   ├── It should set the right total voting power
│   │   │   │   └── It should emit an event
│   │   │   └── Given No locked balance 2 // Redundant with canVote being false
│   │   │       └── It should revert
│   │   ├── Given Voting the same option 2
│   │   │   ├── Given Voting with the same locked balance 3 // Redundant with canVote being false
│   │   │   │   └── It should revert
│   │   │   └── Given Voting with more locked balance 3
│   │   │       ├── It should increase the voter's usedVotingPower
│   │   │       ├── It should increase the tally of the voted option
│   │   │       ├── It should increase the total voting power
│   │   │       └── It should emit an event
│   │   └── Given Voting another option 2
│   │       ├── Given Voting with the same locked balance 4
│   │       │   ├── It should deallocate the current voting power
│   │       │   └── It should allocate that voting power into the new vote option
│   │       └── Given Voting with more locked balance 4
│   │           ├── It should deallocate the current voting power
│   │           ├── It the voter's usedVotingPower should reflect the new balance
│   │           ├── It should allocate to the tally of the voted option
│   │           ├── It should update the total voting power
│   │           └── It should emit an event
│   └── Given early execution mode 2
│       ├── Given Voting the first time 3
│       │   ├── Given Has locked balance 3
│       │   │   ├── It should set the right voter's usedVotingPower
│       │   │   ├── It should set the right tally of the voted option
│       │   │   ├── It should set the right total voting power
│       │   │   └── It should emit an event
│       │   └── Given No locked balance 3 // Redundant with canVote being false
│       │       └── It should revert
│       ├── Given Voting the same option 3
│       │   ├── Given Voting with the same locked balance 5
│       │   │   └── It should revert
│       │   └── Given Voting with more locked balance 5
│       │       ├── It should increase the voter's usedVotingPower
│       │       ├── It should increase the tally of the voted option
│       │       ├── It should increase the total voting power
│       │       └── It should emit an event
│       ├── Given Voting another option 3
│       │   ├── Given Voting with the same locked balance 6
│       │   │   └── It should revert
│       │   └── Given Voting with more locked balance 6
│       │       └── It should revert
│       └── Given the vote makes the proposal pass // partially redundant with canExecute() below
│           └── Given the caller has permission to call execute
│               ├── It hasSucceeded() should return true
│               ├── It canExecute() should return true
│               ├── It isSupportThresholdReachedEarly() should return true
│               ├── It isMinVotingPowerReached() should return true
│               ├── It isMinApprovalReached() should return true
│               ├── It should execute the proposal
│               ├── It the proposal should be marked as executed
│               └── It should emit an event
├── When calling clearvote
│   ├── Given the voter has no prior voting power
│   │   └── It should do nothing
│   ├── Given the proposal is not open
│   │   └── It should revert
│   ├── Given early execution mode 3
│   │   └── It should revert
│   ├── Given standard voting mode 3
│   │   ├── It should deallocate the current voting power
│   │   └── It should allocate that voting power into the new vote option
│   └── Given vote replacement mode 3
│       ├── It should deallocate the current voting power
│       └── It should allocate that voting power into the new vote option
├── When calling getVote
│   ├── Given the vote exists
│   │   └── It should return the right data
│   └── Given the vote does not exist
│       └── It should return empty values
├── When Calling the proposal getters
│   ├── Given it does not exist
│   │   ├── It getProposal() returns empty values
│   │   ├── It isProposalOpen() returns false
│   │   ├── It hasSucceeded() should return false
│   │   ├── It canExecute() should return false
│   │   ├── It isSupportThresholdReachedEarly() should return false
│   │   ├── It isSupportThresholdReached() should return false
│   │   ├── It isMinVotingPowerReached() should return false
│   │   ├── It isMinApprovalReached() should return false
│   │   └── It usedVotingPower() should return 0 for all voters
│   ├── Given it has not started
│   │   ├── It getProposal() returns the right values
│   │   ├── It isProposalOpen() returns false
│   │   ├── It hasSucceeded() should return false
│   │   ├── It canExecute() should return false
│   │   ├── It isSupportThresholdReachedEarly() should return false
│   │   ├── It isSupportThresholdReached() should return false
│   │   ├── It isMinVotingPowerReached() should return false
│   │   ├── It isMinApprovalReached() should return false
│   │   └── It usedVotingPower() should return 0 for all voters
│   ├── Given it has not passed yet
│   │   ├── It getProposal() returns the right values
│   │   ├── It isProposalOpen() returns true
│   │   ├── It hasSucceeded() should return false
│   │   ├── It canExecute() should return false
│   │   ├── It isSupportThresholdReachedEarly() should return false
│   │   ├── It isSupportThresholdReached() should return false
│   │   ├── It isMinVotingPowerReached() should return false
│   │   ├── It isMinApprovalReached() should return false
│   │   └── It usedVotingPower() should return the appropriate values
│   ├── Given it did not pass after endDate
│   │   ├── It getProposal() returns the right values
│   │   ├── It isProposalOpen() returns false
│   │   ├── It hasSucceeded() should return false
│   │   ├── It canExecute() should return false
│   │   ├── It isSupportThresholdReachedEarly() should return false
│   │   ├── Given the support threshold was not achieved
│   │   │   └── It isSupportThresholdReached() should return false
│   │   ├── Given the support threshold was achieved
│   │   │   └── It isSupportThresholdReached() should return true
│   │   ├── Given the minimum voting power was not reached
│   │   │   └── It isMinVotingPowerReached() should return false
│   │   ├── Given the minimum voting power was reached
│   │   │   └── It isMinVotingPowerReached() should return true
│   │   ├── Given the minimum approval tally was not achieved
│   │   │   └── It isMinApprovalReached() should return false
│   │   ├── Given the minimum approval tally was achieved
│   │   │   └── It isMinApprovalReached() should return true
│   │   └── It usedVotingPower() should return the appropriate values
│   ├── Given it has passed after endDate
│   │   ├── It getProposal() returns the right values
│   │   ├── It isProposalOpen() returns false
│   │   ├── It hasSucceeded() should return false
│   │   ├── Given The proposal has not been executed
│   │   │   └── It canExecute() should return true
│   │   ├── Given The proposal has been executed
│   │   │   └── It canExecute() should return false
│   │   ├── It isSupportThresholdReachedEarly() should return false
│   │   ├── It isSupportThresholdReached() should return true
│   │   ├── It isMinVotingPowerReached() should return true
│   │   ├── It isMinApprovalReached() should return true
│   │   └── It usedVotingPower() should return the appropriate values
│   └── Given it has passed early
│       ├── It getProposal() returns the right values
│       ├── It isProposalOpen() returns false
│       ├── It hasSucceeded() should return false
│       ├── Given The proposal has not been executed 2
│       │   └── It canExecute() should return true
│       ├── Given The proposal has been executed 2
│       │   └── It canExecute() should return false
│       ├── It isSupportThresholdReachedEarly() should return true
│       ├── It isSupportThresholdReached() should return true
│       ├── It isMinVotingPowerReached() should return true
│       ├── It isMinApprovalReached() should return true
│       └── It usedVotingPower() should return the appropriate values
├── When calling canExecute and hasSucceeded
│   ├── Given the proposal exists
│   │   ├── Given the proposal is not executed
│   │   │   ├── Given minVotingPower is reached
│   │   │   │   ├── Given minApproval is reached
│   │   │   │   │   ├── Given isSupportThresholdReachedEarly was reached before endDate
│   │   │   │   │   │   ├── Given the proposal allows early execution
│   │   │   │   │   │   │   ├── It canExecute() should return true
│   │   │   │   │   │   │   └── It hasSucceeded() should return true
│   │   │   │   │   │   └── Given the proposal does not allow early execution
│   │   │   │   │   │       ├── It canExecute() should return false
│   │   │   │   │   │       └── It hasSucceeded() should return false
│   │   │   │   │   ├── Given isSupportThresholdReached is reached
│   │   │   │   │   │   ├── It canExecute() should return false before endDate
│   │   │   │   │   │   ├── It hasSucceeded() should return false before endDate
│   │   │   │   │   │   ├── It canExecute() should return true after endDate
│   │   │   │   │   │   └── It hasSucceeded() should return true after endDate
│   │   │   │   │   └── Given isSupportThresholdReached is not reached
│   │   │   │   │       ├── It canExecute() should return false
│   │   │   │   │       └── It hasSucceeded() should return false
│   │   │   │   └── Given minApproval is not reached
│   │   │   │       ├── It canExecute() should return false
│   │   │   │       └── It hasSucceeded() should return false
│   │   │   └── Given minVotingPower is not reached
│   │   │       ├── It canExecute() should return false
│   │   │       └── It hasSucceeded() should return false
│   │   └── Given the proposal is executed
│   │       ├── It canExecute() should return false
│   │       └── It hasSucceeded() should return true
│   └── Given the proposal does not exist
│       ├── It canExecute() should revert
│       └── It hasSucceeded() should revert
├── When calling execute
│   ├── Given the caller no permission to call execute
│   │   └── It should revert
│   └── Given the caller has permission to call execute 2
│       ├── Given canExecute returns false // This relies on the tests above for canExecute()
│       │   └── It should revert
│       └── Given canExecute returns true
│           ├── It should mark the proposal as executed
│           ├── It should make the target execute the proposal actions
│           ├── It should emit an event
│           └── It should call proposalEnded on the LockManager
├── When Calling isMember
│   ├── It Should return true when the sender has positive balance or locked tokens
│   └── It Should return false otherwise
├── When Calling customProposalParamsABI
│   └── It Should return the right value
├── When Calling currentTokenSupply
│   └── It Should return the right value
├── When Calling supportThresholdRatio
│   └── It Should return the right value
├── When Calling minParticipationRatio
│   └── It Should return the right value
├── When Calling proposalDuration
│   └── It Should return the right value
├── When Calling minProposerVotingPower
│   └── It Should return the right value
├── When Calling minApprovalRatio
│   └── It Should return the right value
├── When Calling votingMode
│   └── It Should return the right value
├── When Calling currentTokenSupply 2
│   └── It Should return the right value
├── When Calling lockManager
│   └── It Should return the right address
├── When Calling token
│   └── It Should return the right address
└── When Calling underlyingToken
    ├── Given Underlying token is not defined
    │   └── It Should use the (lockable) token's balance to compute the approval ratio
    └── Given Underlying token is defined
        └── It Should use the underlying token's balance to compute the approval ratio
```

```
LockToVotePluginSetupTest
├── When deploying a new instance
│   └── It completes without errors
├── When preparing an installation
│   ├── When passing an invalid token contract
│   │   └── It should revert
│   ├── It should return the plugin address
│   ├── It should return a list with the 3 helpers
│   ├── It all plugins use the same implementation
│   ├── It the plugin has the given settings
│   ├── It should set the address of the lockManager on the plugin
│   ├── It the plugin should have the right lockManager address
│   └── It the list of permissions should match
└── When preparing an uninstallation
    ├── Given a list of helpers with more or less than 3
    │   └── It should revert
    └── It generates a correct list of permission changes
```

```
MinVotingPowerConditionTest
├── When deploying the contract
│   ├── It records the given plugin address
│   └── It records the plugin's token address
└── When calling isGranted
    ├── Given a plugin with zero minimum voting power
    │   └── It should return true
    └── Given a plugin with a minimum voting power
        ├── It should return true when 'who' holds the minimum voting power
        └── It should return false when 'who' holds less than the minimum voting power
```

