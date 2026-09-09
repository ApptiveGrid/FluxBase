Class {
	#name : 'FBAndJoinBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testCompletingActivationValueIsADictionaryOfSourceNodeToValue [
	| start split a b join end flow instance completingActivation joinValue |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	completingActivation := (instance activations select: [ :act | act node = join ]) last.
	joinValue := completingActivation value.
	self assert: (joinValue at: a) equals: 6.
	self assert: (joinValue at: b) equals: 50
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testDoesNotProceedUntilAllBranchesHaveArrived [
	| start split a b join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initializeExecutor.
	instance step. "start"
	instance step. "split"
	instance step. "a arrives at join"
	self deny: (instance activations anySatisfy: [ :act | act node = end ])
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testDuplicateArrivalOnTheSameBranchIsNotCountedTwice [
	| start split a b join end flow instance realActivationForA duplicate1 duplicate2 joinState splitIdUsed |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initializeExecutor.
	instance step. "start"
	instance step. "split"
	instance step. "a itself runs (not yet at join)"
	realActivationForA := instance activationOfNode: a.
	splitIdUsed := realActivationForA token splitId.
	duplicate1 := FBActivation new executor: instance executor; node: join; argument: 10; yourself.
	duplicate1 token splitId: splitIdUsed; parent: realActivationForA token.
	duplicate2 := FBActivation new executor: instance executor; node: join; argument: 20; yourself.
	duplicate2 token splitId: splitIdUsed; parent: realActivationForA token.
	(join defaultBehaviorClass new activation: duplicate1; yourself) execute.
	(join defaultBehaviorClass new activation: duplicate2; yourself) execute.
	joinState := instance joinStateFor: join splitId: splitIdUsed.
	"both arrivals carry the same parent token, so they are the same branch and
	FBJoinBehavior>>arrivalKey answers the same key for both"
	self assert: joinState arrived size equals: 1.
	self assert: joinState arrived values asArray equals: #( 20 ) "second delivery overwrites, still one entry"
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testWaitsForAllBranchesBeforeFollowingOutgoing [
	| start split a b join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 2
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testWorksWithThreeBranches [
	| start split a b c join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	c := FBTask named: 'c'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	split --> c --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 3
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testJoinReleasesOnlyOnceWhenAFurtherArrivalStillSatisfiesExpected [
	"Two branches of one split reach the join through the same predecessor 'a', so both
	arrivals key onto the same #arrived entry and the second one still finds #expected
	satisfied. Without the FBJoinState>>released latch the join fires for both and
	everything behind it runs twice.

	The join state is picked up by identity from behind the join while the instance
	still runs - a finished instance holds none (FBFlowInstance>>ended)"
	| start split a b join probe end flow instance joinState |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	probe := (FBPluggableTask named: 'probe') block: [ :act |
		joinState := act flowInstance joinStateFor: join splitId: act token splitId.
		act value: act argument ].
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> a.
	join --> probe --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	"the join is entered twice - once per branch - but must release only once"
	self assert: (instance activations select: [ :each | each node = join ]) size equals: 2.
	self assert: (instance activations select: [ :each | each node = end ]) size equals: 1.
	self assert: joinState released
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testAFinishedInstanceKeepsNoJoinState [
	"a pass through a split leaves an FBJoinState and a branch count behind, and the
	join cannot drop them itself - it cannot tell whether a further arrival may still
	come, which is what the release latch is for. They fall at the end of the instance
	instead, FBFlowInstance>>ended, once nothing runs and nothing can arrive. Measured on
	both sides of the end: the node behind the join still sees the state, the finished
	instance holds none"
	| start split a b join after end flow instance seen |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	"the branch count is registered by hand here, the way FBMultiChoiceGatewayBehavior does
	it for its split - an FBAndSplit registers none - so that the second kind of per-split
	bookkeeping is measured as well"
	after := (FBPluggableTask named: 'after') block: [ :act |
		act flowInstance registerExpectedBranchCount: 2 forSplitId: act token splitId.
		seen add: (act flowInstance instVarNamed: 'joinStates') size.
		seen add: (act flowInstance instVarNamed: 'splitBranchCounts') size.
		act value: act argument ].
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> after --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.

	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	"one split execution, one state and one count - there while the instance still ran"
	self assert: seen asArray equals: #( 1 1 ).
	"and gone with the end"
	self assert: (instance instVarNamed: 'joinStates') isNil.
	self assert: (instance instVarNamed: 'splitBranchCounts') isNil
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testArrivalsThroughTheSamePredecessorAreCountedSeparately [
	"Two branches of one split reach the join through the same predecessor 'a' - one
	directly, the other after passing 'b'. Keyed by source node both would collapse
	onto one #arrived entry; keyed by the token they came through they stay countable.

	The join state is picked up by identity from behind the join while the instance
	still runs - a finished instance holds none (FBFlowInstance>>ended). The second
	arrival still lands on that same object, so it is counted here after the run"
	| start split a b join probe end flow instance joinState |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	probe := (FBPluggableTask named: 'probe') block: [ :act |
		joinState := act flowInstance joinStateFor: join splitId: act token splitId.
		act value: act argument ].
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> a.
	join --> probe --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	self assert: joinState arrived size equals: 2
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testJoinReleasesWhenBranchesSharingAPredecessorSatisfyARegisteredCount [
	"the shape a converted FBExclusiveGateway produces: the split registers how many
	branches it started, so #expected is that count rather than the join's incoming
	transitions. Both branches arriving through the same predecessor used to collapse
	onto one #arrived entry, the count was never reached, and the join never released -
	while the instance still reported itself done."
	| start split a b join end flow instance splitId joinState parents |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initializeExecutor.
	splitId := 'split-run'.
	instance registerExpectedBranchCount: 2 forSplitId: splitId.
	"two arrivals through the same predecessor 'a', on distinct branch tokens"
	parents := (1 to: 2) collect: [ :each |
		(FBActivation new executor: instance executor; node: a; yourself) token ].
	parents doWithIndex: [ :parentToken :i |
		| arrival |
		arrival := FBActivation new
			executor: instance executor;
			node: join;
			argument: i * 10;
			yourself.
		arrival token splitId: splitId; parent: parentToken.
		(join defaultBehaviorClass new activation: arrival; yourself) execute ].
	joinState := instance joinStateFor: join splitId: splitId.
	self assert: joinState arrived size equals: 2.
	self assert: joinState released
]
