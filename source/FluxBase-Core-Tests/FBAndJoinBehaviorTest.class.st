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
	| start split a b join end flow instance realActivationForA duplicate1 duplicate2 joinState passUsed |
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
	passUsed := realActivationForA token split.
	duplicate1 := FBActivation new executor: instance executor; node: join; argument: 10; yourself.
	duplicate1 token split: passUsed; parent: realActivationForA token.
	duplicate2 := FBActivation new executor: instance executor; node: join; argument: 20; yourself.
	duplicate2 token split: passUsed; parent: realActivationForA token.
	(join defaultBehaviorClass new activation: duplicate1; yourself) execute.
	(join defaultBehaviorClass new activation: duplicate2; yourself) execute.
	joinState := instance joinStateFor: join split: passUsed.
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
	"Two branches of one split reach the join through the same predecessor 'a'. The
	pass started two branches, so the join waits for both arrivals and releases on the
	second - and only then: without the FBJoinState>>released latch a join whose
	#expected is met by a further arrival fires again, and everything behind it runs
	twice. That shape is still reachable, for arrivals on tokens persisted before splits
	were objects, whose #expected is the join's incoming transitions.

	The join state is picked up by identity from behind the join while the instance
	still runs - a finished instance holds none (FBFlowInstance>>ended); the pass is
	read off a branch, since behind the join the token carries the enclosing one"
	| start split a b join probe end flow instance joinState |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	probe := (FBPluggableTask named: 'probe') block: [ :act |
		joinState := act flowInstance joinStateFor: join split: (act flowInstance activationOfNode: a) token split.
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
	"a pass through a split leaves an FBJoinState behind, and the join cannot drop it
	itself - it cannot tell whether a further arrival may still come, which is what the
	release latch is for. It falls at the end of the instance instead,
	FBFlowInstance>>ended, once nothing runs and nothing can arrive. Measured on both
	sides of the end: the node behind the join still sees the state, the finished
	instance holds none"
	| start split a b join after end flow instance seen |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	after := (FBPluggableTask named: 'after') block: [ :act |
		seen add: (act flowInstance instVarNamed: 'joinStates') size.
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
	"one split execution, one state - there while the instance still ran"
	self assert: seen asArray equals: #( 1 ).
	"and gone with the end"
	self assert: (instance instVarNamed: 'joinStates') isNil
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
		joinState := act flowInstance joinStateFor: join split: (act flowInstance activationOfNode: a) token split.
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
FBAndJoinBehaviorTest >> testTheJoinWaitsForAsManyBranchesAsThePassStarted [
	"what the join waits for is what the split started (FBSplitExecution>>branchCount),
	not how many transitions lead into the join. Two arrivals through the same
	predecessor 'a' on distinct branch tokens are the two branches of a pass with two;
	keyed by node they used to collapse onto one #arrived entry, the count was never
	reached, and the join never released - while the instance still reported itself done"
	| start split a b join end flow instance pass joinState parents |
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
	pass := FBSplitExecution new branchCount: 2; yourself.
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
		arrival token split: pass; parent: parentToken.
		(join defaultBehaviorClass new activation: arrival; yourself) execute ].
	joinState := instance joinStateFor: join split: pass.
	self assert: joinState arrived size equals: 2.
	self assert: joinState released
]

{ #category : 'tests' }
FBAndJoinBehaviorTest >> testNestedSplitsJoinInsideThenOutside [
	"a split inside a branch of another split: the inner join completes the inner pass,
	and the outer join then sees that branch arrive next to its sibling and completes
	too. Used to end the instance #done with the outer join never released - behind the
	inner join the tokens still carried the inner split, so the outer join kept its two
	arrivals under two keys, one pass each, and nothing behind it ever ran"
	| start outer inner a1 a2 innerJoin b outerJoin after end flow instance ran |
	ran := 0.
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBAndSplit named: 'outer').
	inner := outer addOutgoingNode: (FBAndSplit named: 'inner').
	a1 := inner addOutgoingNode: (FBTask named: 'a1').
	a2 := inner addOutgoingNode: (FBTask named: 'a2').
	innerJoin := FBAndJoin named: 'inner join'.
	a1 --> innerJoin.
	a2 --> innerJoin.
	b := outer addOutgoingNode: (FBTask named: 'b').
	outerJoin := FBAndJoin named: 'outer join'.
	innerJoin --> outerJoin.
	b --> outerJoin.
	after := (FBPluggableTask named: 'after') block: [ :act | ran := ran + 1. act value: act argument ].
	outerJoin --> after.
	end := after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: ran equals: 1.
	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :act | act node = innerJoin ]) size equals: 2.
	self assert: (instance activations select: [ :act | act node = outerJoin ]) size equals: 2.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1
]

{ #category : 'tests' }
FBAndJoinBehaviorTest >> testAJoinHandsItsOutgoingTokensTheEnclosingPassBack [
	"behind a join the strand is a branch of the enclosing pass again, not of the one
	just joined - and of none at the outermost level. The passes nest the way the
	splits ran: the inner pass's #outer is the outer pass"
	| start outer inner a1 a2 innerJoin behindInner b outerJoin after flow instance outerPass |
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBAndSplit named: 'outer').
	inner := outer addOutgoingNode: (FBAndSplit named: 'inner').
	a1 := inner addOutgoingNode: (FBTask named: 'a1').
	a2 := inner addOutgoingNode: (FBTask named: 'a2').
	innerJoin := FBAndJoin named: 'inner join'.
	a1 --> innerJoin.
	a2 --> innerJoin.
	behindInner := innerJoin addOutgoingNode: (FBTask named: 'behind inner').
	b := outer addOutgoingNode: (FBTask named: 'b').
	outerJoin := FBAndJoin named: 'outer join'.
	behindInner --> outerJoin.
	b --> outerJoin.
	after := outerJoin addOutgoingNode: (FBTask named: 'after').
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	outerPass := (instance activationOfNode: b) token split.
	self assert: outerPass node identicalTo: outer.
	self assert: outerPass branchCount equals: 2.
	self assert: outerPass outer isNil.
	self assert: (instance activationOfNode: a1) token split node identicalTo: inner.
	self assert: (instance activationOfNode: a1) token split outer identicalTo: outerPass.
	self assert: (instance activationOfNode: behindInner) token split identicalTo: outerPass.
	self assert: (instance activationOfNode: after) token split isNil.
	self assert: (instance activationOfNode: after) token splitId isNil
]
